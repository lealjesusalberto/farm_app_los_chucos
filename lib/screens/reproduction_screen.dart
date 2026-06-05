import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/animal_models.dart';
import '../services/animal_service.dart';

class ReproductionScreen extends StatefulWidget {
  const ReproductionScreen({super.key});

  @override
  State<ReproductionScreen> createState() => _ReproductionScreenState();
}

class _ReproductionScreenState extends State<ReproductionScreen> {
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
        body: TabBarView(
          children: [
            _buildTab(ReproductionRecordType.service),
            _buildTab(ReproductionRecordType.pregnancy),
            _buildTab(ReproductionRecordType.birth),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showEntryDialog(context),
          backgroundColor: AppColors.primaryGreen,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildTab(ReproductionRecordType type) {
    return Consumer<AnimalService>(
      builder: (context, service, child) {
        final records = service.reproductionRecords.where((r) => r.type == type).toList();
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
                        if (record.serviceType != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(record.serviceType!, style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const Divider(),
                    _buildInfoRow('Fecha:', DateFormat('dd/MM/yyyy').format(record.date)),
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
  const ReproductionEntryForm({super.key});

  @override
  State<ReproductionEntryForm> createState() => _ReproductionEntryFormState();
}

class _ReproductionEntryFormState extends State<ReproductionEntryForm> {
  ReproductionRecordType _selectedType = ReproductionRecordType.service;
  String? _selectedAnimalId;
  String _serviceType = 'IA';
  final _bullNameController = TextEditingController();
  final _calfIdController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isPregnant = true;

  @override
  Widget build(BuildContext context) {
    final animalService = Provider.of<AnimalService>(context, listen: false);
    final females = animalService.animals.toList(); // En un entorno real, filtrar por sexo hembra

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
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
            DropdownButtonFormField<String>(
              value: _selectedAnimalId,
              items: females.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.code} - ${a.breed}'))).toList(),
              onChanged: (val) => setState(() => _selectedAnimalId = val),
              decoration: const InputDecoration(labelText: 'Vientre (Madre)'),
            ),
            if (_selectedType == ReproductionRecordType.service) ...[
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _serviceType,
                items: const [
                  DropdownMenuItem(value: 'IA', child: Text('Inseminación Artificial (IA)')),
                  DropdownMenuItem(value: 'Monta Natural', child: Text('Monta Natural')),
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
                final record = ReproductionRecord(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  animalId: _selectedAnimalId!,
                  type: _selectedType,
                  date: DateTime.now(),
                  bullName: _selectedType == ReproductionRecordType.service ? _bullNameController.text : null,
                  serviceType: _selectedType == ReproductionRecordType.service ? _serviceType : null,
                  isPregnant: _selectedType == ReproductionRecordType.pregnancy ? _isPregnant : null,
                  calfId: _selectedType == ReproductionRecordType.birth ? _calfIdController.text : null,
                  notes: _notesController.text,
                );
                animalService.addReproductionRecord(record);
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
