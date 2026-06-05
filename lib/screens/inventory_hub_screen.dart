import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import '../models/inventory_models.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';
import 'inventory_list_screen.dart';

class InventoryHubScreen extends StatelessWidget {
  const InventoryHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(child: _buildAlertSummary(context)),
                  const SizedBox(height: 25),
                  const Text('Categorías de Inventario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 15),
                  _buildCategoriesGrid(context),
                  const SizedBox(height: 30),
                  const Text('Movimientos Recientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 15),
                  _buildRecentTransactions(),
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
      childAspectRatio: 1.1,
      children: [
        _buildCategoryCard(context, 'Agrícola', 'Semillas y Químicos', Icons.grass, Colors.green, InventoryCategory.agricola),
        _buildCategoryCard(context, 'Medicinas', 'Veterinaria', Icons.medical_services, Colors.blue, InventoryCategory.medicina),
        _buildCategoryCard(context, 'Madera', 'Infraestructura', Icons.fence, Colors.brown, InventoryCategory.madera),
        _buildCategoryCard(context, 'Herramientas', 'Bienes Muebles', Icons.handyman, Colors.orange, InventoryCategory.maquinaria),
      ],
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, String sub, IconData icon, Color color, InventoryCategory cat) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => InventoryListScreen(category: cat, categoryName: title))),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Center(
        child: Text('No hay movimientos recientes', style: TextStyle(color: Colors.grey, fontSize: 13)),
      ),
    );
  }
}
