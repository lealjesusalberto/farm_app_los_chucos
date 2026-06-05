import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/animal_models.dart';
import 'package:provider/provider.dart';
import '../services/animal_service.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
              Tab(text: 'Leche (Global)', icon: Icon(FontAwesomeIcons.glassWater, size: 16)),
              Tab(text: 'Leche Individual', icon: Icon(FontAwesomeIcons.cow, size: 16)),
              Tab(text: 'Carne (Pesajes)', icon: Icon(FontAwesomeIcons.weightHanging, size: 16)),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMilkTab(),
                const _IndividualMilkTab(),
                _buildMeatTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEntryDialog(context),
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
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
                  // Calcular resumen mensual simple
                  final thisMonth = DateTime.now().month;
                  final thisYear = DateTime.now().year;
                  
                  final milkThisMonth = service.milkRecords
                    .where((r) => r.date.month == thisMonth && r.date.year == thisYear)
                    .fold(0.0, (sum, r) => sum + r.totalLiters);

                  final individualMilkThisMonth = service.individualMilkRecords
                    .where((r) => r.date.month == thisMonth && r.date.year == thisYear)
                    .fold(0.0, (sum, r) => sum + r.liters);
                    
                  return Column(
                    children: [
                      const Text('Leche Producida este Mes', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('${(milkThisMonth + individualMilkThisMonth).toStringAsFixed(1)} Lts', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Global: ${milkThisMonth.toStringAsFixed(1)} | Individual: ${individualMilkThisMonth.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
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
    return Consumer<AnimalService>(
      builder: (context, service, child) {
        final records = service.milkRecords;
        if (records.isEmpty) return const Center(child: Text('No hay registros de leche'));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final r = records[index];
            return FadeInLeft(
              child: Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: AppColors.background, child: Icon(FontAwesomeIcons.droplet, color: Colors.blue, size: 16)),
                  title: Text('${r.totalLiters} Litros (${r.amOrPm})', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('dd MMMM, yyyy').format(r.date)),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMeatTab() {
    return Consumer<AnimalService>(
      builder: (context, service, child) {
        final records = service.weightRecords;
        if (records.isEmpty) return const Center(child: Text('No hay registros de pesaje'));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final r = records[index];
            final animal = service.animals.firstWhere(
              (a) => a.id == r.animalId,
              orElse: () => Animal(
                id: '', code: 'Desconocido', type: AnimalType.bovine,
                breed: '', sex: '', birthDate: DateTime.now(),
                entryDate: DateTime.now(), currentLocation: '', group: '',
              ),
            );

            return FadeInRight(
              child: Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Animal: ${animal.code}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text('${r.weight} Kg', style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fecha de Pesaje:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(DateFormat('dd/MM/yyyy').format(r.date), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                        ],
                      ),
                      if (r.notes != null && r.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Notas: ${r.notes}', style: const TextStyle(color: Colors.black87, fontSize: 12, fontStyle: FontStyle.italic)),
                      ]
                    ],
                  ),
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
        if (currentTab == 1) {
          // Individual milk tab - show individual milk form
          return const _IndividualMilkEntryForm();
        }
        return const ProductionEntryForm();
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

  @override
  Widget build(BuildContext context) {
    return Consumer<AnimalService>(
      builder: (context, service, _) {
        // Filter only female bovines/buffaloes (typical milk producers)
        final allAnimals = service.animals.toList();
        final records = service.individualMilkRecords;

        // Build filtered animal list based on search
        final filteredAnimals = allAnimals.where((a) {
          if (_searchQuery.isEmpty) return true;
          final query = _searchQuery.toLowerCase();
          final code = a.code.toLowerCase();
          final name = (a.name ?? '').toLowerCase();
          final breed = a.breed.toLowerCase();
          return code.contains(query) || name.contains(query) || breed.contains(query);
        }).toList();

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                onChanged: (val) => setState(() {
                  _searchQuery = val;
                  _selectedAnimalId = null;
                }),
                decoration: InputDecoration(
                  hintText: 'Buscar animal por código, nombre o raza...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
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
    final thisMonth = DateTime.now().month;
    final thisYear = DateTime.now().year;
    final monthRecords = animalRecords.where((r) => r.date.month == thisMonth && r.date.year == thisYear).toList();
    final monthLiters = monthRecords.fold(0.0, (sum, r) => sum + r.liters);

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
                        ],
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

  const _IndividualMilkEntryForm({this.preselectedAnimal});

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
  }

  @override
  Widget build(BuildContext context) {
    final animalService = Provider.of<AnimalService>(context, listen: false);
    final animals = animalService.animals.toList();

    // Filter animals for dropdown
    final filteredAnimals = animals.where((a) {
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
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
                animalService.addIndividualMilkRecord(
                  IndividualMilkRecord(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    animalId: _selectedAnimalId!,
                    date: DateTime.now(),
                    liters: liters,
                    amOrPm: _amPm,
                    notes: _notesController.text.isNotEmpty ? _notesController.text : null,
                  ),
                );
                Navigator.pop(context);
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
  const ProductionEntryForm({super.key});

  @override
  State<ProductionEntryForm> createState() => _ProductionEntryFormState();
}

class _ProductionEntryFormState extends State<ProductionEntryForm> {
  String _entryType = 'Leche'; // 'Leche' o 'Carne'
  
  // Controles Leche
  final _litersController = TextEditingController();
  String _amPm = 'Both';
  
  // Controles Carne (Pesaje)
  String? _selectedAnimalId;
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final animalService = Provider.of<AnimalService>(context, listen: false);
    final animals = animalService.animals.toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Registrar Producción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _entryType,
              items: const [
                DropdownMenuItem(value: 'Leche', child: Text('Producción de Leche (Global)')),
                DropdownMenuItem(value: 'Carne', child: Text('Pesaje de Animal (Individual)')),
              ],
              onChanged: (val) => setState(() => _entryType = val!),
              decoration: const InputDecoration(labelText: 'Tipo de Registro'),
            ),
            const SizedBox(height: 15),

            if (_entryType == 'Leche') ...[
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
            ] else ...[
              DropdownButtonFormField<String>(
                value: _selectedAnimalId,
                items: animals.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.code} - ${a.breed}'))).toList(),
                onChanged: (val) => setState(() => _selectedAnimalId = val),
                decoration: const InputDecoration(labelText: 'Seleccionar Animal'),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Peso (Kg)', hintText: '0.0'),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notas Adicionales (Opcional)'),
                maxLines: 2,
              ),
            ],

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_entryType == 'Leche') {
                  final liters = double.tryParse(_litersController.text) ?? 0.0;
                  if (liters <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa una cantidad válida de litros')));
                    return;
                  }
                  animalService.addMilkRecord(
                    MilkRecord(id: DateTime.now().toString(), date: DateTime.now(), totalLiters: liters, amOrPm: _amPm),
                  );
                } else {
                  if (_selectedAnimalId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un animal')));
                    return;
                  }
                  final weight = double.tryParse(_weightController.text) ?? 0.0;
                  if (weight <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un peso válido')));
                    return;
                  }
                  animalService.addWeightRecord(
                    WeightRecord(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      animalId: _selectedAnimalId!,
                      date: DateTime.now(),
                      weight: weight,
                      notes: _notesController.text,
                    ),
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
