class FarmTask {
  final String id;
  final String title;
  final String category; // 'Potreros', 'Salud', 'Mantenimiento', 'General'
  final DateTime date;
  final double cost;
  final String responsible;
  final String? details;
  final String status; // 'Pendiente', 'En Progreso', 'Completada'
  final String? assignedToUserId;
  final String? relatedEntityId;

  FarmTask({
    required this.id,
    required this.title,
    this.category = 'General',
    required this.date,
    required this.cost,
    required this.responsible,
    this.details,
    this.status = 'Pendiente',
    this.assignedToUserId,
    this.relatedEntityId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'date': date.toIso8601String(),
      'cost': cost,
      'responsible': responsible,
      'details': details,
      'status': status,
      'assignedToUserId': assignedToUserId,
      'relatedEntityId': relatedEntityId,
    };
  }

  factory FarmTask.fromMap(String id, Map<String, dynamic> map) {
    return FarmTask(
      id: id,
      title: map['title'] ?? map['type'] ?? 'Tarea sin título',
      category: map['category'] ?? 'Potreros',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      cost: (map['cost'] ?? 0).toDouble(),
      responsible: map['responsible'] ?? '',
      details: map['details'],
      status: map['status'] ?? 'Pendiente',
      assignedToUserId: map['assignedToUserId'],
      relatedEntityId: map['relatedEntityId'] ?? map['potreroId'],
    );
  }

  FarmTask copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? date,
    double? cost,
    String? responsible,
    String? details,
    String? status,
    String? assignedToUserId,
    String? relatedEntityId,
  }) {
    return FarmTask(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      cost: cost ?? this.cost,
      responsible: responsible ?? this.responsible,
      details: details ?? this.details,
      status: status ?? this.status,
      assignedToUserId: assignedToUserId ?? this.assignedToUserId,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
    );
  }
}

