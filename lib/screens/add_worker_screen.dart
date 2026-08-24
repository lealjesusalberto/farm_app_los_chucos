import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/worker_models.dart';
import '../services/worker_service.dart';

class AddWorkerScreen extends StatefulWidget {
  final Worker? workerToEdit;

  const AddWorkerScreen({super.key, this.workerToEdit});

  @override
  State<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends State<AddWorkerScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _salaryController = TextEditingController(text: '100');
  final _workDescriptionController = TextEditingController();

  // Acumulados
  final _severanceController = TextEditingController(text: '0');
  final _vacationsAmountController = TextEditingController(text: '0');
  final _vacationsDaysController = TextEditingController(text: '0');
  final _profitsController = TextEditingController(text: '0');
  final _bonusesController = TextEditingController(text: '0');

  String _selectedGender = 'Hombre';
  String _paymentFrequency = 'Mensual';
  WorkerContractType _contractType = WorkerContractType.fijo;

  DateTime? _birthDate;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isLoading = false;

  // Resumen de cálculos automáticos (solo para mostrar en panel)
  int _calcSeveranceDays = 0;
  double _calcSeveranceAmount = 0;
  int _calcVacationWorkDays = 0;    // Días hábiles de vacaciones (Art. 190)
  int _calcVacationBonusDays = 0;   // Días de bono vacacional (Art. 192)
  int _calcVacationDays = 0;        // Total combinado
  double _calcVacationWorkAmount = 0;
  double _calcVacationBonusAmount = 0;
  double _calcVacationAmount = 0;   // Total combinado
  double _calcProfitsAmount = 0;
  bool _hasAutoCalc = false;

  @override
  void initState() {
    super.initState();
    if (widget.workerToEdit != null) {
      final w = widget.workerToEdit!;
      _nameController.text = w.name;
      _idNumberController.text = w.idNumber;
      _phoneController.text = w.phone ?? '';
      _addressController.text = w.address ?? '';
      _jobTitleController.text = w.jobTitle;
      _salaryController.text = w.baseSalary.toString();
      _workDescriptionController.text = w.workDescription ?? '';

      _severanceController.text = w.accumulatedSeverance.toString();
      _vacationsAmountController.text = w.accumulatedVacationsAmount.toString();
      _vacationsDaysController.text = w.accumulatedVacationsDays.toString();
      _profitsController.text = w.accumulatedProfits.toString();
      _bonusesController.text = w.accumulatedBonuses.toString();

      _selectedGender = w.gender;
      _paymentFrequency = w.paymentFrequency;
      _contractType = w.contractType;
      _birthDate = w.birthDate;
      _startDate = w.contractStartDate;
      _endDate = w.contractEndDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idNumberController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _jobTitleController.dispose();
    _salaryController.dispose();
    _workDescriptionController.dispose();
    _severanceController.dispose();
    _vacationsAmountController.dispose();
    _vacationsDaysController.dispose();
    _profitsController.dispose();
    _bonusesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, {required bool isBirth, required bool isStart}) async {
    final initial = isBirth
        ? (_birthDate ?? DateTime(1990))
        : (isStart ? _startDate : (_endDate ?? DateTime.now()));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime(2050),
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
      setState(() {
        if (isBirth) {
          _birthDate = picked;
        } else if (isStart) {
          _startDate = picked;
          _autoCalculateBenefits(); // auto-calcular al cambiar fecha de ingreso
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Auto-cálculo de Prestaciones Sociales LOTTT a partir de
  // fecha de ingreso y salario base
  // ─────────────────────────────────────────────────────────────────
  void _autoCalculateBenefits() {
    final salary = double.tryParse(_salaryController.text.trim()) ?? 0;
    if (salary <= 0) return;

    final now = DateTime.now();
    final difference = now.difference(_startDate).inDays;
    final years = (difference / 365.25).clamp(0.0, 100.0);
    final yearsInt = years.floor();



    // Días de Prestaciones (Art. 142 LOTTT)
    int severanceDays;
    if (yearsInt < 1) {
      final months = (difference / 30.43);
      final quarters = (months / 3).floor();
      severanceDays = quarters * 15;
    } else {
      int base = yearsInt * 60;
      int extra = (yearsInt > 1) ? ((yearsInt - 1) * 2).clamp(0, 30) : 0;
      severanceDays = base + extra;
    }

    // Monto Prestaciones
    final dailyIntegral = (salary / 30.0) * 1.25;
    final severanceAmount = severanceDays * dailyIntegral;

    // ─────────────────────────────────────────────────────────
    // VACACIONES (Art. 190 LOTTT)
    // Al cumplir 1 año: 15 días hábiles remunerados
    // Por cada año adicional: +1 día (máximo 15 días extra = 30 días tope)
    // ─────────────────────────────────────────────────────────
    int vacWorkDays = 0;   // Días hábiles de vacaciones
    int vacBonusDays = 0;  // Días de bono vacacional (Art. 192)
    if (yearsInt >= 1) {
      // extra va de 0 (año 1) a 15 (año 16+)
      final extra = (yearsInt - 1).clamp(0, 15);
      vacWorkDays  = 15 + extra; // Art. 190: 15 días hábiles + 1/año, tope 30
      vacBonusDays = 15 + extra; // Art. 192: 15 días sueldo  + 1/año, tope 30
    }
    final dailySalary = salary / 30.0;
    final vacWorkAmount  = vacWorkDays  * dailySalary;
    final vacBonusAmount = vacBonusDays * dailySalary;
    final totalVacDays   = vacWorkDays + vacBonusDays;
    final vacAmount      = vacWorkAmount + vacBonusAmount;

    // Utilidades (Art. 131: mínimo 30 días/año, prorrateado mensualmente)
    final monthsWorked = (difference / 30.43).clamp(0.0, 12.0);
    final profitsAmount = (monthsWorked * 2.5) * dailySalary;

    setState(() {
      _calcSeveranceDays      = severanceDays;
      _calcSeveranceAmount    = severanceAmount;
      _calcVacationWorkDays   = vacWorkDays;
      _calcVacationBonusDays  = vacBonusDays;
      _calcVacationDays       = totalVacDays;
      _calcVacationWorkAmount = vacWorkAmount;
      _calcVacationBonusAmount= vacBonusAmount;
      _calcVacationAmount     = vacAmount;
      _calcProfitsAmount      = profitsAmount;
      _hasAutoCalc = true;

      // Llenar campos automáticamente (usuario puede sobrescribir)
      if (double.tryParse(_severanceController.text) == 0 ||
          _severanceController.text == '0') {
        _severanceController.text = severanceAmount.toStringAsFixed(2);
      }
      if (double.tryParse(_vacationsAmountController.text) == 0 ||
          _vacationsAmountController.text == '0') {
        _vacationsAmountController.text = vacAmount.toStringAsFixed(2);
        _vacationsDaysController.text = vacWorkDays.toString();
      }
      if (double.tryParse(_profitsController.text) == 0 ||
          _profitsController.text == '0') {
        _profitsController.text = profitsAmount.toStringAsFixed(2);
      }
    });
  }

  Future<void> _saveWorker() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final double salary = double.tryParse(_salaryController.text.trim()) ?? 0;
      final double severance = double.tryParse(_severanceController.text.trim()) ?? 0;
      final double vacAmount = double.tryParse(_vacationsAmountController.text.trim()) ?? 0;
      final int vacDays = int.tryParse(_vacationsDaysController.text.trim()) ?? 0;
      final double profits = double.tryParse(_profitsController.text.trim()) ?? 0;
      final double bonuses = double.tryParse(_bonusesController.text.trim()) ?? 0;

      final worker = Worker(
        id: widget.workerToEdit?.id ?? '',
        name: _nameController.text.trim(),
        idNumber: _idNumberController.text.trim(),
        birthDate: _birthDate,
        gender: _selectedGender,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        baseSalary: salary,
        paymentFrequency: _paymentFrequency,
        contractType: _contractType,
        contractStartDate: _startDate,
        contractEndDate: _contractType == WorkerContractType.plazoFijo ? _endDate : null,
        workDescription: _contractType == WorkerContractType.porObra ? _workDescriptionController.text.trim() : null,
        accumulatedSeverance: severance,
        accumulatedVacationsAmount: vacAmount,
        accumulatedVacationsDays: vacDays,
        accumulatedProfits: profits,
        accumulatedBonuses: bonuses,
        status: widget.workerToEdit?.status ?? 'active',
      );

      final service = Provider.of<WorkerService>(context, listen: false);

      if (widget.workerToEdit != null) {
        await service.updateWorker(widget.workerToEdit!.id, worker.toMap());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ficha del trabajador actualizada'), backgroundColor: AppColors.primaryGreen),
          );
        }
      } else {
        await service.addWorker(worker);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Trabajador "${worker.name}" registrado correctamente'), backgroundColor: AppColors.primaryGreen),
          );
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.workerToEdit == null ? 'Nuevo Trabajador' : 'Editar Ficha Técnica',
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
              _buildSectionHeader('1. Identificación & Datos Socioeconómicos', Icons.person_outline),
              const SizedBox(height: 15),

              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(label: 'Nombre y Apellido Completo *', hint: 'Ej. Juan Pérez', icon: Icons.badge_outlined),
                validator: (val) => val == null || val.trim().isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _idNumberController,
                      decoration: _inputDecoration(label: 'Cédula (C.I.) *', hint: 'V-12345678', icon: Icons.subtitles_outlined),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Hombre', child: Text('Hombre', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'Mujer', child: Text('Mujer', style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedGender = val);
                      },
                      decoration: _inputDecoration(label: 'Género', hint: '', icon: Icons.wc_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(label: 'Teléfono de Contacto', hint: '0414-1234567', icon: Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fecha de Nacimiento', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _birthDate == null ? 'Sin fecha' : DateFormat('dd/MM/yyyy').format(_birthDate!),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _birthDate == null ? Colors.grey : AppColors.textDark),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.calendar_month, color: AppColors.primaryGreen, size: 20),
                                onPressed: () => _selectDate(context, isBirth: true, isStart: false),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration(label: 'Dirección de Habitación / Residencia', hint: 'Comunidad, Finca, Caserío', icon: Icons.location_on_outlined),
              ),
              const SizedBox(height: 25),

              _buildSectionHeader('2. Datos Laborales & Contrato', Icons.work_outline),
              const SizedBox(height: 15),

              TextFormField(
                controller: _jobTitleController,
                decoration: _inputDecoration(label: 'Cargo / Descripción del Puesto *', hint: 'Ej. Capataz, Ordeñador, Vaquero', icon: Icons.work_history_outlined),
                validator: (val) => val == null || val.trim().isEmpty ? 'El cargo es obligatorio' : null,
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _salaryController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(label: 'Salario Base (\$USD) *', hint: '100.00', icon: Icons.attach_money),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Requerido';
                        if (double.tryParse(val.trim()) == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _paymentFrequency,
                      items: ['Mensual', 'Quincenal', 'Semanal'].map((f) {
                        return DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 14)));
                      }).toList(),
                      onChanged: (val) => setState(() => _paymentFrequency = val!),
                      decoration: _inputDecoration(label: 'Frecuencia de Pago', hint: '', icon: Icons.schedule),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Tipo de Contrato
              const Text('Tipo de Contrato *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<WorkerContractType>(
                    value: _contractType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: WorkerContractType.fijo, child: Text('Tiempo Indeterminado (Fijo)')),
                      DropdownMenuItem(value: WorkerContractType.plazoFijo, child: Text('Tiempo Determinado (Plazo Fijo)')),
                      DropdownMenuItem(value: WorkerContractType.porObra, child: Text('Por Obra / Trabajo Específico')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _contractType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Fechas de Contrato
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fecha de Ingreso *', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(_startDate),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.event, color: AppColors.primaryGreen, size: 20),
                                onPressed: () => _selectDate(context, isBirth: false, isStart: true),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_contractType == WorkerContractType.plazoFijo) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Fecha Fin de Contrato', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _endDate == null ? 'Sin fecha' : DateFormat('dd/MM/yyyy').format(_endDate!),
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _endDate == null ? Colors.grey : AppColors.textDark),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.event_busy, color: Colors.orange, size: 20),
                                  onPressed: () => _selectDate(context, isBirth: false, isStart: false),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // ── Panel de cálculo automático de Prestaciones ──────────────
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calculate_outlined, color: AppColors.primaryGreen, size: 18),
                            const SizedBox(width: 8),
                            const Text('Cálculo Automático LOTTT',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _autoCalculateBenefits,
                          icon: const Icon(Icons.refresh, size: 14, color: AppColors.primaryGreen),
                          label: const Text('Recalcular', style: TextStyle(fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Basado en: Fecha ingreso ${DateFormat('dd/MM/yyyy').format(_startDate)} • Salario \$${_salaryController.text}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    if (_hasAutoCalc) ...[
                      const SizedBox(height: 10),
                      const Divider(height: 8),
                      const SizedBox(height: 6),
                      _buildCalcRow('Prestaciones Sociales (Art. 142)', '$_calcSeveranceDays días × salario integral', '\$${_calcSeveranceAmount.toStringAsFixed(2)}', Colors.blue),
                      const SizedBox(height: 6),
                      _buildCalcRow(
                        'Vacaciones (Art. 190)',
                        '$_calcVacationWorkDays días hábiles remunerados',
                        '\$${_calcVacationWorkAmount.toStringAsFixed(2)}',
                        Colors.orange,
                      ),
                      const SizedBox(height: 6),
                      _buildCalcRow(
                        'Bono Vacacional (Art. 192)',
                        '$_calcVacationBonusDays días de salario normal',
                        '\$${_calcVacationBonusAmount.toStringAsFixed(2)}',
                        Colors.deepOrange,
                      ),
                      const SizedBox(height: 6),
                      _buildCalcRow('Utilidades (Art. 131)', 'Prorrateado mensual (30 días/año)', '\$${_calcProfitsAmount.toStringAsFixed(2)}', Colors.purple),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: Colors.amber),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Los campos de acumulados se llenaron automáticamente. Puedes editarlos manualmente si el trabajador ya recibió anticipos.',
                                style: TextStyle(fontSize: 10, color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        'Ingresa el salario base y presiona Recalcular (o selecciona una fecha de ingreso pasada) para calcular automáticamente.',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),

              if (_contractType == WorkerContractType.porObra) ...[
                const SizedBox(height: 15),
                TextFormField(
                  controller: _workDescriptionController,
                  decoration: _inputDecoration(label: 'Descripción de la Obra Contratada', hint: 'Ej. Construcción de 200m de cercado eléctrico', icon: Icons.engineering_outlined),
                ),
              ],
              const SizedBox(height: 25),

              _buildSectionHeader('3. Acumulados Iniciales & Prestaciones', Icons.account_balance_wallet_outlined),
              const SizedBox(height: 8),
              Text('Si el trabajador ya posee tiempo en el fundo, ingresa sus acumulados a la fecha:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _severanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(label: 'Prestaciones Acumuladas (\$USD)', hint: '0.00', icon: Icons.savings_outlined),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _profitsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(label: 'Utilidades Acumuladas (\$USD)', hint: '0.00', icon: Icons.card_giftcard),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _vacationsAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(label: 'Monto Vacaciones (\$USD)', hint: '0.00', icon: Icons.beach_access_outlined),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _vacationsDaysController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(label: 'Días Vacaciones Acum.', hint: '0', icon: Icons.today_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _bonusesController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(label: 'Bonos Especiales / Horarios Acumulados (\$USD)', hint: '0.00', icon: Icons.stars_outlined),
              ),
              const SizedBox(height: 30),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveWorker,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'GUARDAR TRABAJADOR',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
        ),
      ],
    );
  }

  Widget _buildCalcRow(String label, String days, String amount, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 30, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              Text(days, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            ],
          ),
        ),
        Text(amount, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
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
