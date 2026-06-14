import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import '../services/animal_service.dart';
import '../models/animal_models.dart';

class ProductionSummaryScreen extends StatefulWidget {
  const ProductionSummaryScreen({super.key});

  @override
  State<ProductionSummaryScreen> createState() => _ProductionSummaryScreenState();
}

class _ProductionSummaryScreenState extends State<ProductionSummaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Resumen de Producción', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(FontAwesomeIcons.cow), text: 'Inventario'),
            Tab(icon: Icon(FontAwesomeIcons.glassWater), text: 'Leche'),
            Tab(icon: Icon(FontAwesomeIcons.weightScale), text: 'Carne'),
          ],
        ),
      ),
      body: Consumer<AnimalService>(
        builder: (context, animalService, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildInventoryTab(animalService),
              _buildMilkTab(animalService),
              _buildMeatTab(animalService),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInventoryTab(AnimalService animalService) {
    final animals = animalService.animals;
    
    // Agrupar por tipo de animal
    final Map<AnimalType, List<Animal>> byType = {};
    for (var a in animals) {
      if (a.status.toLowerCase() != 'active' && a.status.toLowerCase() != 'activo') continue;
      byType.putIfAbsent(a.type, () => []).add(a);
    }

    if (byType.isEmpty) {
      return const Center(child: Text('No hay animales activos.'));
    }

    return ListView(
      padding: const EdgeInsets.all(15),
      children: byType.entries.map((entry) {
        final type = entry.key;
        final typeAnimals = entry.value;

        // Agrupar por edad, inicializando todos los grupos posibles en 0
        final Map<String, int> byAgeGroup = {
          for (var group in type.ageGroups) group: 0
        };

        for (var a in typeAnimals) {
          final group = a.ageGroupDisplayName;
          byAgeGroup[group] = (byAgeGroup[group] ?? 0) + 1;
        }

        return _buildAnimalTypeCard(type, typeAnimals.length, byAgeGroup);
      }).toList(),
    );
  }

  Widget _buildAnimalTypeCard(AnimalType type, int total, Map<String, int> ageGroups) {
    return FadeInUp(
      child: Card(
        margin: const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Icon(_getIconForType(type), color: AppColors.primaryGreen, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _getNameForType(type),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Total: $total',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // Body with age groups in a Wrap
            Padding(
              padding: const EdgeInsets.all(15),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ageGroups.entries.map((entry) {
                  return Container(
                    width: (MediaQuery.of(context).size.width - 70) / 2, // 2 columns roughly
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: entry.value > 0 ? AppColors.textDark : Colors.grey,
                              fontWeight: entry.value > 0 ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          entry.value.toString(),
                          style: TextStyle(
                            color: entry.value > 0 ? AppColors.primaryGreen : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilkTab(AnimalService animalService) {
    final milkRecords = animalService.milkRecords;
    final now = DateTime.now();

    // Cálculos
    double todayMilk = 0;
    double weekMilk = 0;
    double monthMilk = 0;

    for (var r in milkRecords) {
      if (r.date.year == now.year && r.date.month == now.month && r.date.day == now.day) {
        todayMilk += r.totalLiters;
      }
      if (now.difference(r.date).inDays <= 7) {
        weekMilk += r.totalLiters;
      }
      if (r.date.year == now.year && r.date.month == now.month) {
        monthMilk += r.totalLiters;
      }
    }

    final individualMilkRecords = animalService.individualMilkRecords;
    final Map<String, double> milkByAgeGroup = {};
    for (var r in individualMilkRecords) {
      if (r.date.year == now.year && r.date.month == now.month) {
        try {
          final animal = animalService.animals.firstWhere((a) => a.id == r.animalId);
          final group = animal.ageGroupDisplayName;
          milkByAgeGroup[group] = (milkByAgeGroup[group] ?? 0) + r.liters;
        } catch (_) {}
      }
    }

    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        _buildStatCard('Producción de Hoy', '${todayMilk.toStringAsFixed(1)} L', FontAwesomeIcons.sun, Colors.orange),
        const SizedBox(height: 15),
        _buildStatCard('Últimos 7 Días', '${weekMilk.toStringAsFixed(1)} L', FontAwesomeIcons.calendarWeek, Colors.blue),
        const SizedBox(height: 15),
        _buildStatCard('Mes Actual', '${monthMilk.toStringAsFixed(1)} L', FontAwesomeIcons.calendarCheck, AppColors.primaryGreen),
        
        if (milkByAgeGroup.isNotEmpty) ...[
          const SizedBox(height: 30),
          const Text('Producción Individual por Grupo Etario (Mes)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...milkByAgeGroup.entries.map((entry) {
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                  child: const Icon(FontAwesomeIcons.cow, color: AppColors.primaryGreen, size: 18),
                ),
                title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text('${entry.value.toStringAsFixed(1)} L', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            );
          }),
        ]
      ],
    );
  }

  Widget _buildMeatTab(AnimalService animalService) {
    final animals = animalService.animals;
    
    // Filtrar animales activos con peso mayor a 0
    final validAnimals = animals.where((a) => (a.status.toLowerCase() == 'active' || a.status.toLowerCase() == 'activo') && a.currentWeight > 0).toList();

    if (validAnimals.isEmpty) {
      return const Center(child: Text('No hay registros de peso de animales activos.'));
    }

    double totalBiomass = 0;
    final Map<String, double> biomassByGroup = {};
    final Map<String, int> countByGroup = {};

    for (var a in validAnimals) {
      if (a.type == AnimalType.dog) continue;
      
      final group = a.ageGroupDisplayName;
      totalBiomass += a.currentWeight;
      biomassByGroup[group] = (biomassByGroup[group] ?? 0) + a.currentWeight;
      countByGroup[group] = (countByGroup[group] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.all(15),
      children: [

        const Text('Desglose por Grupo Etario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...biomassByGroup.entries.map((entry) {
          final group = entry.key;
          final biomass = entry.value;
          final count = countByGroup[group] ?? 1;
          final avg = biomass / count;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.brown.withOpacity(0.1),
                child: const Icon(FontAwesomeIcons.weightScale, color: Colors.brown, size: 18),
              ),
              title: Text(group, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Promedio: ${avg.toStringAsFixed(1)} Kg/cabeza (Cant: $count)'),
              trailing: Text('${biomass.toStringAsFixed(1)} Kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 5),
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNameForType(AnimalType type) {
    switch (type) {
      case AnimalType.bovine: return 'Bovinos';
      case AnimalType.buffalo: return 'Búfalos';
      case AnimalType.equine: return 'Equinos';
      case AnimalType.porcine: return 'Porcinos';
      case AnimalType.poultry: return 'Aves';
      case AnimalType.dog: return 'Caninos';
    }
  }

  IconData _getIconForType(AnimalType type) {
    switch (type) {
      case AnimalType.bovine: return FontAwesomeIcons.cow;
      case AnimalType.buffalo: return FontAwesomeIcons.hippo;
      case AnimalType.equine: return FontAwesomeIcons.horse;
      case AnimalType.porcine: return FontAwesomeIcons.piggyBank;
      case AnimalType.poultry: return FontAwesomeIcons.crow;
      case AnimalType.dog: return FontAwesomeIcons.dog;
    }
  }
}
