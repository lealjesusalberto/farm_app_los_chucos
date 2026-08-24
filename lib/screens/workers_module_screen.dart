import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/worker_models.dart';
import '../services/worker_service.dart';
import 'add_worker_screen.dart';
import 'worker_detail_screen.dart';
import 'hr_documentation_screen.dart';

class WorkersModuleScreen extends StatefulWidget {
  const WorkersModuleScreen({super.key});

  @override
  State<WorkersModuleScreen> createState() => _WorkersModuleScreenState();
}

class _WorkersModuleScreenState extends State<WorkersModuleScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getContractTypeLabel(WorkerContractType type) {
    switch (type) {
      case WorkerContractType.fijo:
        return 'Indeterminado (Fijo)';
      case WorkerContractType.plazoFijo:
        return 'Plazo Fijo';
      case WorkerContractType.porObra:
        return 'Por Obra';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Recursos Humanos & Nómina', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0.5,
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded, color: AppColors.primaryGreen),
              tooltip: 'Guía y Marco Legal LOTTT',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HrDocumentationScreen()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primaryGreen,
            tabs: [
              Tab(icon: Icon(Icons.people_outline), text: 'Trabajadores'),
              Tab(icon: Icon(Icons.analytics_outlined), text: 'Cargas Laborales'),
              Tab(icon: Icon(Icons.verified_outlined), text: 'Parafiscales (VEN)'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddWorkerScreen()),
            );
          },
          backgroundColor: AppColors.primaryGreen,
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: const Text('Nuevo Trabajador', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Consumer<WorkerService>(
          builder: (context, service, child) {
            final workers = service.activeWorkers.where((w) {
              final query = _searchQuery.toLowerCase();
              return w.name.toLowerCase().contains(query) ||
                  w.idNumber.toLowerCase().contains(query) ||
                  w.jobTitle.toLowerCase().contains(query);
            }).toList();

            return TabBarView(
              children: [
                // Tab 1: Trabajadores (Lista y Ficha Técnica)
                _buildWorkersListTab(context, service, workers),

                // Tab 2: Cargas Laborales & Proyecciones
                _buildLaborChargesTab(context, service),

                // Tab 3: Imposiciones Parafiscales (VEN)
                _buildParafiscalTab(context, service),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWorkersListTab(BuildContext context, WorkerService service, List<Worker> workers) {
    return Column(
      children: [
        // Buscador
        Container(
          padding: const EdgeInsets.all(15),
          color: Colors.white,
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, cédula o cargo...',
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),

        Expanded(
          child: workers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.badge_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty ? 'No hay trabajadores registrados' : 'No se encontraron resultados',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      if (_searchQuery.isEmpty)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddWorkerScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                          icon: const Icon(Icons.person_add, color: Colors.white),
                          label: const Text('Registrar Primer Trabajador', style: TextStyle(color: Colors.white)),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 15, 20, 80),
                  itemCount: workers.length,
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    return FadeInUp(
                      delay: Duration(milliseconds: index * 40),
                      child: _buildWorkerCard(context, worker),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWorkerCard(BuildContext context, Worker worker) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WorkerDetailScreen(workerId: worker.id)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primaryGreen.withOpacity(0.15),
              child: Text(
                worker.name.isNotEmpty ? worker.name[0].toUpperCase() : 'W',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primaryGreen),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(worker.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text('${worker.jobTitle} • C.I.: ${worker.idNumber}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getContractTypeLabel(worker.contractType),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Antigüedad: ${worker.formattedServiceTime}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${worker.baseSalary.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                ),
                Text(worker.paymentFrequency, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaborChargesTab(BuildContext context, WorkerService service) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Resumen de Nómina & Cargas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.menu_book_rounded, color: AppColors.primaryGreen),
                tooltip: 'Ver Guía Legal LOTTT',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HrDocumentationScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Banner de acceso a la Guía Legal
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HrDocumentationScreen()),
              );
            },
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gavel_rounded, color: AppColors.primaryGreen, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Guía & Marco Legal LOTTT (VEN)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                        Text('Consulta cómo se calculan las prestaciones, vacaciones y parafiscales.', style: TextStyle(fontSize: 11, color: Colors.black87)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primaryGreen),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(child: _buildMetricCard('Trabajadores Activos', service.activeWorkers.length.toString(), Icons.badge_outlined, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCard('Nómina Base Mensual', '\$${service.totalMonthlyBasePayroll.toStringAsFixed(2)}', Icons.payments_outlined, AppColors.primaryGreen)),
            ],
          ),
          const SizedBox(height: 12),

          _buildMetricCard(
            'Carga Patronal Real Estimada (Mensual)',
            '\$${service.totalEstimatedEmployerCost.toStringAsFixed(2)}',
            Icons.account_balance_outlined,
            Colors.purple,
            subtitle: 'Incluye salario base + IVSS + FAOV + INCES + provisión de prestaciones',
          ),
          const SizedBox(height: 25),

          const Text('Proyección de Compromisos Acumulados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildCommitmentRow('Prestaciones Sociales Acumuladas', '\$${service.totalAccumulatedSeverance.toStringAsFixed(2)}', Colors.blue),
                const Divider(height: 20),
                _buildCommitmentRow('Vacaciones Acumuladas Pendientes', '\$${service.totalAccumulatedVacations.toStringAsFixed(2)}', Colors.orange),
                const Divider(height: 20),
                _buildCommitmentRow('Utilidades Estimadas a Fin de Año', '\$${service.totalAccumulatedProfits.toStringAsFixed(2)}', Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParafiscalTab(BuildContext context, WorkerService service) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Imposiciones Parafiscales (Legislación VEN)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text('Aportes patronales requeridos para solvencia de finca y permisos sanitarios:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 20),

          _buildParafiscalCard(
            'IVSS (Seguro Social)',
            'Estimado 4.5% Aporte Patronal',
            '\$${service.monthlyIvssTotal.toStringAsFixed(2)} / mes',
            Icons.health_and_safety_outlined,
            Colors.blue,
          ),
          const SizedBox(height: 12),

          _buildParafiscalCard(
            'FAOV / Banavih (Vivienda)',
            '2.0% Aporte Patronal Obligatorio',
            '\$${service.monthlyFaovTotal.toStringAsFixed(2)} / mes',
            Icons.home_work_outlined,
            Colors.orange,
          ),
          const SizedBox(height: 12),

          _buildParafiscalCard(
            'INCES (Capacitación)',
            '2.0% Aporte Patronal',
            '\$${service.monthlyIncesTotal.toStringAsFixed(2)} / mes',
            Icons.school_outlined,
            Colors.green,
          ),
          const SizedBox(height: 25),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.amber)),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.amber, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Solvencia Laboral para Permisología', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                      Text('Mantener al día IVSS y Banavih es indispensable para la obtención de permisos sanitarios del fundo.', style: TextStyle(fontSize: 11, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ],
      ),
    );
  }

  Widget _buildCommitmentRow(String title, String amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        Text(amount, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildParafiscalCard(String title, String subtitle, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
      ),
    );
  }
}
