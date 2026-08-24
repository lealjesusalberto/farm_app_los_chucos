import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/worker_models.dart';

class WorkerService extends ChangeNotifier {
  final DatabaseReference _workersRef = FirebaseDatabase.instance.ref('workers');

  List<Worker> _workers = [];

  List<Worker> get workers => List.unmodifiable(_workers);
  List<Worker> get activeWorkers => List.unmodifiable(_workers.where((w) => w.status == 'active').toList());

  WorkerService() {
    _listenToWorkers();
  }

  void _listenToWorkers() {
    _workersRef.onValue.listen((event) {
      try {
        _workers = [];
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = event.snapshot.value;
          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                _workers.add(Worker.fromMap(key.toString(), Map<String, dynamic>.from(value)));
              }
            });
          } else if (data is List) {
            for (int i = 0; i < data.length; i++) {
              if (data[i] is Map) {
                _workers.add(Worker.fromMap(i.toString(), Map<String, dynamic>.from(data[i])));
              }
            }
          }
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Error en _listenToWorkers: $e');
      }
    }, onError: (error) => debugPrint('Permiso denegado en workers: $error'));
  }

  Worker? getWorkerById(String id) {
    try {
      return _workers.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addWorker(Worker worker) async {
    final newRef = _workersRef.push();
    await newRef.set(worker.toMap());
  }

  Future<void> updateWorker(String id, Map<String, dynamic> updates) async {
    await _workersRef.child(id).update(updates);
  }

  Future<void> deleteWorker(String id) async {
    await _workersRef.child(id).remove();
  }

  // Registrar un pago / abono / liquidación parcial
  Future<void> addPaymentRecord(String workerId, WorkerPaymentRecord record) async {
    final worker = getWorkerById(workerId);
    if (worker == null) return;

    final updatedHistory = List<WorkerPaymentRecord>.from(worker.paymentHistory)..add(record);

    double newSeverance = worker.accumulatedSeverance;
    double newVacations = worker.accumulatedVacationsAmount;
    double newProfits = worker.accumulatedProfits;
    double newBonuses = worker.accumulatedBonuses;

    if (record.type == 'prestaciones') {
      newSeverance = (newSeverance - record.amount).clamp(0.0, double.infinity);
    } else if (record.type == 'vacaciones') {
      newVacations = (newVacations - record.amount).clamp(0.0, double.infinity);
    } else if (record.type == 'utilidades') {
      newProfits = (newProfits - record.amount).clamp(0.0, double.infinity);
    } else if (record.type == 'bono') {
      newBonuses = newBonuses + record.amount;
    }

    await _workersRef.child(workerId).update({
      'accumulatedSeverance': newSeverance,
      'accumulatedVacationsAmount': newVacations,
      'accumulatedProfits': newProfits,
      'accumulatedBonuses': newBonuses,
      'paymentHistory': updatedHistory.map((p) => p.toMap()).toList(),
    });
  }

  // Métricas globales
  double get totalMonthlyBasePayroll {
    return activeWorkers.fold(0.0, (sum, w) => sum + w.baseSalary);
  }

  double get totalEstimatedEmployerCost {
    return activeWorkers.fold(0.0, (sum, w) => sum + w.estimatedMonthlyEmployerCost);
  }

  double get totalAccumulatedSeverance {
    return activeWorkers.fold(0.0, (sum, w) => sum + w.accumulatedSeverance);
  }

  double get totalAccumulatedVacations {
    return activeWorkers.fold(0.0, (sum, w) => sum + w.accumulatedVacationsAmount);
  }

  double get totalAccumulatedProfits {
    return activeWorkers.fold(0.0, (sum, w) => sum + w.accumulatedProfits);
  }

  // Desglose Parafiscal Estimado Mensual
  double get monthlyIvssTotal => activeWorkers.fold(0.0, (sum, w) => sum + (w.baseSalary * 0.045));
  double get monthlyFaovTotal => activeWorkers.fold(0.0, (sum, w) => sum + (w.baseSalary * 0.02));
  double get monthlyIncesTotal => activeWorkers.fold(0.0, (sum, w) => sum + (w.baseSalary * 0.02));
}
