import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/land_models.dart';
import '../models/user_models.dart';
import 'package:provider/provider.dart';
import '../services/land_service.dart';
import '../services/auth_service.dart';

class AddFieldWorkScreen extends StatefulWidget {
  const AddFieldWorkScreen({super.key});

  @override
  State<AddFieldWorkScreen> createState() => _AddFieldWorkScreenState();
}

class _AddFieldWorkScreenState extends State<AddFieldWorkScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedPotreroId;
  String _type = 'Desmatonado';
  String _responsible = '';
  String _details = '';
  DateTime _date = DateTime.now();

  // Task assignment fields
  bool _isTaskAssignment = false;
  String? _assignedUserId;
  AppUser? _assignedUser;

  final List<String> _types = ['Desmatonado', 'Fumigación', 'Fumigación Selectiva', 'Arreglo de Cerca', 'Siembra de Pasto', 'Herrado', 'Vacunación'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (!auth.currentUser!.canAdminUsers) {
        // If not admin, the current user is automatically the responsible
        setState(() {
          _responsible = auth.currentUser!.name;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final landService = Provider.of<LandService>(context);
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    final potreros = landService.potreros;

    final isAdmin = currentUser?.canAdminUsers ?? false;
    
    // Workers that can be assigned (excluding admins/presidents)
    final workers = authService.allUsers.where((u) => u.role != UserRole.presidente && u.role != UserRole.administradora).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registrar Labor / Tarea'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
          key: _formKey,
          child: Column(
            children: [
              FadeInDown(
                child: _buildFormCard(
                  children: [
                    if (isAdmin) ...[
                      SwitchListTile(
                        title: const Text('Asignar como Tarea Pendiente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Asigna a un obrero para que la realice después.', style: TextStyle(fontSize: 12)),
                        value: _isTaskAssignment,
                        activeColor: AppColors.primaryGreen,
                        onChanged: (val) {
                          setState(() {
                            _isTaskAssignment = val;
                          });
                        },
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                    ],

                    _buildDropdownField(
                      label: 'Seleccionar Potrero',
                      value: _selectedPotreroId,
                      items: potreros.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                      onChanged: (val) => setState(() => _selectedPotreroId = val),
                    ),
                    const SizedBox(height: 15),
                    _buildDropdownField(
                      label: 'Tipo de Labor',
                      value: _type,
                      items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) => setState(() => _type = val!),
                    ),
                    const SizedBox(height: 15),
                    
                    if (isAdmin)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Asignar a Obrero', style: TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _assignedUserId,
                            hint: const Text('Seleccionar trabajador'),
                            items: workers.map((w) => DropdownMenuItem(value: w.id, child: Text('${w.name} (${w.roleDisplayName})', overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) {
                              setState(() {
                                _assignedUserId = val;
                                _assignedUser = workers.firstWhere((w) => w.id == val);
                                _responsible = _assignedUser!.name;
                              });
                            },
                            validator: (val) => val == null ? 'Selecciona un responsable' : null,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.background.withOpacity(0.5),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                          ),
                        ],
                      )
                    else
                      _buildTextField(
                        label: 'Responsable',
                        hint: 'Nombre del encargado u obrero',
                        initialValue: _responsible,
                        readOnly: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _buildFormCard(
                  children: [
                    _buildDatePicker(),
                    const SizedBox(height: 15),
                    _buildTextField(
                      label: 'Detalles / Observaciones',
                      hint: 'Ej: Se usaron 3 pipas de veneno...',
                      maxLines: 3,
                      onChanged: (val) => _details = val,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              FadeIn(
                delay: const Duration(milliseconds: 400),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(_isTaskAssignment ? 'ASIGNAR TAREA' : 'GUARDAR LABOR', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildFormCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    String? initialValue,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: readOnly ? Colors.grey.shade200 : AppColors.background.withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required dynamic value,
    required List<DropdownMenuItem<dynamic>> items,
    required Function(dynamic) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<dynamic>(
          value: value,
          items: items,
          onChanged: onChanged,
          validator: (val) => val == null ? 'Campo requerido' : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background.withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_isTaskAssignment ? 'Fecha Programada' : 'Fecha de Realización', style: const TextStyle(fontSize: 13, color: AppColors.textGrey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)), // allow future dates for tasks
            );
            if (date != null) setState(() => _date = date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('dd/MM/yy').format(_date), style: const TextStyle(fontSize: 14)),
                const Icon(Icons.calendar_today, size: 16, color: AppColors.primaryGreen),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final landService = Provider.of<LandService>(context, listen: false);
      
      final newWork = FieldWork(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        potreroId: _selectedPotreroId!,
        type: _type,
        date: _date,
        cost: 0.0,
        responsible: _responsible,
        details: _details,
        status: _isTaskAssignment ? 'Pendiente' : 'Completada',
        assignedToUserId: _assignedUserId,
      );

      await landService.addFieldWork(newWork);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isTaskAssignment ? 'Tarea asignada exitosamente' : 'Labor registrada exitosamente'), backgroundColor: AppColors.primaryGreen),
        );
        Navigator.pop(context);
      }
    }
  }
}
