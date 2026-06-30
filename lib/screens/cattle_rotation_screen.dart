import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/app_colors.dart';
import '../models/land_models.dart';
import '../models/animal_models.dart';
import 'package:provider/provider.dart';
import '../services/land_service.dart';
import '../services/animal_service.dart';


class CattleRotationScreen extends StatefulWidget {
  const CattleRotationScreen({super.key});

  @override
  State<CattleRotationScreen> createState() => _CattleRotationScreenState();
}

class _CattleRotationScreenState extends State<CattleRotationScreen> with SingleTickerProviderStateMixin {
  AnimalType? _selectedAnimalType;
  String? _selectedAgeGroup;
  String? _selectedSourcePotreroId;
  String? _selectedTargetPotreroId;
  
  List<String> _allAgeGroups = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final landService = Provider.of<LandService>(context);
    final potreros = landService.potreros;
    final animalService = Provider.of<AnimalService>(context);
    final activeAnimals = animalService.animals;


    // Todos los potreros pueden ser origen (incluso si no tienen ganado asignado, para correcciones)
    final sourceOptions = potreros.toList();
    // Potreros de destino (excluyendo el seleccionado como origen y los que están en descanso < 45 días)
    final targetOptions = potreros.where((p) {
      if (p.id == _selectedSourcePotreroId) return false;
      if (p.status == 'En Descanso' && p.lastRotationDate != null) {
        final daysResting = DateTime.now().difference(p.lastRotationDate!).inDays;
        if (daysResting < 45) return false; // En descanso obligatorio de 45 días
      }
      return true;
    }).toList();

    // Validación de seguridad
    if (_selectedSourcePotreroId != null && !sourceOptions.any((p) => p.id == _selectedSourcePotreroId)) {
      _selectedSourcePotreroId = null;
    }
    if (_selectedTargetPotreroId != null && !targetOptions.any((p) => p.id == _selectedTargetPotreroId)) {
      _selectedTargetPotreroId = null;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rotación de Rebaños'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryGreen,
          tabs: const [
            Tab(text: 'Registrar Rotación'),
            Tab(text: 'Ubicación Actual'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            FadeInDown(
              child: _buildInfoCard(
                'Seleccione el lote y el potrero de destino para realizar la rotación.',
                Icons.sync_alt,
              ),
            ),
            const SizedBox(height: 20),
            
            FadeInUp(
              child: _buildSelectionCard(
                title: 'LOTE / GRUPO ETARIO A ROTAR',
                icon: Icons.pets,
                color: Colors.blue,
                child: Column(
                  children: [
                    _buildDropdown(
                      label: 'Tipo de Animal',
                      value: _selectedAnimalType?.name,
                      items: AnimalType.values.map((t) {
                        String name = '';
                        switch (t) {
                          case AnimalType.bovine: name = 'Bovino'; break;
                          case AnimalType.buffalo: name = 'Búfalo'; break;
                          case AnimalType.equine: name = 'Equino'; break;
                          case AnimalType.porcine: name = 'Porcino'; break;
                          case AnimalType.poultry: name = 'Aves'; break;
                          case AnimalType.dog: name = 'Perro'; break;
                        }
                        return DropdownMenuItem(value: t.name, child: Text(name));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedAnimalType = AnimalType.values.firstWhere((t) => t.name == val);
                          _selectedAgeGroup = null; // Reset age group when type changes
                          _allAgeGroups = _selectedAnimalType!.ageGroups;
                        });
                      },
                    ),
                    if (_selectedAnimalType != null) ...[
                      const SizedBox(height: 15),
                      _buildDropdown(
                        label: 'Seleccionar Grupo Etario',
                        value: _selectedAgeGroup,
                        items: _allAgeGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedAgeGroup = val;
                            
                            // Auto-select source if we find a potrero with this group
                            final match = potreros.where((p) => p.currentCattleLot == val).toList();
                            if (match.isNotEmpty) {
                              _selectedSourcePotreroId = match.first.id;
                            }
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Icon(Icons.arrow_downward, color: Colors.blue, size: 24),
              ),
            ),
            
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: _buildSelectionCard(
                title: 'ORIGEN (Opcional)',
                icon: Icons.logout,
                color: Colors.orange,
                child: _buildDropdown(
                  label: 'Potrero Actual',
                  value: _selectedSourcePotreroId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Ninguno (Ingreso Externo)')),
                    ...sourceOptions.map((p) => DropdownMenuItem(
                      value: p.id, 
                      child: Text(
                        '${p.name} ${p.currentCattleLot.isNotEmpty ? "(${p.currentCattleLot})" : ""}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedSourcePotreroId = val;
                      if (_selectedTargetPotreroId == _selectedSourcePotreroId) {
                        _selectedTargetPotreroId = null;
                      }
                    });
                  },
                ),
              ),
            ),
            
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Icon(Icons.arrow_downward, color: AppColors.primaryGreen, size: 30),
              ),
            ),
            
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _buildSelectionCard(
                title: 'DESTINO',
                icon: Icons.login,
                color: AppColors.primaryGreen,
                child: _buildDropdown(
                  label: 'Potrero de Destino',
                  value: _selectedTargetPotreroId,
                  items: targetOptions.map((p) => DropdownMenuItem(
                    value: p.id, 
                    child: Text(
                      '${p.name} - ${p.currentCattleLot.isNotEmpty ? "Ocupado por ${p.currentCattleLot}" : p.status}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedTargetPotreroId = val),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            FadeIn(
              delay: const Duration(milliseconds: 600),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (_selectedAgeGroup != null && _selectedTargetPotreroId != null) 
                      ? _performRotation 
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('CONFIRMAR ROTACIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      _buildCurrentLocationsTab(potreros, activeAnimals),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationsTab(List<Potrero> potreros, List<Animal> activeAnimals) {
    final occupiedPotreros = potreros.where((p) => p.currentCattleLot.isNotEmpty).toList();

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
        child: Text('No hay rebaños asignados a ningún potrero en este momento.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: finalDisplayList.length,
      itemBuilder: (context, index) {
        final p = finalDisplayList[index];
        final count = activeAnimals.where((a) => a.ageGroupDisplayName == p.currentCattleLot || a.group == p.currentCattleLot).length;
        final dateStr = p.lastRotationDate != null 
            ? '${p.lastRotationDate!.day.toString().padLeft(2, '0')}/${p.lastRotationDate!.month.toString().padLeft(2, '0')}/${p.lastRotationDate!.year}'
            : 'Sin fecha registrada';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
              child: const Icon(Icons.pets, color: AppColors.primaryGreen),
            ),
            title: Text(p.currentCattleLot, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Ubicación del rebaño Potrero (${p.name})', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
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
                Text('Fecha de ingreso: $dateStr', style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
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

  Widget _buildInfoCard(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.primaryGreen, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const Divider(height: 25),
          child,
        ],
      ),
    );
  }

  Widget _buildDropdown({required String label, required dynamic value, required List<DropdownMenuItem<dynamic>> items, required Function(dynamic) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        const SizedBox(height: 8),
        DropdownButtonFormField<dynamic>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true, // Evita desbordamiento con textos largos
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background.withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  void _performRotation() async {
    final landService = Provider.of<LandService>(context, listen: false);
    final targetPotrero = landService.potreros.firstWhere((p) => p.id == _selectedTargetPotreroId);
    
    // Al no pasar rotationDate, landService.rotateCattle usará DateTime.now() por defecto
    await landService.rotateCattle(_selectedSourcePotreroId ?? '', _selectedTargetPotreroId!, _selectedAgeGroup!);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rebaño movido exitosamente a ${targetPotrero.name}')),
      );
      
      setState(() {
        _selectedAnimalType = null;
        _selectedAgeGroup = null;
        _selectedSourcePotreroId = null;
        _selectedTargetPotreroId = null;
        _allAgeGroups = [];
      });
      
      _tabController.animateTo(1);
    }
  }
}
