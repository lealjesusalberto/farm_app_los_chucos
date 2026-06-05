enum InventoryCategory { agricola, medicina, madera, maquinaria }

class InventoryItem {
  final String id;
  final String name;
  final String unit; // Kg, Litros, Unidades, Sacos
  final double stock;
  final InventoryCategory category;
  final String? brand;
  final DateTime? expirationDate;
  final String? location; // Bodega A, Estante B, etc.
  final double minStock; // For alerts

  InventoryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.stock,
    required this.category,
    this.brand,
    this.expirationDate,
    this.location,
    this.minStock = 0,
  });

  bool get isLowStock => stock <= minStock;
  bool get isExpired => expirationDate != null && expirationDate!.isBefore(DateTime.now());

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'unit': unit,
      'stock': stock,
      'category': category.name,
      'brand': brand,
      'expirationDate': expirationDate?.toIso8601String(),
      'location': location,
      'minStock': minStock,
    };
  }

  factory InventoryItem.fromMap(String id, Map<String, dynamic> map) {
    return InventoryItem(
      id: id,
      name: map['name'] ?? '',
      unit: map['unit'] ?? '',
      stock: (map['stock'] ?? 0).toDouble(),
      category: InventoryCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => InventoryCategory.agricola,
      ),
      brand: map['brand'],
      expirationDate: map['expirationDate'] != null ? DateTime.tryParse(map['expirationDate']) : null,
      location: map['location'],
      minStock: (map['minStock'] ?? 0).toDouble(),
    );
  }
}

class InventoryTransaction {
  final String id;
  final String itemId;
  final double quantity;
  final String type; // 'Entrada', 'Salida'
  final DateTime date;
  final String responsible;
  final String? notes;

  InventoryTransaction({
    required this.id,
    required this.itemId,
    required this.quantity,
    required this.type,
    required this.date,
    required this.responsible,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'quantity': quantity,
      'type': type,
      'date': date.toIso8601String(),
      'responsible': responsible,
      'notes': notes,
    };
  }

  factory InventoryTransaction.fromMap(String id, Map<String, dynamic> map) {
    return InventoryTransaction(
      id: id,
      itemId: map['itemId'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      type: map['type'] ?? 'Entrada',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      responsible: map['responsible'] ?? '',
      notes: map['notes'],
    );
  }
}
