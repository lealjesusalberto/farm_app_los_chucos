import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/animal_service.dart';
import '../services/land_service.dart';
import '../services/task_service.dart';
import '../models/user_models.dart';
import '../models/animal_models.dart';
import 'animal_production_screen.dart';
import 'production_summary_screen.dart';
import 'potreros_module_screen.dart';
import 'tasks_module_screen.dart';
import 'inventory_hub_screen.dart';
import 'finance_hub_screen.dart';
import 'package:intl/intl.dart';
import '../models/land_models.dart';
import '../models/task_models.dart';
import 'user_management_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final taskService = Provider.of<TaskService>(context);
    
    final isAdmin = user?.canAdminUsers ?? false;
    final pendingTasks = taskService.tasks.where((w) => w.status == 'Pendiente' && w.assignedToUserId == user?.id).toList();

    return Scaffold(
      drawer: _buildDrawer(context, user),
      body: Builder(
        builder: (ctx) => SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(ctx, user),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Resumen de Producción', onSeeAll: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductionSummaryScreen()));
                    }),
                    const SizedBox(height: 15),
                    _buildStatsGrid(context),
                    if (pendingTasks.isNotEmpty && !isAdmin) ...[
                      const SizedBox(height: 25),
                      _buildSectionTitle('Mis Tareas Pendientes', onSeeAll: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksModuleScreen()));
                      }),
                      const SizedBox(height: 15),
                      _buildMyTasksPanel(context, pendingTasks),
                    ],
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppUser? user) {
    final taskService = Provider.of<TaskService>(context);
    final isAdmin = user?.canAdminUsers ?? false;
    final pendingTasks = taskService.tasks.where((w) => w.status == 'Pendiente' && (isAdmin || w.assignedToUserId == user?.id)).toList();

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
                    Expanded(
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => Scaffold.of(context).openDrawer(),
                            child: const CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person, color: AppColors.primaryGreen),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Hola, ${user?.name ?? "Usuario"}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    user?.roleDisplayName ?? "Invitado",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                                onPressed: () => _showNotificationsBottomSheet(context, pendingTasks),
                              ),
                            ),
                            if (pendingTasks.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${pendingTasks.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
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

  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAll}) {
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
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
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

    final tasksCount = Provider.of<TaskService>(context).tasks.length;

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

    // Módulo Potreros
    if (user?.canAccessPotrerosModule ?? false) {
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

    if (user?.canAccessInventoryModule ?? false) {
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

    if (user?.canAccessTasksModule ?? false) {
      modules.add(_buildModuleItem(
        context,
        'Tareas',
        'https://images.pexels.com/photos/5980/food-sunset-love-field.jpg?auto=compress&cs=tinysrgb&w=500',
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TasksModuleScreen()),
        ),
      ));
    }

    if (user?.canAccessFinanceModule ?? false) {
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

    if (user?.canAccessUsersModule ?? false) {
      modules.add(_buildModuleItem(
        context,
        'Usuarios',
        'https://images.pexels.com/photos/1216589/pexels-photo-1216589.jpeg?auto=compress&cs=tinysrgb&w=500',
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserManagementScreen()),
        ),
      ));
    }

    if (user?.canAccessReportsModule ?? false) {
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

  Widget _buildDrawer(BuildContext context, AppUser? user) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: AppColors.primaryGreen,
              image: DecorationImage(
                image: AssetImage('assets/dashboard_bg.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
              ),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: AppColors.primaryGreen),
            ),
            accountName: Text(user?.name ?? 'Usuario', style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(user?.roleDisplayName ?? 'Rol no definido'),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home, color: AppColors.primaryGreen),
                  title: const Text('Inicio'),
                  onTap: () => Navigator.pop(context),
                ),
                if (user?.canAccessUsersModule ?? false)
                  ListTile(
                    leading: const Icon(Icons.people, color: Colors.grey),
                    title: const Text('Gestión de Usuarios'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen()));
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () async {
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
    );
  }

  Widget _buildMyTasksPanel(BuildContext context, List<FarmTask> tasks) {
    // Tomamos máximo 3 para mostrar en el dashboard
    final displayTasks = tasks.take(3).toList();
    return Column(
      children: displayTasks.map((task) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.orange, width: 1.5)),
          child: ListTile(
            leading: const Icon(Icons.assignment, color: Colors.orange),
            title: Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange.shade800)),
            subtitle: Text('Programada: ${DateFormat('dd/MM/yy').format(task.date)}'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksModuleScreen())),
          ),
        );
      }).toList(),
    );
  }

  void _showNotificationsBottomSheet(BuildContext context, List<FarmTask> tasks) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        if (tasks.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Text('No tienes tareas pendientes.', style: TextStyle(fontSize: 16)),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tareas Asignadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.assignment_late, color: Colors.white, size: 20)),
                        title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Programada: ${DateFormat('dd/MM/yyyy').format(task.date)}\n${task.details ?? ''}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 28),
                          onPressed: () async {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Completar Tarea'),
                                content: Text('¿Confirmas que completaste la labor "${task.title}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      await Provider.of<TaskService>(context, listen: false).updateTask(task.id, {'status': 'Completada'});
                                      if (context.mounted) Navigator.pop(context); // Close the sheet to refresh
                                    },
                                    child: const Text('SÍ, COMPLETADA', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
