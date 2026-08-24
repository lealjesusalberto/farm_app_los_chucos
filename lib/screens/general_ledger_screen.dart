import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/finance_models.dart';
import '../services/finance_service.dart';
import 'add_transaction_screen.dart';
import 'finance_documentation_screen.dart';

class GeneralLedgerScreen extends StatefulWidget {
  const GeneralLedgerScreen({super.key});

  @override
  State<GeneralLedgerScreen> createState() => _GeneralLedgerScreenState();
}

class _GeneralLedgerScreenState extends State<GeneralLedgerScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Todos';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showReceiptDialog(BuildContext context, FinanceTransaction tx) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Soporte de Comprobante / Factura', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.primaryGreen),
                    const SizedBox(height: 10),
                    Text(
                      tx.receiptUrl ?? 'Comprobante digital registrado',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    if (tx.invoiceNumber != null)
                      Text('N° Factura: ${tx.invoiceNumber}', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monto Operación:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  Text('\$${tx.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryGreen)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CERRAR')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Libro Diario & Libro Mayor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          ],
          bottom: const TabBar(
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryGreen,
            tabs: [
              Tab(icon: Icon(Icons.book_outlined), text: 'Libro Diario'),
              Tab(icon: Icon(Icons.account_balance_outlined), text: 'Libro Mayor'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
            );
          },
          backgroundColor: AppColors.primaryGreen,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nueva Operación', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Consumer<FinanceService>(
          builder: (context, financeService, child) {
            return TabBarView(
              children: [
                // Tab 1: Libro Diario
                _buildJournalTab(context, financeService),

                // Tab 2: Libro Mayor
                _buildLedgerTab(context, financeService),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildJournalTab(BuildContext context, FinanceService service) {
    final transactions = service.transactions.where((FinanceTransaction t) {
      final query = _searchQuery.toLowerCase();
      final matchesQuery = t.title.toLowerCase().contains(query) ||
          t.category.toLowerCase().contains(query) ||
          (t.vendor != null && t.vendor!.toLowerCase().contains(query)) ||
          (t.invoiceNumber != null && t.invoiceNumber!.toLowerCase().contains(query));

      if (_selectedFilter == 'Ingresos') return matchesQuery && t.type == TransactionType.income;
      if (_selectedFilter == 'Egresos') return matchesQuery && t.type == TransactionType.expense;
      return matchesQuery;
    }).toList();

    return Column(
      children: [
        // Filtros y Buscador
        Container(
          padding: const EdgeInsets.all(15),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Buscar transacción, proveedor o factura...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: ['Todos', 'Ingresos', 'Egresos'].map((filter) {
                  final isSel = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter, style: const TextStyle(fontSize: 12)),
                      selected: isSel,
                      selectedColor: AppColors.primaryGreen.withOpacity(0.2),
                      labelStyle: TextStyle(color: isSel ? AppColors.primaryGreen : Colors.black87, fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                      onSelected: (sel) {
                        if (sel) setState(() => _selectedFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        Expanded(
          child: transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty ? 'No hay operaciones registradas en el Libro Diario' : 'No se encontraron operaciones',
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(15, 15, 15, 80),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return FadeInUp(
                      delay: Duration(milliseconds: index * 30),
                      child: _buildJournalCard(context, service, tx),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildJournalCard(BuildContext context, FinanceService service, FinanceTransaction tx) {
    final isIncome = tx.type == TransactionType.income;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
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
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(tx.category, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                    if (tx.quantity != null && tx.unit != null) ...[
                      Text(' • ${tx.quantity} ${tx.unit}', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                    ],
                  ],
                ),
                if (tx.vendor != null || tx.invoiceNumber != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${tx.vendor != null ? tx.vendor! : ''} ${tx.invoiceNumber != null ? "(Fact. #${tx.invoiceNumber})" : ''}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 2),
                Text(DateFormat('dd/MM/yyyy • hh:mm a').format(tx.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isIncome ? Colors.green : Colors.red),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (tx.receiptUrl != null)
                    IconButton(
                      icon: const Icon(Icons.receipt_outlined, color: AppColors.primaryGreen, size: 20),
                      onPressed: () => _showReceiptDialog(context, tx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
                    onPressed: () async {
                      await service.deleteTransaction(tx.id);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerTab(BuildContext context, FinanceService service) {
    final Map<String, Map<String, double>> summary = service.getLedgerCategorySummary();

    if (summary.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No hay datos acumulados en el Libro Mayor', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: summary.length,
      itemBuilder: (context, index) {
        final category = summary.keys.elementAt(index);
        final data = summary[category]!;
        final double ingresos = data['ingresos'] ?? 0;
        final double egresos = data['egresos'] ?? 0;
        final double neto = data['neto'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder_open_outlined, color: AppColors.primaryGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                  const Spacer(),
                  Text(
                    '\$${neto.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: neto >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Créditos (Ingresos)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('\$${ingresos.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Débitos (Egresos)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text('\$${egresos.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
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
