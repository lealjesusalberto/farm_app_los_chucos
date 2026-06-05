import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/animal_service.dart';
import '../services/land_service.dart';
import '../models/user_models.dart';
import '../models/animal_models.dart';
import 'animal_production_screen.dart';
import 'potreros_module_screen.dart';
import 'inventory_hub_screen.dart';
import 'finance_hub_screen.dart';
import 'user_management_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, user),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Resumen de Producción'),
                  const SizedBox(height: 15),
                  _buildStatsGrid(context),
                  const SizedBox(height: 30),
                  _buildSectionTitle('Módulos Principales'),
                  const SizedBox(height: 15),
                  _buildModulesGrid(context, user),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(BuildContext context, AppUser? user) {
    return Stack(
      children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/dashboard_bg.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        Container(
          height: 250,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.1),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: AppColors.primaryGreen),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hola, ${user?.name ?? "Usuario"}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user?.roleDisplayName ?? "Invitado",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_outlined, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
                            onPressed: () async {
                              final authService = Provider.of<AuthService>(context, listen: false);
                              await authService.logout();
                              if (context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                FadeInLeft(
                  child: const Text(
                    'Reporte de Progreso\nAgropecuaria',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('Ver todo'),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final animalService = Provider.of<AnimalService>(context);
    final landService = Provider.of<LandService>(context);

    final activeAnimals = animalService.animals;
    final bovinesCount = activeAnimals.where((a) => a.type == AnimalType.bovine).length;
    final porcinesCount = activeAnimals.where((a) => a.type == AnimalType.porcine).length;

    final now = DateTime.now();
    final todayMilk = animalService.milkRecords
        .where((r) => r.date.year == now.year && r.date.month == now.month && r.date.day == now.day)
        .fold(0.0, (sum, r) => sum + r.totalLiters);
    final milkStr = '${(todayMilk % 1 == 0 ? todayMilk.toInt() : todayMilk.toStringAsFixed(1))}L';

    final tasksCount = landService.fieldWorkHistory.length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Bovinos',
          '$bovinesCount',
          'https://images.pexels.com/photos/235725/pexels-photo-235725.jpeg?auto=compress&cs=tinysrgb&w=500',
          FontAwesomeIcons.cow,
          useImageAsBackground: true,
          isAsset: false,
        ),
        _buildStatCard(
          'Porcinos',
          '$porcinesCount',
          'assets/porcinos.png',
          FontAwesomeIcons.piggyBank,
          useImageAsBackground: true,
          isAsset: true,
        ),
        _buildStatCard(
          'Leche/Día',
          milkStr,
          'assets/milk.png',
          FontAwesomeIcons.droplet,
          useImageAsBackground: true,
          isAsset: true,
        ),
        _buildStatCard(
          'Tareas',
          '$tasksCount',
          'assets/work.png',
          FontAwesomeIcons.listCheck,
          useImageAsBackground: true,
          isAsset: true,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String imageUrl,
    IconData fallbackIcon, {
    bool useImageAsBackground = false,
    bool isAsset = false,
  }) {
    if (useImageAsBackground) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[300], // Fondo por defecto para evitar transparencia al cargar
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              isAsset
                  ? Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.primaryGreen,
                        child: Center(
                          child: Icon(fallbackIcon, size: 40, color: Colors.white.withOpacity(0.5)),
                        ),
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.primaryGreen,
                        child: Center(
                          child: Icon(fallbackIcon, size: 40, color: Colors.white.withOpacity(0.5)),
                        ),
                      ),
                    ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.65),
                      Colors.black.withOpacity(0.3),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(fallbackIcon, size: 20, color: Colors.white70),
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: isAsset
                    ? Image.asset(
                        imageUrl,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 32,
                          height: 32,
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          child: Icon(fallbackIcon, size: 16, color: AppColors.primaryGreen),
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 32,
                          height: 32,
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          child: Icon(fallbackIcon, size: 16, color: AppColors.primaryGreen),
                        ),
                      ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesGrid(BuildContext context, AppUser? user) {
    final List<Widget> modules = [];

    // Módulo Ganado (Animales): Visible si tiene acceso a alguna de sus sub-funciones
    if (user?.canAccessAnimalModule ?? false) {
      modules.add(_buildModuleItem(
        context,
        'Animales',
        'https://images.unsplash.com/photo-1546445317-29f4545e9d53?w=500&q=80',
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnimalProductionScreen()),
        ),
      ));
    }

    // Módulo Potreros: Solo si canManageLand
    if (user?.canManageLand ?? false) {
      modules.add(_buildModuleItem(
        context,
        'Potreros',
        'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=500&q=80',
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PotrerosModuleScreen()),
        ),
      ));
    }

    if (user?.canManageInventory ?? false) {
      modules.add(_buildModuleItem(
        context,
        'Inventario',
        'https://images.unsplash.com/photo-1553413077-190dd305871c?w=500&q=80',
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InventoryHubScreen()),
        ),
      ));
    }

    if (user?.canManageFinance ?? false) {
      modules.add(_buildModuleItem(
        context,
        'Finanzas',
        'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=500&q=80',
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FinanceHubScreen()),
        ),
      ));
    }

    if (user?.canAdminUsers ?? false) {
      modules.add(_buildModuleItem(
        context,
        'Personal',
        'https://images.pexels.com/photos/1216589/pexels-photo-1216589.jpeg?auto=compress&cs=tinysrgb&w=500',
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserManagementScreen()),
        ),
      ));
    }

    if (user?.canManageFinance ?? false || (user?.canManageInventory ?? false)) {
      modules.add(_buildModuleItem(
        context,
        'Reportes',
        'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=500&q=80',
        () {},
      ));
    }

    if (modules.isEmpty) {
      return const Center(child: Text('No tienes acceso a ningún módulo. Contacta al administrador.', style: TextStyle(color: Colors.grey)));
    }

    if (modules.length <= 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: modules.map((m) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SizedBox(
            width: 110,
            height: 110,
            child: m,
          ),
        )).toList(),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: modules,
    );
  }

  Widget _buildModuleItem(BuildContext context, String label, String imageUrl, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    child: const Icon(
                      Icons.image_not_supported,
                      color: AppColors.primaryGreen,
                      size: 30,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          Icon(Icons.home, color: AppColors.primaryGreen, size: 28),
          Icon(Icons.bar_chart, color: Colors.grey, size: 28),
          Icon(Icons.calendar_month, color: Colors.grey, size: 28),
          Icon(Icons.settings, color: Colors.grey, size: 28),
        ],
      ),
    );
  }
}
