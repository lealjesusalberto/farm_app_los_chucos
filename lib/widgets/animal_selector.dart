import 'dart:math';
import 'package:flutter/material.dart';
import '../models/animal_models.dart';
import '../core/app_colors.dart';

class AnimalSelector extends StatefulWidget {
  final List<Animal> animals;
  final String? selectedAnimalId;
  final String labelText;
  final ValueChanged<String?> onChanged;

  const AnimalSelector({
    super.key,
    required this.animals,
    this.selectedAnimalId,
    required this.labelText,
    required this.onChanged,
  });

  @override
  State<AnimalSelector> createState() => _AnimalSelectorState();
}

class _AnimalSelectorState extends State<AnimalSelector> {
  void _showSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AnimalSelectorModal(
          animals: widget.animals,
          initialSelection: widget.selectedAnimalId,
          onSelected: (id) {
            widget.onChanged(id);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = (widget.selectedAnimalId != null && widget.selectedAnimalId!.isNotEmpty)
      ? widget.animals.firstWhere(
          (a) => a.id == widget.selectedAnimalId, 
          orElse: () => Animal(id: '', code: 'No encontrado', breed: '', sex: '', birthDate: DateTime.now(), entryDate: DateTime.now(), currentLocation: '', group: '', type: AnimalType.bovine)
        )
      : null;

    final display = (selected != null && selected.id.isNotEmpty)
      ? '${selected.code} - ${selected.name ?? ''} (${selected.group})'
      : 'Toca para seleccionar';

    return InkWell(
      onTap: _showSelectionModal,
      borderRadius: BorderRadius.circular(15),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.labelText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(display, style: TextStyle(color: selected != null ? Colors.black : Colors.grey.shade600, fontSize: 16)),
      ),
    );
  }
}

class _AnimalSelectorModal extends StatefulWidget {
  final List<Animal> animals;
  final String? initialSelection;
  final ValueChanged<String> onSelected;

  const _AnimalSelectorModal({required this.animals, this.initialSelection, required this.onSelected});

  @override
  State<_AnimalSelectorModal> createState() => _AnimalSelectorModalState();
}

class _AnimalSelectorModalState extends State<_AnimalSelectorModal> {
  String _searchQuery = '';
  List<String> _selectedAgeGroups = [];

  @override
  Widget build(BuildContext context) {
    final allAgeGroups = widget.animals.map((a) => a.group).toSet().toList()..sort();
    
    final filtered = widget.animals.where((a) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!a.code.toLowerCase().contains(q) && !(a.name ?? '').toLowerCase().contains(q)) return false;
      }
      if (_selectedAgeGroups.isNotEmpty) {
        if (!_selectedAgeGroups.contains(a.group)) return false;
      }
      return true;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20 + MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Seleccionar Animal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
             onChanged: (v) => setState(() => _searchQuery = v),
             decoration: InputDecoration(
               hintText: 'Buscar por código o nombre...', 
               prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
               filled: true,
               fillColor: AppColors.background,
               border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
               contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
             ),
          ),
          const SizedBox(height: 15),
          const Text('Filtrar por grupo etario:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: allAgeGroups.map((g) {
                final isSelected = _selectedAgeGroups.contains(g);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(g),
                    selected: isSelected,
                    selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                    checkmarkColor: AppColors.primaryGreen,
                    onSelected: (val) {
                      setState(() {
                        if (val) _selectedAgeGroups.add(g);
                        else _selectedAgeGroups.remove(g);
                      });
                    }
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No se encontraron animales', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final a = filtered[i];
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.primaryGreen, AppColors.secondaryGreen]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                a.code.length > 3 ? a.code.substring(0, 3) : a.code,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                          title: Text('${a.code} - ${a.name ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(a.group),
                          trailing: const Icon(Icons.check_circle_outline, color: Colors.grey),
                          onTap: () => widget.onSelected(a.id),
                        ),
                      );
                    }
                  ),
          ),
        ],
      ),
    );
  }
}
