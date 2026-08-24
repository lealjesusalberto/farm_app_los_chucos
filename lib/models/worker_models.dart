enum WorkerContractType { fijo, plazoFijo, porObra }

class WorkerPaymentRecord {
  final String id;
  final String workerId;
  final String type; // 'prestaciones', 'vacaciones', 'utilidades', 'bono'
  final double amount;
  final DateTime date;
  final String? description;
  final String? responsible;

  WorkerPaymentRecord({
    required this.id,
    required this.workerId,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
    this.responsible,
  });

  Map<String, dynamic> toMap() {
    return {
      'workerId': workerId,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'responsible': responsible,
    };
  }

  factory WorkerPaymentRecord.fromMap(String id, Map<String, dynamic> map) {
    return WorkerPaymentRecord(
      id: id,
      workerId: map['workerId'] ?? '',
      type: map['type'] ?? 'bono',
      amount: (map['amount'] ?? 0).toDouble(),
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      description: map['description'],
      responsible: map['responsible'],
    );
  }
}

class Worker {
  final String id;
  final String name;
  final String idNumber; // Cédula de Identidad C.I.
  final DateTime? birthDate;
  final String gender; // 'Hombre', 'Mujer'
  final String? phone;
  final String? address;

  // Datos Laborales
  final String jobTitle; // Cargo / Descripción de puesto
  final double baseSalary;
  final String paymentFrequency; // 'Mensual', 'Quincenal', 'Semanal'
  final WorkerContractType contractType;
  final DateTime contractStartDate;
  final DateTime? contractEndDate;
  final String? workDescription; // Descripción de la obra (si es por obra)

  // Acumulados y Compromisos
  final double accumulatedSeverance; // Prestaciones Sociales
  final double accumulatedVacationsAmount;
  final int accumulatedVacationsDays;
  final double accumulatedProfits; // Utilidades
  final double accumulatedBonuses; // Bonos especiales / horarios

  final List<WorkerPaymentRecord> paymentHistory;
  final String status; // 'active', 'inactive'

  Worker({
    required this.id,
    required this.name,
    required this.idNumber,
    this.birthDate,
    this.gender = 'Hombre',
    this.phone,
    this.address,
    required this.jobTitle,
    required this.baseSalary,
    this.paymentFrequency = 'Mensual',
    required this.contractType,
    required this.contractStartDate,
    this.contractEndDate,
    this.workDescription,
    this.accumulatedSeverance = 0,
    this.accumulatedVacationsAmount = 0,
    this.accumulatedVacationsDays = 0,
    this.accumulatedProfits = 0,
    this.accumulatedBonuses = 0,
    this.paymentHistory = const [],
    this.status = 'active',
  });

  // Antigüedad en Años
  double get yearsOfService {
    final now = DateTime.now();
    final difference = now.difference(contractStartDate).inDays;
    return (difference / 365.25).clamp(0.0, 100.0);
  }

  // Antigüedad formateada (Años y Meses)
  String get formattedServiceTime {
    final now = DateTime.now();
    int years = now.year - contractStartDate.year;
    int months = now.month - contractStartDate.month;
    if (now.day < contractStartDate.day) {
      months--;
    }
    if (months < 0) {
      years--;
      months += 12;
    }
    if (years < 0) return '0 meses';
    if (years == 0) return '$months mes(es)';
    return '$years año(s) y $months mes(es)';
  }

  // Carga Patronal Estimada Mensual (Legislación Venezolana IVSS 4.5%, FAOV 2%, INCES 2% + Provisiones)
  double get estimatedMonthlyEmployerCost {
    double ivssCost = baseSalary * 0.045; // Aporte patronal estimado IVSS
    double faovCost = baseSalary * 0.02;  // Aporte patronal FAOV Banavih (2%)
    double incesCost = baseSalary * 0.02; // Aporte patronal INCES (2%)
    double severanceProvision = baseSalary * 0.15; // Provisión acumulada mensual prestaciones/vacaciones/utilidades (~15 días por trimestre + utilidades)
    
    return baseSalary + ivssCost + faovCost + incesCost + severanceProvision;
  }

  // -------------------------------------------------------------
  // CÁLCULOS AUTOMÁTICOS SEGÚN LEY LOTTT (ARTÍCULOS 142, 190, 192, 131)
  // -------------------------------------------------------------

  // Días de Garantía de Prestaciones (Art. 142 a y b: 15 días/trimestre + 2 días adicionales por año)
  int get lotttSeveranceDays {
    int years = yearsOfService.floor();
    if (years < 1) {
      double months = (DateTime.now().difference(contractStartDate).inDays / 30.43);
      int quarters = (months / 3).floor();
      return quarters * 15;
    }
    int baseDays = years * 60;
    int extraDays = (years > 1) ? (years - 1) * 2 : 0;
    if (extraDays > 30) extraDays = 30; // Máximo 30 días adicionales
    return baseDays + extraDays;
  }

  // Estimación de Prestaciones Acumuladas por Ley LOTTT ($)
  double get lotttSeveranceAmount {
    if (accumulatedSeverance > 0) return accumulatedSeverance;
    double dailyIntegralSalary = (baseSalary / 30.0) * 1.25; // Salario integral estimado
    return lotttSeveranceDays * dailyIntegralSalary;
  }

  // Días Hábiles de Vacaciones (Art. 190 LOTTT)
  // Al cumplir 1 año: 15 días hábiles remunerados
  // Cada año adicional: +1 día (máximo 15 extra → tope 30 días)
  int get lotttVacationDays {
    int years = yearsOfService.floor();
    if (years < 1) return 0;
    // extra = 0 en el año 1, sube 1 por año hasta 15 en el año 16+
    int extra = (years - 1).clamp(0, 15);
    return 15 + extra; // Rango: 15 (año 1) → 30 (año 16+)
  }

  // Días de Bono Vacacional (Art. 192 LOTTT)
  // Al cumplir 1 año: 15 días de salario normal
  // Cada año adicional: +1 día (máximo 15 extra → tope 30 días)
  int get lotttVacationBonusDays {
    int years = yearsOfService.floor();
    if (years < 1) return 0;
    // extra = 0 en el año 1, sube 1 por año hasta 15 en el año 16+
    int extra = (years - 1).clamp(0, 15);
    return 15 + extra; // Rango: 15 (año 1) → 30 (año 16+)
  }

  // Estimación Vacaciones + Bono Vacacional por Ley LOTTT ($)
  // Vacaciones (Art. 190): días hábiles × (salario/30)
  // Bono Vacacional (Art. 192): días × (salario normal/30)
  double get lotttVacationsAmount {
    if (accumulatedVacationsAmount > 0) return accumulatedVacationsAmount;
    double dailySalary = baseSalary / 30.0;
    // Total combinado = vacaciones + bono vacacional
    int totalDays = lotttVacationDays + lotttVacationBonusDays;
    return totalDays * dailySalary;
  }

  // Estimación de Utilidades Acumuladas por Ley LOTTT ($) (Art. 131: 30 días al año prorrateados)
  double get lotttProfitsAmount {
    if (accumulatedProfits > 0) return accumulatedProfits;
    double monthsWorked = (DateTime.now().difference(contractStartDate).inDays / 30.43).clamp(0.0, 12.0);
    double dailySalary = baseSalary / 30.0;
    return (monthsWorked * 2.5) * dailySalary;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'idNumber': idNumber,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'phone': phone,
      'address': address,
      'jobTitle': jobTitle,
      'baseSalary': baseSalary,
      'paymentFrequency': paymentFrequency,
      'contractType': contractType.name,
      'contractStartDate': contractStartDate.toIso8601String(),
      'contractEndDate': contractEndDate?.toIso8601String(),
      'workDescription': workDescription,
      'accumulatedSeverance': accumulatedSeverance,
      'accumulatedVacationsAmount': accumulatedVacationsAmount,
      'accumulatedVacationsDays': accumulatedVacationsDays,
      'accumulatedProfits': accumulatedProfits,
      'accumulatedBonuses': accumulatedBonuses,
      'paymentHistory': paymentHistory.map((p) => p.toMap()).toList(),
      'status': status,
    };
  }

  factory Worker.fromMap(String id, Map<String, dynamic> map) {
    WorkerContractType cType;
    String rawContract = map['contractType'] ?? 'fijo';
    if (rawContract == 'plazoFijo') {
      cType = WorkerContractType.plazoFijo;
    } else if (rawContract == 'porObra') {
      cType = WorkerContractType.porObra;
    } else {
      cType = WorkerContractType.fijo;
    }

    List<WorkerPaymentRecord> history = [];
    if (map['paymentHistory'] is List) {
      history = (map['paymentHistory'] as List)
          .map((item) => WorkerPaymentRecord.fromMap('', Map<String, dynamic>.from(item)))
          .toList();
    } else if (map['paymentHistory'] is Map) {
      (map['paymentHistory'] as Map).forEach((k, v) {
        if (v is Map) {
          history.add(WorkerPaymentRecord.fromMap(k.toString(), Map<String, dynamic>.from(v)));
        }
      });
    }

    return Worker(
      id: id,
      name: map['name'] ?? '',
      idNumber: map['idNumber'] ?? '',
      birthDate: map['birthDate'] != null ? DateTime.tryParse(map['birthDate']) : null,
      gender: map['gender'] ?? 'Hombre',
      phone: map['phone'],
      address: map['address'],
      jobTitle: map['jobTitle'] ?? 'Trabajador',
      baseSalary: (map['baseSalary'] ?? 0).toDouble(),
      paymentFrequency: map['paymentFrequency'] ?? 'Mensual',
      contractType: cType,
      contractStartDate: DateTime.tryParse(map['contractStartDate'] ?? '') ?? DateTime.now(),
      contractEndDate: map['contractEndDate'] != null ? DateTime.tryParse(map['contractEndDate']) : null,
      workDescription: map['workDescription'],
      accumulatedSeverance: (map['accumulatedSeverance'] ?? 0).toDouble(),
      accumulatedVacationsAmount: (map['accumulatedVacationsAmount'] ?? 0).toDouble(),
      accumulatedVacationsDays: (map['accumulatedVacationsDays'] ?? 0).toInt(),
      accumulatedProfits: (map['accumulatedProfits'] ?? 0).toDouble(),
      accumulatedBonuses: (map['accumulatedBonuses'] ?? 0).toDouble(),
      paymentHistory: history,
      status: map['status'] ?? 'active',
    );
  }
}
