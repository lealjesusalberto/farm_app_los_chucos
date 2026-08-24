import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/animal_models.dart';
import '../services/animal_service.dart';
import '../services/auth_service.dart';
import '../models/user_models.dart';
import '../widgets/animal_selector.dart';
import '../services/inventory_service.dart';
import '../models/inventory_models.dart';

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

  void _showEntryDialog(BuildContext context, int tabIndex, {HealthRecord? initialRecord}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => HealthEntryForm(initialTabIndex: tabIndex, initialRecord: initialRecord),
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

  AnimalType? _filterModalType;

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableGroups = _filterModalType != null 
                ? _filterModalType!.ageGroups 
                : AnimalType.values.expand((t) => t.ageGroups).toSet().toList()..sort();

            return Container(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20 + MediaQuery.of(context).padding.bottom),
              height: MediaQuery.of(context).size.height * 0.6,
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
                  DropdownButtonFormField<AnimalType?>(
                    decoration: const InputDecoration(labelText: '1. Seleccionar Especie', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                    value: _filterModalType,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas las especies')),
                      ...AnimalType.values.map((t) {
                        String name = '';
                        switch (t) {
                          case AnimalType.bovine: name = 'Bovino'; break;
                          case AnimalType.buffalo: name = 'Búfalo'; break;
                          case AnimalType.equine: name = 'Equino'; break;
                          case AnimalType.porcine: name = 'Porcino'; break;
                          case AnimalType.poultry: name = 'Aves'; break;
                          case AnimalType.dog: name = 'Perro'; break;
                        }
                        return DropdownMenuItem(value: t, child: Text(name));
                      }),
                    ],
                    onChanged: (val) {
                      setModalState(() {
                        _filterModalType = val;
                        if (val != null) {
                           _selectedAgeGroups.removeWhere((g) => !val.ageGroups.contains(g));
                        }
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 15),
                  const Text('2. Seleccionar Grupos', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableGroups.map((group) {
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
              child: Consumer<AuthService>(
                builder: (context, authService, _) {
                  final isPresidente = authService.currentUser?.role == UserRole.presidente;
                  
                  return records.isEmpty
                      ? const Center(child: Text('No hay registros que coincidan', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(15, 15, 15, 90),
                          itemCount: records.length,
                          itemBuilder: (context, index) {
            final r = records[index];
            final dateStr = DateFormat('dd/MM/yyyy').format(r.date);
            
            String alert = r.type == HealthRecordType.treatment ? 'Sin fecha de fin' : 'Sin refuerzo programado';
            String nextDoseInfo = '';
            
            if (r.type == HealthRecordType.treatment && r.frequency != null) {
              int freqHours = 0;
              if (r.frequency!.contains('8')) freqHours = 8;
              else if (r.frequency!.contains('12')) freqHours = 12;
              else if (r.frequency!.contains('24')) freqHours = 24;
              else if (r.frequency!.contains('48')) freqHours = 48;
              
              if (freqHours > 0) {
                final now = DateTime.now();
                if (r.nextDueDate == null || now.isBefore(r.nextDueDate!)) {
                  int elapsedHours = now.difference(r.date).inHours;
                  if (elapsedHours < 0) elapsedHours = 0;
                  int nextDoseMultiple = (elapsedHours ~/ freqHours) + 1;
                  DateTime nextDoseDate = r.date.add(Duration(hours: nextDoseMultiple * freqHours));
                  
                  if (r.nextDueDate == null || nextDoseDate.isBefore(r.nextDueDate!)) {
                    final hoursLeft = nextDoseDate.difference(now).inHours;
                    final minsLeft = nextDoseDate.difference(now).inMinutes % 60;
                    if (hoursLeft == 0 && minsLeft <= 0) {
                      nextDoseInfo = 'Dosis AHORA';
                    } else if (hoursLeft == 0) {
                      nextDoseInfo = 'Próxima dosis en $minsLeft min';
                    } else {
                      nextDoseInfo = 'Próxima dosis en $hoursLeft h ${minsLeft}m';
                    }
                  } else {
                    nextDoseInfo = 'Última dosis administrada';
                  }
                }
              }
            }

            if (r.nextDueDate != null) {
              final daysLeft = r.nextDueDate!.difference(DateTime.now()).inDays;
              if (r.type == HealthRecordType.treatment) {
                if (daysLeft < 0) {
                  alert = 'Finalizado hace ${daysLeft.abs()} días';
                  nextDoseInfo = ''; // Ya finalizó
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

            if (nextDoseInfo.isNotEmpty) {
              if (alert == 'Sin fecha de fin') {
                alert = nextDoseInfo;
              } else {
                alert = '$alert • $nextDoseInfo';
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
                r,
                targetLabel,
                alert,
                r.type == HealthRecordType.vaccine ? Icons.vaccines : Icons.medical_services,
                r.type == HealthRecordType.vaccine ? Colors.blue : Colors.orange,
                isPresidente,
                context,
                service,
              ),
            );
          },
        );
      },
    ),
  ),
    ],
  );
},
    );
  }

  Widget _buildHealthCard(HealthRecord record, String herd, String alert, IconData icon, Color color, bool isPresidente, BuildContext context, AnimalService service) {
    final dateStr = DateFormat('dd/MM/yyyy').format(record.date);
    final authService = Provider.of<AuthService>(context, listen: false);
    String assignedName = 'No asignado';
    if (record.assignedTo != null) {
      final user = authService.allUsers.cast<AppUser?>().firstWhere((u) => u?.id == record.assignedTo, orElse: () => null);
      assignedName = user?.name ?? 'Desconocido';
    }
    bool isTreatment = record.type == HealthRecordType.treatment;
    bool isFinished = isTreatment && (alert.contains('Finalizad') || alert == 'Última dosis administrada');
    bool isActive = isTreatment && !isFinished;

    BoxDecoration? cardDecoration;
    if (isTreatment) {
      if (isActive) {
        cardDecoration = BoxDecoration(
          gradient: LinearGradient(colors: [Colors.blue.shade50.withOpacity(0.5), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
        );
      } else {
        cardDecoration = BoxDecoration(
          gradient: LinearGradient(colors: [Colors.red.shade50.withOpacity(0.5), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
        );
      }
    } else {
      cardDecoration = const BoxDecoration(color: Colors.white);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      child: Container(
        decoration: cardDecoration,
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(record.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          if (isTreatment)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.blue.shade100 : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isActive ? 'En proceso' : 'Finalizado',
                                style: TextStyle(
                                  color: isActive ? Colors.blue.shade800 : Colors.red.shade800,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(herd, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('Aplicado: $dateStr', style: const TextStyle(color: Colors.indigo, fontSize: 12)),
                      if (record.animalType != null)
                        _buildInfoRow('Especie:', _translateAnimalType(record.animalType!)),
                      if (record.frequency != null)
                        _buildInfoRow('Frecuencia:', record.frequency!),
                      if (record.assignedTo != null)
                        _buildInfoRow('Personal:', assignedName),
                      if (record.notes != null && record.notes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                          child: Text('Obs: ${record.notes}', style: const TextStyle(color: Colors.black87, fontSize: 12, fontStyle: FontStyle.italic)),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: alert.contains('Vencido') ? Colors.red : Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(alert, style: TextStyle(
                          color: alert.contains('Vencido') ? Colors.red : Colors.orange, 
                          fontSize: 12, 
                          fontWeight: FontWeight.w600
                        )),
                      ),
                    ],
                  ),
                ),
                if (isPresidente)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                            builder: (_) => HealthEntryForm(initialTabIndex: 0, initialRecord: record),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Eliminar Registro'),
                              content: const Text('¿Estás seguro de que deseas eliminar este registro de salud?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await service.deleteHealthRecord(record.id);
                          }
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  String _translateAnimalType(String type) {
    switch (type.toLowerCase()) {
      case 'bovine': return 'Bovino';
      case 'buffalo': return 'Búfalo';
      case 'equine': return 'Equino';
      case 'porcine': return 'Porcino';
      case 'poultry': return 'Ave';
      case 'dog': return 'Perro';
      default: return type;
    }
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

  AnimalType? _filterModalType;

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableGroups = _filterModalType != null 
                ? _filterModalType!.ageGroups 
                : AnimalType.values.expand((t) => t.ageGroups).toSet().toList()..sort();

            return Container(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20 + MediaQuery.of(context).padding.bottom),
              height: MediaQuery.of(context).size.height * 0.6,
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
                  DropdownButtonFormField<AnimalType?>(
                    decoration: const InputDecoration(labelText: '1. Seleccionar Especie', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                    value: _filterModalType,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas las especies')),
                      ...AnimalType.values.map((t) {
                        String name = '';
                        switch (t) {
                          case AnimalType.bovine: name = 'Bovino'; break;
                          case AnimalType.buffalo: name = 'Búfalo'; break;
                          case AnimalType.equine: name = 'Equino'; break;
                          case AnimalType.porcine: name = 'Porcino'; break;
                          case AnimalType.poultry: name = 'Aves'; break;
                          case AnimalType.dog: name = 'Perro'; break;
                        }
                        return DropdownMenuItem(value: t, child: Text(name));
                      }),
                    ],
                    onChanged: (val) {
                      setModalState(() {
                        _filterModalType = val;
                        if (val != null) {
                           _selectedAgeGroups.removeWhere((g) => !val.ageGroups.contains(g));
                        }
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 15),
                  const Text('2. Seleccionar Grupos', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableGroups.map((group) {
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
              child: Consumer<AuthService>(
                builder: (context, authService, _) {
                  final isPresidente = authService.currentUser?.role == UserRole.presidente;
                  
                  return records.isEmpty
                      ? const Center(child: Text('No hay registros que coincidan', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(15, 15, 15, 90),
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
                r,
                targetLabel,
                'Próximo: $nextStr',
                countdown,
                FontAwesomeIcons.shower,
                Colors.teal,
                countdownColor,
                isPresidente,
                context,
                service,
              ),
            );
          },
        );
      },
    ),
  ),
    ],
  );
},
    );
  }

  Widget _buildBathCard(HealthRecord record, String lot, String nextDate, String countdown, IconData icon, Color color, Color countColor, bool isPresidente, BuildContext context, AnimalService service) {
    final appliedDate = DateFormat('dd/MM/yyyy').format(record.date);
    final authService = Provider.of<AuthService>(context, listen: false);
    String assignedName = 'No asignado';
    if (record.assignedTo != null) {
      final user = authService.allUsers.cast<AppUser?>().firstWhere((u) => u?.id == record.assignedTo, orElse: () => null);
      assignedName = user?.name ?? 'Desconocido';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(record.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(lot, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text('Aplicado: $appliedDate', style: const TextStyle(color: Colors.indigo, fontSize: 12)),
                const SizedBox(height: 4),
                Text(nextDate, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600, fontSize: 12)),
                if (record.assignedTo != null) ...[
                  const SizedBox(height: 4),
                  Text('Personal: $assignedName', style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                ],
                if (record.notes != null && record.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                    child: Text('Obs: ${record.notes}', style: const TextStyle(color: Colors.black87, fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (countdown != '-')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: countColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(countdown, style: TextStyle(color: countColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              if (isPresidente)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => HealthEntryForm(initialTabIndex: 1, initialRecord: record),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Eliminar Registro'),
                            content: const Text('¿Estás seguro de que deseas eliminar este registro de baño?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await service.deleteHealthRecord(record.id);
                        }
                      },
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class HealthEntryForm extends StatefulWidget {
  final int initialTabIndex;
  final HealthRecord? initialRecord;
  const HealthEntryForm({super.key, this.initialTabIndex = 0, this.initialRecord});

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
  final _customFrequencyController = TextEditingController();
  
  InventoryItem? _selectedInventoryItem;
  final _dosesPerAnimalController = TextEditingController(text: '1.0');

  DateTime _startDate = DateTime.now();
  bool _scheduleNext = false;
  DateTime _nextDueDate = DateTime.now().add(const Duration(days: 30));
  String? _treatmentFrequency;
  String? _assignedTo;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecord != null) {
      final r = widget.initialRecord!;
      _selectedType = r.type;
      _selectedAnimalType = AnimalType.values.firstWhere((e) => e.name == r.animalType, orElse: () => AnimalType.bovine);
      _isIndividual = r.animalId != null;
      _selectedAnimalId = r.animalId;
      if (!_isIndividual) {
         _selectedGroup = r.herd;
      }
      _nameController.text = r.name;
      _notesController.text = r.notes ?? '';
      _startDate = r.date;
      _scheduleNext = r.nextDueDate != null;
      if (_scheduleNext) {
         _nextDueDate = r.nextDueDate!;
      }
      
      final standardFrequencies = ['Cada 8 horas', 'Cada 12 horas', 'Cada 24 horas', 'Cada 48 horas'];
      if (r.frequency != null && !standardFrequencies.contains(r.frequency)) {
        _treatmentFrequency = 'Otra (especificar)';
        _customFrequencyController.text = r.frequency!;
      } else {
        _treatmentFrequency = r.frequency;
      }
      _assignedTo = r.assignedTo;
      if (r.dosesPerAnimal != null) {
        _dosesPerAnimalController.text = r.dosesPerAnimal.toString();
      }
    } else {
      if (widget.initialTabIndex == 1) {
        _selectedType = HealthRecordType.bath;
      } else {
        _selectedType = HealthRecordType.vaccine;
      }
    }
    
    // Si no es un registro individual y el grupo seleccionado es nulo, asignamos el primero
    if (!_isIndividual && _selectedGroup == null) {
      _selectedGroup = _selectedAnimalType.ageGroups.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _customFrequencyController.dispose();
    _dosesPerAnimalController.dispose();
    super.dispose();
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
    final authService = Provider.of<AuthService>(context, listen: false);
    final inventoryService = Provider.of<InventoryService>(context);

    final medicalInventoryItems = inventoryService.items.where((i) =>
      i.category == InventoryCategory.noConsumibles ||
      i.subCategory == 'Insumos Médicos Veterinarios' ||
      i.unit.toLowerCase().contains('dosis') ||
      i.unit.toLowerCase().contains('ml') ||
      i.unit.toLowerCase().contains('gr')
    ).toList();
    
    // Filter animals by type
    final filteredAnimals = animalService.animals.where((a) => a.type == _selectedAnimalType).toList();

    // Cálculo de dosis totales
    double dosesPerAnimal = double.tryParse(_dosesPerAnimalController.text.trim()) ?? 1.0;
    int targetAnimalCount = 1;
    if (!_isIndividual) {
      final inGroup = filteredAnimals.where((a) => a.group == _selectedGroup).length;
      targetAnimalCount = inGroup > 0 ? inGroup : (filteredAnimals.isNotEmpty ? filteredAnimals.length : 1);
    }
    double calculatedTotalDoses = dosesPerAnimal * targetAnimalCount;
    bool isInsufficient = _selectedInventoryItem != null && calculatedTotalDoses > _selectedInventoryItem!.stock;

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

            // Selector de Insumos de Inventario
            DropdownButtonFormField<InventoryItem?>(
              value: _selectedInventoryItem,
              isExpanded: true,
              items: [
                const DropdownMenuItem<InventoryItem?>(
                  value: null,
                  child: Text('Ingreso manual (sin descontar inventario)', style: TextStyle(color: Colors.grey)),
                ),
                ...medicalInventoryItems.map((item) {
                  return DropdownMenuItem<InventoryItem?>(
                    value: item,
                    child: Text(
                      '${item.name} • Stock: ${item.stock} ${item.unit}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedInventoryItem = val;
                  if (val != null) {
                    _nameController.text = val.name;
                  }
                });
              },
              decoration: const InputDecoration(
                labelText: 'Vincular a Insumo Médico en Inventario',
                prefixIcon: Icon(Icons.inventory_2_outlined, color: AppColors.primaryGreen),
              ),
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

            // Si hay insumo seleccionado, pedir dosis por animal y mostrar resumen
            if (_selectedInventoryItem != null) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dosesPerAnimalController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Dosis por Animal (${_selectedInventoryItem!.unit})',
                        prefixIcon: const Icon(Icons.vaccines, color: AppColors.primaryGreen),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isInsufficient ? Colors.red.withOpacity(0.1) : AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isInsufficient ? Colors.red : AppColors.primaryGreen),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(isInsufficient ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: isInsufficient ? Colors.red : AppColors.primaryGreen, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Total a descontar del inventario: $calculatedTotalDoses ${_selectedInventoryItem!.unit}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isInsufficient ? Colors.red : AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '($dosesPerAnimal ${_selectedInventoryItem!.unit} x $targetAnimalCount animal(es)) • Stock actual: ${_selectedInventoryItem!.stock} ${_selectedInventoryItem!.unit}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                    if (isInsufficient)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          '⚠️ Atención: Las dosis solicitadas superan el stock registrado en inventario.',
                          style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
            ],

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_selectedType == HealthRecordType.treatment ? 'Fecha de Inicio del Tratamiento' : 'Fecha de Aplicación'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate), style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectStartDate(context),
            ),

            if (_selectedType == HealthRecordType.treatment) ...[
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _treatmentFrequency,
                items: const [
                  DropdownMenuItem(value: null, child: Text('No aplica / Única dosis')),
                  DropdownMenuItem(value: 'Cada 8 horas', child: Text('Cada 8 horas')),
                  DropdownMenuItem(value: 'Cada 12 horas', child: Text('Cada 12 horas')),
                  DropdownMenuItem(value: 'Cada 24 horas', child: Text('Cada 24 horas (Diario)')),
                  DropdownMenuItem(value: 'Cada 48 horas', child: Text('Cada 48 horas')),
                  DropdownMenuItem(value: 'Otra (especificar)', child: Text('Otra (especificar)')),
                ],
                onChanged: (val) => setState(() => _treatmentFrequency = val),
                decoration: const InputDecoration(labelText: 'Frecuencia / Alerta de Dosis'),
              ),
              if (_treatmentFrequency == 'Otra (especificar)') ...[
                const SizedBox(height: 15),
                TextField(
                  controller: _customFrequencyController,
                  decoration: const InputDecoration(labelText: 'Especificar Frecuencia (Ej: Cada 3 días)'),
                ),
              ],
            ],

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
            DropdownButtonFormField<String>(
              value: _assignedTo,
              items: [
                const DropdownMenuItem(value: null, child: Text('No asignado')),
                ...authService.allUsers.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))),
              ],
              onChanged: (val) => setState(() => _assignedTo = val),
              decoration: const InputDecoration(labelText: 'Personal a cargo de la aplicación'),
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

                final newRecord = HealthRecord(
                  id: widget.initialRecord?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  herd: targetHerd,
                  type: _selectedType,
                  name: _nameController.text.trim(),
                  date: _startDate,
                  nextDueDate: _scheduleNext ? _nextDueDate : null,
                  notes: _notesController.text,
                  animalId: _isIndividual ? _selectedAnimalId : null,
                  animalType: _selectedAnimalType.name,
                  frequency: _selectedType == HealthRecordType.treatment 
                    ? (_treatmentFrequency == 'Otra (especificar)' ? _customFrequencyController.text.trim() : _treatmentFrequency) 
                    : null,
                  assignedTo: _assignedTo,
                  inventoryItemId: _selectedInventoryItem?.id,
                  dosesPerAnimal: _selectedInventoryItem != null ? dosesPerAnimal : null,
                  totalDosesApplied: _selectedInventoryItem != null ? calculatedTotalDoses : null,
                );

                if (widget.initialRecord != null) {
                  animalService.updateHealthRecord(widget.initialRecord!.id, newRecord.toMap());
                } else {
                  animalService.addHealthRecord(newRecord, inventoryService: inventoryService);
                }
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
