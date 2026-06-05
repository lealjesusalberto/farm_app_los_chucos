class Potrero {
  final String id;
  final String name;
  final double areaTareas;
  final String status; // 'Disponible', 'En Descanso', 'En Mantenimiento'
  final String currentCattleLot; // ID del lote de animales actualmente ahí

  Potrero({
    required this.id,
    required this.name,
    required this.areaTareas,
    this.status = 'Disponible',
    this.currentCattleLot = '',
  });

  double get areaHectares => areaTareas / 15.9; // Factor de conversión estándar (aprox)

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'areaTareas': areaTareas,
      'status': status,
      'currentCattleLot': currentCattleLot,
    };
  }

  factory Potrero.fromMap(String id, Map<String, dynamic> map) {
    return Potrero(
      id: id,
      name: map['name'] ?? '',
      areaTareas: (map['areaTareas'] ?? 0).toDouble(),
      status: map['status'] ?? 'Disponible',
      currentCattleLot: map['currentCattleLot'] ?? '',
    );
  }
}

class FieldWork {
  final String id;
  final String potreroId;
  final String type; // 'Desmatonado', 'Fumigación'
  final DateTime date;
  final double cost;
  final String responsible;
  final String? details; // Tipo de veneno, pipas, etc.
  final String status; // 'Pendiente', 'En Progreso', 'Completada'
  final String? assignedToUserId;

  FieldWork({
    required this.id,
    required this.potreroId,
    required this.type,
    required this.date,
    required this.cost,
    required this.responsible,
    this.details,
    this.status = 'Completada',
    this.assignedToUserId,
  });

  Map<String, dynamic> toMap() {
    return {
      'potreroId': potreroId,
      'type': type,
      'date': date.toIso8601String(),
      'cost': cost,
      'responsible': responsible,
      'details': details,
      'status': status,
      'assignedToUserId': assignedToUserId,
    };
  }

  factory FieldWork.fromMap(String id, Map<String, dynamic> map) {
    return FieldWork(
      id: id,
      potreroId: map['potreroId'] ?? '',
      type: map['type'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      cost: (map['cost'] ?? 0).toDouble(),
      responsible: map['responsible'] ?? '',
      details: map['details'],
      status: map['status'] ?? 'Completada',
      assignedToUserId: map['assignedToUserId'],
    );
  }
}
