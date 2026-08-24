import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/finance_models.dart';
import 'inventory_service.dart';
import 'worker_service.dart';

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

  Future<void> deleteTransaction(String id) async {
    await _transactionsRef.child(id).remove();
  }

  Future<void> addEmployee(Employee employee) async {
    final newRef = _employeesRef.push();
    await newRef.set(employee.toMap());
  }

  Future<void> processPayroll(PayrollRecord record) async {
    final newRef = _payrollRef.push();
    await newRef.set(record.toMap());

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

  // -------------------------------------------------------------
  // CONTABILIDAD: LIBRO DIARIO, LIBRO MAYOR & BALANCE GENERAL
  // -------------------------------------------------------------

  // Consolidado por Categorías para el Libro Mayor
  Map<String, Map<String, double>> getLedgerCategorySummary() {
    final Map<String, Map<String, double>> summary = {};

    for (var tx in _transactions) {
      if (!summary.containsKey(tx.category)) {
        summary[tx.category] = {'ingresos': 0.0, 'egresos': 0.0, 'neto': 0.0};
      }
      if (tx.type == TransactionType.income) {
        summary[tx.category]!['ingresos'] = (summary[tx.category]!['ingresos'] ?? 0) + tx.amount;
      } else {
        summary[tx.category]!['egresos'] = (summary[tx.category]!['egresos'] ?? 0) + tx.amount;
      }
      summary[tx.category]!['neto'] = summary[tx.category]!['ingresos']! - summary[tx.category]!['egresos']!;
    }

    return summary;
  }

  // Valoración Monetaria del Inventario (Activo)
  double getInventoryTotalValue(InventoryService? inventoryService) {
    if (inventoryService == null) return 0.0;
    double total = 0.0;
    for (var item in inventoryService.items) {
      // Estimar precio unitario base si no se encuentra definido ($10.0 valor estándar)
      double unitPrice = 10.0;
      total += (item.stock * unitPrice);
    }
    return total;
  }

  // Pasivos Laborales de RRHH (Prestaciones Sociales + Vacaciones + Parafiscales)
  double getWorkerTotalPassives(WorkerService? workerService) {
    if (workerService == null) return 0.0;
    return workerService.totalAccumulatedSeverance +
        workerService.totalAccumulatedVacations +
        workerService.totalAccumulatedProfits +
        workerService.monthlyIvssTotal +
        workerService.monthlyFaovTotal +
        workerService.monthlyIncesTotal;
  }

  // Total Activos = Disponible en Caja + Valor Inventarios
  double getTotalAssets(InventoryService? inventoryService, {double accountsReceivable = 0.0}) {
    return balance + getInventoryTotalValue(inventoryService) + accountsReceivable;
  }

  // Total Pasivos = Pasivos Laborales LOTTT + Cuentas por Pagar Proveedores
  double getTotalLiabilities(WorkerService? workerService, {double accountsPayable = 0.0}) {
    return getWorkerTotalPassives(workerService) + accountsPayable;
  }

  // Patrimonio Neto = Total Activos - Total Pasivos
  double getNetEquity(InventoryService? inventoryService, WorkerService? workerService, {double ar = 0.0, double ap = 0.0}) {
    return getTotalAssets(inventoryService, accountsReceivable: ar) - getTotalLiabilities(workerService, accountsPayable: ap);
  }
}
