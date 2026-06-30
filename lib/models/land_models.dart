class Potrero {
  final String id;
  final String name;
  final double areaHectares;
  final String status; // 'Disponible', 'En Descanso', 'En Mantenimiento'
  final String currentCattleLot; // ID del lote de animales actualmente ahí
  final String purpose; // Utilidad del potrero (Maternidad, Engorde, etc.)
  final DateTime? lastRotationDate;
  final List<String> subdivisions;

  Potrero({
    required this.id,
    required this.name,
    required this.areaHectares,
    this.status = 'Disponible',
    this.currentCattleLot = '',
    this.purpose = 'General',
    this.lastRotationDate,
    this.subdivisions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'areaHectares': areaHectares,
      'status': status,
      'currentCattleLot': currentCattleLot,
      'purpose': purpose,
      'lastRotationDate': lastRotationDate?.toIso8601String(),
      'subdivisions': subdivisions,
    };
  }

  factory Potrero.fromMap(String id, Map<String, dynamic> map) {
    return Potrero(
      id: id,
      name: map['name'] ?? '',
      areaHectares: (map['areaHectares'] ?? (map['areaTareas'] != null ? (map['areaTareas'] / 15.9) : 0)).toDouble(),
      status: map['status'] ?? 'Disponible',
      currentCattleLot: map['currentCattleLot'] ?? '',
      purpose: map['purpose'] ?? 'General',
      lastRotationDate: map['lastRotationDate'] != null ? DateTime.tryParse(map['lastRotationDate']) : null,
      subdivisions: map['subdivisions'] != null
          ? List<String>.from(map['subdivisions'])
          : [],
    );
  }
}
