import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/app_colors.dart';
import '../models/land_models.dart';
import '../models/animal_models.dart';
import 'package:provider/provider.dart';
import '../services/land_service.dart';

class CattleRotationScreen extends StatefulWidget {
  const CattleRotationScreen({super.key});

  @override
  State<CattleRotationScreen> createState() => _CattleRotationScreenState();
}

class _CattleRotationScreenState extends State<CattleRotationScreen> {
  String? _selectedAgeGroup;
  String? _selectedSourcePotreroId;
  String? _selectedTargetPotreroId;
  
  late List<String> _allAgeGroups;

  @override
  void initState() {
    super.initState();
    _allAgeGroups = AnimalType.values.expand((t) => t.ageGroups).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final landService = Provider.of<LandService>(context);
    final potreros = landService.potreros;

    // Todos los potreros pueden ser origen (incluso si no tienen ganado asignado, para correcciones)
    final sourceOptions = potreros.toList();
    // Potreros de destino (excluyendo el seleccionado como origen)
    final targetOptions = potreros.where((p) => p.id != _selectedSourcePotreroId).toList();

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: SingleChildScrollView(
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
                title: 'GRUPO ETARIO A ROTAR',
                icon: Icons.pets,
                color: Colors.blue,
                child: _buildDropdown(
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
                      '${p.name} - ${p.status}',
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
          ],
        ),
      ),
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
    await landService.rotateCattle(_selectedSourcePotreroId ?? '', _selectedTargetPotreroId!, _selectedAgeGroup!);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rebaño movido exitosamente a ${_selectedTargetPotreroId}')),
    );
    Navigator.pop(context);
  }
}
