import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/finance_service.dart';
import '../services/inventory_service.dart';
import '../services/worker_service.dart';

class BalanceSheetScreen extends StatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  State<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends State<BalanceSheetScreen> {
  final _accountsReceivableController = TextEditingController(text: '0.00');
  final _accountsPayableController = TextEditingController(text: '0.00');

  @override
  void dispose() {
    _accountsReceivableController.dispose();
    _accountsPayableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final financeService = Provider.of<FinanceService>(context);
    final inventoryService = Provider.of<InventoryService>(context, listen: false);
    final workerService = Provider.of<WorkerService>(context, listen: false);

    final double accountsReceivable = double.tryParse(_accountsReceivableController.text.trim()) ?? 0;
    final double accountsPayable = double.tryParse(_accountsPayableController.text.trim()) ?? 0;

    final double availableCash = financeService.balance;
    final double inventoryValuation = financeService.getInventoryTotalValue(inventoryService);
    final double totalAssets = financeService.getTotalAssets(inventoryService, accountsReceivable: accountsReceivable);

    final double workerPassives = financeService.getWorkerTotalPassives(workerService);
    final double totalLiabilities = financeService.getTotalLiabilities(workerService, accountsPayable: accountsPayable);

    final double equity = totalAssets - totalLiabilities;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Balance General de la Finca', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen de Salud Financiera (Patrimonio Neto)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: equity >= 0 ? [AppColors.primaryGreen, AppColors.secondaryGreen] : [Colors.red, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const Text('Patrimonio Neto / Capital de Trabajo', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    '\$${equity.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      equity >= 0 ? 'Estado Financiero Saludable (Activos > Pasivos)' : 'Atención: Pasivos superan a los Activos',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // ESTRUCTURA DE ACTIVOS
            _buildSectionTitle('1. ESTRUCTURA DE ACTIVOS (Bienes & Derechos)', Icons.account_balance_outlined, Colors.blue),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildBalanceRow('Disponible en Caja / Bancos', '\$${availableCash.toStringAsFixed(2)}', Icons.payments_outlined),
                  const Divider(height: 15),
                  _buildBalanceRow('Valoración de Inventario Stock', '\$${inventoryValuation.toStringAsFixed(2)}', Icons.inventory_2_outlined),
                  const Divider(height: 15),
                  Row(
                    children: [
                      const Icon(Icons.assignment_turned_in_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 10),
                      const Text('Cuentas por Cobrar (\$USD)', style: TextStyle(fontSize: 13, color: AppColors.textDark)),
                      const Spacer(),
                      SizedBox(
                        width: 100,
                        height: 35,
                        child: TextField(
                          controller: _accountsReceivableController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          textAlign: TextAlign.end,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildTotalRow('TOTAL ACTIVOS', '\$${totalAssets.toStringAsFixed(2)}', Colors.blue),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // ESTRUCTURA DE PASIVOS
            _buildSectionTitle('2. ESTRUCTURA DE PASIVOS (Deudas & Pasivos Laborales)', Icons.receipt_long_outlined, Colors.red),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildBalanceRow('Pasivos Laborales Acumulados (LOTTT & Parafiscales)', '\$${workerPassives.toStringAsFixed(2)}', Icons.badge_outlined),
                  const Divider(height: 15),
                  Row(
                    children: [
                      const Icon(Icons.request_quote_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 10),
                      const Text('Cuentas por Pagar Proveedores (\$USD)', style: TextStyle(fontSize: 13, color: AppColors.textDark)),
                      const Spacer(),
                      SizedBox(
                        width: 100,
                        height: 35,
                        child: TextField(
                          controller: _accountsPayableController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setState(() {}),
                          textAlign: TextAlign.end,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildTotalRow('TOTAL PASIVOS', '\$${totalLiabilities.toStringAsFixed(2)}', Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ),
      ],
    );
  }

  Widget _buildBalanceRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textDark))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
      ],
    );
  }
}
