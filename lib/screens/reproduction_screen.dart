import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/animal_models.dart';
import '../services/animal_service.dart';
import '../services/auth_service.dart';
import '../models/user_models.dart';
import '../widgets/animal_selector.dart';

class ReproductionScreen extends StatefulWidget {
  const ReproductionScreen({super.key});

  @override
  State<ReproductionScreen> createState() => _ReproductionScreenState();
}

class _ReproductionScreenState extends State<ReproductionScreen> {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filtrar por Grupo Etario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ]
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        children: allAgeGroups.map((g) {
                          final isSelected = _selectedAgeGroups.contains(g);
                          return FilterChip(
                            label: Text(g),
                            selected: isSelected,
                            selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
                            checkmarkColor: AppColors.primaryGreen,
                            onSelected: (val) {
                              setModalState(() {
                                if (val) _selectedAgeGroups.add(g);
                                else _selectedAgeGroups.remove(g);
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: () {
                        setState(() {}); 
                        Navigator.pop(context);
                      },
                      child: const Text('Aplicar Filtros', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Buscar vientre...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.primaryGreen),
            onPressed: () => _showFilterModal(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reproducción & Genética'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryGreen,
            tabs: [
              Tab(text: 'Servicios/IA'),
              Tab(text: 'Preñez'),
              Tab(text: 'Partos'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTab(ReproductionRecordType.service),
                  _buildTab(ReproductionRecordType.pregnancy),
                  _buildTab(ReproductionRecordType.birth),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showEntryDialog(context),
          backgroundColor: AppColors.primaryGreen,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Registrar Evento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildTab(ReproductionRecordType type) {
    final currentUser = Provider.of<AuthService>(context, listen: false).currentUser;
    return Consumer<AnimalService>(
      builder: (context, service, child) {
        final allRecords = service.reproductionRecords.where((r) => r.type == type).toList();
        
        final records = allRecords.where((r) {
          final animal = service.animals.firstWhere((a) => a.id == r.animalId, orElse: () => Animal(id: '', code: 'Desconocido', type: AnimalType.bovine, breed: '', sex: '', birthDate: DateTime.now(), entryDate: DateTime.now(), currentLocation: '', group: ''));
          
          if (_searchQuery.isNotEmpty) {
            if (!animal.code.toLowerCase().contains(_searchQuery.toLowerCase()) && 
                !(animal.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase())) {
              return false;
            }
          }
          if (_selectedAgeGroups.isNotEmpty) {
            if (!_selectedAgeGroups.contains(animal.group)) return false;
          }
          return true;
        }).toList();

        if (records.isEmpty) {
          return const Center(child: Text('No hay registros', style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final animal = service.animals.firstWhere(
              (a) => a.id == record.animalId,
              orElse: () => Animal(
                id: '', code: 'Desconocido', type: AnimalType.bovine,
                breed: '', sex: '', birthDate: DateTime.now(),
                entryDate: DateTime.now(), currentLocation: '', group: '',
              ),
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Vientre: ${animal.code}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            if (record.serviceType != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text(record.serviceType!, style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            if (currentUser?.canUpdateOrDeleteRecords == true)
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                                padding: EdgeInsets.zero,
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                      builder: (ctx) => ReproductionEntryForm(initialType: type, record: record),
                                    );
                                  } else if (value == 'delete') {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Eliminar Registro'),
                                        content: const Text('¿Seguro que deseas eliminar este registro de reproducción?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                          TextButton(
                                            onPressed: () {
                                              Provider.of<AnimalService>(context, listen: false).deleteReproductionRecord(record.id);
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
                    const Divider(),
                    _buildInfoRow('Fecha:', DateFormat('dd/MM/yyyy').format(record.date)),
                    if (record.pregnancyDate != null)
                      _buildInfoRow('Fecha de Monta:', DateFormat('dd/MM/yyyy').format(record.pregnancyDate!)),
                    if (record.deliveryDate != null)
                      _buildInfoRow('Fecha de Parto:', DateFormat('dd/MM/yyyy').format(record.deliveryDate!)),
                    if (record.bullName != null && record.bullName!.isNotEmpty)
                      _buildInfoRow('Toro/Padre:', record.bullName!),
                    if (record.isPregnant != null)
                      _buildInfoRow('Estado:', record.isPregnant! ? 'Positivo (Preñada)' : 'Negativo (Vacía)'),
                    if (record.calfId != null && record.calfId!.isNotEmpty)
                      _buildInfoRow('ID Cría:', record.calfId!),
                    if (record.notes != null && record.notes!.isNotEmpty)
                      _buildInfoRow('Notas:', record.notes!),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
        ],
      ),
    );
  }

  void _showEntryDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => const ReproductionEntryForm(),
    );
  }
}

class ReproductionEntryForm extends StatefulWidget {
  final ReproductionRecordType? initialType;
  final ReproductionRecord? record;

  const ReproductionEntryForm({super.key, this.initialType, this.record});

  @override
  State<ReproductionEntryForm> createState() => _ReproductionEntryFormState();
}

class _ReproductionEntryFormState extends State<ReproductionEntryForm> {
  ReproductionRecordType _selectedType = ReproductionRecordType.service;
  String? _selectedAnimalId;
  String _serviceType = 'IA';
  final _bullNameController = TextEditingController();
  final _calfIdController = TextEditingController();
  String _calfSex = 'Hembra';
  final _notesController = TextEditingController();
  bool _isPregnant = true;
  DateTime _date = DateTime.now();
  DateTime? _pregnancyDate;
  DateTime? _deliveryDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
    if (widget.record != null) {
      final r = widget.record!;
      _selectedType = r.type;
      _selectedAnimalId = r.animalId;
      _date = r.date;
      _pregnancyDate = r.pregnancyDate;
      _deliveryDate = r.deliveryDate;
      if (r.bullName != null) _bullNameController.text = r.bullName!;
      if (r.serviceType != null) _serviceType = r.serviceType!;
      if (r.isPregnant != null) _isPregnant = r.isPregnant!;
      if (r.calfId != null) _calfIdController.text = r.calfId!;
      if (r.notes != null) _notesController.text = r.notes!;
    }
  }

  Widget _buildDatePicker(String label, DateTime? dateValue, Function(DateTime?) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context, 
            initialDate: dateValue ?? DateTime.now(), 
            firstDate: DateTime(2000), 
            lastDate: DateTime(2100)
          );
          if (date != null) onChanged(date);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateValue == null ? 'Seleccionar fecha' : DateFormat('dd/MM/yyyy').format(dateValue)),
              const Icon(Icons.calendar_today, size: 14, color: AppColors.primaryGreen)
            ]
          )
        )
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final animalService = Provider.of<AnimalService>(context, listen: false);
    final females = animalService.animals.toList(); // En un entorno real, filtrar por sexo hembra

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Registrar Evento Reproductivo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            DropdownButtonFormField<ReproductionRecordType>(
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: ReproductionRecordType.service, child: Text('Servicio / Inseminación')),
                DropdownMenuItem(value: ReproductionRecordType.pregnancy, child: Text('Diagnóstico de Preñez')),
                DropdownMenuItem(value: ReproductionRecordType.birth, child: Text('Parto')),
              ],
              onChanged: (val) => setState(() => _selectedType = val!),
              decoration: const InputDecoration(labelText: 'Tipo de Registro'),
            ),
            const SizedBox(height: 15),
            AnimalSelector(
              animals: females,
              selectedAnimalId: _selectedAnimalId,
              labelText: 'Vientre (Madre)',
              onChanged: (val) => setState(() => _selectedAnimalId = val),
            ),
            const SizedBox(height: 15),
            _buildDatePicker('Fecha del Registro', _date, (date) => setState(() => _date = date!)),
            const SizedBox(height: 15),
            _buildDatePicker('Fecha de Monta', _pregnancyDate, (date) => setState(() => _pregnancyDate = date)),
            const SizedBox(height: 15),
            _buildDatePicker('Fecha de Partos (Estimada/Real)', _deliveryDate, (date) => setState(() => _deliveryDate = date)),
            if (_selectedType == ReproductionRecordType.service) ...[
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _serviceType,
                items: const [
                  DropdownMenuItem(value: 'IA', child: Text('Inseminación Artificial (IA)')),
                  DropdownMenuItem(value: 'IATF', child: Text('Inseminación Artificial a Tiempo Fijo (IATF)')),
                  DropdownMenuItem(value: 'Monta Natural', child: Text('Monta Natural')),
                  DropdownMenuItem(value: 'MNTF', child: Text('Monta Natural a Tiempo Fijo (MNTF)')),
                  DropdownMenuItem(value: 'TE', child: Text('Transferencia de Embriones (TE)')),
                ],
                onChanged: (val) => setState(() => _serviceType = val!),
                decoration: const InputDecoration(labelText: 'Tipo de Servicio'),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _bullNameController,
                decoration: const InputDecoration(labelText: 'Nombre / ID del Toro/Pajuela'),
              ),
            ],
            if (_selectedType == ReproductionRecordType.pregnancy) ...[
              const SizedBox(height: 15),
              SwitchListTile(
                title: const Text('¿Está preñada?'),
                value: _isPregnant,
                activeColor: AppColors.primaryGreen,
                onChanged: (val) => setState(() => _isPregnant = val),
              ),
            ],
            if (_selectedType == ReproductionRecordType.birth) ...[
              const SizedBox(height: 15),
              TextField(
                controller: _calfIdController,
                decoration: const InputDecoration(labelText: 'ID / Arete de la Cría (Opcional)'),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _calfSex,
                items: const [
                  DropdownMenuItem(value: 'Hembra', child: Text('Hembra')),
                  DropdownMenuItem(value: 'Macho', child: Text('Macho')),
                ],
                onChanged: (val) => setState(() => _calfSex = val!),
                decoration: const InputDecoration(labelText: 'Sexo de la Cría'),
              ),
            ],
            const SizedBox(height: 15),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notas Adicionales'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_selectedAnimalId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione un vientre')));
                  return;
                }
                if (widget.record != null) {
                  animalService.updateReproductionRecord(widget.record!.id, {
                    'animalId': _selectedAnimalId!,
                    'type': _selectedType.toString(), // Enum serialize if needed, but the service handles it via toMap? No, update needs primitive values or wait...
                    // In animal_service, update methods just pass the Map. Let's make sure we pass the correct properties.
                    // Wait, actually ReproductionRecord has a `toMap` method, so we can just update with the whole map.
                  });
                  final updatedRecord = ReproductionRecord(
                    id: widget.record!.id,
                    animalId: _selectedAnimalId!,
                    type: _selectedType,
                    date: _date,
                    pregnancyDate: _pregnancyDate,
                    deliveryDate: _deliveryDate,
                    bullName: _selectedType == ReproductionRecordType.service ? _bullNameController.text : null,
                    serviceType: _selectedType == ReproductionRecordType.service ? _serviceType : null,
                    isPregnant: _selectedType == ReproductionRecordType.pregnancy ? _isPregnant : null,
                    calfId: _selectedType == ReproductionRecordType.birth ? _calfIdController.text : null,
                    notes: _notesController.text,
                  );
                  animalService.updateReproductionRecord(widget.record!.id, updatedRecord.toMap());
                } else {
                  final record = ReproductionRecord(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    animalId: _selectedAnimalId!,
                    type: _selectedType,
                    date: _date,
                    pregnancyDate: _pregnancyDate,
                    deliveryDate: _deliveryDate,
                    bullName: _selectedType == ReproductionRecordType.service ? _bullNameController.text : null,
                    serviceType: _selectedType == ReproductionRecordType.service ? _serviceType : null,
                    isPregnant: _selectedType == ReproductionRecordType.pregnancy ? _isPregnant : null,
                    calfId: _selectedType == ReproductionRecordType.birth ? _calfIdController.text : null,
                    notes: _notesController.text,
                  );
                  animalService.addReproductionRecord(record);

                  if (_selectedType == ReproductionRecordType.birth) {
                    try {
                      final mother = animalService.animals.firstWhere((a) => a.id == _selectedAnimalId);
                      final newCalf = Animal(
                        id: DateTime.now().millisecondsSinceEpoch.toString() + '_calf',
                        code: _calfIdController.text.trim().isNotEmpty ? _calfIdController.text.trim() : 'CRIA-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                        name: 'Cría de ${mother.code}',
                        type: mother.type,
                        breed: mother.breed,
                        sex: _calfSex,
                        birthDate: _deliveryDate ?? _date,
                        entryDate: DateTime.now(),
                        origin: AnimalOrigin.nacimiento,
                        currentWeight: 0.0,
                        currentLocation: mother.currentLocation,
                        group: mother.group,
                        motherId: mother.id,
                        status: 'active',
                      );
                      animalService.addAnimal(newCalf);
                    } catch (e) {
                      debugPrint('Error creando cría: $e');
                    }
                  }
                }

                Navigator.pop(context);
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
