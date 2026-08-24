import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/finance_models.dart';
import '../services/finance_service.dart';
import 'add_transaction_screen.dart';
import 'general_ledger_screen.dart';
import 'balance_sheet_screen.dart';
import 'workers_module_screen.dart';
import 'finance_documentation_screen.dart';

class FinanceHubScreen extends StatelessWidget {
  const FinanceHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Administración & Finanzas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppColors.primaryGreen),
            tooltip: 'Guía y Funcionamiento Financiero',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FinanceDocumentationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_outlined, color: AppColors.primaryGreen),
            tooltip: 'Balance General',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BalanceSheetScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<FinanceService>(
        builder: (context, financeService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInDown(child: _buildBalanceCard(context, financeService)),
                const SizedBox(height: 25),

                const Text('Módulos Contables & Gestión', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 15),
                _buildActionGrid(context),
                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Libro Diario (Movimientos)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GeneralLedgerScreen()),
                        );
                      },
                      child: const Text('Ver Libro Diario', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTransactionsList(context, financeService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, FinanceService service) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Column(
        children: [
          const Text('Saldo Disponible en Caja / Bancos', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            '\$${service.balance.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSimpleStat('Ingresos Acumulados', service.totalIncome, Colors.green),
              Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.2)),
              _buildSimpleStat('Egresos / Compras', service.totalExpenses, Colors.red),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BalanceSheetScreen()),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance, size: 16, color: AppColors.primaryGreen),
                SizedBox(width: 6),
                Text('Ver Balance General de la Finca (Activos vs Pasivos)', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                Icon(Icons.chevron_right, size: 16, color: AppColors.primaryGreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, double val, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            '\$${val.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildActionItem(
          context,
          'Libro Diario & Mayor',
          Icons.menu_book_outlined,
          AppColors.primaryGreen,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GeneralLedgerScreen()),
            );
          },
        ),
        _buildActionItem(
          context,
          'Balance General',
          Icons.account_balance_outlined,
          Colors.blue,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BalanceSheetScreen()),
            );
          },
        ),
        _buildActionItem(
          context,
          'Registrar Compra / Factura',
          Icons.shopping_cart_outlined,
          Colors.red,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTransactionScreen(initialType: TransactionType.expense)),
            );
          },
        ),
        _buildActionItem(
          context,
          'Nómina & RRHH',
          Icons.badge_outlined,
          Colors.indigo,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkersModuleScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context, FinanceService service) {
    final transactions = service.transactions.take(5).toList();

    if (transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: const Center(child: Text('No hay transacciones recientes', style: TextStyle(color: Colors.grey, fontSize: 13))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final t = transactions[index];
        final isIncome = t.type == TransactionType.income;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isIncome ? Colors.green : Colors.red,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                    Text(
                      '${t.category} ${t.quantity != null && t.unit != null ? "• ${t.quantity} ${t.unit}" : ""}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}\$${t.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isIncome ? Colors.green : Colors.red,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yy').format(t.date),
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
