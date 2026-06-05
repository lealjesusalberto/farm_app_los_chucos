import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/land_models.dart';
import '../services/land_service.dart';
import '../services/auth_service.dart';
import 'add_field_work_screen.dart';
import 'cattle_rotation_screen.dart';

class PotrerosModuleScreen extends StatefulWidget {
  const PotrerosModuleScreen({super.key});

  @override
  State<PotrerosModuleScreen> createState() => _PotrerosModuleScreenState();
}

class _PotrerosModuleScreenState extends State<PotrerosModuleScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LandService>(
      builder: (context, landService, child) {
        final authService = Provider.of<AuthService>(context);
        final currentUser = authService.currentUser;
        final potreros = landService.potreros;
        
        // Filter tasks and history based on role
        final isAdmin = currentUser?.canAdminUsers ?? false;
        final myUserId = currentUser?.id ?? '';
        
        // All pending tasks. If not admin, only show tasks assigned to me.
        final pendingTasks = landService.fieldWorkHistory.where((w) => w.status == 'Pendiente' && (isAdmin || w.assignedToUserId == myUserId)).toList();
        
        // All completed tasks
        final completedHistory = landService.fieldWorkHistory.where((w) => w.status == 'Completada').toList();

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, potreros),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Catastro Maestro (${potreros.length} Potreros)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _showAddPotreroDialog(context),
                                icon: const Icon(Icons.add_circle, color: AppColors.primaryGreen),
                                tooltip: 'Añadir Potrero',
                              ),
                              IconButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CattleRotationScreen())),
                                icon: const Icon(Icons.sync_alt, color: AppColors.primaryGreen),
                                tooltip: 'Rotación de Rebaños',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildPotrerosList(potreros),
                      if (pendingTasks.isNotEmpty) ...[
                        const SizedBox(height: 30),
                        const Text('Mis Tareas Pendientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                        const SizedBox(height: 15),
                        _buildFieldWorkList(pendingTasks, isPending: true),
                      ],
                      const SizedBox(height: 30),
                      const Text('Últimas Labores Completadas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const SizedBox(height: 15),
                      _buildFieldWorkList(completedHistory, isPending: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFieldWorkScreen())),
            backgroundColor: AppColors.primaryGreen,
            icon: const Icon(Icons.cleaning_services, color: Colors.white),
            label: const Text('REGISTRAR LABOR', style: TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, List<Potrero> potreros) {
    double totalTareas = potreros.fold(0, (sum, item) => sum + item.areaTareas);
    double totalHectares = totalTareas / 15.9;

    return Stack(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/land_bg.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.2),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Gestión de Tierras',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeaderStat('Tareas Totales', totalTareas.toStringAsFixed(1)),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _buildHeaderStat('Hectáreas', totalHectares.toStringAsFixed(2)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildPotrerosList(List<Potrero> potreros) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: potreros.length,
      itemBuilder: (context, index) {
        final potrero = potreros[index];
        return FadeInLeft(
          delay: Duration(milliseconds: index * 50),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: potrero.status == 'Disponible' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.landscape,
                    color: potrero.status == 'Disponible' ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(potrero.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        '${potrero.areaTareas} Tareas ≈ ${potrero.areaHectares.toStringAsFixed(2)} Ha',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      if (potrero.currentCattleLot.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.pets, size: 12, color: AppColors.primaryGreen),
                              const SizedBox(width: 4),
                              Text(potrero.currentCattleLot, style: const TextStyle(color: AppColors.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      potrero.status,
                      style: TextStyle(
                        color: potrero.status == 'Disponible' ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFieldWorkList(List<FieldWork> works, {bool isPending = false}) {
    if (works.isEmpty) {
      return Center(child: Text(isPending ? 'No tienes tareas pendientes' : 'No hay labores registradas', style: const TextStyle(color: Colors.grey)));
    }
    return Column(
      children: works.map((work) {
        IconData icon;
        switch (work.type) {
          case 'Desmatonado': icon = Icons.grass; break;
          case 'Fumigación': icon = Icons.opacity; break;
          case 'Arreglo de Cerca': icon = Icons.fence; break;
          default: icon = Icons.cleaning_services;
        }
        
        return InkWell(
          onTap: isPending ? () => _showCompleteTaskDialog(context, work) : null,
          child: Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isPending ? const BorderSide(color: Colors.orange, width: 1.5) : BorderSide.none,
            ),
            child: ListTile(
              leading: Icon(icon, color: isPending ? Colors.orange : AppColors.primaryGreen),
              title: Text('${work.type} en Potrero #${work.potreroId}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isPending ? Colors.orange.shade800 : null)),
              subtitle: Text('Resp: ${work.responsible}', style: const TextStyle(fontSize: 12)),
              trailing: isPending 
                ? const Icon(Icons.check_circle_outline, color: Colors.orange)
                : Text('\$${work.cost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showCompleteTaskDialog(BuildContext context, FieldWork task) {
    final costController = TextEditingController();
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Completar Tarea'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Finalizaste la tarea de ${task.type}?', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Costo Final (\$) (Opcional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: detailsController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Detalles extra (Opcional)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
            onPressed: () async {
              final cost = double.tryParse(costController.text) ?? 0.0;
              final landService = Provider.of<LandService>(context, listen: false);
              
              await landService.updateFieldWork(task.id, {
                'status': 'Completada',
                'cost': cost,
                'details': detailsController.text.isNotEmpty ? detailsController.text : task.details,
              });

              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('MARCAR COMO COMPLETADA'),
          ),
        ],
      ),
    );
  }

  void _showAddPotreroDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const PotreroEntryForm(),
    );
  }
}

class PotreroEntryForm extends StatefulWidget {
  const PotreroEntryForm({super.key});

  @override
  State<PotreroEntryForm> createState() => _PotreroEntryFormState();
}

class _PotreroEntryFormState extends State<PotreroEntryForm> {
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Registrar Nuevo Potrero', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre del Potrero (Ej: Potrero #4)'),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _areaController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Tamaño en Tareas (Ej: 50)'),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un nombre')));
                  return;
                }
                
                final area = double.tryParse(_areaController.text) ?? 0.0;
                if (area <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un área válida')));
                  return;
                }

                final landService = Provider.of<LandService>(context, listen: false);
                await landService.addPotrero(
                  Potrero(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _nameController.text.trim(),
                    areaTareas: area,
                  )
                );
                
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('GUARDAR POTRERO'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
