import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/animal_models.dart';
import 'package:provider/provider.dart';
import '../services/animal_service.dart';

class DeathsModuleScreen extends StatefulWidget {
  const DeathsModuleScreen({super.key});

  @override
  State<DeathsModuleScreen> createState() => _DeathsModuleScreenState();
}

class _DeathsModuleScreenState extends State<DeathsModuleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registro de Decesos'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: Consumer<AnimalService>(
        builder: (context, service, child) {
          final records = service.deathRecords;
          
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text('No hay bajas registradas', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final r = records[index];
              final animal = service.deadAnimals.firstWhere((a) => a.id == r.animalId, orElse: () => Animal(id: '', code: '?', type: AnimalType.bovine, breed: '', sex: '', birthDate: DateTime.now(), entryDate: DateTime.now(), currentLocation: '', group: ''));
              
              return FadeInUp(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.red.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Código: ${animal.code}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          Text(DateFormat('dd/MM/yyyy').format(r.date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Causa: ${r.cause}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      if (r.observations != null && r.observations!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text('Obs: ${r.observations}', style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRegisterDeathDialog,
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('REGISTRAR BAJA', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showRegisterDeathDialog() {
    final service = Provider.of<AnimalService>(context, listen: false);
    final animals = service.animals;
    String? selectedAnimalId;
    String cause = 'Enfermedad';
    final obsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registrar Baja de Animal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Seleccionar Animal'),
              items: animals.map((a) => DropdownMenuItem(value: a.id, child: Text('${a.code} - ${a.breed}'))).toList(),
              onChanged: (val) => selectedAnimalId = val,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Causa del Deceso'),
              value: cause,
              items: const [
                DropdownMenuItem(value: 'Enfermedad', child: Text('Enfermedad')),
                DropdownMenuItem(value: 'Accidente', child: Text('Accidente')),
                DropdownMenuItem(value: 'Predadores', child: Text('Predadores')),
                DropdownMenuItem(value: 'Edad', child: Text('Edad')),
                DropdownMenuItem(value: 'Otro', child: Text('Otro')),
              ],
              onChanged: (val) => cause = val!,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: obsController,
              decoration: const InputDecoration(labelText: 'Observaciones / Detalles'),
              maxLines: 2,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedAnimalId != null) {
                    service.registerDeath(DeathRecord(
                      id: DateTime.now().toString(),
                      animalId: selectedAnimalId!,
                      date: DateTime.now(),
                      cause: cause,
                      observations: obsController.text,
                    ));
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text('CONFIRMAR BAJA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
