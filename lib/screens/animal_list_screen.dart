import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/app_colors.dart';
import '../models/animal_models.dart';
import 'add_animal_screen.dart';
import 'animal_detail_screen.dart';
import 'package:provider/provider.dart';
import '../services/animal_service.dart';

class AnimalListScreen extends StatefulWidget {
  const AnimalListScreen({super.key});

  @override
  State<AnimalListScreen> createState() => _AnimalListScreenState();
}

class _AnimalListScreenState extends State<AnimalListScreen> {
  String selectedFilter = 'Todos';
  final List<String> filters = ['Todos', 'Bovinos', 'Búfalos', 'Equinos', 'Porcinos', 'Aves', 'Perros'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inventario Animal'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: Consumer<AnimalService>(
              builder: (context, animalService, child) {
                // Usamos un try-catch aquí también por seguridad extra en la UI
                try {
                  final animals = animalService.getFilteredAnimals(selectedFilter);

                  if (animals.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FontAwesomeIcons.boxOpen, size: 50, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          const Text('No hay animales registrados', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: animals.length,
                    itemBuilder: (context, index) {
                      final animal = animals[index];
                      return FadeInUp(
                        delay: Duration(milliseconds: index * 50),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnimalDetailScreen(animal: animal),
                              ),
                            );
                          },
                          child: _buildAnimalCard(animal),
                        ),
                      );
                    },
                  );
                } catch (e) {
                  return Center(child: Text('Error al cargar la lista: $e'));
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddAnimalScreen()),
        ),
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => selectedFilter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryGreen : AppColors.background,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textGrey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimalCard(Animal animal) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: animal.photoUrl != null && animal.photoUrl!.isNotEmpty
                ? Image.network(
                    animal.photoUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      imagePath,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset(
                    imagePath,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      animal.name != null && animal.name!.isNotEmpty 
                          ? '${animal.name} (${animal.code})' 
                          : 'Código: ${animal.code}', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    Text(animal.sex, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Text('Raza: ${animal.breed}', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(animal.currentLocation, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        animal.group,
                        style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
