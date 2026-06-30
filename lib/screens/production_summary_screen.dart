import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import '../services/animal_service.dart';
import '../models/animal_models.dart';
import '../services/land_service.dart';
import '../models/land_models.dart';

class ProductionSummaryScreen extends StatefulWidget {
  const ProductionSummaryScreen({super.key});

  @override
  State<ProductionSummaryScreen> createState() =>
      _ProductionSummaryScreenState();
}

class _ProductionSummaryScreenState extends State<ProductionSummaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text(
          'Resumen de Producción',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
            Tab(
              icon: Icon(FontAwesomeIcons.mapLocationDot),
              text: 'Ubicaciones',
            ),
          ],
        ),
      ),
      body: Consumer2<AnimalService, LandService>(
        builder: (context, animalService, landService, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildInventoryTab(animalService),
              _buildMilkTab(animalService),
              _buildMeatTab(animalService),
              _buildLocationsTab(landService, animalService.animals),
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
      if (a.status.toLowerCase() != 'active' &&
          a.status.toLowerCase() != 'activo')
        continue;
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
          for (var group in type.ageGroups) group: 0,
        };

        for (var a in typeAnimals) {
          final group = a.ageGroupDisplayName;
          byAgeGroup[group] = (byAgeGroup[group] ?? 0) + 1;
        }

        return _buildAnimalTypeCard(type, typeAnimals.length, byAgeGroup);
      }).toList(),
    );
  }

  Widget _buildAnimalTypeCard(
    AnimalType type,
    int total,
    Map<String, int> ageGroups,
  ) {
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getIconForType(type),
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _getNameForType(type),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Total: $total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
                    width:
                        (MediaQuery.of(context).size.width - 70) /
                        2, // 2 columns roughly
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 10,
                    ),
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
                              color: entry.value > 0
                                  ? AppColors.textDark
                                  : Colors.grey,
                              fontWeight: entry.value > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'Total: ${entry.value}',
                          style: TextStyle(
                            color: entry.value > 0
                                ? AppColors.primaryGreen
                                : Colors.grey,
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

    final last7Days = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final last30Days = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));

    // Helper para sumar basado en condición
    double sumRecords(bool Function(DateTime) condition) {
      double sum = 0;
      for (var r in milkRecords) {
        if (condition(r.date)) sum += r.totalLiters;
      }
      for (var r in animalService.individualMilkRecords) {
        if (condition(r.date)) sum += r.liters;
      }
      return sum;
    }

    double todayMilk = sumRecords((d) => d.year == now.year && d.month == now.month && d.day == now.day);
    double weekMilk = sumRecords((d) => !d.isBefore(last7Days));
    double monthMilk = sumRecords((d) => !d.isBefore(last30Days));

    final individualMilkRecords = animalService.individualMilkRecords;
    final Map<String, double> milkByAgeGroup = {};
    for (var r in individualMilkRecords) {
      if (r.date.year == now.year && r.date.month == now.month) {
        try {
          final animal = animalService.animals.firstWhere(
            (a) => a.id == r.animalId,
          );
          final group = animal.group;
          if (['Vacas en prod', 'Búfalas en prod'].contains(group)) {
            milkByAgeGroup[group] = (milkByAgeGroup[group] ?? 0) + r.liters;
          }
        } catch (_) {}
      }
    }

    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        _buildStatCard(
          'Producción de Hoy',
          '${todayMilk.toStringAsFixed(1)} L',
          FontAwesomeIcons.sun,
          Colors.orange,
        ),
        const SizedBox(height: 15),
        _buildStatCard(
          'Últimos 7 Días',
          '${weekMilk.toStringAsFixed(1)} L',
          FontAwesomeIcons.calendarWeek,
          Colors.blue,
        ),
        const SizedBox(height: 15),
        _buildStatCard(
          'Últimos 30 Días',
          '${monthMilk.toStringAsFixed(1)} L',
          FontAwesomeIcons.calendarCheck,
          AppColors.primaryGreen,
        ),

        if (milkByAgeGroup.isNotEmpty) ...[
          const SizedBox(height: 30),
          const Text(
            'Producción Individual por Grupo Etario (Mes)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...milkByAgeGroup.entries.map((entry) {
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                  child: const Icon(
                    FontAwesomeIcons.cow,
                    color: AppColors.primaryGreen,
                    size: 18,
                  ),
                ),
                title: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  '${entry.value.toStringAsFixed(1)} L',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildMeatTab(AnimalService animalService) {
    final animals = animalService.animals;

    // Filtrar animales activos con peso mayor a 0
    final validAnimals = animals
        .where(
          (a) =>
              (a.status.toLowerCase() == 'active' ||
                  a.status.toLowerCase() == 'activo') &&
              a.currentWeight > 0,
        )
        .toList();

    if (validAnimals.isEmpty) {
      return const Center(
        child: Text('No hay registros de peso de animales activos.'),
      );
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
        const Text(
          'Desglose por Grupo Etario',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...biomassByGroup.entries.map((entry) {
          final group = entry.key;
          final biomass = entry.value;
          final count = countByGroup[group] ?? 1;
          final avg = biomass / count;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.brown.withOpacity(0.1),
                child: const Icon(
                  FontAwesomeIcons.weightScale,
                  color: Colors.brown,
                  size: 18,
                ),
              ),
              title: Text(
                group,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Promedio: ${avg.toStringAsFixed(1)} Kg/cabeza (Cant: $count)',
              ),
              trailing: Text(
                '${biomass.toStringAsFixed(1)} Kg',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
      case AnimalType.bovine:
        return 'Bovinos';
      case AnimalType.buffalo:
        return 'Búfalos';
      case AnimalType.equine:
        return 'Equinos';
      case AnimalType.porcine:
        return 'Porcinos';
      case AnimalType.poultry:
        return 'Aves';
      case AnimalType.dog:
        return 'Caninos';
    }
  }

  IconData _getIconForType(AnimalType type) {
    switch (type) {
      case AnimalType.bovine:
        return FontAwesomeIcons.cow;
      case AnimalType.buffalo:
        return FontAwesomeIcons.hippo;
      case AnimalType.equine:
        return FontAwesomeIcons.horse;
      case AnimalType.porcine:
        return FontAwesomeIcons.piggyBank;
      case AnimalType.poultry:
        return FontAwesomeIcons.crow;
      case AnimalType.dog:
        return FontAwesomeIcons.dog;
    }
  }

  Widget _buildLocationsTab(LandService landService, List<Animal> activeAnimals) {
    final occupiedPotreros = landService.potreros
        .where((p) => p.currentCattleLot.isNotEmpty)
        .toList();

    // Ordenar para mostrar los más recientes primero, o los que no tienen fecha al final
    occupiedPotreros.sort((a, b) {
      if (a.lastRotationDate == null && b.lastRotationDate == null) return 0;
      if (a.lastRotationDate == null) return 1;
      if (b.lastRotationDate == null) return -1;
      return b.lastRotationDate!.compareTo(a.lastRotationDate!);
    });

    // Quedarse solo con la ubicación más reciente para cada rebaño (lote) único
    final Map<String, Potrero> uniqueLots = {};
    for (var p in occupiedPotreros) {
      if (!uniqueLots.containsKey(p.currentCattleLot)) {
        uniqueLots[p.currentCattleLot] = p;
      }
    }
    
    final finalDisplayList = uniqueLots.values.toList();

    if (finalDisplayList.isEmpty) {
      return const Center(
        child: Text(
          'No hay rebaños asignados a ningún potrero en este momento.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: finalDisplayList.length,
      itemBuilder: (context, index) {
        final p = finalDisplayList[index];
        final count = activeAnimals.where((a) => a.ageGroupDisplayName == p.currentCattleLot || a.group == p.currentCattleLot).length;
        final dateStr = p.lastRotationDate != null
            ? '${p.lastRotationDate!.day.toString().padLeft(2, '0')}/${p.lastRotationDate!.month.toString().padLeft(2, '0')}/${p.lastRotationDate!.year}'
            : 'Sin fecha registrada';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
              child: const Icon(Icons.pets, color: AppColors.primaryGreen),
            ),
            title: Text(
              p.currentCattleLot,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                 Text(
                  'Ubicación del rebaño Potrero (${p.name})',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (p.subdivisions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 2),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: p.subdivisions.map((sub) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.primaryGreen.withOpacity(0.15), width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.grid_3x3, size: 8, color: AppColors.primaryGreen),
                              const SizedBox(width: 2),
                              Text(
                                sub,
                                style: const TextStyle(
                                  color: AppColors.primaryGreen,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  'Fecha de ingreso: $dateStr',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count cab.',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.landscape, color: Colors.green, size: 20),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
