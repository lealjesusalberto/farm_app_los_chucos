import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/land_models.dart';

class LandService extends ChangeNotifier {
  final DatabaseReference _potrerosRef = FirebaseDatabase.instance.ref('potreros');
  List<Potrero> _potreros = [];

  List<Potrero> get potreros => List.unmodifiable(_potreros);

  LandService() {
    _listenToPotreros();
  }

  void _listenToPotreros() {
    _potrerosRef.onValue.listen((event) {
      try {
        _potreros = [];
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = event.snapshot.value;
          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                _potreros.add(Potrero.fromMap(key.toString(), Map<String, dynamic>.from(value)));
              }
            });
          } else if (data is List) {
            for (int i = 0; i < data.length; i++) {
              if (data[i] is Map) {
                _potreros.add(Potrero.fromMap(i.toString(), Map<String, dynamic>.from(data[i])));
              }
            }
          }
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Error en _listenToPotreros: $e');
      }
    }, onError: (error) => debugPrint('Permiso denegado en potreros: $error'));
  }


  Future<void> rotateCattle(String sourcePotreroId, String targetPotreroId, String lotName, {DateTime? rotationDate}) async {
    final rotationDateStr = (rotationDate ?? DateTime.now()).toIso8601String();

    // 1. Quitar este rebaño de cualquier otro potrero que lo tenga actualmente (para asegurar consistencia de ubicación única)
    for (var potrero in _potreros) {
      if (potrero.currentCattleLot == lotName && potrero.id != targetPotreroId) {
        await _potrerosRef.child(potrero.id).update({
          'status': 'En Descanso',
          'currentCattleLot': '',
          'lastRotationDate': rotationDateStr,
        });
      }
    }

    // 2. Quitar ganado del potrero origen (por seguridad, si no se limpió en el paso anterior y es un potrero válido diferente del destino)
    if (sourcePotreroId.isNotEmpty && sourcePotreroId != targetPotreroId) {
      await _potrerosRef.child(sourcePotreroId).update({
        'status': 'En Descanso',
        'currentCattleLot': '',
        'lastRotationDate': rotationDateStr,
      });
    }

    // 3. Mover ganado al potrero destino
    await _potrerosRef.child(targetPotreroId).update({
      'status': 'Disponible',
      'currentCattleLot': lotName,
      'lastRotationDate': rotationDateStr,
    });
  }

  // Agregar potrero nuevo
  Future<void> addPotrero(Potrero potrero) async {
    final temp = List<Potrero>.from(_potreros)..add(potrero);
    _potreros = temp;
    notifyListeners();
    await _potrerosRef.child(potrero.id).set(potrero.toMap());
  }

  // Actualizar potrero existente
  Future<void> updatePotrero(String id, Map<String, dynamic> updates) async {
    final index = _potreros.indexWhere((p) => p.id == id);
    if (index != -1) {
      final temp = List<Potrero>.from(_potreros);
      final existing = temp[index];
      
      List<String>? subDivs;
      if (updates['subdivisions'] != null) {
        subDivs = List<String>.from(updates['subdivisions']);
      }

      temp[index] = Potrero(
        id: existing.id,
        name: updates['name'] ?? existing.name,
        areaHectares: updates['areaHectares'] != null ? (updates['areaHectares'] as num).toDouble() : existing.areaHectares,
        status: updates['status'] ?? existing.status,
        currentCattleLot: updates['currentCattleLot'] ?? existing.currentCattleLot,
        purpose: updates['purpose'] ?? existing.purpose,
        lastRotationDate: updates['lastRotationDate'] != null ? DateTime.tryParse(updates['lastRotationDate']) : existing.lastRotationDate,
        subdivisions: subDivs ?? existing.subdivisions,
      );
      
      _potreros = temp;
      notifyListeners();
    }
    await _potrerosRef.child(id).update(updates);
  }

  // Eliminar potrero
  Future<void> deletePotrero(String id) async {
    final index = _potreros.indexWhere((p) => p.id == id);
    if (index != -1) {
      final temp = List<Potrero>.from(_potreros);
      temp.removeAt(index);
      _potreros = temp;
      notifyListeners();
    }
    await _potrerosRef.child(id).remove();
  }
}
