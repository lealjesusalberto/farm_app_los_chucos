import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/land_models.dart';

class LandService extends ChangeNotifier {
  final DatabaseReference _potrerosRef = FirebaseDatabase.instance.ref('potreros');
  final DatabaseReference _fieldWorkRef = FirebaseDatabase.instance.ref('fieldWork');

  List<Potrero> _potreros = [];
  List<FieldWork> _fieldWorkHistory = [];

  List<Potrero> get potreros => List.unmodifiable(_potreros);
  List<FieldWork> get fieldWorkHistory => List.unmodifiable(_fieldWorkHistory);

  LandService() {
    _listenToPotreros();
    _listenToFieldWork();
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

  void _listenToFieldWork() {
    _fieldWorkRef.onValue.listen((event) {
      try {
        _fieldWorkHistory = [];
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = event.snapshot.value;
          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                _fieldWorkHistory.add(FieldWork.fromMap(key.toString(), Map<String, dynamic>.from(value)));
              }
            });
          } else if (data is List) {
            for (int i = 0; i < data.length; i++) {
              if (data[i] is Map) {
                _fieldWorkHistory.add(FieldWork.fromMap(i.toString(), Map<String, dynamic>.from(data[i])));
              }
            }
          }
          _fieldWorkHistory.sort((a, b) => b.date.compareTo(a.date));
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Error en _listenToFieldWork: $e');
      }
    }, onError: (error) => debugPrint('Permiso denegado en fieldWork: $error'));
  }

  Future<void> addFieldWork(FieldWork work) async {
    final newRef = _fieldWorkRef.push();
    await newRef.set(work.toMap());

    if (work.status == 'Completada') {
      // Actualizar estado del potrero solo si la labor está completada o es mantenimiento inmediato
      await _potrerosRef.child(work.potreroId).update({
        'status': 'En Mantenimiento',
      });
    }
  }

  Future<void> updateFieldWork(String id, Map<String, dynamic> updates) async {
    await _fieldWorkRef.child(id).update(updates);
  }

  Future<void> rotateCattle(String sourcePotreroId, String targetPotreroId, String lotName) async {
    // Quitar ganado del potrero origen
    if (sourcePotreroId.isNotEmpty) {
      await _potrerosRef.child(sourcePotreroId).update({
        'status': 'En Descanso',
        'currentCattleLot': '',
      });
    }

    // Mover ganado al potrero destino
    await _potrerosRef.child(targetPotreroId).update({
      'status': 'Disponible',
      'currentCattleLot': lotName,
    });
  }

  // Agregar potrero nuevo
  Future<void> addPotrero(Potrero potrero) async {
    final newRef = _potrerosRef.push();
    await newRef.set(potrero.toMap());
  }

  // Actualizar potrero existente
  Future<void> updatePotrero(String id, Map<String, dynamic> updates) async {
    await _potrerosRef.child(id).update(updates);
  }

  // Eliminar potrero
  Future<void> deletePotrero(String id) async {
    await _potrerosRef.child(id).remove();
  }
}
