import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/inventory_models.dart';
import '../services/inventory_service.dart';
import 'create_project_screen.dart';

// ─────────────────────────────────────────────
// Modelo de Proyecto y Materiales
// ─────────────────────────────────────────────
class ProjectMaterialRequirement {
  final String itemId;
  final String name;
  final double quantity;
  final String unit;
  final double estimatedCost;
  final bool isFromInventory;
  final String stageName;
  bool isDeducted;
  DateTime? deductedDate;

  ProjectMaterialRequirement({
    this.itemId = '',
    required this.name,
    required this.quantity,
    required this.unit,
    this.estimatedCost = 0.0,
    this.isFromInventory = true,
    this.stageName = 'General / Todo el proyecto',
    this.isDeducted = false,
    this.deductedDate,
  });
}

class ProjectStage {
  String name;
  String status; // 'pendiente', 'en_progreso', 'completado'
  String? notes;

  ProjectStage({required this.name, this.status = 'pendiente', this.notes});
}

class ProjectData {
  final String id;
  String name;
  String type;
  String? description;
  String? location;
  String? responsible;
  DateTime? startDate;
  DateTime? estimatedEndDate;
  final List<ProjectStage> stages;
  final List<String> usedItemIds;
  final List<ProjectMaterialRequirement> materials;
  double estimatedBudget;

  ProjectData({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.location,
    this.responsible,
    this.startDate,
    this.estimatedEndDate,
    List<ProjectStage>? stages,
    List<String>? usedItemIds,
    List<ProjectMaterialRequirement>? materials,
    this.estimatedBudget = 0,
  })  : stages = stages ?? [],
        usedItemIds = usedItemIds ?? [],
        materials = materials ?? [];
}

// ─────────────────────────────────────────────
// Pantalla Principal de Gestión de Proyectos
// ─────────────────────────────────────────────
class ProjectsDetailScreen extends StatefulWidget {
  const ProjectsDetailScreen({super.key});

  @override
  State<ProjectsDetailScreen> createState() => _ProjectsDetailScreenState();
}

class _ProjectsDetailScreenState extends State<ProjectsDetailScreen> {
  int _currentTabIndex = 0;

  final List<ProjectData> _projects = [
    ProjectData(
      id: 'p1',
      name: 'Cerco Perimetral Norte',
      type: 'Alambrado',
      description: 'Instalación de 500m de cerca eléctrica en potrero norte',
      location: 'Potrero 4 - Sector Norte',
      responsible: 'Capataz Juan Gómez',
      startDate: DateTime.now().subtract(const Duration(days: 10)),
      estimatedEndDate: DateTime.now().add(const Duration(days: 20)),
      stages: [
        ProjectStage(name: '1. Medición y replanteo de linderos', status: 'completado'),
        ProjectStage(name: '2. Limpieza de franja y hoyado', status: 'completado'),
        ProjectStage(name: '3. Clavado y fijación de postes', status: 'en_progreso'),
        ProjectStage(name: '4. Tendido y tensado de alambre', status: 'pendiente'),
        ProjectStage(name: '5. Colocación de aisladores y prueba', status: 'pendiente'),
      ],
      materials: [
        ProjectMaterialRequirement(
          name: 'Postes de Teca 2.5m',
          quantity: 150,
          unit: 'Unidades',
          estimatedCost: 750,
          stageName: '3. Clavado y fijación de postes',
          isDeducted: true,
          deductedDate: DateTime.now().subtract(const Duration(days: 2)),
        ),
        ProjectMaterialRequirement(
          name: 'Rollo Alambre de Púas 400m',
          quantity: 4,
          unit: 'Rollos',
          estimatedCost: 320,
          stageName: '4. Tendido y tensado de alambre',
          isDeducted: false,
        ),
        ProjectMaterialRequirement(
          name: 'Aisladores de paso',
          quantity: 300,
          unit: 'Unidades',
          estimatedCost: 150,
          stageName: '5. Colocación de aisladores y prueba',
          isDeducted: false,
        ),
        ProjectMaterialRequirement(
          name: 'Grapas para cerca 1 1/2"',
          quantity: 20,
          unit: 'Kg',
          estimatedCost: 60,
          stageName: 'General / Todo el proyecto',
          isDeducted: false,
        ),
      ],
      estimatedBudget: 2500,
    ),
  ];

  ProjectData? _selectedProject;

  @override
  void initState() {
    super.initState();
    if (_projects.isNotEmpty) {
      _selectedProject = _projects.first;
    }
  }

  Color _stageColor(String status) {
    switch (status) {
      case 'completado':
        return Colors.green;
      case 'en_progreso':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _stageIcon(String status) {
    switch (status) {
      case 'completado':
        return Icons.check_circle;
      case 'en_progreso':
        return Icons.radio_button_checked;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  String _stageLabel(String status) {
    switch (status) {
      case 'completado':
        return 'Completado';
      case 'en_progreso':
        return 'En Progreso';
      default:
        return 'Pendiente';
    }
  }

  Future<void> _openCreateProjectScreen([ProjectData? editProject]) async {
    final result = await Navigator.push<ProjectData>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateProjectScreen(initialProject: editProject),
      ),
    );

    if (result != null) {
      setState(() {
        if (editProject != null) {
          final index = _projects.indexWhere((p) => p.id == editProject.id);
          if (index != -1) {
            _projects[index] = result;
          }
        } else {
          _projects.add(result);
        }
        _selectedProject = result;
      });
    }
  }

  void _onStageStatusChange(ProjectStage stage, String newStatus) {
    if (_selectedProject == null) return;

    if (newStatus == 'en_progreso' && stage.status != 'en_progreso') {
      final pendingMaterials = _selectedProject!.materials.where((m) =>
        m.isFromInventory &&
        !m.isDeducted &&
        (m.stageName == stage.name || m.stageName.contains(stage.name) || m.stageName == 'General / Todo el proyecto')
      ).toList();

      if (pendingMaterials.isNotEmpty) {
        _showDeductConfirmationDialog(stage, pendingMaterials);
        return;
      }
    }

    setState(() => stage.status = newStatus);
  }

  void _showDeductConfirmationDialog(ProjectStage stage, List<ProjectMaterialRequirement> materials) {
    final inventoryService = Provider.of<InventoryService>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.inventory_2, color: AppColors.primaryGreen, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Iniciar Etapa y Descontar Materiales',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Al iniciar "${stage.name}", se registrará la salida automática de los siguientes materiales del inventario de bodega:',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              ...materials.map((mat) {
                final invItem = mat.itemId.isNotEmpty ? inventoryService.getItemById(mat.itemId) : null;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            if (invItem != null)
                              Text('Stock actual: ${invItem.stock.toStringAsFixed(0)} ${invItem.unit}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text(
                        '-${mat.quantity == mat.quantity.roundToDouble() ? mat.quantity.toStringAsFixed(0) : mat.quantity.toStringAsFixed(1)} ${mat.unit}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => stage.status = 'en_progreso');
            },
            child: const Text('Iniciar sin descontar', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              for (var mat in materials) {
                if (mat.itemId.isNotEmpty) {
                  final tx = InventoryTransaction(
                    id: '',
                    itemId: mat.itemId,
                    quantity: mat.quantity,
                    type: 'Salida',
                    date: DateTime.now(),
                    responsible: _selectedProject?.responsible ?? 'Encargado de Obra',
                    notes: 'Consumo por inicio de etapa: ${stage.name} - Proyecto: ${_selectedProject?.name}',
                  );
                  await inventoryService.addTransaction(tx);
                }
                mat.isDeducted = true;
                mat.deductedDate = DateTime.now();
              }
              setState(() => stage.status = 'en_progreso');

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Materiales descontados del inventario y etapa iniciada.'),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('DESCONTAR E INICIAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _deductSingleMaterial(ProjectMaterialRequirement mat) async {
    final inventoryService = Provider.of<InventoryService>(context, listen: false);
    if (mat.itemId.isNotEmpty) {
      final tx = InventoryTransaction(
        id: '',
        itemId: mat.itemId,
        quantity: mat.quantity,
        type: 'Salida',
        date: DateTime.now(),
        responsible: _selectedProject?.responsible ?? 'Encargado de Obra',
        notes: 'Despacho manual para proyecto: ${_selectedProject?.name} (${mat.stageName})',
      );
      await inventoryService.addTransaction(tx);
    }
    setState(() {
      mat.isDeducted = true;
      mat.deductedDate = DateTime.now();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Descontado "${mat.name}" del inventario.'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestión de Proyectos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryGreen),
            tooltip: 'Nuevo Proyecto',
            onPressed: () => _openCreateProjectScreen(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── SEGMENT BAR NAVEGACIÓN LIMPIA ───────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildSegmentButton(0, 'Proyectos', Icons.folder_outlined),
                const SizedBox(width: 8),
                _buildSegmentButton(1, 'Etapas', Icons.timeline),
                const SizedBox(width: 8),
                _buildSegmentButton(2, 'Materiales', Icons.inventory_2_outlined),
                const SizedBox(width: 8),
                _buildSegmentButton(3, 'Estimación', Icons.monetization_on_outlined),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── CONTENIDO DEL TAB ACTIVO ───────────────────────────
          Expanded(
            child: _buildActiveTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(int index, String title, IconData icon) {
    final isSelected = _currentTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentTabIndex = index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryGreen.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: AppColors.primaryGreen, width: 1.2) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.primaryGreen : Colors.grey[600]),
              const SizedBox(height: 3),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primaryGreen : Colors.grey[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_currentTabIndex) {
      case 0:
        return _buildProjectsTab();
      case 1:
        return _buildStagesTab();
      case 2:
        return _buildMaterialsTab();
      case 3:
        return _buildEstimationTab();
      default:
        return _buildProjectsTab();
    }
  }

  // ── TAB 1: Lista de Proyectos ──────────────────────────────────
  Widget _buildProjectsTab() {
    if (_projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.foundation, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No hay proyectos registrados', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openCreateProjectScreen(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Registrar Primer Proyecto', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      itemCount: _projects.length,
      itemBuilder: (context, index) {
        final project = _projects[index];
        final isSelected = _selectedProject?.id == project.id;
        final completed = project.stages.where((s) => s.status == 'completado').length;
        final total = project.stages.length;
        final progress = total > 0 ? completed / total : 0.0;

        return InkWell(
          onTap: () => setState(() {
            _selectedProject = project;
            _currentTabIndex = 1; // Ir a etapas
          }),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isSelected ? Border.all(color: AppColors.primaryGreen, width: 2) : null,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.foundation, color: Colors.deepOrange, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(project.type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                              ),
                              if (project.location != null) ...[
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '• ${project.location!}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                      tooltip: 'Editar Proyecto',
                      onPressed: () => _openCreateProjectScreen(project),
                    ),
                  ],
                ),
                if (project.description != null && project.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(project.description!, style: TextStyle(fontSize: 12, color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 12),

                // Resumen de etapas y materiales
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        children: [
                          const Icon(Icons.timeline, size: 12, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text('$completed/$total etapas', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 12, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text('${project.materials.length} materiales', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (project.estimatedBudget > 0)
                      Text(
                        'Presupuesto: \$${NumberFormat('#,##0').format(project.estimatedBudget)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryGreen),
                      ),
                  ],
                ),

                if (total > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── TAB 2: Etapas del Proyecto ──────────────────────────────────
  Widget _buildStagesTab() {
    if (_selectedProject == null) return _buildNoProjectSelected();
    final project = _selectedProject!;

    return Column(
      children: [
        _buildProjectSelector(),
        Expanded(
          child: project.stages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_tree_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text('No hay etapas definidas', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _openCreateProjectScreen(project),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Configurar Etapas', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  itemCount: project.stages.length,
                  itemBuilder: (context, index) {
                    final stage = project.stages[index];
                    final color = _stageColor(stage.status);

                    final stageMaterials = project.materials.where((m) =>
                        m.stageName == stage.name ||
                        m.stageName == 'General / Todo el proyecto').toList();
                    final pendingCount = stageMaterials.where((m) => m.isFromInventory && !m.isDeducted).length;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withOpacity(0.4)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Icon(_stageIcon(stage.status), color: color, size: 24),
                              if (index < project.stages.length - 1)
                                Container(width: 2, height: 30, color: Colors.grey.withOpacity(0.2)),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${index + 1}. ${stage.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                                if (stage.notes != null) ...[
                                  const SizedBox(height: 4),
                                  Text(stage.notes!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                ],

                                if (stageMaterials.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: pendingCount > 0 ? Colors.amber.withOpacity(0.12) : Colors.green.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          pendingCount > 0 ? Icons.inventory_2_outlined : Icons.check_circle,
                                          size: 12,
                                          color: pendingCount > 0 ? Colors.amber[800] : Colors.green[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          pendingCount > 0
                                              ? '$pendingCount materiales planificados (se descuentan al iniciar)'
                                              : 'Materiales despachados de bodega (${stageMaterials.length})',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: pendingCount > 0 ? Colors.amber[900] : Colors.green[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  children: ['pendiente', 'en_progreso', 'completado'].map((s) {
                                    final isSel = stage.status == s;
                                    final c = _stageColor(s);
                                    return GestureDetector(
                                      onTap: () => _onStageStatusChange(stage, s),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isSel ? c.withOpacity(0.15) : Colors.grey.withOpacity(0.07),
                                          borderRadius: BorderRadius.circular(8),
                                          border: isSel ? Border.all(color: c.withOpacity(0.5)) : null,
                                        ),
                                        child: Text(
                                          _stageLabel(s),
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? c : Colors.grey[600]),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            onPressed: () => setState(() => project.stages.removeAt(index)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── TAB 3: Materiales ──────────────────────────────────────────
  Widget _buildMaterialsTab() {
    if (_selectedProject == null) return _buildNoProjectSelected();
    final project = _selectedProject!;

    return Column(
      children: [
        _buildProjectSelector(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Materiales Planificados (${project.materials.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  TextButton.icon(
                    onPressed: () => _openCreateProjectScreen(project),
                    icon: const Icon(Icons.edit, size: 16, color: AppColors.primaryGreen),
                    label: const Text('Gestionar Materiales', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (project.materials.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Text(
                      'No se han planificado materiales para este proyecto aún.\nToca "Gestionar Materiales" para asignarlos a cada etapa.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...project.materials.map((mat) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: mat.isDeducted ? Colors.green.withOpacity(0.4) : Colors.grey.shade200,
                        width: mat.isDeducted ? 1.5 : 1,
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              mat.isDeducted
                                  ? Icons.check_circle
                                  : (mat.isFromInventory ? Icons.inventory_2_outlined : Icons.shopping_bag_outlined),
                              color: mat.isDeducted
                                  ? AppColors.primaryGreen
                                  : (mat.isFromInventory ? Colors.blueGrey : Colors.orange),
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(mat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                                  Text('Etapa: ${mat.stageName}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${mat.quantity == mat.quantity.roundToDouble() ? mat.quantity.toStringAsFixed(0) : mat.quantity.toStringAsFixed(1)} ${mat.unit}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                                ),
                                if (mat.estimatedCost > 0)
                                  Text(
                                    '\$${mat.estimatedCost.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: mat.isDeducted
                                    ? Colors.green.withOpacity(0.12)
                                    : (mat.isFromInventory ? Colors.amber.withOpacity(0.12) : Colors.orange.withOpacity(0.12)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                mat.isDeducted
                                    ? '🟢 Descontado de Bodega'
                                    : (mat.isFromInventory ? '🟡 Planificado (Se descuenta al iniciar etapa)' : '🛒 Por Comprar'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: mat.isDeducted
                                      ? Colors.green[800]
                                      : (mat.isFromInventory ? Colors.amber[900] : Colors.orange[900]),
                                ),
                              ),
                            ),
                            if (mat.isFromInventory && !mat.isDeducted)
                              InkWell(
                                onTap: () => _deductSingleMaterial(mat),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.primaryGreen.withOpacity(0.4)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.output, size: 12, color: AppColors.primaryGreen),
                                      SizedBox(width: 4),
                                      Text('Despachar Ahora', style: TextStyle(fontSize: 10, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  // ── TAB 4: Estimación ──────────────────────────────────────────
  Widget _buildEstimationTab() {
    if (_selectedProject == null) return _buildNoProjectSelected();
    final project = _selectedProject!;

    final completedStages = project.stages.where((s) => s.status == 'completado').length;
    final totalStages = project.stages.length;
    final progressPct = totalStages > 0 ? (completedStages / totalStages * 100).round() : 0;
    final totalMaterialsCost = project.materials.fold(0.0, (sum, m) => sum + m.estimatedCost);

    return Column(
      children: [
        _buildProjectSelector(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              // Avance General
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.donut_large_outlined, color: Colors.deepOrange, size: 22),
                        SizedBox(width: 8),
                        Text('Avance del Proyecto', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 110,
                            height: 110,
                            child: CircularProgressIndicator(
                              value: totalStages > 0 ? completedStages / totalStages : 0,
                              strokeWidth: 10,
                              backgroundColor: Colors.grey.withOpacity(0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$progressPct%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                              const Text('Completado', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildEstRow('Etapas Totales', '$totalStages', Icons.list),
                    const Divider(height: 16),
                    _buildEstRow('Completadas', '$completedStages', Icons.check_circle, Colors.green),
                    const Divider(height: 16),
                    _buildEstRow('En Progreso', '${project.stages.where((s) => s.status == 'en_progreso').length}', Icons.radio_button_checked, Colors.orange),
                    const Divider(height: 16),
                    _buildEstRow('Pendientes', '${project.stages.where((s) => s.status == 'pendiente').length}', Icons.radio_button_unchecked, Colors.grey),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Resumen financiero
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bar_chart, color: Colors.purple, size: 22),
                        SizedBox(width: 8),
                        Text('Resumen Financiero', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildEstRow('Presupuesto Total', '\$${NumberFormat('#,##0.00').format(project.estimatedBudget)}', Icons.account_balance_outlined, Colors.purple),
                    const Divider(height: 16),
                    _buildEstRow('Subtotal Materiales', '\$${NumberFormat('#,##0.00').format(totalMaterialsCost)}', Icons.inventory_2_outlined, Colors.blue),
                    const Divider(height: 16),
                    _buildEstRow('Avance Estimado', '\$${NumberFormat('#,##0.00').format(project.estimatedBudget * (totalStages > 0 ? completedStages / totalStages : 0))}', Icons.trending_up, AppColors.primaryGreen),
                    const Divider(height: 16),
                    _buildEstRow('Saldo Restante', '\$${NumberFormat('#,##0.00').format(project.estimatedBudget * (totalStages > 0 ? 1 - completedStages / totalStages : 1))}', Icons.money_off, Colors.orange),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectSelector() {
    if (_projects.isEmpty) return const SizedBox.shrink();

    final selectedId = _selectedProject != null && _projects.any((p) => p.id == _selectedProject!.id)
        ? _selectedProject!.id
        : _projects.first.id;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.foundation, color: AppColors.primaryGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedId,
                isExpanded: true,
                items: _projects.map((p) {
                  return DropdownMenuItem<String>(
                    value: p.id,
                    child: Text(
                      p.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id != null) {
                    setState(() {
                      _selectedProject = _projects.firstWhere((p) => p.id == id, orElse: () => _projects.first);
                    });
                  }
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryGreen, size: 22),
            tooltip: 'Configurar Proyecto / Etapas',
            onPressed: () => _openCreateProjectScreen(_selectedProject),
          ),
        ],
      ),
    );
  }

  Widget _buildNoProjectSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text('Selecciona un proyecto', style: TextStyle(color: Colors.grey, fontSize: 15)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openCreateProjectScreen(),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Crear Proyecto', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEstRow(String label, String value, IconData icon, [Color? color]) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textDark))),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color ?? AppColors.textDark)),
      ],
    );
  }
}
