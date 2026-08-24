enum TransactionType { income, expense }

class FinanceTransaction {
  final String id;
  final String title;
  final String category; // 'Venta Leche', 'Venta Queso', 'Venta Ganado', 'Nómina', 'Insumos', 'Medicinas', 'Herramientas', etc.
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? notes;

  // Campos adicionales para Libro Diario y Registro de Compras
  final double? quantity;
  final String? unit; // 'Sacos', 'Kg', 'Litros', 'Libras', 'mg', 'Unidades'
  final String? vendor; // Proveedor o Vendedor / Cliente
  final String? invoiceNumber; // Número de Factura o Nota de Entrega
  final String? receiptUrl; // Imagen / Documento de comprobante

  FinanceTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    this.notes,
    this.quantity,
    this.unit,
    this.vendor,
    this.invoiceNumber,
    this.receiptUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'type': type.name,
      'date': date.toIso8601String(),
      'notes': notes,
      'quantity': quantity,
      'unit': unit,
      'vendor': vendor,
      'invoiceNumber': invoiceNumber,
      'receiptUrl': receiptUrl,
    };
  }

  factory FinanceTransaction.fromMap(String id, Map<String, dynamic> map) {
    return FinanceTransaction(
      id: id,
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      notes: map['notes'],
      quantity: map['quantity'] != null ? (map['quantity'] as num).toDouble() : null,
      unit: map['unit'],
      vendor: map['vendor'],
      invoiceNumber: map['invoiceNumber'],
      receiptUrl: map['receiptUrl'],
    );
  }
}

class Employee {
  final String id;
  final String name;
  final String position; // 'Vaquero', 'Obrero', 'Administrador'
  final double salary;
  final String paymentFrequency; // 'Semanal', 'Quincenal'
  final DateTime hireDate;
  final bool isActive;

  Employee({
    required this.id,
    required this.name,
    required this.position,
    required this.salary,
    required this.paymentFrequency,
    required this.hireDate,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'position': position,
      'salary': salary,
      'paymentFrequency': paymentFrequency,
      'hireDate': hireDate.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Employee.fromMap(String id, Map<String, dynamic> map) {
    return Employee(
      id: id,
      name: map['name'] ?? '',
      position: map['position'] ?? '',
      salary: (map['salary'] ?? 0).toDouble(),
      paymentFrequency: map['paymentFrequency'] ?? 'Semanal',
      hireDate: DateTime.tryParse(map['hireDate'] ?? '') ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }
}

class PayrollRecord {
  final String id;
  final String employeeId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double amount;
  final DateTime paymentDate;
  final String status; // 'Pagado', 'Pendiente'

  PayrollRecord({
    required this.id,
    required this.employeeId,
    required this.periodStart,
    required this.periodEnd,
    required this.amount,
    required this.paymentDate,
    this.status = 'Pagado',
  });

  Map<String, dynamic> toMap() {
    return {
      'employeeId': employeeId,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'status': status,
    };
  }

  factory PayrollRecord.fromMap(String id, Map<String, dynamic> map) {
    return PayrollRecord(
      id: id,
      employeeId: map['employeeId'] ?? '',
      periodStart: DateTime.tryParse(map['periodStart'] ?? '') ?? DateTime.now(),
      periodEnd: DateTime.tryParse(map['periodEnd'] ?? '') ?? DateTime.now(),
      amount: (map['amount'] ?? 0).toDouble(),
      paymentDate: DateTime.tryParse(map['paymentDate'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'Pagado',
    );
  }
}
