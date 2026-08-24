import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/inventory_models.dart';
import '../services/inventory_service.dart';
import 'projects_detail_screen.dart';

class CreateProjectScreen extends StatefulWidget {
  final ProjectData? initialProject;

  const CreateProjectScreen({super.key, this.initialProject});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores básicos
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _responsibleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _laborCostController = TextEditingController();

  String _selectedType = 'Corrales';
  DateTime _startDate = DateTime.now();
  DateTime? _estimatedEndDate;

  // Lista dinámica de Etapas
  final List<TextEditingController> _stageControllers = [];
  final List<TextEditingController> _stageNotesControllers = [];

  // Lista dinámica de Materiales Requeridos
  final List<ProjectMaterialRequirement> _selectedMaterials = [];

  final List<String> _projectTypes = [
    'Corrales',
    'Alambrado',
    'Casa Obreros',
    'Ordeño',
    'Manejo',
    'Gallinero',
    'Cochinero',
    'Pastos',
    'Caminos',
    'Reservorios',
    'Acueducto',
    'Eléctrico',
    'Bebederos',
    'Comederos',
    'Infraestructura',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialProject != null) {
      final p = widget.initialProject!;
      _nameController.text = p.name;
      _selectedType = p.type;
      _descriptionController.text = p.description ?? '';
      _locationController.text = p.location ?? '';
      _responsibleController.text = p.responsible ?? '';
      _budgetController.text = p.estimatedBudget > 0 ? p.estimatedBudget.toStringAsFixed(2) : '';
      _startDate = p.startDate ?? DateTime.now();
      _estimatedEndDate = p.estimatedEndDate;

      for (var stage in p.stages) {
        _stageControllers.add(TextEditingController(text: stage.name));
        _stageNotesControllers.add(TextEditingController(text: stage.notes ?? ''));
      }
      _selectedMaterials.addAll(p.materials);
    } else {
      // Plantilla por defecto con 3 etapas iniciales
      _addStage(name: '1. Planificación y compra de materiales');
      _addStage(name: '2. Preparación de terreno y estructura');
      _addStage(name: '3. Instalación, acabados y pruebas');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _responsibleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _laborCostController.dispose();
    for (var c in _stageControllers) {
      c.dispose();
    }
    for (var c in _stageNotesControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addStage({String name = '', String notes = ''}) {
    setState(() {
      _stageControllers.add(TextEditingController(text: name));
      _stageNotesControllers.add(TextEditingController(text: notes));
    });
  }

  void _removeStage(int index) {
    setState(() {
      _stageControllers[index].dispose();
      _stageNotesControllers[index].dispose();
      _stageControllers.removeAt(index);
      _stageNotesControllers.removeAt(index);
    });
  }

  void _applyStagePreset(String type) {
    setState(() {
      for (var c in _stageControllers) {
        c.dispose();
      }
      for (var c in _stageNotesControllers) {
        c.dispose();
      }
      _stageControllers.clear();
      _stageNotesControllers.clear();

      switch (type) {
        case 'Alambrado':
          _addStage(name: '1. Medición y replanteo de linderos');
          _addStage(name: '2. Limpieza de franja y hoyado');
          _addStage(name: '3. Clavado y fijación de postes y esquineros');
          _addStage(name: '4. Tendido y tensado de alambre de púas/eléctrico');
          _addStage(name: '5. Colocación de aisladores y prueba');
          break;
        case 'Corrales':
          _addStage(name: '1. Nivelación de suelo y drenajes');
          _addStage(name: '2. Fundación y plantado de estantillos');
          _addStage(name: '3. Envarillado / armado de tablas y mangas');
          _addStage(name: '4. Fabricación e instalación de portones');
          _addStage(name: '5. Techado de embudo y zona de trabajo');
          break;
        case 'Pastos':
          _addStage(name: '1. Control de malezas y pase de rastra');
          _addStage(name: '2. Encalado / fertilización de fondo');
          _addStage(name: '3. Siembra de semilla o material vegetativo');
          _addStage(name: '4. Primer riego / control de plagas');
          _addStage(name: '5. Evaluación de germinación y aforo');
          break;
        default:
          _addStage(name: '1. Planificación y compra de insumos');
          _addStage(name: '2. Preparación y obras preliminares');
          _addStage(name: '3. Ejecución principal de la obra');
          _addStage(name: '4. Detalles, acabados e inspección');
          break;
      }
    });
  }

  void _openAddMaterialDialog() {
    final inventoryService = Provider.of<InventoryService>(context, listen: false);
    final availableItems = inventoryService.items;

    InventoryItem? selectedItem;
    final customNameCtrl = TextEditingController();
    final customUnitCtrl = TextEditingController(text: 'Unidades');
    final qtyCtrl = TextEditingController(text: '1');
    final costCtrl = TextEditingController(text: '0');
    bool isFromCatalog = availableItems.isNotEmpty;

    String selectedStage = 'General / Todo el proyecto';
    final currentStageNames = [
      'General / Todo el proyecto',
      ..._stageControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty)
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(Icons.add_shopping_cart, color: AppColors.primaryGreen, size: 22),
                const SizedBox(width: 8),
                const Text('Planificar Material', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'El material quedará planificado y se descontará del inventario cuando inicies la etapa correspondiente.',
                            style: TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Asignar a Etapa
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: '¿Para qué etapa se usará? *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    isExpanded: true,
                    value: currentStageNames.contains(selectedStage) ? selectedStage : currentStageNames.first,
                    items: currentStageNames.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedStage = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Del Inventario'),
                        selected: isFromCatalog,
                        selectedColor: AppColors.primaryGreen.withOpacity(0.15),
                        onSelected: (val) {
                          if (val) setDlgState(() => isFromCatalog = true);
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Por Comprar'),
                        selected: !isFromCatalog,
                        selectedColor: Colors.orange.withOpacity(0.15),
                        onSelected: (val) {
                          if (val) setDlgState(() => isFromCatalog = false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (isFromCatalog) ...[
                    DropdownButtonFormField<InventoryItem>(
                      decoration: InputDecoration(
                        labelText: 'Seleccionar del Inventario *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      isExpanded: true,
                      value: selectedItem,
                      items: availableItems.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text('${item.name} (${item.stock} ${item.unit} disponible)', style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDlgState(() {
                          selectedItem = val;
                          if (val != null) {
                            customUnitCtrl.text = val.unit;
                          }
                        });
                      },
                    ),
                  ] else ...[
                    TextField(
                      controller: customNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Material *',
                        hintText: 'Ej. Cemento Portland, Clavos 4"',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Cantidad *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: customUnitCtrl,
                          enabled: !isFromCatalog,
                          decoration: InputDecoration(
                            labelText: 'Unidad',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: costCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Costo Total Estimado (\$ USD)',
                      prefixText: '\$ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
              ElevatedButton(
                onPressed: () {
                  final qty = double.tryParse(qtyCtrl.text) ?? 0.0;
                  final cost = double.tryParse(costCtrl.text) ?? 0.0;

                  String matName = '';
                  String matUnit = customUnitCtrl.text.trim();
                  String matId = '';

                  if (isFromCatalog) {
                    if (selectedItem == null) return;
                    matName = selectedItem!.name;
                    matUnit = selectedItem!.unit;
                    matId = selectedItem!.id;
                  } else {
                    if (customNameCtrl.text.trim().isEmpty) return;
                    matName = customNameCtrl.text.trim();
                  }

                  if (qty <= 0) return;

                  setState(() {
                    _selectedMaterials.add(ProjectMaterialRequirement(
                      itemId: matId,
                      name: matName,
                      quantity: qty,
                      unit: matUnit.isEmpty ? 'Unidades' : matUnit,
                      estimatedCost: cost,
                      isFromInventory: isFromCatalog,
                      stageName: selectedStage,
                      isDeducted: false,
                    ));
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('PLANIFICAR', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _saveProject() {
    if (!_formKey.currentState!.validate()) return;

    final stages = <ProjectStage>[];
    for (int i = 0; i < _stageControllers.length; i++) {
      final name = _stageControllers[i].text.trim();
      final notes = _stageNotesControllers[i].text.trim();
      if (name.isNotEmpty) {
        stages.add(ProjectStage(
          name: name,
          notes: notes.isEmpty ? null : notes,
          status: 'pendiente',
        ));
      }
    }

    final double budget = double.tryParse(_budgetController.text) ?? 0.0;

    final project = ProjectData(
      id: widget.initialProject?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      type: _selectedType,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      responsible: _responsibleController.text.trim().isEmpty ? null : _responsibleController.text.trim(),
      startDate: _startDate,
      estimatedEndDate: _estimatedEndDate,
      stages: stages,
      materials: _selectedMaterials,
      estimatedBudget: budget,
    );

    Navigator.pop(context, project);
  }

  @override
  Widget build(BuildContext context) {
    double totalMaterialsCost = _selectedMaterials.fold(0.0, (sum, m) => sum + m.estimatedCost);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.initialProject != null ? 'Editar Proyecto' : 'Registro Completo de Proyecto',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
        actions: [
          TextButton.icon(
            onPressed: _saveProject,
            icon: const Icon(Icons.check, color: AppColors.primaryGreen),
            label: const Text('GUARDAR', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            // ── SECCIÓN 1: DATOS BÁSICOS ──────────────────────────────
            _buildSectionHeader('1. Información General del Proyecto', Icons.business_center_outlined),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del Proyecto *',
                      hintText: 'Ej. Construcción de Corral de Manejo Norte',
                      prefixIcon: const Icon(Icons.foundation, color: AppColors.primaryGreen),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
                  ),
                  const SizedBox(height: 14),

                  const Text('Tipo / Rubro de Obra', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _projectTypes.map((type) {
                      final isSel = _selectedType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSel,
                        selectedColor: AppColors.primaryGreen.withOpacity(0.18),
                        labelStyle: TextStyle(
                          color: isSel ? AppColors.primaryGreen : Colors.black87,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedType = type);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            labelText: 'Ubicación / Potrero',
                            hintText: 'Ej. Potrero 4',
                            prefixIcon: const Icon(Icons.place_outlined, color: Colors.grey),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _responsibleController,
                          decoration: InputDecoration(
                            labelText: 'Responsable de Obra',
                            hintText: 'Ej. Maestro Juan',
                            prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Fechas
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fecha de Inicio', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(DateFormat('dd/MM/yyyy').format(_startDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.event, color: AppColors.primaryGreen, size: 20),
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _startDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2035),
                                      );
                                      if (picked != null) setState(() => _startDate = picked);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fin Estimado', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _estimatedEndDate == null ? 'Sin definir' : DateFormat('dd/MM/yyyy').format(_estimatedEndDate!),
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _estimatedEndDate == null ? Colors.grey : AppColors.textDark),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.event_available, color: Colors.orange, size: 20),
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _estimatedEndDate ?? _startDate.add(const Duration(days: 30)),
                                        firstDate: _startDate,
                                        lastDate: DateTime(2035),
                                      );
                                      if (picked != null) setState(() => _estimatedEndDate = picked);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Descripción y Objetivos',
                      hintText: 'Dimensiones, propósito o notas importantes...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ── SECCIÓN 2: DEFINICIÓN DE ETAPAS ───────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('2. Etapas del Proyecto (${_stageControllers.length})', Icons.timeline),
                PopupMenuButton<String>(
                  onSelected: _applyStagePreset,
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'Alambrado', child: Text('Plantilla: Alambrado')),
                    const PopupMenuItem(value: 'Corrales', child: Text('Plantilla: Corrales')),
                    const PopupMenuItem(value: 'Pastos', child: Text('Plantilla: Pastos y Siembra')),
                    const PopupMenuItem(value: 'General', child: Text('Plantilla: General (4 Etapas)')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 14, color: Colors.blue),
                        SizedBox(width: 4),
                        Text('Plantillas', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)]),
              child: Column(
                children: [
                  if (_stageControllers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No has agregado etapas aún', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _stageControllers.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final ctrl = _stageControllers.removeAt(oldIndex);
                          final notes = _stageNotesControllers.removeAt(oldIndex);
                          _stageControllers.insert(newIndex, ctrl);
                          _stageNotesControllers.insert(newIndex, notes);
                        });
                      },
                      itemBuilder: (context, index) {
                        return Container(
                          key: ValueKey('stage_$index'),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.15), shape: BoxShape.circle),
                                child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen, fontSize: 12)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _stageControllers[index],
                                      decoration: const InputDecoration(
                                        hintText: 'Nombre de la etapa...',
                                        isDense: true,
                                        border: InputBorder.none,
                                      ),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    TextFormField(
                                      controller: _stageNotesControllers[index],
                                      decoration: const InputDecoration(
                                        hintText: 'Detalles / notas de la etapa (opcional)',
                                        isDense: true,
                                        border: InputBorder.none,
                                      ),
                                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                onPressed: () => _removeStage(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _addStage(name: 'Etapa ${_stageControllers.length + 1}'),
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text('Agregar Otra Etapa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      minimumSize: const Size(double.infinity, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ── SECCIÓN 3: MATERIALES A UTILIZAR Y CANTIDADES ─────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('3. Materiales a Utilizar (${_selectedMaterials.length})', Icons.inventory_2_outlined),
                TextButton.icon(
                  onPressed: _openAddMaterialDialog,
                  icon: const Icon(Icons.add, size: 16, color: AppColors.primaryGreen),
                  label: const Text('Asignar Material', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)]),
              child: Column(
                children: [
                  if (_selectedMaterials.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No se han asignado materiales al proyecto aún.', style: TextStyle(color: Colors.grey)),
                    )
                  else
                    Column(
                      children: _selectedMaterials.asMap().entries.map((entry) {
                        final index = entry.key;
                        final mat = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                mat.isFromInventory ? Icons.check_circle_outline : Icons.shopping_cart_outlined,
                                color: mat.isFromInventory ? AppColors.primaryGreen : Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(mat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text(
                                      '${mat.stageName} • ${mat.isFromInventory ? 'En inventario' : 'Por comprar'}',
                                      style: TextStyle(fontSize: 10, color: mat.isFromInventory ? Colors.green[700] : Colors.orange[800], fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${mat.quantity == mat.quantity.roundToDouble() ? mat.quantity.toStringAsFixed(0) : mat.quantity.toStringAsFixed(1)} ${mat.unit}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                  ),
                                  if (mat.estimatedCost > 0)
                                    Text('\$${mat.estimatedCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                                onPressed: () {
                                  setState(() => _selectedMaterials.removeAt(index));
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _openAddMaterialDialog,
                    icon: const Icon(Icons.add_shopping_cart, size: 16, color: AppColors.primaryGreen),
                    label: const Text('Agregar Material o Insumo', style: TextStyle(color: AppColors.primaryGreen)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                      side: const BorderSide(color: AppColors.primaryGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ── SECCIÓN 4: ESTIMACIÓN DE COSTOS & PRESUPUESTO ─────────
            _buildSectionHeader('4. Estimación Presupuestaria', Icons.monetization_on_outlined),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _budgetController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Presupuesto Total Estimado (\$ USD) *',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (totalMaterialsCost > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal Materiales Estimados:', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
                          Text('\$${totalMaterialsCost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Botón Guardar Principal
            ElevatedButton(
              onPressed: _saveProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: const Text(
                'GUARDAR PROYECTO COMPLETO',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ],
    );
  }
}
