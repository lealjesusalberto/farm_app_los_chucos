import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/animal_models.dart';

class AnimalDetailScreen extends StatelessWidget {
  final Animal animal;

  const AnimalDetailScreen({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInUp(child: _buildMainStats()),
                  const SizedBox(height: 25),
                  FadeInUp(delay: const Duration(milliseconds: 200), child: _buildInfoSection()),
                  const SizedBox(height: 25),
                  FadeInUp(delay: const Duration(milliseconds: 400), child: _buildGenealogySection()),
                  const SizedBox(height: 100), // Espacio para el bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    String imagePath = 'assets/types/bovine.png';
    switch (animal.type) {
      case AnimalType.bovine: imagePath = 'assets/types/bovine.png'; break;
      case AnimalType.porcine: imagePath = 'assets/types/porcine.png'; break;
      case AnimalType.buffalo: imagePath = 'assets/types/buffalo.png'; break;
      case AnimalType.equine: imagePath = 'assets/types/equine.png'; break;
      case AnimalType.poultry: imagePath = 'assets/types/poultry.png'; break;
      case AnimalType.dog: imagePath = 'assets/types/dog.png'; break;
      default: imagePath = 'assets/types/bovine.png';
    }

    final hasPhoto = animal.photoUrl != null && animal.photoUrl!.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          animal.name != null && animal.name!.isNotEmpty 
              ? '${animal.name} (${animal.code})' 
              : 'Animal ${animal.code}', 
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold, 
            fontSize: 18,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 4.0,
                color: Colors.black87,
              ),
            ],
          )
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto) ...[
              Image.network(
                animal.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ] else ...[
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryGreen, Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Center(
                child: Opacity(
                  opacity: 0.3,
                  child: Image.asset(imagePath, width: 120, height: 120),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainStats() {
    return Row(
      children: [
        _buildStatCard('Peso Actual', '${animal.currentWeight} Kg', FontAwesomeIcons.weightHanging, Colors.orange),
        const SizedBox(width: 15),
        _buildStatCard('Edad', '${animal.ageInMonths} meses', FontAwesomeIcons.calendarDay, Colors.blue),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return _buildSectionContainer(
      title: 'Detalles del Animal',
      icon: Icons.info_outline,
      children: [
        if (animal.name != null && animal.name!.isNotEmpty)
          _buildDetailRow('Nombre', animal.name!),
        _buildDetailRow('Origen', animal.origin.name[0].toUpperCase() + animal.origin.name.substring(1)),
        _buildDetailRow('Raza', animal.breed),
        _buildDetailRow('Sexo', animal.sex),
        _buildDetailRow('F. Nacimiento', DateFormat('dd/MM/yyyy').format(animal.birthDate)),
        _buildDetailRow('F. Ingreso', DateFormat('dd/MM/yyyy').format(animal.entryDate)),
        _buildDetailRow('Ubicación Actual', animal.currentLocation),
        _buildDetailRow('Grupo Etario', animal.group),
        _buildDetailRow('Estado', animal.status == 'active' ? 'Activo' : 'Baja', isLast: true),
      ],
    );
  }

  Widget _buildGenealogySection() {
    return _buildSectionContainer(
      title: 'Genealogía',
      icon: Icons.family_restroom,
      children: [
        _buildDetailRow('Padre (Toro)', animal.fatherId ?? 'Desconocido'),
        _buildDetailRow('Madre (Vaca)', animal.motherId ?? 'Desconocido', isLast: true),
      ],
    );
  }

  Widget _buildSectionContainer({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Divider(height: 30),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
