import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/inventory_models.dart';
import '../services/inventory_service.dart';
import 'add_inventory_item_screen.dart';

class InventoryListScreen extends StatefulWidget {
  final InventoryCategory category;
  final String categoryName;

  const InventoryListScreen(
      {super.key, required this.category, required this.categoryName});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  String _selectedSubFilter = 'Todos';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.categoryName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.primaryGreen),
            tooltip: 'Agregar Bien',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AddInventoryItemScreen(initialCategory: widget.category),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<InventoryService>(
        builder: (context, service, _) {
          final allCategoryItems =
              service.getItemsByCategory(widget.category);

          // Subcategorías únicas
          final subCategories = <String>{
            'Todos',
            ...allCategoryItems
                .map((i) => i.subCategory ?? 'General')
                .where((s) => s.isNotEmpty)
          };

          // Filtrar por subcategoría + búsqueda
          List<InventoryItem> items = _selectedSubFilter == 'Todos'
              ? allCategoryItems
              : allCategoryItems
                  .where((i) =>
                      (i.subCategory ?? 'General') == _selectedSubFilter)
                  .toList();

          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            items = items
                .where((i) =>
                    i.name.toLowerCase().contains(q) ||
                    (i.brand ?? '').toLowerCase().contains(q) ||
                    (i.subCategory ?? '').toLowerCase().contains(q))
                .toList();
          }

          if (allCategoryItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay bienes registrados en ${widget.categoryName}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddInventoryItemScreen(
                            initialCategory: widget.category),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Registrar Primer Bien',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // ── Buscador ─────────────────────────────────────────
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Buscar en ${widget.categoryName}...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.grey, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.grey, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primaryGreen, width: 1.5),
                    ),
                  ),
                ),
              ),

              // ── Filtros de Subcategoría ───────────────────────────
              if (subCategories.length > 2)
                Container(
                  height: 46,
                  color: Colors.white,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    children: subCategories.map((sub) {
                      final isSel = _selectedSubFilter == sub;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () =>
                              setState(() => _selectedSubFilter = sub),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? AppColors.primaryGreen
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              sub,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color:
                                    isSel ? Colors.white : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // ── Contador de resultados ─────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${items.length} bienes',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                    if (_searchQuery.isNotEmpty || _selectedSubFilter != 'Todos')
                      InkWell(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() {
                            _searchQuery = '';
                            _selectedSubFilter = 'Todos';
                          });
                        },
                        child: const Text('Limpiar filtros',
                            style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ── Lista de Ítems ────────────────────────────────────
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text('Sin resultados para "$_searchQuery"',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return _buildItemCard(context, items[index], service);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AddInventoryItemScreen(initialCategory: widget.category),
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Agregar',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildItemCard(
      BuildContext context, InventoryItem item, InventoryService service) {
    final hasWoodSpecs = item.length != null ||
        item.width != null ||
        item.depth != null ||
        item.radius != null ||
        item.woodType != null;
    final hasMedicalSpecs =
        item.presentation != null || item.itemType != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: item.isLowStock
            ? Border.all(color: Colors.orange.withOpacity(0.6), width: 1.5)
            : Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showItemDetailModal(context, item, service),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cabecera: Nombre + Stock ──────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _categoryColor(item).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_categoryIcon(item),
                          color: _categoryColor(item), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textDark)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              if (item.subCategory != null &&
                                  item.subCategory!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(item.subCategory!,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.primaryGreen,
                                          fontWeight: FontWeight.bold)),
                                ),
                              if (item.brand != null && item.brand!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: Text('• ${item.brand}',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 11)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.stock == item.stock.roundToDouble()
                              ? item.stock.toStringAsFixed(0)
                              : item.stock.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: item.isLowStock
                                ? Colors.orange
                                : AppColors.primaryGreen,
                          ),
                        ),
                        Text(item.unit,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),

                // ── Ficha técnica resumida ────────────────────────
                if (hasMedicalSpecs &&
                    item.subCategory == 'Insumos Médicos Veterinarios') ...[
                  const SizedBox(height: 8),
                  _buildSpecBadge(
                      '${item.itemType ?? "Medicina"} • ${item.presentation ?? "N/A"}',
                      Colors.blue,
                      Icons.medical_services_outlined),
                ],

                if (hasWoodSpecs) ...[
                  const SizedBox(height: 8),
                  _buildSpecBadge(
                      '${item.woodType ?? item.itemType ?? "Madera"}'
                      '${item.length != null ? " • L:${item.length}m" : ""}'
                      '${item.width != null ? " An:${item.width}cm" : ""}',
                      Colors.brown,
                      Icons.square_foot),
                ],

                if (item.quantityBags != null || item.kgPerBag != null) ...[
                  const SizedBox(height: 8),
                  _buildSpecBadge(
                      '${item.quantityBags?.toStringAsFixed(0) ?? ""} sacos × ${item.kgPerBag?.toStringAsFixed(0) ?? "?"} Kg/saco'
                      '${item.totalKg != null ? " = ${item.totalKg!.toStringAsFixed(1)} Kg" : ""}',
                      Colors.amber.shade800,
                      Icons.shopping_bag_outlined),
                ],

                // ── Tags: Ubicación, Stock Bajo, Vencimiento ──────
                if (item.isLowStock ||
                    item.isExpired ||
                    (item.location != null && item.location!.isNotEmpty) ||
                    item.expirationDate != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (item.location != null && item.location!.isNotEmpty)
                        _buildTag(item.location!,
                            Icons.location_on_outlined, Colors.grey.shade600),
                      if (item.expirationDate != null)
                        _buildTag(
                          'Vence: ${DateFormat('dd/MM/yy').format(item.expirationDate!)}',
                          item.isExpired ? Icons.event_busy : Icons.event,
                          item.isExpired ? Colors.red : Colors.blueGrey,
                        ),
                      if (item.isLowStock)
                        _buildTag('⚠ Stock Bajo',
                            Icons.warning_amber_rounded, Colors.orange),
                    ],
                  ),
                ],

                const Divider(height: 20),

                // ── Botones de Acción ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Ver Detalles
                    InkWell(
                      onTap: () =>
                          _showItemDetailModal(context, item, service),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline,
                                size: 14, color: AppColors.primaryGreen),
                            SizedBox(width: 5),
                            Text('Ver Detalles',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),

                    // Entrada / Salida
                    Row(
                      children: [
                        _buildActionButton(
                            Icons.remove, Colors.red,
                            () => _showTransactionDialog(
                                context, item, 'Salida', service)),
                        const SizedBox(width: 8),
                        _buildActionButton(
                            Icons.add, AppColors.primaryGreen,
                            () => _showTransactionDialog(
                                context, item, 'Entrada', service)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(text,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Color _categoryColor(InventoryItem item) {
    final sub = (item.subCategory ?? '').toLowerCase();
    if (sub.contains('médico') || sub.contains('veterinar')) return Colors.blue;
    if (sub.contains('madera') || item.woodType != null) return Colors.brown;
    if (sub.contains('herramienta')) return Colors.blueGrey;
    return AppColors.primaryGreen;
  }

  IconData _categoryIcon(InventoryItem item) {
    final sub = (item.subCategory ?? '').toLowerCase();
    if (sub.contains('médico') || sub.contains('veterinar')) {
      return Icons.medical_services_outlined;
    }
    if (sub.contains('madera') || item.woodType != null) {
      return Icons.park_outlined;
    }
    if (sub.contains('herramienta')) {
      return Icons.build_outlined;
    }
    return Icons.inventory_2_outlined;
  }

  // ── Diálogo de Transacción ──────────────────────────────────────
  void _showTransactionDialog(BuildContext context, InventoryItem item,
      String type, InventoryService service) {
    final qtyController = TextEditingController();
    final respController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(
              type == 'Entrada' ? Icons.add_circle : Icons.remove_circle,
              color: type == 'Entrada' ? AppColors.primaryGreen : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$type: ${item.name}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Cantidad (${item.unit})',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: respController,
              decoration: InputDecoration(
                labelText: 'Responsable',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCELAR',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              final qty =
                  double.tryParse(qtyController.text.trim()) ?? 0.0;
              if (qty > 0 && respController.text.trim().isNotEmpty) {
                service.addTransaction(
                  InventoryTransaction(
                    id: DateTime.now().toString(),
                    itemId: item.id,
                    quantity: qty,
                    type: type,
                    date: DateTime.now(),
                    responsible: respController.text.trim(),
                  ),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('$type registrada: $qty ${item.unit}'),
                  backgroundColor: type == 'Entrada'
                      ? AppColors.primaryGreen
                      : Colors.red,
                ));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  type == 'Entrada' ? AppColors.primaryGreen : Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('CONFIRMAR',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Modal de Detalles (ESTÁTICO: sin Consumer reactivo) ─────────
  void _showItemDetailModal(
      BuildContext context, InventoryItem item, InventoryService service) {
    // Capturamos el estado actual del ítem UNA SOLA VEZ antes de abrir el modal
    final currentItem =
        (item.id.isNotEmpty ? service.getItemById(item.id) : null) ?? item;
    final txHistory = service.transactions
        .where((t) =>
            currentItem.id.isNotEmpty && t.itemId == currentItem.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Sin Consumer aquí para evitar rebuilds durante la animación del modal
      builder: (_) => _ItemDetailSheet(
        item: currentItem,
        txHistory: txHistory,
        onEntrada: () => _showTransactionDialog(
            context, currentItem, 'Entrada', service),
        onSalida: () => _showTransactionDialog(
            context, currentItem, 'Salida', service),
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────────
// Widget estático separado para el Bottom Sheet de Detalles
// (separado del árbol de Consumer para evitar rebuilds de Firebase)
// ─────────────────────────────────────────────────────────────────
class _ItemDetailSheet extends StatelessWidget {
  final InventoryItem item;
  final List<InventoryTransaction> txHistory;
  final VoidCallback onEntrada;
  final VoidCallback onSalida;

  const _ItemDetailSheet({
    required this.item,
    required this.txHistory,
    required this.onEntrada,
    required this.onSalida,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.88,
        minHeight: screenHeight * 0.5,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10)),
          ),

          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: AppColors.primaryGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark)),
                      if (item.subCategory != null &&
                          item.subCategory!.isNotEmpty)
                        Text(item.subCategory!,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Stock Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: item.isLowStock
                          ? [Colors.orange.shade50, Colors.orange.shade100]
                          : [
                              AppColors.primaryGreen.withOpacity(0.06),
                              AppColors.primaryGreen.withOpacity(0.14)
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
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
                          const Text('Stock Actual',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black54)),
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
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: Text(item.unit,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54)),
                              ),
                            ],
                          ),
                          Text(
                              'Mínimo: ${item.minStock.toStringAsFixed(0)} ${item.unit}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.black45)),
                        ],
                      ),
                      Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              onEntrada();
                            },
                            icon: const Icon(Icons.add,
                                size: 14, color: Colors.white),
                            label: const Text('Entrada',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              onSalida();
                            },
                            icon: const Icon(Icons.remove,
                                size: 14, color: Colors.white),
                            label: const Text('Salida',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Sacos/Kg Card
                if (item.quantityBags != null || item.kgPerBag != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined,
                            color: Colors.amber, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${item.quantityBags?.toStringAsFixed(0) ?? ""} sacos  ×  ${item.kgPerBag?.toStringAsFixed(0) ?? "?"} Kg/saco'
                            '${item.totalKg != null ? "  =  ${item.totalKg!.toStringAsFixed(1)} Kg total" : ""}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Ficha Técnica
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.primaryGreen, size: 18),
                    SizedBox(width: 8),
                    Text('Ficha Técnica',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      if (item.brand != null && item.brand!.isNotEmpty)
                        _infoRow('Marca / Fabricante', item.brand!,
                            Icons.branding_watermark_outlined),
                      if (item.itemType != null &&
                          item.itemType!.isNotEmpty) ...[
                        const Divider(height: 14),
                        _infoRow('Tipo / Clasificación', item.itemType!,
                            Icons.category_outlined),
                      ],
                      if (item.presentation != null &&
                          item.presentation!.isNotEmpty) ...[
                        const Divider(height: 14),
                        _infoRow('Presentación / Vía', item.presentation!,
                            Icons.local_hospital_outlined),
                      ],
                      if (item.packaging != null &&
                          item.packaging!.isNotEmpty) ...[
                        const Divider(height: 14),
                        _infoRow('Embalaje', item.packaging!,
                            Icons.inventory_outlined),
                      ],
                      if (item.usage != null && item.usage!.isNotEmpty) ...[
                        const Divider(height: 14),
                        _infoRow('Uso Recomendado', item.usage!,
                            Icons.assignment_outlined),
                      ],
                      if (item.location != null &&
                          item.location!.isNotEmpty) ...[
                        const Divider(height: 14),
                        _infoRow('Ubicación / Bodega', item.location!,
                            Icons.place_outlined),
                      ],
                      if (item.expirationDate != null) ...[
                        const Divider(height: 14),
                        _infoRow(
                          'Fecha de Vencimiento',
                          DateFormat('dd/MM/yyyy')
                              .format(item.expirationDate!),
                          Icons.event_outlined,
                          valueColor:
                              item.isExpired ? Colors.red : null,
                        ),
                      ],
                      if (item.woodType != null ||
                          item.length != null) ...[
                        const Divider(height: 14),
                        _infoRow('Especie Madera',
                            item.woodType ?? 'N/A', Icons.park_outlined),
                        if (item.length != null)
                          _infoRow(
                              'Dimensiones',
                              '${item.length}m (L) × ${item.width ?? 0}cm (An) × ${item.depth ?? 0}cm (P)',
                              Icons.straighten),
                      ],
                    ],
                  ),
                ),

                // Historial de Movimientos
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.history,
                            color: AppColors.primaryGreen, size: 18),
                        SizedBox(width: 8),
                        Text('Movimientos Recientes',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark)),
                      ],
                    ),
                    Text('${txHistory.length} registros',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 10),

                if (txHistory.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Center(
                        child: Text('Sin movimientos registrados aún',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12))),
                  )
                else
                  Column(
                    children: txHistory.take(15).map((tx) {
                      final isEntrada = tx.type == 'Entrada';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
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
                                color: isEntrada
                                    ? Colors.green
                                    : Colors.red,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(tx.type,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: isEntrada
                                              ? Colors.green[800]
                                              : Colors.red[800])),
                                  Text(
                                      '${tx.responsible} • ${DateFormat('dd/MM/yy HH:mm').format(tx.date)}',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey)),
                                  if (tx.notes != null &&
                                      tx.notes!.isNotEmpty)
                                    Text(tx.notes!,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black54)),
                                ],
                              ),
                            ),
                            Text(
                              '${isEntrada ? '+' : '-'}${tx.quantity == tx.quantity.roundToDouble() ? tx.quantity.toStringAsFixed(0) : tx.quantity.toStringAsFixed(1)} ${item.unit}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isEntrada
                                      ? Colors.green
                                      : Colors.red),
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
        ],
      ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey))),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppColors.textDark)),
      ],
    );
  }
}
