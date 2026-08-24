import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class HrDocumentationScreen extends StatelessWidget {
  const HrDocumentationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Guía & Marco Legal LOTTT (VEN)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  Icon(Icons.gavel_rounded, color: AppColors.primaryGreen, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Marco Legal de Trabajo (Venezuela)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Fundamentado en la Ley Orgánica del Trabajo, los Trabajadores y las Trabajadoras (LOTTT, 2012).',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Sección 1: Prestaciones Sociales
            _buildDocSection(
              title: '1. Prestaciones Sociales (Art. 142 LOTTT)',
              icon: Icons.savings_outlined,
              color: Colors.blue,
              content: [
                _buildBulletPoint(
                  'Garantía Trimestral (Literales a y b)',
                  'Cada 3 meses de servicio el patrono acredita 15 días de salario integral (60 días al año). A partir del 2do año, suma 2 días adicionales por año de servicio (hasta un máximo de 30 días adicionales).',
                ),
                _buildBulletPoint(
                  'Retroactividad al Término del Contrato (Literal c)',
                  'Al finalizar la relación laboral se calcula el servicio total a razón de 30 días de salario por cada año o fracción superior a 6 meses, al último salario integral.',
                ),
                _buildBulletPoint(
                  'Regla del Monto Mayor (Literal d)',
                  'El trabajador recibe el monto que resulte MAYOR entre los depósitos acumulados trimestrales y la retroactividad.',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sección 2: Vacaciones y Bono Vacacional
            _buildDocSection(
              title: '2. Vacaciones y Bono Vacacional (Art. 190 y 192)',
              icon: Icons.beach_access_outlined,
              color: Colors.orange,
              content: [
                _buildBulletPoint(
                  'Días de Vacaciones Hábiles (Art. 190)',
                  '1er año: 15 días hábiles pagados. Cada año posterior suma 1 día hábil adicional (máximo 30 días hábiles).',
                ),
                _buildBulletPoint(
                  'Bono Vacacional (Art. 192)',
                  '1er año: 15 días de salario. Cada año posterior suma 1 día de salario adicional (máximo 30 días de salario).',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sección 3: Utilidades
            _buildDocSection(
              title: '3. Utilidades y Fin de Año (Art. 131 y 132)',
              icon: Icons.card_giftcard,
              color: Colors.purple,
              content: [
                _buildBulletPoint(
                  'Bonificación de Fin de Año',
                  'Pago legal entre 15 días (mínimo) y 4 meses / 120 días (máximo). El sistema presupuesta 30 días al año prorrateados mensualmente a razón de 2.5 días por mes de servicio.',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sección 4: Parafiscales
            _buildDocSection(
              title: '4. Aportes Parafiscales (IVSS, FAOV, INCES)',
              icon: Icons.verified_outlined,
              color: Colors.green,
              content: [
                _buildBulletPoint(
                  'IVSS (Seguro Social)',
                  'Aporte Patronal del 4.5% al 11% (según nivel de riesgo agrícola). Retención al trabajador: 4%.',
                ),
                _buildBulletPoint(
                  'FAOV / Banavih (Vivienda)',
                  'Aporte Patronal del 2.0% del salario mensual. Retención al trabajador: 1.0%.',
                ),
                _buildBulletPoint(
                  'INCES (Capacitación)',
                  'Aporte Patronal del 2.0% sobre sueldos pagados (cuando la entidad posee 5 o más trabajadores).',
                ),
                _buildBulletPoint(
                  'Carga Patronal Real Estimada',
                  'Salario Base + IVSS (4.5%) + FAOV (2%) + INCES (2%) + Provisión de Pasivos (~15%) ≈ 150% del salario base.',
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
