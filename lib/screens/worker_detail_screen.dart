import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/worker_models.dart';
import '../services/worker_service.dart';
import 'add_worker_screen.dart';

class WorkerDetailScreen extends StatelessWidget {
  final String workerId;

  const WorkerDetailScreen({super.key, required this.workerId});

  String _getContractTypeLabel(WorkerContractType type) {
    switch (type) {
      case WorkerContractType.fijo:
        return 'Tiempo Indeterminado (Fijo)';
      case WorkerContractType.plazoFijo:
        return 'Tiempo Determinado (Plazo Fijo)';
      case WorkerContractType.porObra:
        return 'Por Obra / Trabajo';
    }
  }

  void _showPaymentDialog(BuildContext context, Worker worker) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'prestaciones';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Registrar Pago / Adelanto a ${worker.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      items: const [
                        DropdownMenuItem(value: 'prestaciones', child: Text('Adelanto / Pago Prestaciones')),
                        DropdownMenuItem(value: 'vacaciones', child: Text('Pago de Vacaciones')),
                        DropdownMenuItem(value: 'utilidades', child: Text('Pago de Utilidades')),
                        DropdownMenuItem(value: 'bono', child: Text('Bono Especial / Horario')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedType = val);
                      },
                      decoration: const InputDecoration(labelText: 'Concepto de Pago'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Monto (\$USD)', prefixText: '\$ '),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Observación / Detalle'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
                ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text.trim()) ?? 0;
                    if (amount <= 0) return;

                    final record = WorkerPaymentRecord(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      workerId: worker.id,
                      type: selectedType,
                      amount: amount,
                      date: DateTime.now(),
                      description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                      responsible: 'Administración',
                    );

                    final service = Provider.of<WorkerService>(context, listen: false);
                    await service.addPaymentRecord(worker.id, record);

                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pago registrado correctamente'), backgroundColor: AppColors.primaryGreen),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                  child: const Text('CONFIRMAR PAGO', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkerService>(
      builder: (context, service, child) {
        final worker = service.getWorkerById(workerId);

        if (worker == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ficha de Trabajador')),
            body: const Center(child: Text('Trabajador no encontrado')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Ficha Técnica del Trabajador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textDark,
            elevation: 0.5,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primaryGreen),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddWorkerScreen(workerToEdit: worker)),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card de Cabecera con Foto/Iniciales
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: AppColors.primaryGreen.withOpacity(0.15),
                        child: Text(
                          worker.name.isNotEmpty ? worker.name[0].toUpperCase() : 'W',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(worker.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            const SizedBox(height: 4),
                            Text('C.I.: ${worker.idNumber}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                worker.jobTitle,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Pestañas / Bloques Informativos
                _buildSectionHeader('Datos Socioeconómicos', Icons.badge_outlined),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: [
                      _buildInfoRow('Género', worker.gender, Icons.person_outline),
                      const Divider(height: 15),
                      _buildInfoRow('Teléfono', worker.phone ?? 'No especificado', Icons.phone_outlined),
                      const Divider(height: 15),
                      _buildInfoRow('Dirección', worker.address ?? 'No especificada', Icons.location_on_outlined),
                      const Divider(height: 15),
                      _buildInfoRow(
                        'Fecha de Nacimiento',
                        worker.birthDate == null ? 'No especificada' : DateFormat('dd/MM/yyyy').format(worker.birthDate!),
                        Icons.cake_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                _buildSectionHeader('Relación Laboral & Contrato', Icons.work_history_outlined),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: [
                      _buildInfoRow('Tipo de Contrato', _getContractTypeLabel(worker.contractType), Icons.assignment_outlined),
                      const Divider(height: 15),
                      _buildInfoRow('Fecha de Ingreso', DateFormat('dd/MM/yyyy').format(worker.contractStartDate), Icons.calendar_month),
                      const Divider(height: 15),
                      _buildInfoRow('Antigüedad Registrada', worker.formattedServiceTime, Icons.history_toggle_off, highlight: true),
                      const Divider(height: 15),
                      _buildInfoRow('Salario Base', '\$${worker.baseSalary.toStringAsFixed(2)} (${worker.paymentFrequency})', Icons.attach_money),
                      const Divider(height: 15),
                      _buildInfoRow('Carga Patronal Estimada', '\$${worker.estimatedMonthlyEmployerCost.toStringAsFixed(2)} / mes', Icons.account_balance_outlined),
                      if (worker.workDescription != null && worker.workDescription!.isNotEmpty) ...[
                        const Divider(height: 15),
                        _buildInfoRow('Obra Contratada', worker.workDescription!, Icons.engineering_outlined),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // Acumulados de Ley
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('Acumulados & Prestaciones', Icons.account_balance_wallet_outlined),
                    ElevatedButton.icon(
                      onPressed: () => _showPaymentDialog(context, worker),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.add_card, size: 16, color: Colors.white),
                      label: const Text('Registrar Pago', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    _buildStatCard(
                      'Prestaciones (LOTTT)',
                      '\$${worker.lotttSeveranceAmount.toStringAsFixed(2)}',
                      Colors.blue,
                      Icons.savings_outlined,
                      subText: '${worker.lotttSeveranceDays} días (Art. 142)',
                    ),
                    _buildStatCard(
                      'Vacaciones + Bono',
                      '\$${worker.lotttVacationsAmount.toStringAsFixed(2)}',
                      Colors.orange,
                      Icons.beach_access_outlined,
                      subText: '${worker.lotttVacationDays + worker.lotttVacationBonusDays} días (Art. 190/192)',
                    ),
                    _buildStatCard(
                      'Utilidades',
                      '\$${worker.lotttProfitsAmount.toStringAsFixed(2)}',
                      Colors.purple,
                      Icons.card_giftcard,
                      subText: 'Art. 131 LOTTT',
                    ),
                    _buildStatCard(
                      'Bonos Pagados',
                      '\$${worker.accumulatedBonuses.toStringAsFixed(2)}',
                      Colors.green,
                      Icons.stars_outlined,
                      subText: 'Bonificaciones',
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                _buildSectionHeader('Histórico de Pagos y Adelantos', Icons.receipt_long_outlined),
                const SizedBox(height: 10),

                if (worker.paymentHistory.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                    child: const Center(child: Text('No hay registros de pagos anteriores', style: TextStyle(color: Colors.grey, fontSize: 13))),
                  )
                else
                  Column(
                    children: worker.paymentHistory.reversed.map((p) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.payment, color: AppColors.primaryGreen, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  if (p.description != null) Text(p.description!, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                  Text(DateFormat('dd/MM/yyyy').format(p.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Text('\$${p.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryGreen)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
            color: highlight ? AppColors.primaryGreen : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon, {String? subText}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
          if (subText != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(subText, style: TextStyle(fontSize: 9, color: Colors.grey[600]), textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }
}
