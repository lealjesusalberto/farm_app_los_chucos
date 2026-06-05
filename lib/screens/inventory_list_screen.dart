import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/inventory_models.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';

class InventoryListScreen extends StatelessWidget {
  final InventoryCategory category;
  final String categoryName;

  const InventoryListScreen({super.key, required this.category, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Inventario $categoryName'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: Consumer<InventoryService>(
        builder: (context, service, child) {
          final items = service.getItemsByCategory(category);

          if (items.isEmpty) {
            return const Center(child: Text('No hay ítems en esta categoría'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return FadeInUp(
                delay: Duration(milliseconds: index * 50),
                child: _buildItemCard(context, item),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, InventoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: item.isLowStock ? Border.all(color: Colors.orange.withOpacity(0.5)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (item.brand != null)
                      Text(item.brand!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${item.stock}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: item.isLowStock ? Colors.orange : AppColors.primaryGreen)),
                  Text(item.unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (item.expirationDate != null)
                Row(
                  children: [
                    Icon(Icons.event, size: 14, color: item.isExpired ? Colors.red : Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Vence: ${DateFormat('dd/MM/yy').format(item.expirationDate!)}',
                      style: TextStyle(fontSize: 11, color: item.isExpired ? Colors.red : Colors.grey),
                    ),
                  ],
                )
              else
                const SizedBox(),
              Row(
                children: [
                  _buildActionButton(context, Icons.remove, Colors.red, () => _showTransactionDialog(context, item, 'Salida')),
                  const SizedBox(width: 10),
                  _buildActionButton(context, Icons.add, AppColors.primaryGreen, () => _showTransactionDialog(context, item, 'Entrada')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _showTransactionDialog(BuildContext context, InventoryItem item, String type) {
    final qtyController = TextEditingController();
    final respController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$type de ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Cantidad (${item.unit})'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: respController,
              decoration: const InputDecoration(labelText: 'Responsable'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(qtyController.text) ?? 0.0;
              if (qty > 0 && respController.text.isNotEmpty) {
                Provider.of<InventoryService>(context, listen: false).addTransaction(
                  InventoryTransaction(
                    id: DateTime.now().toString(),
                    itemId: item.id,
                    quantity: qty,
                    type: type,
                    date: DateTime.now(),
                    responsible: respController.text,
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: type == 'Entrada' ? AppColors.primaryGreen : Colors.red),
            child: const Text('CONFIRMAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
