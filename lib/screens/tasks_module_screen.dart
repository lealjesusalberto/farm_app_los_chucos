import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

import '../core/app_colors.dart';
import '../models/task_models.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import 'add_task_screen.dart';

class TasksModuleScreen extends StatefulWidget {
  const TasksModuleScreen({super.key});

  @override
  State<TasksModuleScreen> createState() => _TasksModuleScreenState();
}

class _TasksModuleScreenState extends State<TasksModuleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    final isAdmin = currentUser?.canManageTasks ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskScreen())),
              backgroundColor: AppColors.primaryGreen,
              icon: const Icon(Icons.add_task, color: Colors.white),
              label: const Text('NUEVA TAREA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: Column(
        children: [
          _buildHeader(),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryGreen,
            tabs: const [
              Tab(text: 'Pendientes'),
              Tab(text: 'Completadas'),
            ],
          ),
          Expanded(
            child: Consumer<TaskService>(
              builder: (context, taskService, _) {
                final allTasks = taskService.tasks;
                
                // Si no es admin, solo ve sus tareas asignadas
                final visibleTasks = isAdmin 
                    ? allTasks 
                    : allTasks.where((t) => t.assignedToUserId == currentUser?.id || t.responsible == currentUser?.name).toList();

                final pending = visibleTasks.where((t) => t.status == 'Pendiente').toList();
                final completed = visibleTasks.where((t) => t.status == 'Completada').toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(pending, isPending: true),
                    _buildTaskList(completed, isPending: false),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de Tareas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Administra las labores de la finca',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<FarmTask> tasks, {required bool isPending}) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          isPending ? 'No hay tareas pendientes' : 'No hay tareas completadas',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return FadeInUp(
          delay: Duration(milliseconds: 50 * index),
          child: _buildTaskCard(task, isPending: isPending),
        );
      },
    );
  }

  Widget _buildTaskCard(FarmTask task, {required bool isPending}) {
    IconData icon;
    Color iconColor;
    switch (task.category) {
      case 'Potreros':
        icon = Icons.grass;
        iconColor = Colors.green;
        break;
      case 'Salud (Sanidad)':
        icon = Icons.medical_services;
        iconColor = Colors.red;
        break;
      case 'Alimentación':
        icon = Icons.food_bank;
        iconColor = Colors.orange;
        break;
      case 'Mantenimiento':
        icon = Icons.build;
        iconColor = Colors.blueGrey;
        break;
      default:
        icon = Icons.assignment;
        iconColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isPending ? const BorderSide(color: Colors.orange, width: 1.5) : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isPending ? Colors.orange.shade800 : AppColors.textDark,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Responsable: ${task.responsible}', style: const TextStyle(fontSize: 12)),
            Text('Fecha: ${DateFormat('dd/MM/yyyy').format(task.date)}', style: const TextStyle(fontSize: 12)),
            if (task.details != null && task.details!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Detalles: ${task.details}', style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
        trailing: isPending
            ? IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Colors.orange, size: 30),
                onPressed: () => _showCompleteTaskDialog(context, task),
              )
            : const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  void _showCompleteTaskDialog(BuildContext context, FarmTask task) {
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Completar Tarea'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Finalizaste la tarea "${task.title}"?', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: detailsController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Detalles extra (Opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
            onPressed: () async {
              final taskService = Provider.of<TaskService>(context, listen: false);
              
              await taskService.updateTask(task.id, {
                'status': 'Completada',
                'details': detailsController.text.isNotEmpty 
                    ? (task.details != null && task.details!.isNotEmpty ? '${task.details} | ${detailsController.text}' : detailsController.text)
                    : task.details,
              });

              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('MARCAR COMO COMPLETADA'),
          ),
        ],
      ),
    );
  }
}
