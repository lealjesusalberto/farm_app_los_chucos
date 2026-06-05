import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/animal_models.dart';

class AnimalService extends ChangeNotifier {
  final DatabaseReference _animalsRef = FirebaseDatabase.instance.ref('animals');
  final DatabaseReference _milkRef = FirebaseDatabase.instance.ref('milkRecords');
  final DatabaseReference _deathRef = FirebaseDatabase.instance.ref('deathRecords');
  final DatabaseReference _reproductionRef = FirebaseDatabase.instance.ref('reproductionRecords');
  final DatabaseReference _weightRef = FirebaseDatabase.instance.ref('weightRecords');
  final DatabaseReference _healthRef = FirebaseDatabase.instance.ref('healthRecords');
  final DatabaseReference _individualMilkRef = FirebaseDatabase.instance.ref('individualMilkRecords');

  List<Animal> _animals = [];
  List<MilkRecord> _milkRecords = [];
  List<DeathRecord> _deathRecords = [];
  List<ReproductionRecord> _reproductionRecords = [];
  List<WeightRecord> _weightRecords = [];
  List<HealthRecord> _healthRecords = [];
  List<IndividualMilkRecord> _individualMilkRecords = [];

  List<Animal> get animals => _animals.where((a) => a.status == 'active').toList();
  List<Animal> get deadAnimals => _animals.where((a) => a.status == 'dead').toList();
  List<MilkRecord> get milkRecords => List.unmodifiable(_milkRecords);
  List<DeathRecord> get deathRecords => List.unmodifiable(_deathRecords);
  List<ReproductionRecord> get reproductionRecords => List.unmodifiable(_reproductionRecords);
  List<WeightRecord> get weightRecords => List.unmodifiable(_weightRecords);
  List<HealthRecord> get healthRecords => List.unmodifiable(_healthRecords);
  List<IndividualMilkRecord> get individualMilkRecords => List.unmodifiable(_individualMilkRecords);

  AnimalService() {
    _listenToAnimals();
    _listenToMilkRecords();
    _listenToDeathRecords();
    _listenToReproductionRecords();
    _listenToWeightRecords();
    _listenToHealthRecords();
    _listenToIndividualMilkRecords();
  }

  void _listenToAnimals() {
    _animalsRef.onValue.listen((event) {
      try {
        List<Animal> tempAnimals = [];
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = event.snapshot.value;
          if (data is Map) {
            data.forEach((key, value) {
              try {
                if (value is Map) {
                  final animalData = Map<String, dynamic>.from(value);
                  tempAnimals.add(Animal.fromMap(key.toString(), animalData));
                }
              } catch (e) {
                debugPrint('Error parseando animal $key: $e');
              }
            });
          }
        }
        _animals = tempAnimals;
        notifyListeners();
      } catch (e) {
        debugPrint('Error en listener de animales: $e');
      }
    });
  }

  void _listenToMilkRecords() {
    _milkRef.onValue.listen((event) {
      try {
        List<MilkRecord> temp = [];
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = event.snapshot.value;
          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                temp.add(MilkRecord.fromMap(key.toString(), Map<String, dynamic>.from(value)));
              }
            });
            temp.sort((a, b) => b.date.compareTo(a.date));
          }
        }
        _milkRecords = temp;
        notifyListeners();
      } catch (e) {}
    });
  }

  void _listenToDeathRecords() {
    _deathRef.onValue.listen((event) {
      try {
        List<DeathRecord> temp = [];
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = event.snapshot.value;
          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                temp.add(DeathRecord.fromMap(key.toString(), Map<String, dynamic>.from(value)));
              }
            });
            temp.sort((a, b) => b.date.compareTo(a.date));
          }
        }
        _deathRecords = temp;
        notifyListeners();
      } catch (e) {}
    });
  }

  void _listenToReproductionRecords() {
    _reproductionRef.onValue.listen((event) {
      try {
        List<ReproductionRecord> temp = [];
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = event.snapshot.value;
          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                temp.add(ReproductionRecord.fromMap(key.toString(), Map<String, dynamic>.from(value)));
              }
            });
            temp.sort((a, b) => b.date.compareTo(a.date));
          }
        }
        _reproductionRecords = temp;
        notifyListeners();
      } catch (e) {
        debugPrint('Error en listener de reproduction: $e');
      }
    });
  }

  void _listenToWeightRecords() {
    _weightRef.onValue.listen((event) {
      try {
        List<WeightRecord> temp = [];
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = event.snapshot.value;
          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                temp.add(WeightRecord.fromMap(key.toString(), Map<String, dynamic>.from(value)));
              }
            });
            temp.sort((a, b) => b.date.compareTo(a.date));
          }
        }
        _weightRecords = temp;
        notifyListeners();
      } catch (e) {
        debugPrint('Error en listener de weight: $e');
      }
    });
  }

  void _listenToHealthRecords() {
    _healthRef.onValue.listen((event) {
      try {
        List<HealthRecord> temp = [];
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = event.snapshot.value;
          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                temp.add(HealthRecord.fromMap(key.toString(), Map<String, dynamic>.from(value)));
              }
            });
            temp.sort((a, b) => b.date.compareTo(a.date));
          }
        }
        _healthRecords = temp;
        notifyListeners();
      } catch (e) {
        debugPrint('Error en listener de health: $e');
      }
    });
  }

  void _listenToIndividualMilkRecords() {
    _individualMilkRef.onValue.listen((event) {
      try {
        List<IndividualMilkRecord> temp = [];
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = event.snapshot.value;
          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                temp.add(IndividualMilkRecord.fromMap(key.toString(), Map<String, dynamic>.from(value)));
              }
            });
            temp.sort((a, b) => b.date.compareTo(a.date));
          }
        }
        _individualMilkRecords = temp;
        notifyListeners();
      } catch (e) {
        debugPrint('Error en listener de individual milk: $e');
      }
    });
  }

  Future<void> addAnimal(Animal animal) async {
    await _animalsRef.push().set(animal.toMap());
  }

  Future<void> addMilkRecord(MilkRecord record) async {
    await _milkRef.push().set(record.toMap());
  }

  Future<void> addIndividualMilkRecord(IndividualMilkRecord record) async {
    await _individualMilkRef.push().set(record.toMap());
  }

  Future<void> addReproductionRecord(ReproductionRecord record) async {
    await _reproductionRef.push().set(record.toMap());
  }

  Future<void> addWeightRecord(WeightRecord record) async {
    await _weightRef.push().set(record.toMap());
    
    // Opcional: Actualizar el peso actual del animal
    await _animalsRef.child(record.animalId).update({
      'currentWeight': record.weight,
    });
  }

  Future<void> addHealthRecord(HealthRecord record) async {
    await _healthRef.push().set(record.toMap());
  }

  Future<void> registerDeath(DeathRecord record) async {
    await _deathRef.push().set(record.toMap());
    await _animalsRef.child(record.animalId).update({
      'status': 'dead',
      'currentLocation': 'Baja',
      'group': 'Baja',
    });
  }

  List<Animal> getFilteredAnimals(String filter) {
    if (filter == 'Todos') return animals;
    
    AnimalType? type;
    switch (filter) {
      case 'Bovinos': type = AnimalType.bovine; break;
      case 'Búfalos': type = AnimalType.buffalo; break;
      case 'Equinos': type = AnimalType.equine; break;
      case 'Porcinos': type = AnimalType.porcine; break;
      case 'Aves': type = AnimalType.poultry; break;
      case 'Perros': type = AnimalType.dog; break;
    }
    
    if (type == null) return animals;
    return animals.where((a) => a.type == type).toList();
  }
}
