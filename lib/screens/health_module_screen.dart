import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/animal_models.dart';
import '../services/animal_service.dart';
import '../widgets/animal_selector.dart';

class HealthModuleScreen extends StatelessWidget {
  const HealthModuleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            _buildHeader(context),
            const TabBar(
              labelColor: AppColors.primaryGreen,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primaryGreen,
              tabs: [
                Tab(text: 'Vacunas/Tratamientos'),
                Tab(text: 'Control de Baños'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  VaccinesTab(),
                  BathsTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton.extended(
              onPressed: () {
                final tabIndex = DefaultTabController.of(context).index;
                _showEntryDialog(context, tabIndex);
              },
              backgroundColor: AppColors.primaryGreen,
              icon: const Icon(Icons.add_moderator, color: Colors.white),
              label: const Text('Registrar Sanidad', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            );
          }
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/health_bg.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.5),
                Colors.transparent,
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Sanidad & Higiene',
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

  void _showEntryDialog(BuildContext context, int tabIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => HealthEntryForm(initialTabIndex: tabIndex),
    );
  }
}

class VaccinesTab extends StatefulWidget {
  const VaccinesTab({super.key});

  @override
  State<VaccinesTab> createState() => _VaccinesTabState();
}

class _VaccinesTabState extends State<VaccinesTab> {
  String _searchQuery = '';
  List<String> _selectedAgeGroups = [];

  void _showFilterModal(BuildContext context) {
    final allAgeGroups = AnimalType.values.expand((t) => t.ageGroups).toSet().toList()..sort();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20 + MediaQuery.of(context).padding.bottom),
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filtrar por Grupo Etario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allAgeGroups.map((group) {
                          final isSelected = _selectedAgeGroups.contains(group);
                          return FilterChip(
                            label: Text(group),
                            selected: isSelected,
                            selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                            checkmarkColor: AppColors.primaryGreen,
                            onSelected: (bool selected) {
                              setModalState(() {
                                if (selected) {
                                  _selectedAgeGroups.add(group);
                                } else {
                                  _selectedAgeGroups.remove(group);
                                }
                              });
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Aplicar Filtros', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnimalService>(
      builder: (context, service, child) {
        final rawRecords = service.healthRecords
            .where((r) => r.type == HealthRecordType.vaccine || r.type == HealthRecordType.treatment)
            .toList();

        final records = rawRecords.where((r) {
          final isIndividual = r.animalId != null && r.animalId!.isNotEmpty;
          Animal? animal;
          if (isIndividual) {
            final allAnimals = [...service.animals, ...service.deadAnimals];
            animal = allAnimals.cast<Animal?>().firstWhere(
              (a) => a?.id == r.animalId,
              orElse: () => null,
            );
          }

          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final nameMatch = r.name.toLowerCase().contains(query);
            final herdMatch = r.herd.toLowerCase().contains(query);
            final animalMatch = animal != null && (
              animal.code.toLowerCase().contains(query) ||
              (animal.name ?? '').toLowerCase().contains(query)
            );
            if (!nameMatch && !herdMatch && !animalMatch) return false;
          }

          if (_selectedAgeGroups.isNotEmpty) {
            if (isIndividual) {
              if (animal == null || !_selectedAgeGroups.contains(animal.group)) return false;
            } else {
              if (!_selectedAgeGroups.contains(r.herd)) return false;
            }
          }

          return true;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Buscar registro...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _selectedAgeGroups.isNotEmpty ? AppColors.primaryGreen : AppColors.background,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.filter_list, 
                        color: _selectedAgeGroups.isNotEmpty ? Colors.white : AppColors.primaryGreen
                      ),
                      onPressed: () => _showFilterModal(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: records.isEmpty
                  ? const Center(child: Text('No hay registros que coincidan', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(15),
                      itemCount: records.length,
                      itemBuilder: (context, index) {
            final r = records[index];
            final dateStr = DateFormat('dd/MM/yyyy').format(r.date);
            
            String alert = r.type == HealthRecordType.treatment ? 'Sin fecha de fin' : 'Sin refuerzo programado';
            if (r.nextDueDate != null) {
              final daysLeft = r.nextDueDate!.difference(DateTime.now()).inDays;
              if (r.type == HealthRecordType.treatment) {
                if (daysLeft < 0) {
                  alert = 'Finalizado hace ${daysLeft.abs()} días';
                } else if (daysLeft == 0) {
                  alert = 'Finaliza HOY';
                } else {
                  alert = 'Finaliza en $daysLeft días';
                }
              } else {
                if (daysLeft < 0) {
                  alert = '¡Vencido hace ${daysLeft.abs()} días!';
                } else if (daysLeft == 0) {
                  alert = '¡Refuerzo programado para HOY!';
                } else {
                  alert = 'Próximo refuerzo en $daysLeft días';
                }
              }
            }

            final isIndividual = r.animalId != null && r.animalId!.isNotEmpty;
            String targetLabel = '';
            if (isIndividual) {
              final allAnimals = [...service.animals, ...service.deadAnimals];
              final animal = allAnimals.firstWhere(
                (a) => a.id == r.animalId,
                orElse: () => Animal(id: '', code: r.herd, breed: '', sex: '', birthDate: DateTime.now(), entryDate: DateTime.now(), currentLocation: '', group: '', type: AnimalType.bovine),
              );
              targetLabel = animal.name != null && animal.name!.isNotEmpty 
                  ? 'Individual: ${animal.name} (${animal.code})'
                  : 'Individual: ${animal.code}';
            } else {
              targetLabel = 'Grupo: ${r.herd}';
            }

            return FadeInUp(
              child: _buildHealthCard(
                r.name,
                targetLabel,
                dateStr,
                alert,
                r.type == HealthRecordType.vaccine ? Icons.vaccines : Icons.medical_services,
                r.type == HealthRecordType.vaccine ? Colors.blue : Colors.orange,
              ),
            );
          },
        ),
      ),
    ],
  );
},
    );
  }

  Widget _buildHealthCard(String title, String herd, String date, String alert, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(herd, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const Divider(height: 25),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: alert.contains('Vencido') ? Colors.red : Colors.orange),
                const SizedBox(width: 8),
                Text(alert, style: TextStyle(
                  color: alert.contains('Vencido') ? Colors.red : Colors.orange, 
                  fontSize: 12, 
                  fontWeight: FontWeight.w600
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BathsTab extends StatefulWidget {
  const BathsTab({super.key});

  @override
  State<BathsTab> createState() => _BathsTabState();
}

class _BathsTabState extends State<BathsTab> {
  String _searchQuery = '';
  List<String> _selectedAgeGroups = [];

  void _showFilterModal(BuildContext context) {
    final allAgeGroups = AnimalType.values.expand((t) => t.ageGroups).toSet().toList()..sort();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20 + MediaQuery.of(context).padding.bottom),
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filtrar por Grupo Etario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allAgeGroups.map((group) {
                          final isSelected = _selectedAgeGroups.contains(group);
                          return FilterChip(
                            label: Text(group),
                            selected: isSelected,
                            selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                            checkmarkColor: AppColors.primaryGreen,
                            onSelected: (bool selected) {
                              setModalState(() {
                                if (selected) {
                                  _selectedAgeGroups.add(group);
                                } else {
                                  _selectedAgeGroups.remove(group);
                                }
                              });
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Aplicar Filtros', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnimalService>(
      builder: (context, service, child) {
        final rawRecords = service.healthRecords.where((r) => r.type == HealthRecordType.bath).toList();

        final records = rawRecords.where((r) {
          final isIndividual = r.animalId != null && r.animalId!.isNotEmpty;
          Animal? animal;
          if (isIndividual) {
            final allAnimals = [...service.animals, ...service.deadAnimals];
            animal = allAnimals.cast<Animal?>().firstWhere(
              (a) => a?.id == r.animalId,
              orElse: () => null,
            );
          }

          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final nameMatch = r.name.toLowerCase().contains(query);
            final herdMatch = r.herd.toLowerCase().contains(query);
            final animalMatch = animal != null && (
              animal.code.toLowerCase().contains(query) ||
              (animal.name ?? '').toLowerCase().contains(query)
            );
            if (!nameMatch && !herdMatch && !animalMatch) return false;
          }

          if (_selectedAgeGroups.isNotEmpty) {
            if (isIndividual) {
              if (animal == null || !_selectedAgeGroups.contains(animal.group)) return false;
            } else {
              if (!_selectedAgeGroups.contains(r.herd)) return false;
            }
          }

          return true;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Buscar registro...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _selectedAgeGroups.isNotEmpty ? AppColors.primaryGreen : AppColors.background,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.filter_list, 
                        color: _selectedAgeGroups.isNotEmpty ? Colors.white : AppColors.primaryGreen
                      ),
                      onPressed: () => _showFilterModal(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: records.isEmpty
                  ? const Center(child: Text('No hay registros que coincidan', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(15),
                      itemCount: records.length,
                      itemBuilder: (context, index) {
            final r = records[index];
            final nextStr = r.nextDueDate != null ? DateFormat('dd/MM/yyyy').format(r.nextDueDate!) : 'No programado';
            
            String countdown = '-';
            Color countdownColor = AppColors.primaryGreen;
            if (r.nextDueDate != null) {
              final daysLeft = r.nextDueDate!.difference(DateTime.now()).inDays;
              if (daysLeft < 0) {
                countdown = 'Vencido';
                countdownColor = Colors.red;
              } else if (daysLeft == 0) {
                countdown = 'Hoy';
                countdownColor = Colors.orange;
              } else {
                countdown = '$daysLeft d';
              }
            }

            final isIndividual = r.animalId != null && r.animalId!.isNotEmpty;
            String targetLabel = '';
            if (isIndividual) {
              final allAnimals = [...service.animals, ...service.deadAnimals];
              final animal = allAnimals.firstWhere(
                (a) => a.id == r.animalId,
                orElse: () => Animal(id: '', code: r.herd, breed: '', sex: '', birthDate: DateTime.now(), entryDate: DateTime.now(), currentLocation: '', group: '', type: AnimalType.bovine),
              );
              targetLabel = animal.name != null && animal.name!.isNotEmpty 
                  ? 'Individual: ${animal.name} (${animal.code})'
                  : 'Individual: ${animal.code}';
            } else {
              targetLabel = 'Grupo: ${r.herd}';
            }

            return FadeInUp(
              child: _buildBathCard(
                r.name,
                targetLabel,
                'Próximo: $nextStr',
                countdown,
                FontAwesomeIcons.shower,
                Colors.teal,
                countdownColor,
              ),
            );
          },
        ),
      ),
    ],
  );
},
    );
  }

  Widget _buildBathCard(String title, String lot, String nextDate, String countdown, IconData icon, Color color, Color countColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(lot, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 5),
                Text(nextDate, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),
          if (countdown != '-')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: countColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(countdown, style: TextStyle(color: countColor, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class HealthEntryForm extends StatefulWidget {
  final int initialTabIndex;
  const HealthEntryForm({super.key, this.initialTabIndex = 0});

  @override
  State<HealthEntryForm> createState() => _HealthEntryFormState();
}

class _HealthEntryFormState extends State<HealthEntryForm> {
  late HealthRecordType _selectedType;
  AnimalType _selectedAnimalType = AnimalType.bovine;
  bool _isIndividual = false;
  String? _selectedGroup;
  String? _selectedAnimalId;
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  bool _scheduleNext = false;
  DateTime _nextDueDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    if (widget.initialTabIndex == 1) {
      _selectedType = HealthRecordType.bath;
    } else {
      _selectedType = HealthRecordType.vaccine;
    }
    _selectedGroup = _selectedAnimalType.ageGroups.first;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _nextDueDate) {
      setState(() {
        _nextDueDate = picked;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final animalService = Provider.of<AnimalService>(context, listen: false);
    
    // Filter animals by type
    final filteredAnimals = animalService.animals.where((a) => a.type == _selectedAnimalType).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initialTabIndex == 1 ? 'Registrar Control de Baños' : 'Registrar Sanidad (Vacuna/Tratamiento)', 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 20),

            // Selector de Modo (Grupo vs Individual)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _isIndividual = false;
                    }),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: !_isIndividual ? AppColors.primaryGreen : Colors.transparent,
                      foregroundColor: !_isIndividual ? Colors.white : AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Por Grupo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _isIndividual = true;
                    }),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _isIndividual ? AppColors.primaryGreen : Colors.transparent,
                      foregroundColor: _isIndividual ? Colors.white : AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Individual'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            if (widget.initialTabIndex == 0) ...[
              DropdownButtonFormField<HealthRecordType>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: HealthRecordType.vaccine, child: Text('Vacuna')),
                  DropdownMenuItem(value: HealthRecordType.treatment, child: Text('Tratamiento')),
                ],
                onChanged: (val) => setState(() => _selectedType = val!),
                decoration: const InputDecoration(labelText: 'Tipo de Registro'),
              ),
              const SizedBox(height: 15),
            ],

            // Selector de Tipo de Animal
            DropdownButtonFormField<AnimalType>(
              value: _selectedAnimalType,
              items: const [
                DropdownMenuItem(value: AnimalType.bovine, child: Text('Bovino')),
                DropdownMenuItem(value: AnimalType.buffalo, child: Text('Búfalo')),
                DropdownMenuItem(value: AnimalType.equine, child: Text('Equino')),
                DropdownMenuItem(value: AnimalType.porcine, child: Text('Porcino')),
                DropdownMenuItem(value: AnimalType.poultry, child: Text('Ave')),
                DropdownMenuItem(value: AnimalType.dog, child: Text('Perro')),
              ],
              onChanged: (val) => setState(() {
                _selectedAnimalType = val!;
                _selectedGroup = _selectedAnimalType.ageGroups.first;
                _selectedAnimalId = null;
              }),
              decoration: const InputDecoration(labelText: 'Tipo de Animal'),
            ),
            const SizedBox(height: 15),

            // Selector específico de Grupo o Animal
            if (!_isIndividual)
              DropdownButtonFormField<String>(
                value: _selectedGroup,
                items: _selectedAnimalType.ageGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _selectedGroup = val!),
                decoration: const InputDecoration(labelText: 'Grupo Etario Aplicado'),
              )
            else if (filteredAnimals.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Text(
                  'No hay animales registrados de este tipo.',
                  style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              )
            else
              AnimalSelector(
                animals: filteredAnimals,
                selectedAnimalId: _selectedAnimalId,
                labelText: 'Animal Específico',
                onChanged: (val) => setState(() => _selectedAnimalId = val),
              ),
            const SizedBox(height: 15),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: widget.initialTabIndex == 1 
                  ? 'Producto Garrapaticida Aplicado' 
                  : (_selectedType == HealthRecordType.vaccine ? 'Nombre de la Vacuna (Ej: Aftosa)' : 'Tratamiento Aplicado'),
              ),
            ),
            const SizedBox(height: 15),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_selectedType == HealthRecordType.treatment ? 'Fecha de Inicio del Tratamiento' : 'Fecha de Aplicación'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate), style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectStartDate(context),
            ),

            SwitchListTile(
              title: Text(_selectedType == HealthRecordType.treatment ? '¿Definir Fecha de Fin de Tratamiento?' : '¿Programar Próxima Dosis/Baño?'),
              value: _scheduleNext,
              activeColor: AppColors.primaryGreen,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _scheduleNext = val),
            ),

            if (_scheduleNext)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_selectedType == HealthRecordType.treatment ? 'Fecha de Fin del Tratamiento' : 'Fecha del próximo refuerzo/baño'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_nextDueDate), style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),

            const SizedBox(height: 15),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notas Adicionales (Opcional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor ingresa el nombre del producto')));
                  return;
                }
                if (_isIndividual && _selectedAnimalId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor selecciona un animal')));
                  return;
                }

                final targetHerd = _isIndividual 
                    ? (filteredAnimals.firstWhere((a) => a.id == _selectedAnimalId).code)
                    : _selectedGroup!;

                animalService.addHealthRecord(
                  HealthRecord(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    herd: targetHerd,
                    type: _selectedType,
                    name: _nameController.text.trim(),
                    date: _startDate,
                    nextDueDate: _scheduleNext ? _nextDueDate : null,
                    notes: _notesController.text,
                    animalId: _isIndividual ? _selectedAnimalId : null,
                    animalType: _selectedAnimalType.name,
                  ),
                );
                Navigator.pop(context); // Cierra el BottomSheet
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(_isIndividual ? 'GUARDAR REGISTRO INDIVIDUAL' : 'GUARDAR REGISTRO GRUPAL'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
