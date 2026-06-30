import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/land_models.dart';
import '../services/land_service.dart';
import '../services/auth_service.dart';
import '../models/user_models.dart';

import 'cattle_rotation_screen.dart';

class PotrerosModuleScreen extends StatefulWidget {
  const PotrerosModuleScreen({super.key});

  @override
  State<PotrerosModuleScreen> createState() => _PotrerosModuleScreenState();
}

class _PotrerosModuleScreenState extends State<PotrerosModuleScreen> {
  String _potreroFilter = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Consumer<LandService>(
      builder: (context, landService, child) {
        final authService = Provider.of<AuthService>(context);
        final currentUser = authService.currentUser;
        final allPotreros = landService.potreros;
        
        final potreros = allPotreros.where((p) {
          if (_potreroFilter == 'Ocupados') return p.currentCattleLot.isNotEmpty;
          if (_potreroFilter == 'Disponibles') return p.currentCattleLot.isEmpty && p.status != 'En Descanso';
          if (_potreroFilter == 'Descanso') return p.status == 'En Descanso';
          return true;
        }).toList();
        


        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, allPotreros),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Catastro Maestro (${potreros.length} Potreros)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _showAddPotreroDialog(context),
                                icon: const Icon(Icons.add_circle, color: AppColors.primaryGreen),
                                tooltip: 'Añadir Potrero',
                              ),
                              IconButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CattleRotationScreen())),
                                icon: const Icon(Icons.sync_alt, color: AppColors.primaryGreen),
                                tooltip: 'Rotación de Rebaños',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'Todos', label: Text('Todos', style: TextStyle(fontSize: 11))),
                            ButtonSegment(value: 'Ocupados', label: Text('Ocupados', style: TextStyle(fontSize: 11))),
                            ButtonSegment(value: 'Disponibles', label: Text('Libres', style: TextStyle(fontSize: 11))),
                            ButtonSegment(value: 'Descanso', label: Text('Descanso', style: TextStyle(fontSize: 11))),
                          ],
                          selected: {_potreroFilter},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              _potreroFilter = newSelection.first;
                            });
                          },
                          showSelectedIcon: false,
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith<Color>(
                              (Set<WidgetState> states) {
                                if (states.contains(WidgetState.selected)) {
                                  return AppColors.primaryGreen.withOpacity(0.2);
                                }
                                return Colors.white;
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildPotrerosList(potreros, currentUser),
                      const SizedBox(height: 30), // Padding extra
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, List<Potrero> potreros) {
    double totalHectares = potreros.fold(0, (sum, item) => sum + item.areaHectares);

    final ocupadosCount = potreros.where((p) => p.currentCattleLot.isNotEmpty).length;

    return Stack(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/land_bg.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.2),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Gestión de Tierras',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildHeaderStat('Hectáreas', totalHectares.toStringAsFixed(2)),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _buildHeaderStat('Ocupados', '$ocupadosCount'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildPotrerosList(List<Potrero> potreros, AppUser? currentUser) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: potreros.length,
      itemBuilder: (context, index) {
        final potrero = potreros[index];
        final isOccupied = potrero.currentCattleLot.isNotEmpty;
        final effectiveStatus = isOccupied ? 'Ocupado' : potrero.status;
        final statusColor = effectiveStatus == 'Disponible' ? Colors.green : (isOccupied ? Colors.red : Colors.orange);

        return FadeInLeft(
          delay: Duration(milliseconds: index * 50),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.landscape,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(potrero.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        'Tamaño: ${potrero.areaHectares.toStringAsFixed(2)} Ha',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      Text(
                        'Uso: ${potrero.purpose}',
                        style: const TextStyle(color: Colors.indigo, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      if (potrero.subdivisions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 2),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: potrero.subdivisions.map((sub) {
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
                      if (potrero.currentCattleLot.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.pets, size: 12, color: AppColors.primaryGreen),
                              const SizedBox(width: 4),
                              Text(potrero.currentCattleLot, style: const TextStyle(color: AppColors.primaryGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      if (potrero.status == 'En Descanso' && potrero.lastRotationDate != null)
                        Builder(
                          builder: (context) {
                            final daysPassed = DateTime.now().difference(potrero.lastRotationDate!).inDays;
                            final daysLeft = 45 - daysPassed;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.timer, size: 12, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(
                                    daysLeft > 0 ? 'Faltan $daysLeft días' : '¡Disponible (45 días cumplidos)!',
                                    style: TextStyle(
                                      color: daysLeft > 0 ? Colors.orange : Colors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        ),
                    ],
                  ),
                ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        effectiveStatus,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      if (currentUser?.canUpdateOrDeleteRecords == true)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                          padding: EdgeInsets.zero,
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showAddPotreroDialog(context, potrero: potrero);
                            } else if (value == 'delete') {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Eliminar Potrero'),
                                  content: Text('¿Seguro que deseas eliminar el potrero ${potrero.name}? Esta acción no se puede deshacer.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                    TextButton(
                                      onPressed: () {
                                        Provider.of<LandService>(context, listen: false).deletePotrero(potrero.id);
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
                        )
                      else
                        const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }


  void _showAddPotreroDialog(BuildContext context, {Potrero? potrero}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => PotreroEntryForm(potrero: potrero),
    );
  }
}

class PotreroEntryForm extends StatefulWidget {
  final Potrero? potrero;

  const PotreroEntryForm({super.key, this.potrero});

  @override
  State<PotreroEntryForm> createState() => _PotreroEntryFormState();
}

class _PotreroEntryFormState extends State<PotreroEntryForm> {
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  String _purpose = 'Pastoreo General';
  bool _enDescanso = false;
  List<String> _subdivisions = [];

  @override
  void initState() {
    super.initState();
    if (widget.potrero != null) {
      _nameController.text = widget.potrero!.name;
      _areaController.text = widget.potrero!.areaHectares.toString();
      _purpose = widget.potrero!.purpose;
      _enDescanso = widget.potrero!.status == 'En Descanso';
      _subdivisions = List<String>.from(widget.potrero!.subdivisions);
      
      // Asegurarse de que el propósito sea válido
      const validPurposes = ['Pastoreo General', 'Maternidad', 'Destete', 'Engorde', 'Pasto de Corte', 'Otro'];
      if (!validPurposes.contains(_purpose)) {
        _purpose = 'Otro';
      }
    }
  }

  void _showAddSubdivisionDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Subdivisión'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre de la subdivisión',
            hintText: 'Ej: Lote A',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                if (_subdivisions.contains(name)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ya existe una subdivisión con ese nombre')),
                  );
                  return;
                }
                setState(() {
                  _subdivisions.add(name);
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('AGREGAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20, left: 20, right: 20, top: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.potrero != null ? 'Editar Potrero' : 'Registrar Nuevo Potrero',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre del Potrero (Ej: Potrero #4)'),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _areaController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Tamaño en Hectáreas (Ej: 3.5)'),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: _purpose,
              items: const [
                DropdownMenuItem(value: 'Pastoreo General', child: Text('Pastoreo General')),
                DropdownMenuItem(value: 'Maternidad', child: Text('Maternidad')),
                DropdownMenuItem(value: 'Destete', child: Text('Destete')),
                DropdownMenuItem(value: 'Engorde', child: Text('Engorde')),
                DropdownMenuItem(value: 'Pasto de Corte', child: Text('Pasto de Corte')),
                DropdownMenuItem(value: 'Otro', child: Text('Otro')),
              ],
              onChanged: (val) => setState(() => _purpose = val!),
              decoration: const InputDecoration(labelText: 'Utilidad del Potrero'),
            ),
            const SizedBox(height: 15),

            // Subdivisiones Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subdivisiones (Máx. 6)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                Text(
                  '${_subdivisions.length}/6',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ..._subdivisions.map((sub) => InputChip(
                  label: Text(sub, style: const TextStyle(fontSize: 12)),
                  onDeleted: () {
                    setState(() {
                      _subdivisions.remove(sub);
                    });
                  },
                  deleteIconColor: Colors.redAccent,
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.05),
                  side: BorderSide(color: AppColors.primaryGreen.withOpacity(0.2)),
                )),
                if (_subdivisions.length < 6)
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16, color: AppColors.primaryGreen),
                    label: const Text('Agregar división', style: TextStyle(color: AppColors.primaryGreen, fontSize: 12)),
                    onPressed: () => _showAddSubdivisionDialog(context),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.primaryGreen),
                  ),
              ],
            ),
            const SizedBox(height: 15),

            if (widget.potrero == null || widget.potrero!.currentCattleLot.isEmpty)
              SwitchListTile(
                title: const Text('Poner en descanso', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Iniciará el contador de 45 días obligatorios.'),
                value: _enDescanso,
                activeColor: AppColors.primaryGreen,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _enDescanso = val),
              ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un nombre')));
                  return;
                }
                
                final area = double.tryParse(_areaController.text) ?? 0.0;
                if (area <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un área válida')));
                  return;
                }
                final landService = Provider.of<LandService>(context, listen: false);
                
                if (widget.potrero != null) {
                  final updates = <String, dynamic>{
                    'name': _nameController.text.trim(),
                    'areaHectares': area,
                    'purpose': _purpose,
                    'subdivisions': _subdivisions,
                  };
                  if (_enDescanso && widget.potrero!.status != 'En Descanso') {
                    updates['status'] = 'En Descanso';
                    updates['lastRotationDate'] = DateTime.now().toIso8601String();
                  } else if (!_enDescanso && widget.potrero!.status == 'En Descanso') {
                    updates['status'] = 'Disponible';
                  }

                  await landService.updatePotrero(widget.potrero!.id, updates);
                } else {
                  final newPotrero = Potrero(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _nameController.text.trim(),
                    areaHectares: area,
                    status: _enDescanso ? 'En Descanso' : 'Disponible',
                    currentCattleLot: '',
                    purpose: _purpose,
                    lastRotationDate: _enDescanso ? DateTime.now() : null,
                    subdivisions: _subdivisions,
                  );
                  await landService.addPotrero(newPotrero);
                }
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Potrero guardado exitosamente'), backgroundColor: AppColors.primaryGreen));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('GUARDAR POTRERO'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
