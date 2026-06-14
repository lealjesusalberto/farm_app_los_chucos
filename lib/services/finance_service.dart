import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/finance_models.dart';

class FinanceService extends ChangeNotifier {
  final DatabaseReference _transactionsRef = FirebaseDatabase.instance.ref('financeTransactions');
  final DatabaseReference _employeesRef = FirebaseDatabase.instance.ref('employees');
  final DatabaseReference _payrollRef = FirebaseDatabase.instance.ref('payrollRecords');

  List<FinanceTransaction> _transactions = [];
  List<Employee> _employees = [];
  List<PayrollRecord> _payrollHistory = [];

  List<FinanceTransaction> get transactions => List.unmodifiable(_transactions);
  List<Employee> get employees => List.unmodifiable(_employees);
  List<PayrollRecord> get payrollHistory => List.unmodifiable(_payrollHistory);

  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpenses => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpenses;

  FinanceService() {
    _listenToTransactions();
    _listenToEmployees();
    _listenToPayroll();
  }

  void _listenToTransactions() {
    _transactionsRef.onValue.listen((event) {
      try {
        _transactions = [];
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = event.snapshot.value;
          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                _transactions.add(FinanceTransaction.fromMap(key.toString(), Map<String, dynamic>.from(value)));
              }
            });
          } else if (data is List) {
            for (int i = 0; i < data.length; i++) {
              if (data[i] is Map) {
                _transactions.add(FinanceTransaction.fromMap(i.toString(), Map<String, dynamic>.from(data[i])));
              }
            }
          }
          _transactions.sort((a, b) => b.date.compareTo(a.date));
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Error en _listenToTransactions: $e');
      }
    }, onError: (error) => debugPrint('Permiso denegado en finance tx: $error'));
  }

  void _listenToEmployees() {
    _employeesRef.onValue.listen((event) {
      try {
        _employees = [];
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = event.snapshot.value;
          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                _employees.add(Employee.fromMap(key.toString(), Map<String, dynamic>.from(value)));
              }
            });
          } else if (data is List) {
            for (int i = 0; i < data.length; i++) {
              if (data[i] is Map) {
                _employees.add(Employee.fromMap(i.toString(), Map<String, dynamic>.from(data[i])));
              }
            }
          }
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Error en _listenToEmployees: $e');
      }
    }, onError: (error) => debugPrint('Permiso denegado en employees: $error'));
  }

  void _listenToPayroll() {
    _payrollRef.onValue.listen((event) {
      try {
        _payrollHistory = [];
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = event.snapshot.value;
          if (data is Map) {
            data.forEach((key, value) {
              if (value is Map) {
                _payrollHistory.add(PayrollRecord.fromMap(key.toString(), Map<String, dynamic>.from(value)));
              }
            });
          } else if (data is List) {
            for (int i = 0; i < data.length; i++) {
              if (data[i] is Map) {
                _payrollHistory.add(PayrollRecord.fromMap(i.toString(), Map<String, dynamic>.from(data[i])));
              }
            }
          }
          _payrollHistory.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Error en _listenToPayroll: $e');
      }
    }, onError: (error) => debugPrint('Permiso denegado en payroll: $error'));
  }

  Future<void> addTransaction(FinanceTransaction transaction) async {
    final newRef = _transactionsRef.push();
    await newRef.set(transaction.toMap());
  }

  Future<void> addEmployee(Employee employee) async {
    final newRef = _employeesRef.push();
    await newRef.set(employee.toMap());
  }

  Future<void> processPayroll(PayrollRecord record) async {
    final newRef = _payrollRef.push();
    await newRef.set(record.toMap());

    // Auto-crear transacción de gasto para esta nómina
    final empSnapshot = await _employeesRef.child(record.employeeId).get();
    String empName = 'Empleado';
    if (empSnapshot.exists) {
      final empData = Map<String, dynamic>.from(empSnapshot.value as Map);
      empName = empData['name'] ?? 'Empleado';
    }

    await addTransaction(FinanceTransaction(
      id: '',
      title: 'Pago Nómina: $empName',
      category: 'Nómina',
      amount: record.amount,
      type: TransactionType.expense,
      date: record.paymentDate,
    ));
  }
}
