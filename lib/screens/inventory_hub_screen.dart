import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/inventory_models.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';
import 'package:intl/intl.dart';
import 'add_inventory_item_screen.dart';
import 'inventory_list_screen.dart';
import 'projects_detail_screen.dart';

class InventoryHubScreen extends StatelessWidget {
  const InventoryHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddInventoryItemScreen()),
          );
        },
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo Producto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAlertSummary(context),
                  const SizedBox(height: 25),
                  const Text('Categorías de Inventario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 15),
                  _buildCategoriesGrid(context),
                  const SizedBox(height: 30),
                  const Text('Movimientos Recientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 15),
                  _buildRecentTransactions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 150,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryGreen,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Logística & Stock', style: TextStyle(fontWeight: FontWeight.bold)),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.primaryGreen),
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(Icons.inventory_2, size: 150, color: Colors.white.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertSummary(BuildContext context) {
    final service = Provider.of<InventoryService>(context);
    final lowStock = service.items.where((i) => i.isLowStock).length;
    final expired = service.items.where((i) => i.isExpired).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Stock Bajo',
            lowStock.toString(),
            lowStock > 0 ? Colors.orange : Colors.grey,
            Icons.warning_amber_rounded,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildStatCard(
            'Vencidos',
            expired.toString(),
            expired > 0 ? Colors.red : Colors.grey,
            Icons.event_busy,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.05,
      children: [
        _buildCategoryCard(
          context,
          '1. Insumos',
          'Médicos, Vet, Alimentos, Concentrados',
          Icons.grass,
          Colors.green,
          InventoryCategory.insumos,
        ),
        _buildCategoryCard(
          context,
          '2. Proyectos',
          'Infraestructura & Obras',
          Icons.foundation,
          Colors.deepOrange,
          InventoryCategory.proyectos,
        ),
        _buildCategoryCard(
          context,
          '3. Herramientas & Madera',
          'Construcción, Mecánica & Madera',
          Icons.construction,
          Colors.brown,
          InventoryCategory.herramientas,
        ),
        _buildCategoryCard(
          context,
          '4. Equipos y Maquinaria',
          'Tractores, Bombas, Generadores',
          Icons.precision_manufacturing,
          Colors.indigo,
          InventoryCategory.maquinaria,
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String sub,
    IconData icon,
    Color color,
    InventoryCategory cat,
  ) {
    final service = Provider.of<InventoryService>(context);
    final count = service.getItemsByCategory(cat).length;

    return InkWell(
      onTap: () {
        if (cat == InventoryCategory.proyectos) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProjectsDetailScreen()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InventoryListScreen(category: cat, categoryName: title),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count ítems',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    final service = Provider.of<InventoryService>(context);
    final transactions = service.transactions.take(5).toList();

    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text('No hay movimientos recientes', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      );
    }

    return Column(
      children: transactions.map((tx) {
        final isEntrada = tx.type == 'Entrada';
        final item = service.getItemById(tx.itemId);
        final itemName = item?.name ?? 'Producto';
        final unit = item?.unit ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isEntrada ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isEntrada ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      '${tx.responsible} • ${DateFormat('dd/MM HH:mm').format(tx.date)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isEntrada ? '+' : '-'}${tx.quantity} $unit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isEntrada ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    tx.type,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
