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
      _transactions = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final txData = Map<String, dynamic>.from(value);
          _transactions.add(FinanceTransaction.fromMap(key, txData));
        });
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      }
      notifyListeners();
    });
  }

  void _listenToEmployees() {
    _employeesRef.onValue.listen((event) {
      _employees = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final empData = Map<String, dynamic>.from(value);
          _employees.add(Employee.fromMap(key, empData));
        });
      }
      notifyListeners();
    });
  }

  void _listenToPayroll() {
    _payrollRef.onValue.listen((event) {
      _payrollHistory = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final prData = Map<String, dynamic>.from(value);
          _payrollHistory.add(PayrollRecord.fromMap(key, prData));
        });
        _payrollHistory.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      }
      notifyListeners();
    });
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
