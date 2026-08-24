import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/inventory_models.dart';

class InventoryService extends ChangeNotifier {
  final DatabaseReference _itemsRef =
      FirebaseDatabase.instance.ref('inventoryItems');
  final DatabaseReference _transactionsRef =
      FirebaseDatabase.instance.ref('inventoryTransactions');

  List<InventoryItem> _items = [];
  List<InventoryTransaction> _transactions = [];

  List<InventoryItem> get items => List.unmodifiable(_items);
  List<InventoryTransaction> get transactions =>
      List.unmodifiable(_transactions);

  InventoryService() {
    _listenToItems();
    _listenToTransactions();
  }

  // ── Parseo pesado movido fuera del hilo de UI con compute ──────
  static List<InventoryItem> _parseItems(Map<dynamic, dynamic> data) {
    final result = <InventoryItem>[];
    data.forEach((key, value) {
      if (value is Map) {
        try {
          result.add(InventoryItem.fromMap(
              key.toString(), Map<String, dynamic>.from(value)));
        } catch (_) {}
      }
    });
    return result;
  }

  static List<InventoryTransaction> _parseTx(Map<dynamic, dynamic> data) {
    final result = <InventoryTransaction>[];
    data.forEach((key, value) {
      if (value is Map) {
        try {
          result.add(InventoryTransaction.fromMap(
              key.toString(), Map<String, dynamic>.from(value)));
        } catch (_) {}
      }
    });
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  void _listenToItems() {
    _itemsRef.onValue.listen((event) async {
      try {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = event.snapshot.value;
          if (data is Map) {
            // Parseo en isolate secundario para no bloquear UI
            _items = await compute(_parseItems, data);
          } else if (data is List) {
            final map = <dynamic, dynamic>{};
            for (int i = 0; i < data.length; i++) {
              if (data[i] != null) map[i.toString()] = data[i];
            }
            _items = await compute(_parseItems, map);
          }
        } else {
          _items = [];
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Error en _listenToItems: $e');
      }
    }, onError: (error) => debugPrint('Firebase items error: $error'));
  }

  void _listenToTransactions() {
    _transactionsRef.onValue.listen((event) async {
      try {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final data = event.snapshot.value;
          if (data is Map) {
            _transactions = await compute(_parseTx, data);
          } else if (data is List) {
            final map = <dynamic, dynamic>{};
            for (int i = 0; i < data.length; i++) {
              if (data[i] != null) map[i.toString()] = data[i];
            }
            _transactions = await compute(_parseTx, map);
          }
        } else {
          _transactions = [];
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Error en _listenToTransactions: $e');
      }
    }, onError: (error) => debugPrint('Firebase tx error: $error'));
  }

  List<InventoryItem> getItemsByCategory(InventoryCategory category) {
    return _items.where((item) => item.category == category).toList();
  }

  Future<void> addTransaction(InventoryTransaction transaction) async {
    final newTxRef = _transactionsRef.push();
    await newTxRef.set(transaction.toMap());

    // Actualizar stock del item directamente en Firebase
    final itemSnapshot = await _itemsRef.child(transaction.itemId).get();
    if (itemSnapshot.exists && itemSnapshot.value != null) {
      final itemData =
          Map<String, dynamic>.from(itemSnapshot.value as Map);
      final double currentStock = (itemData['stock'] ?? 0).toDouble();
      final double newStock = transaction.type == 'Entrada'
          ? currentStock + transaction.quantity
          : (currentStock - transaction.quantity).clamp(0.0, double.infinity);

      await _itemsRef
          .child(transaction.itemId)
          .update({'stock': newStock});
    }
  }

  InventoryItem? getItemById(String id) {
    if (id.isEmpty) return null;
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addItem(InventoryItem item,
      {String responsible = 'Administrador'}) async {
    final newRef = _itemsRef.push();
    await newRef.set(item.toMap());

    if (item.stock > 0 && newRef.key != null) {
      final tx = InventoryTransaction(
        id: '',
        itemId: newRef.key!,
        quantity: item.stock,
        type: 'Entrada',
        date: DateTime.now(),
        responsible: responsible,
        notes: 'Registro e ingreso inicial en inventario',
      );
      final newTxRef = _transactionsRef.push();
      await newTxRef.set(tx.toMap());
    }
  }
}
