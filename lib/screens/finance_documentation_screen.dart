import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class FinanceDocumentationScreen extends StatelessWidget {
  const FinanceDocumentationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Guía & Funcionamiento Financiero', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera Informativa
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_balance_outlined, color: AppColors.primaryGreen, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Módulo de Administración & Contabilidad',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Guía explicativa de cómo opera el Libro Diario, Libro Mayor, Compras con Factura y Balance General de la Finca.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Sección 1: Libro Diario
            _buildDocSection(
              title: '1. Libro Diario (Operaciones Diarias)',
              icon: Icons.book_outlined,
              color: Colors.blue,
              content: [
                _buildBulletPoint(
                  'Registro Cronológico',
                  'Registra en tiempo real cada transacción de Ingreso (Ventas) o Egreso (Compras y Gastos).',
                ),
                _buildBulletPoint(
                  'Detalle de la Operación',
                  'Captura Concepto, Categoría, Monto (\$USD), Cantidad, Unidad de Medida (Sacos, Kg, Litros, etc.), Nombre del Proveedor/Cliente y N° de Factura.',
                ),
                _buildBulletPoint(
                  'Soporte de Comprobante / Factura',
                  'Permite adjuntar foto o archivo del comprobante fiscal o nota de entrega para respaldo de auditoría.',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sección 2: Libro Mayor
            _buildDocSection(
              title: '2. Libro Mayor (Cuentas Contables)',
              icon: Icons.pie_chart_outline,
              color: Colors.purple,
              content: [
                _buildBulletPoint(
                  'Consolidación por Rubro',
                  'Agrupa automáticamente todas las transacciones por categoría contable (ej. Insumos/Alimentos, Medicinas, Venta Leche, Nómina).',
                ),
                _buildBulletPoint(
                  'Resumen de Débitos y Créditos',
                  'Muestra el Total Créditos (Ingresos), Total Débitos (Egresos) y el Saldo Neto de cada cuenta.',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sección 3: Balance General
            _buildDocSection(
              title: '3. Balance General (Activos vs Pasivos)',
              icon: Icons.balance_outlined,
              color: AppColors.primaryGreen,
              content: [
                _buildBulletPoint(
                  'Estructura de Activos',
                  'Suma el Disponible en Caja/Bancos + Valoración en tiempo real del Inventario Stock + Cuentas por Cobrar.',
                ),
                _buildBulletPoint(
                  'Estructura de Pasivos',
                  'Consolida los Pasivos Laborales Acumulados LOTTT (Prestaciones, Vacaciones, Utilidades e Imposiciones IVSS/FAOV calculados dinámicamente desde RRHH) + Cuentas por Pagar Proveedores.',
                ),
                _buildBulletPoint(
                  'Patrimonio Neto / Capital de Trabajo',
                  'Calcula la Solvencia Financiera Real de la finca mediante la ecuación básica patrimonial: Patrimonio = Activos - Pasivos.',
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Botón Entendido
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ENTENDIDO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDocSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> content,
  }) {
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...content,
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4, right: 8),
            child: Icon(Icons.circle, size: 6, color: AppColors.primaryGreen),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.4),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
