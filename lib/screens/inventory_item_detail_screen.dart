import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/inventory_models.dart';
import '../services/inventory_service.dart';
import 'add_inventory_item_screen.dart';

class InventoryItemDetailScreen extends StatefulWidget {
  final String itemId;
  final InventoryItem? item;

  const InventoryItemDetailScreen({
    super.key,
    required this.itemId,
    this.item,
  });

  @override
  State<InventoryItemDetailScreen> createState() => _InventoryItemDetailScreenState();
}

class _InventoryItemDetailScreenState extends State<InventoryItemDetailScreen> {

  Color _categoryColor(InventoryCategory cat) {
    switch (cat) {
      case InventoryCategory.insumos:
        return Colors.green;
      case InventoryCategory.noConsumibles:
        return Colors.blue;
      case InventoryCategory.proyectos:
        return Colors.deepOrange;
      case InventoryCategory.herramientas:
        return Colors.brown;
      case InventoryCategory.maquinaria:
        return Colors.indigo;
    }
  }

  String _categoryName(InventoryCategory cat) {
    switch (cat) {
      case InventoryCategory.insumos:
        return 'Insumos';
      case InventoryCategory.noConsumibles:
        return 'No Consumibles';
      case InventoryCategory.proyectos:
        return 'Proyectos';
      case InventoryCategory.herramientas:
        return 'Herramientas & Madera';
      case InventoryCategory.maquinaria:
        return 'Equipos y Maquinaria';
    }
  }

  void _showTransactionDialog(InventoryItem item, String type) {
    final qtyController = TextEditingController();
    final respController = TextEditingController();
    // Capturar el service ANTES de abrir el diálogo para evitar pérdida de contexto
    final service = Provider.of<InventoryService>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(type == 'Entrada' ? Icons.add_circle : Icons.remove_circle,
                color: type == 'Entrada' ? Colors.green : Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text('$type — ${item.name}', style: const TextStyle(fontSize: 15))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Cantidad (${item.unit})',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: respController,
              decoration: InputDecoration(
                labelText: 'Responsable',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(qtyController.text) ?? 0.0;
              if (qty > 0 && respController.text.isNotEmpty) {
                service.addTransaction(
                  InventoryTransaction(
                    id: DateTime.now().toString(),
                    itemId: item.id,
                    quantity: qty,
                    type: type,
                    date: DateTime.now(),
                    responsible: respController.text,
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: type == 'Entrada' ? AppColors.primaryGreen : Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('CONFIRMAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InventoryService>(
      builder: (context, service, child) {
        final item = (widget.itemId.isNotEmpty ? service.getItemById(widget.itemId) : null) ?? widget.item;

        debugPrint('🔍 [INVENTARIO DETALLE] build() -> itemId recibido: "${widget.itemId}", item encontrado: "${item?.name}", categoría: ${item?.category.name}, stock: ${item?.stock}');

        if (item == null) {
          debugPrint('⚠️ [INVENTARIO DETALLE] item es NULL. Items en memoria del servicio: ${service.items.length}');
          return Scaffold(
            appBar: AppBar(title: const Text('Ficha de Bien')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text('Ítem no encontrado (ID: "${widget.itemId}")',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Es posible que los datos estén sincronizando con Firebase.',
                        textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        }

        final effectiveId = item.id.isNotEmpty ? item.id : widget.itemId;
        final catColor = _categoryColor(item.category);
        final txHistory = service.transactions
            .where((t) => effectiveId.isNotEmpty && t.itemId == effectiveId)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        debugPrint('🚀 [INVENTARIO DETALLE] Retornando Scaffold de Ficha Técnica para "${item.name}" con ${txHistory.length} transacciones');

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Ficha Técnica del Bien',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textDark,
            elevation: 0.5,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primaryGreen),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          AddInventoryItemScreen(initialCategory: item.category)),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.inventory_2_outlined,
                                color: catColor, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark)),
                                const SizedBox(height: 4),
                                if (item.brand != null && item.brand!.isNotEmpty)
                                  Text('Marca: ${item.brand}',
                                      style: TextStyle(
                                          color: Colors.grey[600], fontSize: 13)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: catColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(_categoryName(item.category),
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: catColor)),
                                    ),
                                    if (item.subCategory != null &&
                                        item.subCategory!.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(item.subCategory!,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey)),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Stock prominente
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: item.isLowStock
                                ? [Colors.orange.shade50, Colors.orange.shade100]
                                : [
                                    AppColors.primaryGreen.withOpacity(0.05),
                                    AppColors.primaryGreen.withOpacity(0.12)
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: item.isLowStock
                                ? Colors.orange.withOpacity(0.4)
                                : AppColors.primaryGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Stock Actual',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600])),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      item.stock == item.stock.roundToDouble()
                                          ? item.stock.toStringAsFixed(0)
                                          : item.stock.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: item.isLowStock
                                            ? Colors.orange
                                            : AppColors.primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 5),
                                      child: Text(item.unit,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700])),
                                    ),
                                  ],
                                ),
                                Text(
                                    'Mínimo: ${item.minStock.toStringAsFixed(0)} ${item.unit}',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[600])),
                              ],
                            ),
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _showTransactionDialog(item, 'Entrada'),
                                  icon: const Icon(Icons.add,
                                      size: 16, color: Colors.white),
                                  label: const Text('Entrada',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _showTransactionDialog(item, 'Salida'),
                                  icon: const Icon(Icons.remove,
                                      size: 16, color: Colors.white),
                                  label: const Text('Salida',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Medida dual Sacos / Kg
                      if (item.quantityBags != null || item.kgPerBag != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.shopping_bag_outlined,
                                  color: Colors.amber, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Medida en Sacos',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.brown,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                            fontSize: 13, color: Colors.black87),
                                        children: [
                                          if (item.quantityBags != null)
                                            TextSpan(
                                              text:
                                                  '${item.quantityBags!.toStringAsFixed(0)} sacos',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          if (item.quantityBags != null &&
                                              item.kgPerBag != null)
                                            const TextSpan(text: '  ×  '),
                                          if (item.kgPerBag != null)
                                            TextSpan(
                                              text:
                                                  '${item.kgPerBag!.toStringAsFixed(0)} Kg/saco',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          if (item.totalKg != null)
                                            TextSpan(
                                              text:
                                                  '  =  ${item.totalKg!.toStringAsFixed(1)} Kg total',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.brown),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Alertas
                      if (item.isLowStock || item.isExpired) ...[
                        const SizedBox(height: 12),
                        if (item.isLowStock)
                          _buildAlert(
                              '⚠️  Stock bajo del mínimo (${item.minStock.toStringAsFixed(0)} ${item.unit})',
                              Colors.orange),
                        if (item.isExpired)
                          _buildAlert(
                              '🚫  VENCIDO — ${DateFormat('dd/MM/yyyy').format(item.expirationDate!)}',
                              Colors.red),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Ficha Técnica
                _buildSectionHeader('Ficha Técnica Completa', Icons.info_outline),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      if (item.itemType != null && item.itemType!.isNotEmpty) ...[
                        _buildInfoRow('Tipo / Clasificación', item.itemType!,
                            Icons.category_outlined),
                        const Divider(height: 16),
                      ],
                      if (item.presentation != null &&
                          item.presentation!.isNotEmpty) ...[
                        _buildInfoRow('Presentación / Vía', item.presentation!,
                            Icons.local_hospital_outlined),
                        const Divider(height: 16),
                      ],
                      if (item.packaging != null && item.packaging!.isNotEmpty) ...[
                        _buildInfoRow('Embalaje / Presentación', item.packaging!,
                            Icons.inventory_outlined),
                        const Divider(height: 16),
                      ],
                      if (item.usage != null && item.usage!.isNotEmpty) ...[
                        _buildInfoRow(
                            'Uso / Destino', item.usage!, Icons.assignment_outlined),
                        const Divider(height: 16),
                      ],
                      if (item.location != null && item.location!.isNotEmpty) ...[
                        _buildInfoRow(
                            'Ubicación / Bodega', item.location!, Icons.place_outlined),
                        const Divider(height: 16),
                      ],
                      if (item.expirationDate != null) ...[
                        _buildInfoRow(
                          'Fecha de Vencimiento',
                          DateFormat('dd/MM/yyyy').format(item.expirationDate!),
                          Icons.event_outlined,
                          valueColor: item.isExpired ? Colors.red : AppColors.textDark,
                        ),
                        const Divider(height: 16),
                      ],
                      if (item.woodType != null) ...[
                        _buildInfoRow('Especie de Madera',
                            item.woodType ?? 'Sin especie', Icons.park_outlined),
                        if (item.length != null) ...[
                          const Divider(height: 16),
                          _buildInfoRow(
                              'Largo', '${item.length} m', Icons.straighten),
                        ],
                        if (item.width != null) ...[
                          const Divider(height: 16),
                          _buildInfoRow(
                              'Ancho', '${item.width} cm', Icons.swap_horiz),
                        ],
                        if (item.depth != null) ...[
                          const Divider(height: 16),
                          _buildInfoRow(
                              'Profundidad', '${item.depth} cm', Icons.height),
                        ],
                        if (item.radius != null) ...[
                          const Divider(height: 16),
                          _buildInfoRow('Radio', '${item.radius} cm', Icons.adjust),
                        ],
                      ],
                      if (item.itemType == null &&
                          item.presentation == null &&
                          item.packaging == null &&
                          item.usage == null &&
                          item.location == null &&
                          item.expirationDate == null &&
                          item.woodType == null)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Sin datos técnicos adicionales',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 13)),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Historial de movimientos
                _buildSectionHeader('Historial de Movimientos', Icons.history),
                const SizedBox(height: 12),

                if (txHistory.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16)),
                    child: const Center(
                        child: Text('Sin movimientos registrados',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 13))),
                  )
                else
                  Column(
                    children: txHistory.take(20).map((tx) {
                      final isEntrada = tx.type == 'Entrada';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 6)
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isEntrada
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isEntrada
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: isEntrada ? Colors.green : Colors.red,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tx.type,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isEntrada
                                              ? Colors.green[800]
                                              : Colors.red[800])),
                                  Text(
                                      '${tx.responsible} • ${DateFormat('dd/MM/yy HH:mm').format(tx.date)}',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey[600])),
                                  if (tx.notes != null && tx.notes!.isNotEmpty)
                                    Text(tx.notes!,
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.grey[500])),
                                ],
                              ),
                            ),
                            Text(
                              '${isEntrada ? '+' : '-'}${tx.quantity == tx.quantity.roundToDouble() ? tx.quantity.toStringAsFixed(0) : tx.quantity.toStringAsFixed(1)} ${item.unit}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isEntrada ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlert(String msg, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(msg,
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.textDark),
              textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
