import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/task_models.dart';

class TaskService extends ChangeNotifier {
  final DatabaseReference _tasksRef = FirebaseDatabase.instance.ref().child('tasks');

  List<FarmTask> _tasks = [];
  List<FarmTask> get tasks => List.unmodifiable(_tasks);

  TaskService() {
    _listenToTasks();
  }

  void _listenToTasks() {
    _tasksRef.onValue.listen((event) {
      try {
        List<FarmTask> temp = [];
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = event.snapshot.value;
          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                temp.add(FarmTask.fromMap(key.toString(), Map<String, dynamic>.from(value)));
              }
            });
          } else if (data is List) {
            for (var i = 0; i < data.length; i++) {
              if (data[i] != null && data[i] is Map) {
                temp.add(FarmTask.fromMap(i.toString(), Map<String, dynamic>.from(data[i])));
              }
            }
          }
          temp.sort((a, b) => b.date.compareTo(a.date));
        }
        _tasks = temp;
        notifyListeners();
      } catch (e) {
        debugPrint('Error en _listenToTasks: $e');
      }
    }, onError: (error) => debugPrint('Permiso denegado en tasks: $error'));
  }

  Future<void> addTask(FarmTask task) async {
    final temp = List<FarmTask>.from(_tasks)..insert(0, task);
    _tasks = temp;
    notifyListeners();
    await _tasksRef.push().set(task.toMap());
  }

  Future<void> updateTask(String id, Map<String, dynamic> updates) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final temp = List<FarmTask>.from(_tasks);
      final existing = temp[index];
      
      temp[index] = existing.copyWith(
        title: updates['title'],
        category: updates['category'],
        date: updates['date'] != null ? DateTime.tryParse(updates['date']) : null,
        cost: updates['cost'] != null ? (updates['cost'] as num).toDouble() : null,
        responsible: updates['responsible'],
        details: updates['details'],
        status: updates['status'],
        assignedToUserId: updates['assignedToUserId'],
        relatedEntityId: updates['relatedEntityId'],
      );
      
      _tasks = temp;
      notifyListeners();
    }
    await _tasksRef.child(id).update(updates);
  }

  Future<void> deleteTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final temp = List<FarmTask>.from(_tasks);
      temp.removeAt(index);
      _tasks = temp;
      notifyListeners();
    }
    await _tasksRef.child(id).remove();
  }
}

