import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/animal_models.dart';
import '../models/finance_models.dart';
import '../models/inventory_models.dart';
import '../services/animal_service.dart';
import '../services/finance_service.dart';
import '../services/inventory_service.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionType initialType;

  const AddTransactionScreen({super.key, this.initialType = TransactionType.expense});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TransactionType _type;
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _vendorController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();

  // Controllers para Compra de Animal
  final _boughtAnimalCodeController = TextEditingController();
  final _boughtAnimalNameController = TextEditingController();
  final _boughtAnimalWeightController = TextEditingController(text: '250');

  String _category = 'Insumos / Alimentos';
  String _unit = 'Sacos';
  DateTime _date = DateTime.now();
  bool _isLoading = false;
  String? _attachedReceiptName;

  // Integración Animales & Inventario
  String? _selectedSoldAnimalId;
  String? _selectedMilkItemId;
  bool _autoCreateBoughtAnimal = true;
  AnimalType _boughtAnimalType = AnimalType.bovine;
  String _boughtAnimalSex = 'Hembra';
  String _boughtAnimalGroup = 'Mantecadas';

  final List<String> _incomeCategories = [
    'Venta Leche',
    'Venta Queso',
    'Venta Mantequilla/Nata',
    'Venta Ganado / Animales',
    'Servicios Finca',
    'Otros Ingresos',
  ];

  final List<String> _expenseCategories = [
    'Compra de Ganado / Animales',
    'Insumos / Alimentos',
    'Medicinas / Veterinaria',
    'Semillas y Fertilizantes',
    'Herramientas y Repuestos',
    'Mantenimiento / Reparación',
    'Obras y Proyectos',
    'Nómina y Mano de Obra',
    'Combustible y Servicios',
    'Otros Gastos',
  ];

  final List<String> _units = [
    'Sacos',
    'Kg',
    'Litros',
    'Libras',
    'mg',
    'Unidades',
    'Quintal',
    'Cesta',
    'Cabezas',
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _category = _type == TransactionType.income ? _incomeCategories.first : _expenseCategories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    _vendorController.dispose();
    _invoiceNumberController.dispose();
    _notesController.dispose();
    _boughtAnimalCodeController.dispose();
    _boughtAnimalNameController.dispose();
    _boughtAnimalWeightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _simulateAttachReceipt() {
    setState(() {
      _attachedReceiptName = 'Factura_${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Comprobante adjuntado: $_attachedReceiptName'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final double amount = double.tryParse(_amountController.text.trim()) ?? 0;
      final double? quantity = double.tryParse(_quantityController.text.trim());

      final tx = FinanceTransaction(
        id: '',
        title: _titleController.text.trim(),
        category: _category,
        amount: amount,
        type: _type,
        date: _date,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        quantity: quantity,
        unit: quantity != null ? _unit : null,
        vendor: _vendorController.text.trim().isEmpty ? null : _vendorController.text.trim(),
        invoiceNumber: _invoiceNumberController.text.trim().isEmpty ? null : _invoiceNumberController.text.trim(),
        receiptUrl: _attachedReceiptName,
      );

      final financeService = Provider.of<FinanceService>(context, listen: false);
      final animalService = Provider.of<AnimalService>(context, listen: false);
      final inventoryService = Provider.of<InventoryService>(context, listen: false);

      // 1. Guardar Transacción Financiera
      await financeService.addTransaction(tx);

      // 2. INTEGRACIÓN: VENTA DE LECHE -> Descontar stock de inventario
      if (_type == TransactionType.income && _category == 'Venta Leche' && quantity != null && quantity > 0) {
        String? targetItemId = _selectedMilkItemId;
        if (targetItemId == null) {
          final milkItems = inventoryService.items.where((i) => i.name.toLowerCase().contains('leche')).toList();
          if (milkItems.isNotEmpty) {
            targetItemId = milkItems.first.id;
          }
        }
        if (targetItemId != null) {
          await inventoryService.addTransaction(InventoryTransaction(
            id: '',
            itemId: targetItemId,
            quantity: quantity,
            type: 'Salida',
            date: _date,
            responsible: 'Administración (Venta)',
            notes: 'Descuento automático por Venta de Leche (\$${amount.toStringAsFixed(2)})',
          ));
        }
      }

      // 3. INTEGRACIÓN: VENTA DE GANADO -> Marcar animal como Vendido
      if (_type == TransactionType.income && _category == 'Venta Ganado / Animales' && _selectedSoldAnimalId != null) {
        await animalService.markAnimalAsSold(_selectedSoldAnimalId!);
      }

      // 4. INTEGRACIÓN: COMPRA DE GANADO -> Crear animal en el rebaño activo
      if (_type == TransactionType.expense && _category == 'Compra de Ganado / Animales' && _autoCreateBoughtAnimal) {
        final code = _boughtAnimalCodeController.text.trim().isEmpty
            ? 'COMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'
            : _boughtAnimalCodeController.text.trim();
        final name = _boughtAnimalNameController.text.trim().isEmpty ? null : _boughtAnimalNameController.text.trim();
        final weight = double.tryParse(_boughtAnimalWeightController.text.trim()) ?? 250.0;

        final boughtAnimal = Animal(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          code: code,
          name: name,
          type: _boughtAnimalType,
          breed: 'Mestizo',
          sex: _boughtAnimalSex,
          birthDate: DateTime.now().subtract(const Duration(days: 730)), // ~2 años estimado
          entryDate: _date,
          origin: AnimalOrigin.comprado,
          currentWeight: weight,
          currentLocation: 'Potrero Principal',
          group: _boughtAnimalGroup,
          status: 'active',
        );

        await animalService.addAnimal(boughtAnimal);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_type == TransactionType.income ? 'Ingreso registrado correctamente' : 'Compra/Egreso registrado correctamente'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == TransactionType.income ? _incomeCategories : _expenseCategories;
    final animalService = Provider.of<AnimalService>(context);
    final inventoryService = Provider.of<InventoryService>(context);

    final activeAnimals = animalService.animals;
    final milkItems = inventoryService.items.where((i) => i.name.toLowerCase().contains('leche')).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _type == TransactionType.income ? 'Registrar Ingreso / Venta' : 'Registrar Compra / Egreso',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector Tipo (Ingreso vs Egreso)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _type = TransactionType.income;
                          _category = _incomeCategories.first;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == TransactionType.income ? Colors.green : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_upward, color: _type == TransactionType.income ? Colors.white : Colors.green, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'INGRESO / VENTA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _type == TransactionType.income ? Colors.white : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _type = TransactionType.expense;
                          _category = _expenseCategories.first;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _type == TransactionType.expense ? Colors.red : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_downward, color: _type == TransactionType.expense ? Colors.white : Colors.red, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'COMPRA / EGRESO',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _type == TransactionType.expense ? Colors.white : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration(
                  label: _type == TransactionType.income ? 'Concepto de Venta / Ingreso *' : 'Descripción de Compra / Gasto *',
                  hint: _type == TransactionType.income ? 'Ej. Venta 100L Leche Líquida' : 'Ej. Compra 2 Mautes Carora',
                  icon: Icons.description_outlined,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 15),

              // CATEGORÍA FULL WIDTH
              DropdownButtonFormField<String>(
                initialValue: categories.contains(_category) ? _category : categories.first,
                isExpanded: true,
                items: categories.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
                decoration: _inputDecoration(
                  label: 'Categoría de Operación *',
                  hint: 'Seleccione la categoría',
                  icon: Icons.category_outlined,
                ),
              ),
              const SizedBox(height: 15),

              // Monto Total ($USD) + Cantidad + Unidad
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(label: 'Monto Total (\$USD) *', hint: '0.00', icon: Icons.attach_money),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Requerido';
                        if (double.tryParse(val.trim()) == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(label: 'Cantidad', hint: '10', icon: Icons.straighten_outlined),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      isExpanded: true,
                      items: _units.map((u) => DropdownMenuItem(
                        value: u,
                        child: Text(u, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _unit = val);
                      },
                      decoration: _inputDecoration(label: 'Unidad', hint: '', icon: Icons.square_foot_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // -------------------------------------------------------------
              // SECCIÓN DE INTEGRACIÓN ESPECÍFICA SEGÚN CATEGORÍA
              // -------------------------------------------------------------

              // A. VENTA DE LECHE -> Seleccionar item de inventario de leche
              if (_type == TransactionType.income && _category == 'Venta Leche') ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.water_drop_outlined, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text('Descuento Automático de Inventario (Leche)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Al guardar la venta, se descontará la cantidad de litros ingresada del inventario.', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                      if (milkItems.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedMilkItemId ?? milkItems.first.id,
                          isExpanded: true,
                          items: milkItems.map((item) {
                            return DropdownMenuItem(
                              value: item.id,
                              child: Text('${item.name} (Stock: ${item.stock} ${item.unit})', style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedMilkItemId = val),
                          decoration: _inputDecoration(label: 'Ítem de Inventario Leche', hint: '', icon: Icons.inventory),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 15),
              ],

              // B. VENTA DE GANADO -> Seleccionar Animal a marcar como Vendido
              if (_type == TransactionType.income && _category == 'Venta Ganado / Animales') ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.pets, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Text('Seleccionar Animal Vendido del Rebaño', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('El animal seleccionado cambiará su estatus a "Vendido" y saldrá del rebaño activo.', style: TextStyle(fontSize: 11, color: Colors.grey[800])),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSoldAnimalId,
                        isExpanded: true,
                        items: activeAnimals.map((a) {
                          return DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.code} ${a.name != null ? "- ${a.name}" : ""} (${a.group})', style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedSoldAnimalId = val),
                        decoration: _inputDecoration(label: 'Animal Vendido *', hint: 'Seleccione un animal', icon: Icons.badge_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
              ],

              // C. COMPRA DE GANADO -> Formulario de Registro de Nuevo Animal Comprado
              if (_type == TransactionType.expense && _category == 'Compra de Ganado / Animales') ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.add_shopping_cart, color: AppColors.primaryGreen, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Registrar Animal Comprado en el Rebaño', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                          ),
                          Switch(
                            value: _autoCreateBoughtAnimal,
                            activeColor: AppColors.primaryGreen,
                            onChanged: (val) => setState(() => _autoCreateBoughtAnimal = val),
                          ),
                        ],
                      ),
                      if (_autoCreateBoughtAnimal) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _boughtAnimalCodeController,
                                decoration: _inputDecoration(label: 'Cód / Arete *', hint: 'Ej. BOV-050', icon: Icons.subtitles_outlined),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _boughtAnimalNameController,
                                decoration: _inputDecoration(label: 'Nombre (Opcional)', hint: 'Ej. Carora 50', icon: Icons.badge_outlined),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _boughtAnimalSex,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'Hembra', child: Text('Hembra', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Macho', child: Text('Macho', style: TextStyle(fontSize: 12))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _boughtAnimalSex = val);
                                },
                                decoration: _inputDecoration(label: 'Sexo', hint: '', icon: Icons.wc),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _boughtAnimalWeightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: _inputDecoration(label: 'Peso (kg)', hint: '250', icon: Icons.monitor_weight_outlined),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 15),
              ],

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _vendorController,
                      decoration: _inputDecoration(
                        label: _type == TransactionType.expense ? 'Proveedor / Vendedor' : 'Cliente / Comprador',
                        hint: 'Nombre comercial',
                        icon: Icons.store_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _invoiceNumberController,
                      decoration: _inputDecoration(label: 'N° Factura / Control', hint: 'F-00123', icon: Icons.receipt_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Fecha
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppColors.primaryGreen, size: 20),
                      const SizedBox(width: 10),
                      const Text('Fecha de Operación:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const Spacer(),
                      Text(DateFormat('dd/MM/yyyy').format(_date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Adjunto de Factura / Comprobante
              const Text('Soporte de Comprobante / Factura', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      _attachedReceiptName != null ? Icons.check_circle : Icons.camera_alt_outlined,
                      color: _attachedReceiptName != null ? AppColors.primaryGreen : Colors.grey,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _attachedReceiptName ?? 'No se ha adjuntado factura o foto del comprobante',
                        style: TextStyle(fontSize: 11, color: _attachedReceiptName != null ? AppColors.primaryGreen : Colors.grey[600]),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _simulateAttachReceipt,
                      icon: const Icon(Icons.upload_file, size: 16, color: AppColors.primaryGreen),
                      label: Text(_attachedReceiptName != null ? 'Cambiar' : 'Adjuntar', style: const TextStyle(fontSize: 11, color: AppColors.primaryGreen)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type == TransactionType.income ? Colors.green : AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              _type == TransactionType.income ? 'REGISTRAR INGRESO' : 'REGISTRAR COMPRA / GASTO',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required String hint, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
      prefixIcon: Icon(icon, color: Colors.grey[600], size: 18),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2)),
    );
  }
}
