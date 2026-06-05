import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/animal_models.dart';
import 'package:provider/provider.dart';
import '../services/animal_service.dart';

class AddAnimalScreen extends StatefulWidget {
  const AddAnimalScreen({super.key});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  String _code = '';
  String? _name;
  String? _photoUrl;
  AnimalType _selectedType = AnimalType.bovine;
  AnimalOrigin _selectedOrigin = AnimalOrigin.nacimiento;
  String _breed = '';
  String _sex = 'Hembra';
  DateTime _birthDate = DateTime.now();
  DateTime _entryDate = DateTime.now();
  double _weight = 0.0;
  String _potrero = 'Potrero #1';
  late String _selectedGroup;
  String? _fatherId;
  String? _motherId;

  final List<String> _sexes = ['Hembra', 'Macho'];
  final List<String> _potreros = ['Potrero #1', 'Potrero #2', 'Potrero #3', 'Corral de Engorde'];
  List<String> get _groups => _selectedType.ageGroups;

  @override
  void initState() {
    super.initState();
    _selectedGroup = _selectedType.ageGroups.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registrar Nuevo Animal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(duration: const Duration(milliseconds: 400), child: _buildTypeSelector()),
              const SizedBox(height: 25),
              
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _buildSectionCard(
                  title: 'Información Básica',
                  icon: Icons.info_outline,
                  children: [
                    _buildTextField(label: 'Código / Arete ID', hint: 'Ej: LC-1025', onChanged: (val) => _code = val, validator: (val) => val!.isEmpty ? 'Campo requerido' : null),
                    const SizedBox(height: 15),
                    _buildTextField(label: 'Nombre (Opcional)', hint: 'Ej: Max / Luna', onChanged: (val) => _name = val),
                    const SizedBox(height: 15),
                    _buildTextField(
                      label: 'Foto del Animal (URL) (Opcional)', 
                      hint: 'Ej: https://images.unsplash.com/photo-1543466835-00a7907e9de1', 
                      onChanged: (val) => setState(() => _photoUrl = val)
                    ),
                    if (_photoUrl != null && _photoUrl!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _photoUrl!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 120,
                            color: Colors.grey[200],
                            child: const Center(
                              child: Text(
                                'Error al cargar imagen. Verifique la URL.', 
                                style: TextStyle(color: Colors.red, fontSize: 12)
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 15),
                    _buildTextField(label: 'Raza', hint: 'Ej: Brahman Gris', onChanged: (val) => _breed = val, validator: (val) => val!.isEmpty ? 'Campo requerido' : null),
                    const SizedBox(height: 15),
                    _buildDropdownField(label: 'Sexo', value: _sex, items: _sexes, onChanged: (val) => setState(() => _sex = val!)),
                    const SizedBox(height: 20),
                    const Text('Origen del Animal', style: TextStyle(fontSize: 14, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildOriginOption(AnimalOrigin.nacimiento, 'Nacimiento', Icons.cake),
                        const SizedBox(width: 15),
                        _buildOriginOption(AnimalOrigin.comprado, 'Comprado', Icons.shopping_cart),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _buildDatePicker('F. Nacimiento', _birthDate, (date) => setState(() => _birthDate = date))),
                        const SizedBox(width: 15),
                        Expanded(child: _buildDatePicker('F. Ingreso', _entryDate, (date) => setState(() => _entryDate = date))),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: _buildSectionCard(
                  title: 'Ubicación y Estado',
                  icon: Icons.location_on_outlined,
                  children: [
                    _buildDropdownField(label: 'Ubicación Actual (Potrero)', value: _potrero, items: _potreros, onChanged: (val) => setState(() => _potrero = val!)),
                    const SizedBox(height: 15),
                    _buildDropdownField(label: 'Grupo Etario', value: _selectedGroup, items: _groups, onChanged: (val) => setState(() => _selectedGroup = val!)),
                    const SizedBox(height: 15),
                    _buildTextField(label: 'Peso Inicial (Kg)', hint: '0.0', keyboardType: TextInputType.number, onChanged: (val) => _weight = double.tryParse(val) ?? 0.0),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: _buildSectionCard(
                  title: 'Genealogía (Opcional)',
                  icon: Icons.family_restroom_outlined,
                  children: [
                    _buildTextField(label: 'ID del Padre', hint: 'Código del Toro', onChanged: (val) => _fatherId = val),
                    const SizedBox(height: 15),
                    _buildTextField(label: 'ID de la Madre', hint: 'Código de la Vaca', onChanged: (val) => _motherId = val),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              FadeIn(
                delay: const Duration(milliseconds: 800),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 5),
                    child: const Text('GUARDAR REGISTRO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo de Animal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildTypeItem(AnimalType.bovine, 'assets/types/bovine.png', 'Bovino'),
              _buildTypeItem(AnimalType.buffalo, 'assets/types/buffalo.png', 'Búfalo'),
              _buildTypeItem(AnimalType.equine, 'assets/types/equine.png', 'Equino'),
              _buildTypeItem(AnimalType.porcine, 'assets/types/porcine.png', 'Porcino'),
              _buildTypeItem(AnimalType.poultry, 'assets/types/poultry.png', 'Aves'),
              _buildTypeItem(AnimalType.dog, 'assets/types/dog.png', 'Perro'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeItem(AnimalType type, String imagePath, String label) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedType = type;
        _selectedGroup = type.ageGroups.first;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? AppColors.primaryGreen : Colors.transparent, width: 3), boxShadow: [BoxShadow(color: isSelected ? AppColors.primaryGreen.withOpacity(0.2) : Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))]),
        child: Stack(
          children: [
            Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(17), child: Image.asset(imagePath, fit: BoxFit.cover))),
            Positioned(bottom: 0, left: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17))), child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? AppColors.primaryGreen : AppColors.textDark)))),
            if (isSelected) Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 12))),
          ],
        ),
      ),
    );
  }

  Widget _buildOriginOption(AnimalOrigin origin, String label, IconData icon) {
    final isSelected = _selectedOrigin == origin;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedOrigin = origin),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? AppColors.primaryGreen.withOpacity(0.1) : AppColors.background.withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? AppColors.primaryGreen : Colors.transparent)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 16, color: isSelected ? AppColors.primaryGreen : Colors.grey), const SizedBox(width: 8), Text(label, style: TextStyle(color: isSelected ? AppColors.primaryGreen : AppColors.textGrey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))]),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: AppColors.primaryGreen, size: 20), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark))]), const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider()), ...children]));
  }

  Widget _buildTextField({required String label, required String hint, TextInputType keyboardType = TextInputType.text, Function(String)? onChanged, String? Function(String?)? validator}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textGrey, fontWeight: FontWeight.w500)), const SizedBox(height: 8), TextFormField(keyboardType: keyboardType, onChanged: onChanged, validator: validator, decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14), filled: true, fillColor: AppColors.background.withOpacity(0.5), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5))))]);
  }

  Widget _buildDropdownField({required String label, required String value, required List<String> items, required Function(String?) onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textGrey, fontWeight: FontWeight.w500)), const SizedBox(height: 8), DropdownButtonFormField<String>(value: value, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged, decoration: InputDecoration(filled: true, fillColor: AppColors.background.withOpacity(0.5), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))]);
  }

  Widget _buildDatePicker(String label, DateTime dateValue, Function(DateTime) onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textGrey, fontWeight: FontWeight.w500)), const SizedBox(height: 8), InkWell(onTap: () async { final date = await showDatePicker(context: context, initialDate: dateValue, firstDate: DateTime(2000), lastDate: DateTime.now(), builder: (context, child) { return Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primaryGreen)), child: child!); }); if (date != null) onChanged(date); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: AppColors.background.withOpacity(0.5), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(DateFormat('dd/MM/yy').format(dateValue), style: const TextStyle(fontSize: 12)), const Icon(Icons.calendar_today, size: 14, color: AppColors.primaryGreen)])))]);
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
      try {
        final animalService = Provider.of<AnimalService>(context, listen: false);
        final newAnimal = Animal(
          id: DateTime.now().millisecondsSinceEpoch.toString(), 
          code: _code, 
          name: _name,
          photoUrl: _photoUrl,
          type: _selectedType, 
          origin: _selectedOrigin, 
          breed: _breed, 
          sex: _sex, 
          birthDate: _birthDate, 
          entryDate: _entryDate, 
          currentWeight: _weight, 
          currentLocation: _potrero, 
          group: _selectedGroup, 
          fatherId: _fatherId, 
          motherId: _motherId,
        );
        await animalService.addAnimal(newAnimal);
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro guardado exitosamente'), backgroundColor: AppColors.primaryGreen));
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
