import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import 'animal_list_screen.dart';
import 'reproduction_screen.dart';
import 'health_module_screen.dart';
import 'production_module_screen.dart';
import 'deaths_module_screen.dart';
import 'potreros_module_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/animal_service.dart';
import '../models/animal_models.dart';

class AnimalProductionScreen extends StatelessWidget {
  const AnimalProductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(child: _buildMainStats(context)),
                  const SizedBox(height: 30),
                  const Text(
                    'Gestión Operativa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildCategoryGrid(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/animal_prod_bg.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.5), Colors.transparent],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Producción Animal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainStats(BuildContext context) {
    final animalService = Provider.of<AnimalService>(context);
    
    final totalAnimals = animalService.animals.length;
    
    // Próximos partos: Registros de preñez confirmados
    final proximosPartos = animalService.reproductionRecords
        .where((r) => r.isPregnant == true && r.type == ReproductionRecordType.pregnancy)
        .length;

    // En tratamiento: Registros de tratamiento en los últimos 30 días
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final enTratamiento = animalService.healthRecords
        .where((r) => r.type == HealthRecordType.treatment && r.date.isAfter(thirtyDaysAgo))
        .length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.secondaryGreen],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Animales', totalAnimals.toString(), FontAwesomeIcons.tags),
          _buildSummaryItem(
            'Próximos Partos',
            proximosPartos.toString(),
            FontAwesomeIcons.babyCarriage,
          ),
          _buildSummaryItem('En Tratamiento', enTratamiento.toString(), Icons.medication),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    final List<Widget> categories = [];

    if (user?.canManageAnimalInventory ?? false) {
      categories.add(_buildCategoryCard(
        context,
        'Inventario Animal',
        'Gestión de semovientes y porcicultura',
        FontAwesomeIcons.cow,
        AppColors.primaryGreen,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnimalListScreen())),
      ));
    }

    if (user?.canManageGenetics ?? false) {
      categories.add(_buildCategoryCard(
        context,
        'Reproducción',
        'IA, FIV, Celos y Partos',
        FontAwesomeIcons.dna,
        Colors.blue,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReproductionScreen())),
      ));
    }

    if (user?.canRegisterProduction ?? false) {
      categories.add(_buildCategoryCard(
        context,
        'Producción',
        'Control de Leche y Carne',
        FontAwesomeIcons.glassWater,
        Colors.orange,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductionModuleScreen())),
      ));
    }

    if (user?.canRegisterSanity ?? false) {
      categories.add(_buildCategoryCard(
        context,
        'Sanidad',
        'Vacunas, Baños y Tratamientos',
        Icons.health_and_safety,
        Colors.redAccent,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthModuleScreen())),
      ));
    }

    if (user?.canManageLand ?? false) {
      categories.add(_buildCategoryCard(
        context,
        'Pastoreo',
        'Rotación de potreros y mapa',
        Icons.map,
        Colors.teal,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PotrerosModuleScreen())),
      ));
    }

    if ((user?.canManageInventory ?? false) || (user?.canRegisterSanity ?? false)) {
      categories.add(_buildCategoryCard(
        context,
        'Decesos',
        'Registro de bajas y causas',
        FontAwesomeIcons.skull,
        Colors.grey,
        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeathsModuleScreen())),
      ));
    }

    if (categories.isEmpty) {
      return const Center(child: Text('No tienes acceso a ninguna gestión.', style: TextStyle(color: Colors.grey)));
    }

    if (categories.length == 1) {
      return Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.45,
          height: MediaQuery.of(context).size.width * 0.45,
          child: categories.first,
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      children: categories,
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
