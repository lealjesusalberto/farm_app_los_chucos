import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/inventory_models.dart';
import '../services/inventory_service.dart';

class AddInventoryItemScreen extends StatefulWidget {
  final InventoryCategory? initialCategory;

  const AddInventoryItemScreen({super.key, this.initialCategory});

  @override
  State<AddInventoryItemScreen> createState() => _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState extends State<AddInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _locationController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _minStockController = TextEditingController(text: '5');
  final _customUnitController = TextEditingController();
  final _usageController = TextEditingController();
  final _responsibleController = TextEditingController(text: 'Administrador');

  // Controllers para Ficha Técnica de Madera
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _depthController = TextEditingController();
  final _radiusController = TextEditingController();
  final _woodTypeController = TextEditingController();

  // Controllers para cantidad dual (Sacos / Kg)
  final _quantityBagsController = TextEditingController();
  final _kgPerBagController = TextEditingController();

  late InventoryCategory _selectedCategory;
  String _selectedSubCategory = 'General';
  String _selectedItemType = '';
  String _selectedUnit = 'Unidades';
  String _selectedPackaging = 'Saco';
  String _selectedPresentation = 'Inyectado';
  DateTime? _expirationDate;
  bool _isLoading = false;

  // Catalog Data
  final Map<InventoryCategory, List<String>> _subCategoryMap = {
    InventoryCategory.insumos: [
      'Alimentos y Concentrados',
      'Sales y Minerales',
      'Aditivos y Suplementos',
      'Insumos Médicos Veterinarios',
      'De Uso Agrícola',
      'Otros Insumos',
    ],
    InventoryCategory.noConsumibles: [
      'Equipos de Trabajo',
      'De Uso Agrícola',
      'Insumos Médicos Veterinarios',
    ],
    InventoryCategory.proyectos: [
      'Infraestructura',
      'Cercado y Alambrado',
      'Sistemas de Agua y Riego',
      'Construcciones',
    ],
    InventoryCategory.herramientas: [
      'De Construcción',
      'De Carpintería',
      'De Mecánica General',
      'De Mantenimiento',
      'Madera',
    ],
    InventoryCategory.maquinaria: [
      'Tractores e Implementos',
      'Bombas de Agua',
      'Generadores Eléctricos',
      'Motosierras y Desbrozadoras',
      'Equipos de Ordeño',
      'Vehículos de Trabajo',
      'Otras Máquinas',
    ],
  };

  final List<String> _medicalTypes = [
    'Antibiótico',
    'Antidiarreico',
    'Antiinflamatorio',
    'Calmante',
    'Diurético',
    'Antialérgico',
    'Antihistamínico',
    'Hidratación',
    'Vitamina',
    'Minerales',
    'Modificador Orgánico',
    'Desparasitante',
    'Pomada',
    'Garrapaticida',
    'Cicatrizante',
    'Hormona',
    'Esteroide',
    'Dispositivo Intravaginal',
    'Vacuna Bovita',
    'Vacuna Clostridial',
    'Vacuna Aftosa',
    'Vacuna Rabia',
    'Vacuna Leptospira',
    'Vacuna Parvovirus',
    'Vacuna Reproductiva',
    'Otra Medicina',
  ];

  final List<String> _projectTypes = [
    'Casa Obreros',
    'Corrales',
    'Ordeño',
    'Manejo',
    'Gallinero',
    'Cochinero',
    'Alambrado',
    'Pastos',
    'Caminos',
    'Reservorios',
    'Acueducto',
    'Eléctrico',
    'Bebederos',
    'Comideros',
    'Nuevo Proyecto',
  ];

  final List<String> _woodSubtypes = [
    'Botalón',
    'Horcón',
    'Estantillo',
    'Listón',
    'Tabla',
    'Cuartón',
    'Otro Tipo Madera',
  ];

  final List<String> _medicalPresentations = [
    'Inyectado',
    'Oral',
    'Tópico',
    'Intravaginal',
    'Subcutáneo',
    'Intramuscular',
    'Intravenoso',
  ];

  final List<String> _packagingOptions = [
    'Saco',
    'Quintal',
    'Cesta',
    'Bulto',
    'Tambor',
    'Frasco',
    'Caja',
    'Unidad',
  ];

  final List<String> _commonUnits = [
    'Unidades',
    'Kg',
    'Litros',
    'ml',
    'Gr',
    'Sacos',
    'Quintal',
    'Cesta',
    'Dosis',
    'Frasco',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? InventoryCategory.insumos;
    _updateDefaultSubcategory();
  }

  void _updateDefaultSubcategory() {
    final list = _subCategoryMap[_selectedCategory];
    if (list != null && list.isNotEmpty) {
      _selectedSubCategory = list.first;
    } else {
      _selectedSubCategory = 'General';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _locationController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _customUnitController.dispose();
    _usageController.dispose();
    _responsibleController.dispose();

    _lengthController.dispose();
    _widthController.dispose();
    _depthController.dispose();
    _radiusController.dispose();
    _woodTypeController.dispose();

    _quantityBagsController.dispose();
    _kgPerBagController.dispose();
    super.dispose();
  }

  Future<void> _selectExpirationDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 180)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }

  String _getCategoryTitle(InventoryCategory category) {
    switch (category) {
      case InventoryCategory.insumos:
        return 'Insumos (Alimentos, Médicos, Sales)';
      case InventoryCategory.noConsumibles:
        return 'No Consumibles (Equipos)';
      case InventoryCategory.proyectos:
        return 'Proyectos (Infraestructura)';
      case InventoryCategory.herramientas:
        return 'Herramientas & Madera';
      case InventoryCategory.maquinaria:
        return 'Equipos y Maquinaria';
    }
  }

  IconData _getCategoryIcon(InventoryCategory category) {
    switch (category) {
      case InventoryCategory.insumos:
        return Icons.grass;
      case InventoryCategory.noConsumibles:
        return Icons.construction;
      case InventoryCategory.proyectos:
        return Icons.architecture;
      case InventoryCategory.herramientas:
        return Icons.build;
      case InventoryCategory.maquinaria:
        return Icons.precision_manufacturing;
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final finalUnit = _selectedUnit == 'Otro'
        ? _customUnitController.text.trim()
        : _selectedUnit;

    if (finalUnit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor especifique la unidad de medida.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final double stock = double.tryParse(_stockController.text.trim()) ?? 0;
      final double minStock = double.tryParse(_minStockController.text.trim()) ?? 0;

      // Leer dimensiones de madera si aplica
      double? length = double.tryParse(_lengthController.text.trim());
      double? width = double.tryParse(_widthController.text.trim());
      double? depth = double.tryParse(_depthController.text.trim());
      double? radius = double.tryParse(_radiusController.text.trim());
      String? woodType = _woodTypeController.text.trim().isEmpty ? null : _woodTypeController.text.trim();

      final newItem = InventoryItem(
        id: '',
        name: _nameController.text.trim(),
        unit: finalUnit,
        stock: stock,
        category: _selectedCategory,
        subCategory: _selectedSubCategory,
        itemType: _selectedItemType.isNotEmpty ? _selectedItemType : null,
        packaging: (_selectedCategory == InventoryCategory.insumos || _selectedSubCategory == 'De Uso Agrícola')
            ? _selectedPackaging
            : null,
        presentation: _selectedSubCategory == 'Insumos Médicos Veterinarios'
            ? _selectedPresentation
            : null,
        usage: _usageController.text.trim().isEmpty ? null : _usageController.text.trim(),
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        expirationDate: _expirationDate,
        minStock: minStock,
        length: length,
        width: width,
        depth: depth,
        radius: radius,
        woodType: woodType,
        quantityBags: double.tryParse(_quantityBagsController.text.trim()),
        kgPerBag: double.tryParse(_kgPerBagController.text.trim()),
      );

      final service = Provider.of<InventoryService>(context, listen: false);
      final responsible = _responsibleController.text.trim().isEmpty
          ? 'Administrador'
          : _responsibleController.text.trim();

      await service.addItem(newItem, responsible: responsible);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${newItem.name}" registrado correctamente en inventario'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ficha Técnica de Registro', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Clasificación General', Icons.category_outlined),
              const SizedBox(height: 15),

              // Categoría Principal
              const Text('Categoría Principal *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<InventoryCategory>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: InventoryCategory.values.map((cat) {
                      return DropdownMenuItem<InventoryCategory>(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(_getCategoryIcon(cat), color: AppColors.primaryGreen, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getCategoryTitle(cat),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCategory = val;
                          _updateDefaultSubcategory();
                          _selectedItemType = '';
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Subcategoría
              const Text('Subcategoría / Renglón *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _subCategoryMap[_selectedCategory]!.contains(_selectedSubCategory)
                        ? _selectedSubCategory
                        : _subCategoryMap[_selectedCategory]!.first,
                    isExpanded: true,
                    items: _subCategoryMap[_selectedCategory]!.map((sub) {
                      return DropdownMenuItem<String>(
                        value: sub,
                        child: Text(sub, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedSubCategory = val;
                          _selectedItemType = '';
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Nombre del Producto / Bien
              _buildSectionHeader('Identificación del Producto', Icons.label_outlined),
              const SizedBox(height: 15),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(
                  label: 'Nombre del Bien o Insumo *',
                  hint: 'Ej. Sales Minerales 8%, Ivermectina 1%, Estantillos, Pala Bellota',
                  icon: Icons.inventory_2_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // CAMPO DINÁMICO 1: Insumos Médicos Veterinarios
              if (_selectedSubCategory == 'Insumos Médicos Veterinarios') ...[
                _buildSectionHeader('Ficha Técnica de Medicamentos', Icons.medical_information),
                const SizedBox(height: 15),

                const Text('Tipo / Clasificación Médica', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _medicalTypes.contains(_selectedItemType) ? _selectedItemType : _medicalTypes.first,
                      isExpanded: true,
                      items: _medicalTypes.map((med) {
                        return DropdownMenuItem<String>(
                          value: med,
                          child: Text(med, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedItemType = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                const Text('Presentación / Vía de Administración', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _medicalPresentations.map((pres) {
                    final isSel = _selectedPresentation == pres;
                    return ChoiceChip(
                      label: Text(pres),
                      selected: isSel,
                      selectedColor: Colors.blue.withOpacity(0.2),
                      labelStyle: TextStyle(color: isSel ? Colors.blue[900] : Colors.black87, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedPresentation = pres);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 15),
              ],

              // CAMPO DINÁMICO 2: Proyectos
              if (_selectedCategory == InventoryCategory.proyectos) ...[
                _buildSectionHeader('Detalle del Proyecto', Icons.account_tree_outlined),
                const SizedBox(height: 15),
                const Text('Tipo de Proyecto / Obra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _projectTypes.contains(_selectedItemType) ? _selectedItemType : _projectTypes.first,
                      isExpanded: true,
                      items: _projectTypes.map((proj) {
                        return DropdownMenuItem<String>(
                          value: proj,
                          child: Text(proj, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedItemType = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],

              // CAMPO DINÁMICO 3: Madera
              if (_selectedSubCategory == 'Madera') ...[
                _buildSectionHeader('Ficha Técnica de Madera', Icons.square_foot),
                const SizedBox(height: 15),

                const Text('Tipo de Bien de Madera', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _woodSubtypes.contains(_selectedItemType) ? _selectedItemType : _woodSubtypes.first,
                      isExpanded: true,
                      items: _woodSubtypes.map((wood) {
                        return DropdownMenuItem<String>(
                          value: wood,
                          child: Text(wood, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedItemType = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _woodTypeController,
                  decoration: _inputDecoration(
                    label: 'Tipo / Especie de Madera',
                    hint: 'Ej. Teca, Pino, Saqui-Saqui, Caoba',
                    icon: Icons.park_outlined,
                  ),
                ),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lengthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration(label: 'Largo (mts)', hint: '2.5', icon: Icons.straighten),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _widthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration(label: 'Ancho (cm)', hint: '10', icon: Icons.swap_horiz),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _depthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration(label: 'Profundidad (cm)', hint: '5', icon: Icons.height),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _radiusController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: _inputDecoration(label: 'Radio (cm)', hint: '7', icon: Icons.adjust),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
              ],

              // CAMPO DINÁMICO 4: Embalaje (Insumos / Agrícola)
              if (_selectedCategory == InventoryCategory.insumos || _selectedSubCategory == 'De Uso Agrícola') ...[
                const Text('Presentación de Medida / Embalaje', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _packagingOptions.map((pack) {
                    final isSel = _selectedPackaging == pack;
                    return ChoiceChip(
                      label: Text(pack),
                      selected: isSel,
                      selectedColor: Colors.amber.withOpacity(0.3),
                      labelStyle: TextStyle(color: isSel ? Colors.brown[900] : Colors.black87, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedPackaging = pack);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 15),
              ],

              // Uso Recomendado (Para todos los insumos y alimentos)
              TextFormField(
                controller: _usageController,
                decoration: _inputDecoration(
                  label: 'Uso Recomendado / Destino',
                  hint: 'Ej. Comida para cerdos, Baño de ganado, Mantenimiento cercos',
                  icon: Icons.assignment_outlined,
                ),
              ),
              const SizedBox(height: 20),

              _buildSectionHeader('Unidades y Stock', Icons.inventory),
              const SizedBox(height: 15),

              // Unidad de Medida
              const Text('Unidad de Peso / Medida *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonUnits.map((unit) {
                  final isSelected = _selectedUnit == unit;
                  return ChoiceChip(
                    label: Text(unit),
                    selected: isSelected,
                    selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primaryGreen : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedUnit = unit;
                        });
                      }
                    },
                  );
                }).toList(),
              ),

              if (_selectedUnit == 'Otro') ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: _customUnitController,
                  decoration: _inputDecoration(
                    label: 'Especifique Unidad *',
                    hint: 'Ej. Galones, Paquetes, Cestos',
                    icon: Icons.edit_note,
                  ),
                ),
              ],
              const SizedBox(height: 15),

              // Campos duales Sacos / Kg (siempre disponibles como opcionales)
              const Text('Medida Dual (Sacos & Kg) — Opcional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text('Si el producto se maneja en sacos, especifica la cantidad de sacos y los Kg por saco para calcular el total automáticamente.', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityBagsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(
                        label: 'Número de Sacos',
                        hint: 'Ej. 5',
                        icon: Icons.shopping_bag_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _kgPerBagController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(
                        label: 'Kg por Saco',
                        hint: 'Ej. 50',
                        icon: Icons.scale_outlined,
                      ),
                    ),
                  ),
                ],
              ),
              // Indicador de total calculado
              Builder(
                builder: (context) {
                  final bags = double.tryParse(_quantityBagsController.text);
                  final kg = double.tryParse(_kgPerBagController.text);
                  if (bags != null && kg != null && bags > 0 && kg > 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calculate_outlined, size: 16, color: AppColors.primaryGreen),
                            const SizedBox(width: 8),
                            Text(
                              'Total: ${(bags * kg).toStringAsFixed(1)} Kg (${bags.toStringAsFixed(0)} sacos × ${kg.toStringAsFixed(0)} Kg/saco)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(
                        label: 'Cantidad Inicial *',
                        hint: '1',
                        icon: Icons.add_box_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Requerido';
                        if (double.tryParse(value.trim()) == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(
                        label: 'Stock Mínimo (Alerta)',
                        hint: '5',
                        icon: Icons.warning_amber_rounded,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionHeader('Ubicación y Vencimiento', Icons.location_on_outlined),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandController,
                      decoration: _inputDecoration(
                        label: 'Marca / Fabricante',
                        hint: 'Ej. Bayer, Pfizer, Bellota',
                        icon: Icons.branding_watermark_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: _inputDecoration(
                        label: 'Ubicación / Bodega',
                        hint: 'Ej. Galpón 1, Estante A',
                        icon: Icons.place_outlined,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Expiración
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined, color: AppColors.primaryGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fecha de Expiración / Vencimiento', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            _expirationDate == null
                                ? 'No especificada (opcional)'
                                : DateFormat('dd/MM/yyyy').format(_expirationDate!),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _expirationDate == null ? Colors.grey : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_expirationDate != null)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red, size: 20),
                        onPressed: () {
                          setState(() {
                            _expirationDate = null;
                          });
                        },
                      ),
                    TextButton(
                      onPressed: () => _selectExpirationDate(context),
                      child: Text(_expirationDate == null ? 'SELECCIONAR' : 'CAMBIAR'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _responsibleController,
                decoration: _inputDecoration(
                  label: 'Responsable del Registro',
                  hint: 'Nombre de la persona que registra',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(height: 30),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'REGISTRAR BIEN EN INVENTARIO',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String label, required String hint, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
      prefixIcon: Icon(icon, color: Colors.grey[600], size: 18),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
      ),
    );
  }
}
