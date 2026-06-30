import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/animal_models.dart';
import '../services/animal_service.dart';
import '../services/auth_service.dart';
import '../models/user_models.dart';
import '../widgets/animal_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ReproductionScreen extends StatefulWidget {
  const ReproductionScreen({super.key});

  @override
  State<ReproductionScreen> createState() => _ReproductionScreenState();
}

class _ReproductionScreenState extends State<ReproductionScreen> {
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
            final reproductionGroups = ['Novillas', 'Buvillas', 'Vacas en prod', 'Búfalas en prod', 'Búfalas secas', 'Vacas secas', 'Hembra Reproductora', 'Hembra Reemplazo', 'Vientres'];
            final availableGroups = _filterModalType != null 
                ? _filterModalType!.ageGroups.where((g) => reproductionGroups.contains(g)).toList()
                : reproductionGroups;

            return Container(
              padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 20 + MediaQuery.of(context).padding.bottom),
              height: MediaQuery.of(context).size.height * 0.6,
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
                  const SizedBox(height: 10),
                  DropdownButtonFormField<AnimalType?>(
                    decoration: const InputDecoration(labelText: '1. Seleccionar Especie', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                    value: _filterModalType,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas las especies')),
                      ...AnimalType.values.where((t) => t == AnimalType.bovine || t == AnimalType.buffalo || t == AnimalType.porcine).map((t) {
                        String name = '';
                        switch (t) {
                          case AnimalType.bovine: name = 'Bovino'; break;
                          case AnimalType.buffalo: name = 'Búfalo'; break;
                          case AnimalType.equine: name = 'Equino'; break;
                          case AnimalType.porcine: name = 'Porcino'; break;
                          default: name = t.name;
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
                        children: availableGroups.map((g) {
                          final isSelected = _selectedAgeGroups.contains(g);
                          return FilterChip(
                            label: Text(g),
                            selected: isSelected,
                            selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                            checkmarkColor: AppColors.primaryGreen,
                            onSelected: (val) {
                              setModalState(() {
                                if (val) _selectedAgeGroups.add(g);
                                else _selectedAgeGroups.remove(g);
                              });
                              setState(() {});
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
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton.extended(
              onPressed: () {
                final tabIndex = DefaultTabController.of(context).index;
                ReproductionRecordType type = ReproductionRecordType.service;
                if (tabIndex == 1) type = ReproductionRecordType.pregnancy;
                if (tabIndex == 2) type = ReproductionRecordType.birth;
                _showEntryDialog(context, initialType: type);
              },
              backgroundColor: AppColors.primaryGreen,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Registrar Evento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            );
          }
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

        IconData cardIcon;
        Color cardColor;
        switch (type) {
          case ReproductionRecordType.service: cardIcon = FontAwesomeIcons.venusMars; cardColor = Colors.blue; break;
          case ReproductionRecordType.pregnancy: cardIcon = FontAwesomeIcons.stethoscope; cardColor = Colors.orange; break;
          case ReproductionRecordType.birth: cardIcon = Icons.child_friendly; cardColor = Colors.pink; break;
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 15, left: 15, right: 15, bottom: 80),
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

            final animalName = animal.name != null && animal.name!.trim().isNotEmpty ? animal.name! : '';

            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: cardColor.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(cardIcon, color: cardColor, size: 24),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(animalName.isNotEmpty ? '$animalName (${animal.code})' : 'Nº ${animal.code}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('${animal.breed} • ${animal.group}', style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
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
                    const Divider(height: 25),
                    _buildInfoRow('Fecha del Evento:', DateFormat('dd/MM/yyyy').format(record.date)),
                    if (record.pregnancyDate != null)
                      _buildInfoRow(
                        record.type == ReproductionRecordType.service ? 'Diagnóstico de Preñez:' : 'Fecha de Monta:', 
                        DateFormat('dd/MM/yyyy').format(record.pregnancyDate!)
                      ),
                    if (record.deliveryDate != null)
                      _buildInfoRow('Fecha Estimada de Parto:', DateFormat('dd/MM/yyyy').format(record.deliveryDate!)),
                    if (record.bullName != null && record.bullName!.isNotEmpty)
                      _buildInfoRow('Toro/Padre:', record.bullName!),
                    if (record.isPregnant != null)
                      _buildInfoRow('Estado Diagnóstico:', record.isPregnant! ? 'POSITIVO (Preñada)' : 'NEGATIVO (Vacía)', 
                        valueColor: record.isPregnant! ? Colors.green : Colors.red),
                    if (record.calfId != null && record.calfId!.isNotEmpty)
                      _buildInfoRow('ID de la Cría:', record.calfId!),
                    if (record.offspringCount != null)
                      _buildInfoRow('Cantidad de Crías:', '${record.offspringCount} crías'),
                    if (record.calfPhotoUrl != null && record.calfPhotoUrl!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(record.calfPhotoUrl!, fit: BoxFit.contain),
                        ),
                      ),
                    ],
                    if (record.notes != null && record.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                        child: Text('Obs: ${record.notes}', style: const TextStyle(color: Colors.black87, fontSize: 12, fontStyle: FontStyle.italic)),
                      ),
                    ]
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: TextStyle(color: valueColor ?? AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  void _showEntryDialog(BuildContext context, {ReproductionRecordType? initialType, ReproductionRecord? record}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => ReproductionEntryForm(initialType: initialType, record: record),
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
  final _calfNameController = TextEditingController();
  final _offspringCountController = TextEditingController();
  String _calfSex = 'Hembra';
  final _notesController = TextEditingController();
  bool _isPregnant = true;
  DateTime _date = DateTime.now();
  DateTime? _pregnancyDate;
  DateTime? _deliveryDate;
  
  String? _calfPhotoUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
    
    // Default pregnancy diagnosis date for new service
    if (widget.record == null && _selectedType == ReproductionRecordType.service) {
      _pregnancyDate = _date.add(const Duration(days: 21));
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
      if (r.calfName != null) _calfNameController.text = r.calfName!;
      if (r.calfPhotoUrl != null) _calfPhotoUrl = r.calfPhotoUrl;
      if (r.notes != null) _notesController.text = r.notes!;
      if (r.offspringCount != null) _offspringCountController.text = r.offspringCount!.toString();
    }
  }

  @override
  void dispose() {
    _bullNameController.dispose();
    _calfIdController.dispose();
    _calfNameController.dispose();
    _offspringCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile != null) {
      setState(() => _isUploadingImage = true);
      try {
        final bytes = await pickedFile.readAsBytes();
        final String fileName = 'calf_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference storageRef = FirebaseStorage.instance.ref().child('animal_photos').child(fileName);
        final UploadTask uploadTask = storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        final TaskSnapshot snapshot = await uploadTask;
        final String imageUrl = await snapshot.ref.getDownloadURL();

        if (!mounted) return;
        setState(() => _calfPhotoUrl = imageUrl);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto de la cría subida exitosamente'), backgroundColor: AppColors.primaryGreen));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir foto: $e'), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isUploadingImage = false);
      }
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
    final allowedGroups = [
      'Novillas', 'Buvillas', 'Vacas en prod', 'Búfalas en prod', 'Búfalas secas', 'Vacas secas',
      'Hembra Reproductora', 'Hembra Reemplazo', 'Vientres'
    ];
    List<Animal> females = animalService.animals.where((a) => 
      a.sex.toLowerCase() == 'hembra' && 
      (a.type == AnimalType.bovine || a.type == AnimalType.buffalo || a.type == AnimalType.porcine) &&
      allowedGroups.contains(a.group)
    ).toList();

    Animal? selectedMother;
    if (_selectedAnimalId != null) {
      try {
        selectedMother = animalService.animals.firstWhere((a) => a.id == _selectedAnimalId);
      } catch (_) {}
    }
    final isPorcine = selectedMother?.type == AnimalType.porcine;


    if (_selectedType == ReproductionRecordType.pregnancy) {
      final servicedAnimalIds = animalService.reproductionRecords
          .where((r) => r.type == ReproductionRecordType.service)
          .map((r) => r.animalId)
          .toSet();
      females = females.where((f) => servicedAnimalIds.contains(f.id)).toList();
    } else if (_selectedType == ReproductionRecordType.birth) {
      final pregnantAnimalIds = animalService.reproductionRecords
          .where((r) => r.type == ReproductionRecordType.pregnancy && r.isPregnant == true)
          .map((r) => r.animalId)
          .toSet();
      females = females.where((f) => pregnantAnimalIds.contains(f.id)).toList();
    }

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
              onChanged: (val) {
                setState(() {
                  _selectedType = val!;
                  if (_selectedType == ReproductionRecordType.service && widget.record == null) {
                    _pregnancyDate = _date.add(const Duration(days: 21));
                  }
                  _selectedAnimalId = null;
                  _bullNameController.text = '';
                  _serviceType = 'IA';
                });
              },
              decoration: const InputDecoration(labelText: 'Tipo de Registro'),
            ),
            const SizedBox(height: 15),
            AnimalSelector(
              animals: females,
              selectedAnimalId: _selectedAnimalId,
              labelText: 'Vientre (Madre)',
              onChanged: (val) {
                setState(() {
                  _selectedAnimalId = val;
                  if (_selectedType == ReproductionRecordType.pregnancy && val != null) {
                    final services = animalService.reproductionRecords
                        .where((r) => r.type == ReproductionRecordType.service && r.animalId == val)
                        .toList();
                    if (services.isNotEmpty) {
                      services.sort((a, b) => b.date.compareTo(a.date));
                      final lastService = services.first;
                      _serviceType = lastService.serviceType ?? 'IA';
                      _bullNameController.text = lastService.bullName ?? '';
                    }
                  }
                });
              },
            ),
            const SizedBox(height: 15),
            _buildDatePicker(
              _selectedType == ReproductionRecordType.service 
                ? 'Fecha del Servicio / Inseminación' 
                : _selectedType == ReproductionRecordType.birth 
                  ? 'Fecha del Parto' 
                  : 'Fecha del Registro', 
              _date, 
              (date) {
                setState(() {
                  _date = date!;
                  if (_selectedType == ReproductionRecordType.service) {
                    _pregnancyDate = _date.add(const Duration(days: 21));
                  }
                });
              }
            ),
            if (_selectedType != ReproductionRecordType.birth) ...[
              const SizedBox(height: 15),
              _buildDatePicker(
                _selectedType == ReproductionRecordType.service 
                  ? 'Fecha de Diagnóstico de Preñez (Automático a 21 días)' 
                  : 'Fecha de Monta / Diagnóstico', 
                _pregnancyDate, 
                (date) => setState(() => _pregnancyDate = date)
              ),
              const SizedBox(height: 15),
              _buildDatePicker('Fecha Estimada de Parto', _deliveryDate, (date) => setState(() => _deliveryDate = date)),
            ],
            if (_selectedType == ReproductionRecordType.service || _selectedType == ReproductionRecordType.pregnancy) ...[
              const SizedBox(height: 15),
              IgnorePointer(
                ignoring: _selectedType == ReproductionRecordType.pregnancy,
                child: DropdownButtonFormField<String>(
                  value: _serviceType,
                  items: const [
                    DropdownMenuItem(value: 'IA', child: Text('Inseminación Artificial (IA)')),
                    DropdownMenuItem(value: 'IATF', child: Text('Inseminación Artificial a Tiempo Fijo (IATF)')),
                    DropdownMenuItem(value: 'Monta Natural', child: Text('Monta Natural')),
                    DropdownMenuItem(value: 'MNTF', child: Text('Monta Natural a Tiempo Fijo (MNTF)')),
                    DropdownMenuItem(value: 'TE', child: Text('Transferencia de Embriones (TE)')),
                  ],
                  onChanged: (val) => setState(() => _serviceType = val!),
                  decoration: InputDecoration(
                    labelText: 'Tipo de Servicio',
                    filled: _selectedType == ReproductionRecordType.pregnancy,
                    fillColor: Colors.grey.shade200,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              IgnorePointer(
                ignoring: _selectedType == ReproductionRecordType.pregnancy,
                child: TextField(
                  controller: _bullNameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre / ID del Toro/Pajuela',
                    filled: _selectedType == ReproductionRecordType.pregnancy,
                    fillColor: Colors.grey.shade200,
                  ),
                ),
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
              if (isPorcine) ...[
                TextField(
                  controller: _offspringCountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad de Crías Nacidas'),
                ),
              ] else ...[
                TextField(
                  controller: _calfIdController,
                  decoration: const InputDecoration(labelText: 'Número de Identificación de la Cría'),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _calfNameController,
                  decoration: const InputDecoration(labelText: 'Nombre de la Cría (Opcional)'),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _calfSex,
                  items: ['Hembra', 'Macho'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _calfSex = val!),
                  decoration: const InputDecoration(labelText: 'Sexo de la Cría'),
                ),
                const SizedBox(height: 15),
                Text('Foto de la Cría', style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _isUploadingImage ? null : _pickAndUploadImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                    ),
                    child: _isUploadingImage
                        ? const Center(child: CircularProgressIndicator())
                        : _calfPhotoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(_calfPhotoUrl!, fit: BoxFit.contain),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                  SizedBox(height: 10),
                                  Text('Toca para agregar foto', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 15),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notas Adicionales'),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_selectedAnimalId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccione un vientre')));
                  return;
                }
                
                Animal? mother;
                try {
                  mother = animalService.animals.firstWhere((a) => a.id == _selectedAnimalId);
                } catch (_) {}
                
                final isPorcine = mother?.type == AnimalType.porcine;

                if (_selectedType == ReproductionRecordType.birth) {
                  if (isPorcine) {
                    if (_offspringCountController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La cantidad de crías es obligatoria')));
                      return;
                    }
                  } else {
                    if (_calfIdController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El número de identificación de la cría es obligatorio')));
                      return;
                    }
                  }
                }

                if (widget.record != null) {
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
                    calfId: (_selectedType == ReproductionRecordType.birth && !isPorcine) ? _calfIdController.text : null,
                    calfName: (_selectedType == ReproductionRecordType.birth && !isPorcine) ? _calfNameController.text : null,
                    calfPhotoUrl: (_selectedType == ReproductionRecordType.birth && !isPorcine) ? _calfPhotoUrl : null,
                    offspringCount: (_selectedType == ReproductionRecordType.birth && isPorcine) ? int.tryParse(_offspringCountController.text) : null,
                    notes: _notesController.text,
                  );
                  await animalService.updateReproductionRecord(widget.record!.id, updatedRecord.toMap());
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
                    calfId: (_selectedType == ReproductionRecordType.birth && !isPorcine) ? _calfIdController.text : null,
                    calfName: (_selectedType == ReproductionRecordType.birth && !isPorcine) ? _calfNameController.text : null,
                    calfPhotoUrl: (_selectedType == ReproductionRecordType.birth && !isPorcine) ? _calfPhotoUrl : null,
                    offspringCount: (_selectedType == ReproductionRecordType.birth && isPorcine) ? int.tryParse(_offspringCountController.text) : null,
                    notes: _notesController.text,
                  );
                  await animalService.addReproductionRecord(record);

                  if (_selectedType == ReproductionRecordType.birth) {
                    if (isPorcine && mother != null) {
                      try {
                        final count = int.tryParse(_offspringCountController.text) ?? 1;
                        for (int i = 1; i <= count; i++) {
                          final newPiglet = Animal(
                            id: '${DateTime.now().millisecondsSinceEpoch}_piglet_$i',
                            code: '${mother.code}_C$i',
                            name: 'Lechón $i de ${mother.code}',
                            type: AnimalType.porcine,
                            breed: mother.breed,
                            sex: 'Macho',
                            birthDate: _deliveryDate ?? _date,
                            entryDate: DateTime.now(),
                            origin: AnimalOrigin.nacimiento,
                            currentWeight: 0.0,
                            currentLocation: mother.currentLocation,
                            group: 'Lechon Maternidad',
                            motherId: mother.id,
                            status: 'active',
                          );
                          await animalService.addAnimal(newPiglet);
                        }
                      } catch (e) {
                        debugPrint('Error creando lechones: $e');
                      }
                    } else if (mother != null) {
                      try {
                        final newCalf = Animal(
                          id: DateTime.now().millisecondsSinceEpoch.toString() + '_calf',
                          code: _calfIdController.text.trim(),
                          name: _calfNameController.text.trim().isNotEmpty ? _calfNameController.text.trim() : 'Cría de ${mother.code}',
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
                        await animalService.addAnimal(newCalf);
                      } catch (e) {
                        debugPrint('Error creando cría: $e');
                      }
                    }
                  }
                }

                if (mounted) Navigator.pop(context);
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
