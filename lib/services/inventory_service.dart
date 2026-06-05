import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/inventory_models.dart';

class InventoryService extends ChangeNotifier {
  final DatabaseReference _itemsRef = FirebaseDatabase.instance.ref('inventoryItems');
  final DatabaseReference _transactionsRef = FirebaseDatabase.instance.ref('inventoryTransactions');

  List<InventoryItem> _items = [];
  List<InventoryTransaction> _transactions = [];

  List<InventoryItem> get items => List.unmodifiable(_items);
  List<InventoryTransaction> get transactions => List.unmodifiable(_transactions);

  InventoryService() {
    _listenToItems();
    _listenToTransactions();
  }

  void _listenToItems() {
    _itemsRef.onValue.listen((event) {
      _items = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final itemData = Map<String, dynamic>.from(value);
          _items.add(InventoryItem.fromMap(key, itemData));
        });
      }
      notifyListeners();
    });
  }

  void _listenToTransactions() {
    _transactionsRef.onValue.listen((event) {
      _transactions = [];
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final txData = Map<String, dynamic>.from(value);
          _transactions.add(InventoryTransaction.fromMap(key, txData));
        });
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      }
      notifyListeners();
    });
  }

  List<InventoryItem> getItemsByCategory(InventoryCategory category) {
    return _items.where((item) => item.category == category).toList();
  }

  Future<void> addTransaction(InventoryTransaction transaction) async {
    final newTxRef = _transactionsRef.push();
    await newTxRef.set(transaction.toMap());

    // Actualizar stock del item
    final itemSnapshot = await _itemsRef.child(transaction.itemId).get();
    if (itemSnapshot.exists) {
      final itemData = Map<String, dynamic>.from(itemSnapshot.value as Map);
      double currentStock = (itemData['stock'] ?? 0).toDouble();
      double newStock = transaction.type == 'Entrada'
          ? currentStock + transaction.quantity
          : currentStock - transaction.quantity;
      
      await _itemsRef.child(transaction.itemId).update({'stock': newStock});
    }
  }

  Future<void> addItem(InventoryItem item) async {
    final newRef = _itemsRef.push();
    await newRef.set(item.toMap());
  }
}
