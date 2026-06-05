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
      _potreros = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final potData = Map<String, dynamic>.from(value);
          _potreros.add(Potrero.fromMap(key, potData));
        });
      }
      notifyListeners();
    });
  }

  void _listenToFieldWork() {
    _fieldWorkRef.onValue.listen((event) {
      _fieldWorkHistory = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final workData = Map<String, dynamic>.from(value);
          _fieldWorkHistory.add(FieldWork.fromMap(key, workData));
        });
        _fieldWorkHistory.sort((a, b) => b.date.compareTo(a.date));
      }
      notifyListeners();
    });
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
}
