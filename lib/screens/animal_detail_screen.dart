import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/animal_models.dart';
import 'package:provider/provider.dart';
import '../services/animal_service.dart';
import '../services/auth_service.dart';
import '../models/user_models.dart';
import 'add_animal_screen.dart';

class AnimalDetailScreen extends StatelessWidget {
  final Animal animal;

  const AnimalDetailScreen({super.key, required this.animal});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnimalService>(
      builder: (context, service, _) {
        // Find latest version of the animal to ensure real-time updates
        final currentAnimal = service.animals.firstWhere(
          (a) => a.id == animal.id,
          orElse: () => animal,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, currentAnimal),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      FadeInUp(child: _buildMainStats(currentAnimal)),
                      const SizedBox(height: 25),
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: _buildInfoSection(currentAnimal),
                      ),
                      const SizedBox(height: 25),
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: _buildGenealogySection(currentAnimal),
                      ),
                      const SizedBox(height: 25),
                      FadeInUp(
                        delay: const Duration(milliseconds: 500),
                        child: _buildProductionHistory(context, currentAnimal),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Animal currentAnimal) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    String imagePath = 'assets/types/bovine.png';
    switch (currentAnimal.type) {
      case AnimalType.bovine:
        imagePath = 'assets/types/bovine.png';
        break;
      case AnimalType.porcine:
        imagePath = 'assets/types/porcine.png';
        break;
      case AnimalType.buffalo:
        imagePath = 'assets/types/buffalo.png';
        break;
      case AnimalType.equine:
        imagePath = 'assets/types/equine.png';
        break;
      case AnimalType.poultry:
        imagePath = 'assets/types/poultry.png';
        break;
      case AnimalType.dog:
        imagePath = 'assets/types/dog.png';
        break;
      default:
        imagePath = 'assets/types/bovine.png';
    }

    final hasPhoto = animal.photoUrl != null && animal.photoUrl!.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.primaryGreen,
      actions: [
        if (user?.canEditAnimal == true)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
              tooltip: 'Editar Animal',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddAnimalScreen(animal: animal),
                  ),
                );
              },
            ),
          ),
        if (user?.canDeleteAnimal == true)
          Container(
          margin: const EdgeInsets.only(right: 12, left: 4, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.delete_rounded,
              color: Colors.white,
              size: 20,
            ),
            tooltip: user?.needsApprovalToDelete == true ? 'Solicitar Eliminación' : 'Eliminar Animal',
            onPressed: () {
              final needsApproval = user?.needsApprovalToDelete == true;
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(needsApproval ? 'Solicitar Eliminación' : 'Eliminar Animal'),
                  content: Text(
                    needsApproval
                        ? '¿Estás seguro de que deseas enviar una solicitud para eliminar este animal?'
                        : '¿Estás seguro de que deseas eliminar este registro permanentemente?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator()),
                        );
                        
                        try {
                          final animalService = Provider.of<AnimalService>(
                            context,
                            listen: false,
                          );
                          
                          if (needsApproval) {
                            final request = AnimalEditRequest(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              animalId: animal.id,
                              animalCode: animal.code,
                              animalName: animal.name,
                              requestedById: user?.id ?? 'Desconocido',
                              requestedByName: user?.name ?? 'Usuario',
                              requestedByEmail: user?.email ?? '',
                              requestedAt: DateTime.now(),
                              status: 'pending',
                              requestType: 'delete',
                              originalData: animal.toMap(),
                              newData: {},
                            );
                            await animalService.addEditRequest(request);
                            
                            if (context.mounted) {
                              Navigator.pop(context); // Close loading indicator
                              Navigator.pop(context); // Go back to previous screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Solicitud de eliminación enviada al presidente.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          } else {
                            await animalService.deleteAnimal(animal.id);
                            if (context.mounted) {
                              Navigator.pop(context); // Close loading indicator
                              Navigator.pop(context); // Go back to previous screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Animal eliminado exitosamente'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context); // Close loading indicator
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        needsApproval ? 'Solicitar' : 'Eliminar',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
          ),
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
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
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

  Widget _buildMainStats(Animal currentAnimal) {
    return Row(
      children: [
        _buildStatCard(
          'Peso Actual',
          '${currentAnimal.currentWeight} Kg',
          FontAwesomeIcons.weightHanging,
          Colors.orange,
        ),
        const SizedBox(width: 15),
        _buildStatCard(
          'Edad',
          '${currentAnimal.ageInMonths} meses',
          FontAwesomeIcons.calendarDay,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(Animal currentAnimal) {
    return _buildSectionContainer(
      title: 'Detalles del Animal',
      icon: Icons.info_outline,
      children: [
        if (currentAnimal.name != null && currentAnimal.name!.isNotEmpty)
          _buildDetailRow('Nombre', currentAnimal.name!),
        _buildDetailRow(
          'Origen',
          currentAnimal.origin.name[0].toUpperCase() + currentAnimal.origin.name.substring(1),
        ),
        _buildDetailRow('Raza', currentAnimal.breed),
        _buildDetailRow('Sexo', currentAnimal.sex),
        _buildDetailRow(
          'F. Nacimiento',
          DateFormat('dd/MM/yyyy').format(currentAnimal.birthDate),
        ),
        _buildDetailRow(
          'F. Ingreso',
          DateFormat('dd/MM/yyyy').format(currentAnimal.entryDate),
        ),
        _buildDetailRow('Ubicación Actual', currentAnimal.currentLocation),
        _buildDetailRow('Grupo Etario', currentAnimal.group),
        _buildDetailRow(
          'Estado',
          currentAnimal.status == 'active' ? 'Activo' : 'Baja',
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildGenealogySection(Animal currentAnimal) {
    return _buildSectionContainer(
      title: 'Genealogía',
      icon: Icons.family_restroom,
      children: [
        _buildDetailRow('Padre (Toro)', currentAnimal.fatherId ?? 'Desconocido'),
        _buildDetailRow(
          'Madre (Vaca)',
          currentAnimal.motherId ?? 'Desconocido',
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
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
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionHistory(BuildContext context, Animal currentAnimal) {
    final animalService = Provider.of<AnimalService>(context);
    final List<Widget> sections = [];

    if (currentAnimal.type == AnimalType.bovine || currentAnimal.type == AnimalType.buffalo) {
      if (currentAnimal.sex.toLowerCase() == 'hembra') {
        final records = animalService.individualMilkRecords
            .where((r) => r.animalId == currentAnimal.id)
            .toList();
        if (records.isNotEmpty) {
          final topRecords = records.take(5).toList();
          final List<Widget> children = topRecords.map((r) => _buildDetailRow(
            DateFormat('dd/MM/yyyy').format(r.date),
            '${r.liters} Lts (${r.amOrPm})',
            isLast: r == topRecords.last,
          )).toList();
          
          if (records.length > 5) {
            children.add(
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Center(child: Text('Mostrando últimos 5 registros', style: TextStyle(color: Colors.grey, fontSize: 12))),
              )
            );
          }
          
          sections.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 25),
              child: _buildSectionContainer(
                title: 'Historial de Leche',
                icon: FontAwesomeIcons.droplet,
                children: children,
              ),
            )
          );
        }
      }
    }

    final weightRecords = animalService.weightRecords
        .where((r) => r.animalId == animal.id)
        .toList();
    if (weightRecords.isNotEmpty) {
      final topRecords = weightRecords.take(5).toList();
      final List<Widget> children = topRecords.map((r) => _buildDetailRow(
        DateFormat('dd/MM/yyyy').format(r.date),
        '${r.weight} Kg',
        isLast: r == topRecords.last,
      )).toList();
      
      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 25),
          child: _buildSectionContainer(
            title: 'Historial de Pesajes',
            icon: FontAwesomeIcons.weightHanging,
            children: children,
          ),
        )
      );
    }

    if (sections.isEmpty) return const SizedBox.shrink();
    return Column(children: sections);
  }
}
