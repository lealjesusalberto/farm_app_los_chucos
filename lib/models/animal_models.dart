import 'package:flutter/material.dart';

enum AnimalType { bovine, buffalo, equine, porcine, poultry, dog }
enum AnimalOrigin { nacimiento, comprado }

class Animal {
  final String id;
  final String code;
  final String? name;
  final String? photoUrl;
  final AnimalType type;
  final String breed;
  final String sex;
  final DateTime birthDate;
  final DateTime entryDate;
  final AnimalOrigin origin;
  final double currentWeight;
  final String currentLocation;
  final String group;
  final String? fatherId;
  final String? motherId;
  final String status;

  Animal({
    required this.id,
    required this.code,
    this.name,
    this.photoUrl,
    required this.type,
    required this.breed,
    required this.sex,
    required this.birthDate,
    required this.entryDate,
    this.origin = AnimalOrigin.nacimiento,
    this.currentWeight = 0.0,
    required this.currentLocation,
    required this.group,
    this.fatherId,
    this.motherId,
    this.status = 'active',
  });

  int get ageInMonths {
    final now = DateTime.now();
    return (now.year - birthDate.year) * 12 + now.month - birthDate.month;
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'photoUrl': photoUrl,
      'type': type.name,
      'breed': breed,
      'sex': sex,
      'birthDate': birthDate.toIso8601String(),
      'entryDate': entryDate.toIso8601String(),
      'origin': origin.name,
      'currentWeight': currentWeight,
      'currentLocation': currentLocation,
      'group': group,
      'fatherId': fatherId,
      'motherId': motherId,
      'status': status,
    };
  }

  factory Animal.fromMap(String id, Map<String, dynamic> map) {
    return Animal(
      id: id,
      code: map['code']?.toString() ?? 'S/C',
      name: map['name']?.toString(),
      photoUrl: map['photoUrl']?.toString(),
      type: _parseType(map['type']),
      breed: map['breed']?.toString() ?? 'N/A',
      sex: map['sex']?.toString() ?? 'N/A',
      birthDate: DateTime.tryParse(map['birthDate']?.toString() ?? '') ?? DateTime.now(),
      entryDate: DateTime.tryParse(map['entryDate']?.toString() ?? '') ?? (DateTime.tryParse(map['birthDate']?.toString() ?? '') ?? DateTime.now()),
      origin: _parseOrigin(map['origin']),
      currentWeight: _parseDouble(map['currentWeight']),
      currentLocation: map['currentLocation']?.toString() ?? 'General',
      group: map['group']?.toString() ?? 'General',
      fatherId: map['fatherId']?.toString(),
      motherId: map['motherId']?.toString(),
      status: map['status']?.toString() ?? 'active',
    );
  }

  static AnimalOrigin _parseOrigin(dynamic val) {
    if (val == null) return AnimalOrigin.nacimiento;
    return AnimalOrigin.values.firstWhere((o) => o.name == val.toString(), orElse: () => AnimalOrigin.nacimiento);
  }

  static AnimalType _parseType(dynamic val) {
    if (val == null) return AnimalType.bovine;
    return AnimalType.values.firstWhere((t) => t.name == val.toString(), orElse: () => AnimalType.bovine);
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}

class MilkRecord {
  final String id;
  final DateTime date;
  final double totalLiters;
  final String amOrPm;

  MilkRecord({required this.id, required this.date, required this.totalLiters, this.amOrPm = 'Both'});

  Map<String, dynamic> toMap() => {'date': date.toIso8601String(), 'totalLiters': totalLiters, 'amOrPm': amOrPm};

  factory MilkRecord.fromMap(String id, Map<String, dynamic> map) {
    return MilkRecord(
      id: id,
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      totalLiters: (map['totalLiters'] is num) ? (map['totalLiters'] as num).toDouble() : 0.0,
      amOrPm: map['amOrPm']?.toString() ?? 'Both',
    );
  }
}

class IndividualMilkRecord {
  final String id;
  final String animalId;
  final DateTime date;
  final double liters;
  final String amOrPm;
  final String? notes;

  IndividualMilkRecord({
    required this.id,
    required this.animalId,
    required this.date,
    required this.liters,
    this.amOrPm = 'Both',
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'animalId': animalId,
    'date': date.toIso8601String(),
    'liters': liters,
    'amOrPm': amOrPm,
    'notes': notes,
  };

  factory IndividualMilkRecord.fromMap(String id, Map<String, dynamic> map) {
    return IndividualMilkRecord(
      id: id,
      animalId: map['animalId']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      liters: (map['liters'] is num) ? (map['liters'] as num).toDouble() : 0.0,
      amOrPm: map['amOrPm']?.toString() ?? 'Both',
      notes: map['notes']?.toString(),
    );
  }
}

class DeathRecord {
  final String id;
  final String animalId;
  final DateTime date;
  final String cause;
  final String? observations;

  DeathRecord({required this.id, required this.animalId, required this.date, required this.cause, this.observations});

  Map<String, dynamic> toMap() => {'animalId': animalId, 'date': date.toIso8601String(), 'cause': cause, 'observations': observations};

  factory DeathRecord.fromMap(String id, Map<String, dynamic> map) {
    return DeathRecord(
      id: id,
      animalId: map['animalId']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      cause: map['cause']?.toString() ?? 'Desconocida',
      observations: map['observations']?.toString(),
    );
  }
}

enum ReproductionRecordType { service, pregnancy, birth }

class ReproductionRecord {
  final String id;
  final String animalId;
  final ReproductionRecordType type;
  final DateTime date;
  final String? bullName;
  final String? serviceType; // e.g. "IA", "Monta Natural"
  final bool? isPregnant;
  final String? calfId;
  final String? notes;

  ReproductionRecord({
    required this.id,
    required this.animalId,
    required this.type,
    required this.date,
    this.bullName,
    this.serviceType,
    this.isPregnant,
    this.calfId,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'animalId': animalId,
      'type': type.name,
      'date': date.toIso8601String(),
      'bullName': bullName,
      'serviceType': serviceType,
      'isPregnant': isPregnant,
      'calfId': calfId,
      'notes': notes,
    };
  }

  factory ReproductionRecord.fromMap(String id, Map<String, dynamic> map) {
    return ReproductionRecord(
      id: id,
      animalId: map['animalId']?.toString() ?? '',
      type: _parseReproductionType(map['type']),
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      bullName: map['bullName']?.toString(),
      serviceType: map['serviceType']?.toString(),
      isPregnant: map['isPregnant'] as bool?,
      calfId: map['calfId']?.toString(),
      notes: map['notes']?.toString(),
    );
  }

  static ReproductionRecordType _parseReproductionType(dynamic val) {
    if (val == null) return ReproductionRecordType.service;
    return ReproductionRecordType.values.firstWhere(
      (t) => t.name == val.toString(),
      orElse: () => ReproductionRecordType.service,
    );
  }
}

class WeightRecord {
  final String id;
  final String animalId;
  final DateTime date;
  final double weight;
  final String? notes;

  WeightRecord({
    required this.id,
    required this.animalId,
    required this.date,
    required this.weight,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'animalId': animalId,
      'date': date.toIso8601String(),
      'weight': weight,
      'notes': notes,
    };
  }

  factory WeightRecord.fromMap(String id, Map<String, dynamic> map) {
    return WeightRecord(
      id: id,
      animalId: map['animalId']?.toString() ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      weight: (map['weight'] is num) ? (map['weight'] as num).toDouble() : (double.tryParse(map['weight']?.toString() ?? '0') ?? 0.0),
      notes: map['notes']?.toString(),
    );
  }
}

enum HealthRecordType { vaccine, bath, treatment }

class HealthRecord {
  final String id;
  final String herd;
  final HealthRecordType type;
  final String name; // name of vaccine/bath product
  final DateTime date;
  final DateTime? nextDueDate;
  final String? notes;
  final String? animalId;
  final String? animalType;

  HealthRecord({
    required this.id,
    required this.herd,
    required this.type,
    required this.name,
    required this.date,
    this.nextDueDate,
    this.notes,
    this.animalId,
    this.animalType,
  });

  Map<String, dynamic> toMap() {
    return {
      'herd': herd,
      'type': type.name,
      'name': name,
      'date': date.toIso8601String(),
      'nextDueDate': nextDueDate?.toIso8601String(),
      'notes': notes,
      'animalId': animalId,
      'animalType': animalType,
    };
  }

  factory HealthRecord.fromMap(String id, Map<String, dynamic> map) {
    return HealthRecord(
      id: id,
      herd: map['herd']?.toString() ?? 'General',
      type: _parseHealthType(map['type']),
      name: map['name']?.toString() ?? 'Desconocido',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      nextDueDate: map['nextDueDate'] != null ? DateTime.tryParse(map['nextDueDate'].toString()) : null,
      notes: map['notes']?.toString(),
      animalId: map['animalId']?.toString(),
      animalType: map['animalType']?.toString(),
    );
  }

  static HealthRecordType _parseHealthType(dynamic val) {
    if (val == null) return HealthRecordType.vaccine;
    return HealthRecordType.values.firstWhere(
      (t) => t.name == val.toString(),
      orElse: () => HealthRecordType.vaccine,
    );
  }
}

extension AnimalTypeGroups on AnimalType {
  List<String> get ageGroups {
    switch (this) {
      case AnimalType.bovine:
        return ['Vaca', 'Toro', 'Novilla', 'Novillo', 'Maute', 'Becerro', 'Becerra'];
      case AnimalType.buffalo:
        return ['Búfalo', 'Búfala', 'Bubilla', 'Bubillo'];
      case AnimalType.equine:
        return ['Yegua', 'Caballo', 'Potro', 'Potra', 'Mula', 'Burro'];
      case AnimalType.porcine:
        return ['Paridoras', 'Padrotes', 'Gestantes', 'Lechones', 'Engorde'];
      case AnimalType.poultry:
        return ['Gallina', 'Gallo', 'Pollo', 'Polla'];
      case AnimalType.dog:
        return ['Cachorro', 'Adulto'];
    }
  }
}
