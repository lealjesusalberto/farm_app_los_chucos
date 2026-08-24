enum InventoryCategory { insumos, noConsumibles, proyectos, herramientas, maquinaria }

class InventoryItem {
  final String id;
  final String name;
  final String unit; // Kg, Litros, Unidades, Sacos, ml, Gr, etc.
  final double stock;
  final InventoryCategory category;
  final String? subCategory; // ej. 'Insumos Médicos', 'Equipos de Trabajo', 'Madera', 'Carpintería'
  final String? itemType; // ej. 'Antibiótico', 'Vacuna Aftosa', 'Granos', 'Construcción'
  final String? packaging; // Saco, Quintal, Cesta, Frasco, etc.
  final String? presentation; // Oral, Inyectado, Tópico, Intravaginal, etc.
  final String? usage; // Uso recomendado / Aplicación
  final String? brand;
  final DateTime? expirationDate;
  final String? location; // Bodega, Estante, Fundo
  final double minStock;

  // Ficha Técnica específica de Madera
  final double? length; // Largo
  final double? width; // Ancho
  final double? depth; // Profundidad
  final double? radius; // Radio
  final String? woodType; // Tipo de Madera (Teca, Pino, Saqui-Saqui, etc.)

  // Campos de cantidad dual: Sacos y Kg por Saco
  final double? quantityBags;   // Número de sacos
  final double? kgPerBag;       // Kg por saco (para calcular total en Kg)

  InventoryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.stock,
    required this.category,
    this.subCategory,
    this.itemType,
    this.packaging,
    this.presentation,
    this.usage,
    this.brand,
    this.expirationDate,
    this.location,
    this.minStock = 0,
    this.length,
    this.width,
    this.depth,
    this.radius,
    this.woodType,
    this.quantityBags,
    this.kgPerBag,
  });

  bool get isLowStock => stock <= minStock;
  bool get isExpired => expirationDate != null && expirationDate!.isBefore(DateTime.now());

  // Total en Kg calculado a partir de sacos
  double? get totalKg {
    if (quantityBags != null && kgPerBag != null) {
      return quantityBags! * kgPerBag!;
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'unit': unit,
      'stock': stock,
      'category': category.name,
      'subCategory': subCategory,
      'itemType': itemType,
      'packaging': packaging,
      'presentation': presentation,
      'usage': usage,
      'brand': brand,
      'expirationDate': expirationDate?.toIso8601String(),
      'location': location,
      'minStock': minStock,
      'length': length,
      'width': width,
      'depth': depth,
      'radius': radius,
      'woodType': woodType,
      'quantityBags': quantityBags,
      'kgPerBag': kgPerBag,
    };
  }

  factory InventoryItem.fromMap(String id, Map<String, dynamic> map) {
    String rawCategory = map['category'] ?? 'insumos';
    InventoryCategory cat;

    // Mapeo retrocompatible de categorías anteriores
    if (rawCategory == 'consumibles' || rawCategory == 'agricola') {
      cat = InventoryCategory.insumos;
    } else if (rawCategory == 'medicina') {
      cat = InventoryCategory.noConsumibles;
    } else if (rawCategory == 'madera') {
      cat = InventoryCategory.herramientas;
    } else {
      cat = InventoryCategory.values.firstWhere(
        (c) => c.name == rawCategory,
        orElse: () => InventoryCategory.insumos,
      );
    }

    return InventoryItem(
      id: id,
      name: map['name'] ?? '',
      unit: map['unit'] ?? '',
      stock: (map['stock'] ?? 0).toDouble(),
      category: cat,
      subCategory: map['subCategory'],
      itemType: map['itemType'],
      packaging: map['packaging'],
      presentation: map['presentation'],
      usage: map['usage'],
      brand: map['brand'],
      expirationDate: map['expirationDate'] != null ? DateTime.tryParse(map['expirationDate']) : null,
      location: map['location'],
      minStock: (map['minStock'] ?? 0).toDouble(),
      length: map['length'] != null ? (map['length'] as num).toDouble() : null,
      width: map['width'] != null ? (map['width'] as num).toDouble() : null,
      depth: map['depth'] != null ? (map['depth'] as num).toDouble() : null,
      radius: map['radius'] != null ? (map['radius'] as num).toDouble() : null,
      woodType: map['woodType'],
      quantityBags: map['quantityBags'] != null ? (map['quantityBags'] as num).toDouble() : null,
      kgPerBag: map['kgPerBag'] != null ? (map['kgPerBag'] as num).toDouble() : null,
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
