import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/animal_models.dart';
import 'package:provider/provider.dart';
import '../services/animal_service.dart';
import '../services/auth_service.dart';
import '../models/user_models.dart';

class ProductionModuleScreen extends StatefulWidget {
  const ProductionModuleScreen({super.key});

  @override
  State<ProductionModuleScreen> createState() => _ProductionModuleScreenState();
}

class _ProductionModuleScreenState extends State<ProductionModuleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryGreen,
            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            tabs: const [
              Tab(text: 'Leche Individual', icon: Icon(FontAwesomeIcons.cow, size: 16)),
              Tab(text: 'Carne (Pesajes)', icon: Icon(FontAwesomeIcons.weightHanging, size: 16)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _IndividualMilkTab(),
                _IndividualMeatTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showEntryDialog(context);
        },
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Registrar Producción', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            image: DecorationImage(image: AssetImage('assets/animal_prod_bg.png'), fit: BoxFit.cover),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
        Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.6), Colors.transparent]),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    const Text('Control de Producción', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Consumer<AnimalService>(
                builder: (context, service, _) {
                  final now = DateTime.now();
                  
                  // Calcular resumen mensual (Últimos 30 días)
                  final last30Days = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
                  
                  final milkThisMonth = service.milkRecords
                    .where((r) => !r.date.isBefore(last30Days))
                    .fold(0.0, (sum, r) => sum + r.totalLiters);

                  final individualMilkThisMonth = service.individualMilkRecords
                    .where((r) => !r.date.isBefore(last30Days))
                    .fold(0.0, (sum, r) => sum + r.liters);
                    
                  // Calcular resumen semanal (Últimos 7 días)
                  final last7Days = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
                  
                  final milkThisWeek = service.milkRecords
                    .where((r) => !r.date.isBefore(last7Days))
                    .fold(0.0, (sum, r) => sum + r.totalLiters);
                    
                  final individualMilkThisWeek = service.individualMilkRecords
                    .where((r) => !r.date.isBefore(last7Days))
                    .fold(0.0, (sum, r) => sum + r.liters);
                    
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Text('Últimos 7 Días', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('${(milkThisWeek + individualMilkThisWeek).toStringAsFixed(1)} Lts', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('G: ${milkThisWeek.toStringAsFixed(1)} | I: ${individualMilkThisWeek.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      Column(
                        children: [
                          const Text('Últimos 30 Días', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('${(milkThisMonth + individualMilkThisMonth).toStringAsFixed(1)} Lts', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('G: ${milkThisMonth.toStringAsFixed(1)} | I: ${individualMilkThisMonth.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                    ],
                  );
                }
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMilkTab() {
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
    return Consumer<AnimalService>(
      builder: (context, service, child) {
        final groupRecords = service.milkRecords;
        
        // Agregar registros individuales por Fecha y Turno
        final Map<String, Map<String, dynamic>> aggregatedRecords = {};
        for (final r in service.individualMilkRecords) {
          final dateKey = DateFormat('yyyy-MM-dd').format(r.date);
          final shiftKey = r.amOrPm;
          final key = '${dateKey}_$shiftKey';
          
          if (aggregatedRecords.containsKey(key)) {
            final existing = aggregatedRecords[key]!;
            aggregatedRecords[key] = {
              'id': existing['id'],
              'date': existing['date'],
              'totalLiters': existing['totalLiters'] + r.liters,
              'cowsMilked': existing['cowsMilked'] + 1,
              'amOrPm': existing['amOrPm'],
            };
          } else {
            aggregatedRecords[key] = {
              'id': 'agg_$key',
              'date': r.date,
              'totalLiters': r.liters,
              'cowsMilked': 1,
              'amOrPm': r.amOrPm,
            };
          }
        }
        
        // Fusionar con registros grupales
        final Map<String, Map<String, dynamic>> finalRecordsMap = {...aggregatedRecords};
        for (final r in groupRecords) {
          final dateKey = DateFormat('yyyy-MM-dd').format(r.date);
          final shiftKey = r.amOrPm;
          final key = '${dateKey}_$shiftKey';
          
          if (finalRecordsMap.containsKey(key)) {
            final existing = finalRecordsMap[key]!;
            finalRecordsMap[key] = {
              'id': r.id,
              'date': r.date,
              'totalLiters': r.totalLiters + existing['totalLiters'],
              'cowsMilked': existing['cowsMilked'], // Keep cow count
              'amOrPm': r.amOrPm,
            };
          } else {
            finalRecordsMap[key] = {
              'id': r.id,
              'date': r.date,
              'totalLiters': r.totalLiters,
              'cowsMilked': null, // No cow count
              'amOrPm': r.amOrPm,
            };
          }
        }
        
        final finalRecords = finalRecordsMap.values.toList();
        finalRecords.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

        if (finalRecords.isEmpty) return const Center(child: Text('No hay registros de leche'));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: finalRecords.length,
          itemBuilder: (context, index) {
            final r = finalRecords[index];
            final date = r['date'] as DateTime;
            final liters = (r['totalLiters'] as double).toStringAsFixed(1);
            final amOrPm = r['amOrPm'] as String;
            final cowsMilked = r['cowsMilked'] as int?;
            final isAgg = (r['id'] as String).startsWith('agg_');
            
            return FadeInLeft(
              child: Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.background, 
                    child: Icon(isAgg ? FontAwesomeIcons.cow : FontAwesomeIcons.droplet, color: Colors.blue, size: 16)
                  ),
                  title: Text('$liters Litros ($amOrPm)', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    cowsMilked != null 
                        ? '${DateFormat('dd MMM, yyyy').format(date)} • $cowsMilked vacas'
                        : DateFormat('dd MMM, yyyy').format(date),
                  ),
                  trailing: (!isAgg && currentUser?.canUpdateOrDeleteRecords == true)
                      ? PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                          padding: EdgeInsets.zero,
                          onSelected: (value) {
                            if (value == 'edit') {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => ProductionEntryForm(
                                  record: MilkRecord(
                                    id: r['id'],
                                    date: r['date'],
                                    totalLiters: r['totalLiters'],
                                    amOrPm: r['amOrPm'],
                                  ),
                                ),
                              );
                            } else if (value == 'delete') {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Eliminar Registro'),
                                  content: const Text('¿Seguro que deseas eliminar este registro global de leche?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                    TextButton(
                                      onPressed: () {
                                        Provider.of<AnimalService>(context, listen: false).deleteMilkRecord(r['id']);
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Editar')),
                            const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                          ],
                        )
                      : const Icon(Icons.chevron_right),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEntryDialog(BuildContext context) {
    // Determine which tab is active to show the right form
    final currentTab = _tabController.index;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        if (currentTab == 0) {
          return const _IndividualMilkEntryForm();
        } else {
          return const _IndividualMeatEntryForm();
        }
      },
    );
  }
}

// ============================================================
// TAB: Producción de Leche Individual
// ============================================================

class _IndividualMilkTab extends StatefulWidget {
  const _IndividualMilkTab();

  @override
  State<_IndividualMilkTab> createState() => _IndividualMilkTabState();
}

class _IndividualMilkTabState extends State<_IndividualMilkTab> {
  String _searchQuery = '';
  String? _selectedAnimalId;
  List<String> _selectedAgeGroups = [];

  void _showFilterModal(BuildContext context, List<String> availableGroups) {
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
      builder: (context, service, _) {
        // Filter only typical milk producers
        final allAnimals = service.animals.toList();
        final records = service.individualMilkRecords;
        
        final milkGroups = ['Vacas en prod', 'Búfalas en prod'];
        final milkProducers = allAnimals.where((a) => milkGroups.contains(a.group)).toList();

        // Build filtered animal list based on search AND filter
        final filteredAnimals = milkProducers.where((a) {
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final code = a.code.toLowerCase();
            final name = (a.name ?? '').toLowerCase();
            final breed = a.breed.toLowerCase();
            if (!(code.contains(query) || name.contains(query) || breed.contains(query))) return false;
          }
          if (_selectedAgeGroups.isNotEmpty) {
            if (!_selectedAgeGroups.contains(a.group)) return false;
          }
          return true;
        }).toList();

        return Column(
          children: [
            // Search bar and Filter
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() {
                        _searchQuery = val;
                        _selectedAnimalId = null;
                      }),
                      decoration: InputDecoration(
                        hintText: 'Buscar animal...',
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
                      onPressed: () => _showFilterModal(context, milkGroups),
                    ),
                  ),
                ],
              ),
            ),

            // If no animal selected, show animal list to pick
            if (_selectedAnimalId == null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(FontAwesomeIcons.filter, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      '${filteredAnimals.length} animales encontrados',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filteredAnimals.isEmpty
                    ? const Center(child: Text('No se encontraron animales', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredAnimals.length,
                        itemBuilder: (context, index) {
                          final animal = filteredAnimals[index];
                          // Count records for this animal
                          final animalRecords = records.where((r) => r.animalId == animal.id).toList();
                          final totalLiters = animalRecords.fold(0.0, (sum, r) => sum + r.liters);

                          return FadeInUp(
                            delay: Duration(milliseconds: index * 50),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => setState(() => _selectedAnimalId = animal.id),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      // Animal avatar
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [AppColors.primaryGreen, AppColors.secondaryGreen],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            animal.code.length > 3 ? animal.code.substring(0, 3) : animal.code,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Animal info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              animal.name != null && animal.name!.isNotEmpty ? '${animal.code} - ${animal.name}' : animal.code,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${animal.breed} • ${animal.sex} • ${animal.group}',
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Milk stats
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: animalRecords.isNotEmpty ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${totalLiters.toStringAsFixed(1)} Lts',
                                              style: TextStyle(
                                                color: animalRecords.isNotEmpty ? Colors.blue.shade700 : Colors.grey,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${animalRecords.length} registros',
                                            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ]
            // If animal selected, show its individual records
            else ...[
              _buildSelectedAnimalHeader(service),
              Expanded(child: _buildAnimalMilkHistory(service)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSelectedAnimalHeader(AnimalService service) {
    final animal = service.animals.firstWhere(
      (a) => a.id == _selectedAnimalId,
      orElse: () => Animal(
        id: '', code: '???', type: AnimalType.bovine,
        breed: '', sex: '', birthDate: DateTime.now(),
        entryDate: DateTime.now(), currentLocation: '', group: '',
      ),
    );

    final animalRecords = service.individualMilkRecords.where((r) => r.animalId == _selectedAnimalId).toList();
    final totalLiters = animalRecords.fold(0.0, (sum, r) => sum + r.liters);

    // Monthly average
    final now = DateTime.now();
    final thisMonth = now.month;
    final thisYear = now.year;
    final monthRecords = animalRecords.where((r) => r.date.month == thisMonth && r.date.year == thisYear).toList();
    final monthLiters = monthRecords.fold(0.0, (sum, r) => sum + r.liters);

    // Weekly average
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final weekRecords = animalRecords.where((r) => !r.date.isBefore(startOfWeek)).toList();
    final weekLiters = weekRecords.fold(0.0, (sum, r) => sum + r.liters);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => setState(() => _selectedAnimalId = null),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.name != null && animal.name!.isNotEmpty ? '${animal.code} - ${animal.name}' : animal.code,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${animal.breed} • ${animal.sex} • ${animal.group}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Add record button
              InkWell(
                onTap: () => _showIndividualMilkForm(context, animal),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Color(0xFF1565C0), size: 16),
                      SizedBox(width: 4),
                      Text('Registrar', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Total', '${totalLiters.toStringAsFixed(1)} Lts', Icons.water_drop),
              _buildMiniStat('Esta Sem', '${weekLiters.toStringAsFixed(1)} Lts', Icons.view_week),
              _buildMiniStat('Este Mes', '${monthLiters.toStringAsFixed(1)} Lts', Icons.calendar_month),
              _buildMiniStat('Registros', '${animalRecords.length}', Icons.list_alt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _buildAnimalMilkHistory(AnimalService service) {
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
    final animalRecords = service.individualMilkRecords
        .where((r) => r.animalId == _selectedAnimalId)
        .toList();

    if (animalRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.droplet, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Sin registros de producción', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Toca "Registrar" para agregar el primero', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    // Group by date
    final Map<String, List<IndividualMilkRecord>> groupedByDate = {};
    for (final r in animalRecords) {
      final dateKey = DateFormat('yyyy-MM-dd').format(r.date);
      groupedByDate.putIfAbsent(dateKey, () => []).add(r);
    }

    final dateKeys = groupedByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: dateKeys.length,
      itemBuilder: (context, index) {
        final dateKey = dateKeys[index];
        final dayRecords = groupedByDate[dateKey]!;
        final dayTotal = dayRecords.fold(0.0, (sum, r) => sum + r.liters);
        final date = dayRecords.first.date;

        return FadeInLeft(
          delay: Duration(milliseconds: index * 80),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM, yyyy').format(date),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${dayTotal.toStringAsFixed(1)} Lts',
                          style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  ...dayRecords.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: r.amOrPm == 'AM'
                                ? Colors.orange.withOpacity(0.1)
                                : r.amOrPm == 'PM'
                                    ? Colors.indigo.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            r.amOrPm == 'Both' ? 'Completo' : r.amOrPm,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: r.amOrPm == 'AM'
                                  ? Colors.orange.shade700
                                  : r.amOrPm == 'PM'
                                      ? Colors.indigo.shade700
                                      : Colors.green.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${r.liters.toStringAsFixed(1)} Lts', style: const TextStyle(fontWeight: FontWeight.w500)),
                        if (r.notes != null && r.notes!.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              r.notes!,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontStyle: FontStyle.italic),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ] else ...[
                          const Spacer(),
                        ],
                        if (currentUser?.canUpdateOrDeleteRecords == true)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey, size: 16),
                            padding: EdgeInsets.zero,
                            onSelected: (value) {
                              if (value == 'edit') {
                                final animal = service.animals.firstWhere((a) => a.id == _selectedAnimalId, orElse: () => Animal(id: '', code: '', type: AnimalType.bovine, breed: '', sex: '', birthDate: DateTime.now(), entryDate: DateTime.now(), currentLocation: '', group: ''));
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                  builder: (_) => _IndividualMilkEntryForm(
                                    preselectedAnimal: animal.id.isNotEmpty ? animal : null,
                                    record: r,
                                  ),
                                );
                              } else if (value == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Eliminar Registro'),
                                    content: const Text('¿Seguro que deseas eliminar este registro individual de leche?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                      TextButton(
                                        onPressed: () {
                                          Provider.of<AnimalService>(context, listen: false).deleteIndividualMilkRecord(r.id);
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Editar')),
                              const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showIndividualMilkForm(BuildContext context, Animal animal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _IndividualMilkEntryForm(preselectedAnimal: animal),
    );
  }
}

// ============================================================
// FORM: Registro de Leche Individual
// ============================================================

class _IndividualMilkEntryForm extends StatefulWidget {
  final Animal? preselectedAnimal;
  final IndividualMilkRecord? record;

  const _IndividualMilkEntryForm({this.preselectedAnimal, this.record});

  @override
  State<_IndividualMilkEntryForm> createState() => _IndividualMilkEntryFormState();
}

class _IndividualMilkEntryFormState extends State<_IndividualMilkEntryForm> {
  final _litersController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  String _amPm = 'AM';
  String? _selectedAnimalId;
  String _animalSearchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.preselectedAnimal != null) {
      _selectedAnimalId = widget.preselectedAnimal!.id;
    }
    if (widget.record != null) {
      _selectedAnimalId = widget.record!.animalId;
      _litersController.text = widget.record!.liters.toString();
      _amPm = widget.record!.amOrPm;
      if (widget.record!.notes != null) {
        _notesController.text = widget.record!.notes!;
      }
    }
    
    _searchController.addListener(() {
      setState(() {
        _animalSearchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final animalService = Provider.of<AnimalService>(context, listen: false);
    final animals = animalService.animals.toList();

    final milkGroups = ['Vacas en prod', 'Búfalas en prod'];
    final milkProducers = animals.where((a) => milkGroups.contains(a.group)).toList();

    // Filter animals for dropdown
    final filteredAnimals = milkProducers.where((a) {
      if (_animalSearchQuery.isEmpty) return true;
      final q = _animalSearchQuery.toLowerCase();
      return a.code.toLowerCase().contains(q) ||
          (a.name ?? '').toLowerCase().contains(q) ||
          a.breed.toLowerCase().contains(q);
    }).toList();

    // Get selected animal info
    Animal? selectedAnimal;
    if (_selectedAnimalId != null) {
      try {
        selectedAnimal = animals.firstWhere((a) => a.id == _selectedAnimalId);
      } catch (_) {
        selectedAnimal = null;
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(FontAwesomeIcons.cow, color: Colors.blue, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Registrar Leche Individual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Animal selection
            if (selectedAnimal != null) ...[
              // Show selected animal chip
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primaryGreen, AppColors.secondaryGreen]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          selectedAnimal.code.length > 3 ? selectedAnimal.code.substring(0, 3) : selectedAnimal.code,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedAnimal.name != null && selectedAnimal.name!.isNotEmpty
                                ? '${selectedAnimal.code} - ${selectedAnimal.name}'
                                : selectedAnimal.code,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text('${selectedAnimal.breed} • ${selectedAnimal.sex}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (widget.preselectedAnimal == null)
                      InkWell(
                        onTap: () => setState(() {
                          _selectedAnimalId = null;
                          _searchController.clear();
                          _animalSearchQuery = '';
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.close, color: Colors.red, size: 16),
                        ),
                      ),
                  ],
                ),
              ),
            ] else ...[
              // Search and select animal
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _animalSearchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Buscar animal por código o nombre...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: filteredAnimals.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No se encontraron animales', style: TextStyle(color: Colors.grey))))
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredAnimals.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final a = filteredAnimals[index];
                          return ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primaryGreen,
                              child: Text(
                                a.code.length > 2 ? a.code.substring(0, 2) : a.code,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              a.name != null && a.name!.isNotEmpty ? '${a.code} - ${a.name}' : a.code,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text('${a.breed} • ${a.sex}', style: const TextStyle(fontSize: 10)),
                            onTap: () => setState(() {
                              _selectedAnimalId = a.id;
                              _searchController.text = a.code;
                            }),
                          );
                        },
                      ),
              ),
            ],

            const SizedBox(height: 16),
            // Liters input
            TextField(
              controller: _litersController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Litros Producidos',
                hintText: '0.0',
                prefixIcon: const Icon(FontAwesomeIcons.droplet, size: 16, color: Colors.blue),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            // Shift selector
            DropdownButtonFormField<String>(
              value: _amPm,
              items: const [
                DropdownMenuItem(value: 'AM', child: Text('Mañana (AM)')),
                DropdownMenuItem(value: 'PM', child: Text('Tarde (PM)')),
                DropdownMenuItem(value: 'Both', child: Text('Día Completo')),
              ],
              onChanged: (val) => setState(() => _amPm = val!),
              decoration: InputDecoration(
                labelText: 'Turno',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            // Notes
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notas (Opcional)',
                hintText: 'Observaciones...',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_selectedAnimalId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un animal')));
                  return;
                }
                final liters = double.tryParse(_litersController.text) ?? 0.0;
                if (liters <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa una cantidad válida de litros')));
                  return;
                }

                final animalService = Provider.of<AnimalService>(context, listen: false);
                if (widget.record != null) {
                  animalService.updateIndividualMilkRecord(widget.record!.id, {
                    'animalId': _selectedAnimalId!,
                    'liters': liters,
                    'amOrPm': _amPm,
                    'notes': _notesController.text.trim(),
                  });
                } else {
                  animalService.addIndividualMilkRecord(
                    IndividualMilkRecord(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      animalId: _selectedAnimalId!,
                      date: DateTime.now(),
                      liters: liters,
                      amOrPm: _amPm,
                      notes: _notesController.text.trim(),
                    ),
                  );
                }
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Producción individual registrada'),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('GUARDAR REGISTRO', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FORM: Producción Global / Pesaje (existente)
// ============================================================

class ProductionEntryForm extends StatefulWidget {
  final MilkRecord? record;
  const ProductionEntryForm({super.key, this.record});

  @override
  State<ProductionEntryForm> createState() => _ProductionEntryFormState();
}

class _ProductionEntryFormState extends State<ProductionEntryForm> {
  final _litersController = TextEditingController();
  String _amPm = 'Both';

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _litersController.text = widget.record!.totalLiters.toString();
      _amPm = widget.record!.amOrPm;
    }
  }

  @override
  Widget build(BuildContext context) {
    final animalService = Provider.of<AnimalService>(context, listen: false);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Registrar Leche (Global)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            TextField(
              controller: _litersController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Litros Totales', hintText: '0.0'),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _amPm,
              items: const [
                DropdownMenuItem(value: 'AM', child: Text('Mañana (AM)')),
                DropdownMenuItem(value: 'PM', child: Text('Tarde (PM)')),
                DropdownMenuItem(value: 'Both', child: Text('Día Completo')),
              ],
              onChanged: (val) => setState(() => _amPm = val!),
              decoration: const InputDecoration(labelText: 'Turno'),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final liters = double.tryParse(_litersController.text) ?? 0.0;
                if (liters <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa una cantidad válida de litros')));
                  return;
                }
                if (widget.record != null) {
                  animalService.updateMilkRecord(widget.record!.id, {
                    'totalLiters': liters,
                    'amOrPm': _amPm,
                  });
                } else {
                  animalService.addMilkRecord(
                    MilkRecord(id: DateTime.now().millisecondsSinceEpoch.toString(), date: DateTime.now(), totalLiters: liters, amOrPm: _amPm),
                  );
                }
                Navigator.pop(context); // Cierra el BottomSheet
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('GUARDAR REGISTRO'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TAB: Producción de Carne Individual (Pesajes)
// ============================================================

class _IndividualMeatTab extends StatefulWidget {
  const _IndividualMeatTab();

  @override
  State<_IndividualMeatTab> createState() => _IndividualMeatTabState();
}

class _IndividualMeatTabState extends State<_IndividualMeatTab> {
  String _searchQuery = '';
  String? _selectedAnimalId;
  List<String> _selectedAgeGroups = [];

  AnimalType? _filterModalType;

  void _showFilterModal(BuildContext context, List<String> allMeatAgeGroups) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableGroups = _filterModalType != null 
                ? _filterModalType!.ageGroups 
                : allMeatAgeGroups;

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
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todas las especies')),
                      DropdownMenuItem(value: AnimalType.bovine, child: Text('Bovino')),
                      DropdownMenuItem(value: AnimalType.buffalo, child: Text('Búfalo')),
                      DropdownMenuItem(value: AnimalType.porcine, child: Text('Porcino')),
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
      builder: (context, service, _) {
        final allAnimals = service.animals.toList();
        final records = service.weightRecords;

        // Filter valid meat animals (exclude dogs)
        final meatAnimals = allAnimals.where((a) => a.type != AnimalType.dog).toList();
        final allMeatAgeGroups = meatAnimals.map((a) => a.group).toSet().toList()..sort();

        final filteredAnimals = meatAnimals.where((a) {
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final code = a.code.toLowerCase();
            final name = (a.name ?? '').toLowerCase();
            final breed = a.breed.toLowerCase();
            if (!(code.contains(query) || name.contains(query) || breed.contains(query))) return false;
          }
          if (_selectedAgeGroups.isNotEmpty) {
            if (!_selectedAgeGroups.contains(a.group)) return false;
          }
          return true;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() {
                        _searchQuery = val;
                        _selectedAnimalId = null;
                      }),
                      decoration: InputDecoration(
                        hintText: 'Buscar animal...',
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
                      onPressed: () => _showFilterModal(context, allMeatAgeGroups),
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedAnimalId == null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(FontAwesomeIcons.filter, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text('${filteredAnimals.length} animales encontrados', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filteredAnimals.isEmpty
                    ? const Center(child: Text('No se encontraron animales', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredAnimals.length,
                        itemBuilder: (context, index) {
                          final animal = filteredAnimals[index];
                          final animalRecords = records.where((r) => r.animalId == animal.id).toList()..sort((a, b) => b.date.compareTo(a.date));
                          final lastWeight = animalRecords.isNotEmpty ? animalRecords.first.weight : animal.currentWeight;

                          return FadeInUp(
                            delay: Duration(milliseconds: index * 50),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => setState(() => _selectedAnimalId = animal.id),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primaryGreen, AppColors.secondaryGreen]), borderRadius: BorderRadius.circular(12)),
                                        child: Center(child: Text(animal.code.length > 3 ? animal.code.substring(0, 3) : animal.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(animal.name != null && animal.name!.isNotEmpty ? '${animal.code} - ${animal.name}' : animal.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            const SizedBox(height: 2),
                                            Text('${animal.breed} • ${animal.sex} • ${animal.group}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                            child: Text('${lastWeight.toStringAsFixed(1)} Kg', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text('${animalRecords.length} registros', style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                                        ],
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ] else ...[
              _buildSelectedAnimalHeader(service),
              Expanded(child: _buildAnimalWeightHistory(service)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSelectedAnimalHeader(AnimalService service) {
    final animal = service.animals.firstWhere((a) => a.id == _selectedAnimalId, orElse: () => Animal(id: '', code: '???', type: AnimalType.bovine, breed: '', sex: '', birthDate: DateTime.now(), entryDate: DateTime.now(), currentLocation: '', group: ''));
    final animalRecords = service.weightRecords.where((r) => r.animalId == _selectedAnimalId).toList()..sort((a, b) => b.date.compareTo(a.date));
    final lastWeight = animalRecords.isNotEmpty ? animalRecords.first.weight : animal.currentWeight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryGreen, AppColors.secondaryGreen], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => setState(() => _selectedAnimalId = null),
                child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.arrow_back, color: Colors.white, size: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(animal.name != null && animal.name!.isNotEmpty ? '${animal.code} - ${animal.name}' : animal.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${animal.breed} • ${animal.sex} • ${animal.group}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (ctx) => _IndividualMeatEntryForm(preselectedAnimal: animal),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: AppColors.primaryGreen, size: 16),
                      SizedBox(width: 4),
                      Text('Registrar', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Último Peso', '${lastWeight.toStringAsFixed(1)} Kg', Icons.scale),
              _buildMiniStat('Registros', '${animalRecords.length}', Icons.list_alt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
      ],
    );
  }

  Widget _buildAnimalWeightHistory(AnimalService service) {
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
    final animalRecords = service.weightRecords.where((r) => r.animalId == _selectedAnimalId).toList()..sort((a, b) => b.date.compareTo(a.date));

    if (animalRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.weightHanging, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Sin registros de pesaje', style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Toca "Registrar" para agregar el primero', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: animalRecords.length,
      itemBuilder: (context, index) {
        final r = animalRecords[index];
        final isLatest = index == 0;
        
        double gain = 0;
        if (index < animalRecords.length - 1) {
          gain = r.weight - animalRecords[index+1].weight;
        }

        return FadeInLeft(
          delay: Duration(milliseconds: index * 80),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: isLatest ? 3 : 1,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: isLatest ? AppColors.primaryGreen : Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(DateFormat('dd MMM, yyyy').format(r.date), style: TextStyle(fontWeight: isLatest ? FontWeight.bold : FontWeight.w500, fontSize: 14, color: isLatest ? AppColors.textDark : Colors.black87)),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Text('${r.weight.toStringAsFixed(1)} Kg', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          if (currentUser?.canUpdateOrDeleteRecords == true)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                              padding: EdgeInsets.zero,
                              onSelected: (value) {
                                if (value == 'edit') {
                                  final animal = service.animals.firstWhere((a) => a.id == _selectedAnimalId);
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                    builder: (_) => _IndividualMeatEntryForm(
                                      preselectedAnimal: animal,
                                      record: r,
                                    ),
                                  );
                                } else if (value == 'delete') {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Eliminar Registro'),
                                      content: const Text('¿Seguro que deseas eliminar este registro de pesaje?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                        TextButton(
                                          onPressed: () {
                                            Provider.of<AnimalService>(context, listen: false).deleteWeightRecord(r.id);
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (index < animalRecords.length - 1 || (r.notes != null && r.notes!.isNotEmpty)) const Divider(height: 16),
                  if (index < animalRecords.length - 1) ...[
                    Row(
                      children: [
                        Icon(gain >= 0 ? Icons.trending_up : Icons.trending_down, color: gain >= 0 ? Colors.green : Colors.red, size: 14),
                        const SizedBox(width: 4),
                        Text(gain >= 0 ? '+${gain.toStringAsFixed(1)} Kg desde anterior' : '${gain.toStringAsFixed(1)} Kg desde anterior', style: TextStyle(color: gain >= 0 ? Colors.green : Colors.red, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (r.notes != null && r.notes!.isNotEmpty)
                    Text('Notas: ${r.notes!}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// FORM: Registro de Pesaje Individual
// ============================================================

class _IndividualMeatEntryForm extends StatefulWidget {
  final Animal? preselectedAnimal;
  final WeightRecord? record;

  const _IndividualMeatEntryForm({this.preselectedAnimal, this.record});

  @override
  State<_IndividualMeatEntryForm> createState() => _IndividualMeatEntryFormState();
}

class _IndividualMeatEntryFormState extends State<_IndividualMeatEntryForm> {
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  String? _selectedAnimalId;
  String _animalSearchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.preselectedAnimal != null) {
      _selectedAnimalId = widget.preselectedAnimal!.id;
    }
    if (widget.record != null) {
      _selectedAnimalId = widget.record!.animalId;
      _weightController.text = widget.record!.weight.toString();
      if (widget.record!.notes != null) {
        _notesController.text = widget.record!.notes!;
      }
    }
    _searchController.addListener(() {
      setState(() {
        _animalSearchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final animalService = Provider.of<AnimalService>(context, listen: false);
    final animals = animalService.animals.toList();

    final filteredAnimals = animals.where((a) {
      if (_animalSearchQuery.isEmpty) return true;
      final q = _animalSearchQuery.toLowerCase();
      return a.code.toLowerCase().contains(q) || (a.name ?? '').toLowerCase().contains(q) || a.breed.toLowerCase().contains(q);
    }).toList();

    Animal? selectedAnimal;
    if (_selectedAnimalId != null) {
      try {
        selectedAnimal = animals.firstWhere((a) => a.id == _selectedAnimalId);
      } catch (_) {
        selectedAnimal = null;
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            Row(
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(FontAwesomeIcons.weightHanging, color: AppColors.primaryGreen, size: 18)),
                const SizedBox(width: 12),
                const Expanded(child: Text('Registrar Pesaje Individual', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 20),

            if (selectedAnimal != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3))),
                child: Row(
                  children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primaryGreen, AppColors.secondaryGreen]), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(selectedAnimal.code.length > 3 ? selectedAnimal.code.substring(0, 3) : selectedAnimal.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(selectedAnimal.name != null && selectedAnimal.name!.isNotEmpty ? '${selectedAnimal.code} - ${selectedAnimal.name}' : selectedAnimal.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('${selectedAnimal.breed} • ${selectedAnimal.sex}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                        ],
                      ),
                    ),
                    if (widget.preselectedAnimal == null)
                      InkWell(
                        onTap: () => setState(() { _selectedAnimalId = null; _searchController.clear(); _animalSearchQuery = ''; }),
                        child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.close, color: Colors.red, size: 16)),
                      ),
                  ],
                ),
              ),
            ] else ...[
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _animalSearchQuery = val),
                decoration: InputDecoration(hintText: 'Buscar animal por código o nombre...', prefixIcon: const Icon(Icons.search, size: 20), filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                child: filteredAnimals.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No se encontraron animales', style: TextStyle(color: Colors.grey))))
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredAnimals.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final a = filteredAnimals[index];
                          return ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            leading: CircleAvatar(radius: 16, backgroundColor: AppColors.primaryGreen, child: Text(a.code.length > 2 ? a.code.substring(0, 2) : a.code, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                            title: Text(a.name != null && a.name!.isNotEmpty ? '${a.code} - ${a.name}' : a.code, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            subtitle: Text('${a.breed} • ${a.sex}', style: const TextStyle(fontSize: 10)),
                            onTap: () => setState(() { _selectedAnimalId = a.id; _searchController.text = a.code; }),
                          );
                        },
                      ),
              ),
            ],

            const SizedBox(height: 16),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Peso (Kg)', hintText: '0.0', prefixIcon: const Icon(FontAwesomeIcons.scaleBalanced, size: 16, color: AppColors.primaryGreen), filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(labelText: 'Notas (Opcional)', hintText: 'Observaciones...', filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
              maxLines: 2,
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_selectedAnimalId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un animal')));
                  return;
                }
                final weight = double.tryParse(_weightController.text) ?? 0.0;
                if (weight <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un peso válido')));
                  return;
                }

                if (widget.record != null) {
                  animalService.updateWeightRecord(widget.record!.id, {
                    'animalId': _selectedAnimalId!,
                    'weight': weight,
                    'notes': _notesController.text.trim(),
                  });
                } else {
                  animalService.addWeightRecord(
                    WeightRecord(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      animalId: _selectedAnimalId!,
                      date: DateTime.now(),
                      weight: weight,
                      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
                    ),
                  );
                }
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Pesaje individual registrado'), backgroundColor: AppColors.primaryGreen));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('GUARDAR REGISTRO', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
