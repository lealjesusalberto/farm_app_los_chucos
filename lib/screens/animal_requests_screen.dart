import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../core/app_colors.dart';
import '../models/animal_models.dart';
import '../services/animal_service.dart';

class AnimalRequestsScreen extends StatefulWidget {
  const AnimalRequestsScreen({super.key});

  @override
  State<AnimalRequestsScreen> createState() => _AnimalRequestsScreenState();
}

class _AnimalRequestsScreenState extends State<AnimalRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, String> _fieldLabels = {
    'code': 'Código',
    'name': 'Nombre',
    'photoUrl': 'Foto del Animal',
    'type': 'Tipo',
    'breed': 'Raza',
    'sex': 'Sexo',
    'birthDate': 'F. Nacimiento',
    'entryDate': 'F. Ingreso',
    'origin': 'Origen',
    'currentWeight': 'Peso (Kg)',
    'currentLocation': 'Ubicación',
    'group': 'Grupo Etario',
    'fatherId': 'ID del Padre',
    'motherId': 'ID de la Madre',
    'status': 'Estado',
    'productiveStatus': 'Estado Productivo',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatValue(String key, dynamic value) {
    if (value == null || value.toString().isEmpty) return 'No definido';
    if (key == 'birthDate' || key == 'entryDate') {
      try {
        final date = DateTime.parse(value.toString());
        return DateFormat('dd/MM/yyyy').format(date);
      } catch (_) {
        return value.toString();
      }
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Solicitudes de Ganado'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textGrey,
          indicatorColor: AppColors.primaryGreen,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pending_actions_rounded),
                  SizedBox(width: 8),
                  Text('Pendientes', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded),
                  SizedBox(width: 8),
                  Text('Historial', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Consumer<AnimalService>(
        builder: (context, animalService, _) {
          final requests = animalService.editRequests;
          final pending = requests.where((r) => r.status == 'pending').toList();
          final history = requests.where((r) => r.status != 'pending').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRequestsList(pending, isPending: true),
              _buildRequestsList(history, isPending: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestsList(List<AnimalEditRequest> list, {required bool isPending}) {
    if (list.isEmpty) {
      return Center(
        child: FadeIn(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPending ? Icons.playlist_add_check_rounded : Icons.history_toggle_off_rounded,
                size: 70,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 15),
              Text(
                isPending ? 'No hay solicitudes pendientes' : 'El historial está vacío',
                style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final request = list[index];
        return FadeInUp(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: index * 50),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: CircleAvatar(
                backgroundColor: request.requestType == 'delete'
                    ? Colors.red.withOpacity(0.1)
                    : _getStatusColor(request.status).withOpacity(0.1),
                child: Icon(
                  request.requestType == 'delete'
                      ? Icons.delete_forever_rounded
                      : _getStatusIcon(request.status),
                  color: request.requestType == 'delete'
                      ? Colors.red
                      : _getStatusColor(request.status),
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      request.animalName != null && request.animalName!.isNotEmpty
                          ? '${request.animalName} (${request.animalCode})'
                          : 'Animal ${request.animalCode}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(request.status),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: request.requestType == 'delete'
                              ? Colors.red.shade100
                              : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          request.requestType == 'delete' ? 'Eliminar' : 'Editar',
                          style: TextStyle(
                            color: request.requestType == 'delete'
                                ? Colors.red.shade800
                                : Colors.blue.shade800,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Solicitado por: ${request.requestedByName}',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(request.requestedAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => _showComparisonDialog(request),
            ),
          ),
        );
      },
    );
  }

  void _showComparisonDialog(AnimalEditRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.requestType == 'delete'
                                    ? 'Eliminar: ${request.animalName != null && request.animalName!.isNotEmpty ? request.animalName : "Animal"} (${request.animalCode})'
                                    : request.animalName != null && request.animalName!.isNotEmpty
                                        ? 'Modificar: ${request.animalName} (${request.animalCode})'
                                        : 'Modificar: Animal ${request.animalCode}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Por ${request.requestedByName} (${request.requestedByEmail})',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),
                  const Divider(height: 25),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildComparisonList(request),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                  if (request.status == 'pending')
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3))],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _confirmReject(request),
                                icon: const Icon(Icons.close_rounded, color: Colors.red),
                                label: const Text('RECHAZAR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _confirmApprove(request),
                                icon: const Icon(Icons.check_rounded, color: Colors.white),
                                label: const Text('APROBAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDeletedAnimalField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildComparisonList(AnimalEditRequest request) {
    if (request.requestType == 'delete') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DETALLES DE ELIMINACIÓN',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red, letterSpacing: 1.1),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Se solicita la eliminación permanente de este registro de animal.',
                        style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 25, color: Colors.redAccent),
                _buildDeletedAnimalField('Código / Arete ID', request.animalCode),
                if (request.animalName != null && request.animalName!.isNotEmpty)
                  _buildDeletedAnimalField('Nombre', request.animalName!),
                if (request.originalData['type'] != null)
                  _buildDeletedAnimalField('Tipo', request.originalData['type'].toString().toUpperCase()),
                if (request.originalData['breed'] != null)
                  _buildDeletedAnimalField('Raza', request.originalData['breed'].toString()),
                if (request.originalData['sex'] != null)
                  _buildDeletedAnimalField('Sexo', request.originalData['sex'].toString()),
                if (request.originalData['currentLocation'] != null)
                  _buildDeletedAnimalField('Ubicación Actual', request.originalData['currentLocation'].toString()),
                if (request.originalData['group'] != null)
                  _buildDeletedAnimalField('Grupo Etario', request.originalData['group'].toString()),
              ],
            ),
          ),
        ],
      );
    }

    final changedFields = <String>[];
    
    // Identificar qué campos cambiaron
    request.newData.forEach((key, val) {
      final origVal = request.originalData[key];
      // Si son diferentes, los agregamos a los campos cambiados
      if (origVal.toString() != val.toString()) {
        changedFields.add(key);
      }
    });

    if (changedFields.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            'No se detectaron diferencias entre los datos.',
            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CAMPOS MODIFICADOS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryGreen, letterSpacing: 1.1),
        ),
        const SizedBox(height: 15),
        ...changedFields.map((fieldKey) {
          final originalValue = request.originalData[fieldKey];
          final newValue = request.newData[fieldKey];
          final fieldLabel = _fieldLabels[fieldKey] ?? fieldKey;

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.4),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fieldLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
                ),
                const SizedBox(height: 12),
                if (fieldKey == 'photoUrl') ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Original', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            _buildPhotoComparisonItem(originalValue),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.grey),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Nuevo', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 4),
                            _buildPhotoComparisonItem(newValue),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ORIGINAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red)),
                              const SizedBox(height: 4),
                              Text(
                                _formatValue(fieldKey, originalValue),
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PROPUESTO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)),
                              const SizedBox(height: 4),
                              Text(
                                _formatValue(fieldKey, newValue),
                                style: TextStyle(
                                  color: Colors.green.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPhotoComparisonItem(dynamic urlValue) {
    final urlStr = urlValue?.toString() ?? '';
    if (urlStr.isEmpty) {
      return Container(
        height: 80,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
        child: const Center(child: Icon(Icons.no_photography_outlined, color: Colors.grey, size: 24)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        urlStr,
        height: 80,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 80,
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.red, size: 24)),
        ),
      ),
    );
  }

  void _confirmApprove(AnimalEditRequest request) {
    final isDelete = request.requestType == 'delete';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isDelete ? 'Aprobar Eliminación' : 'Aprobar Modificación'),
        content: Text(
          isDelete
              ? '¿Confirmas que deseas eliminar permanentemente al animal ${request.animalCode}?'
              : '¿Confirmas que deseas aplicar estas modificaciones al animal ${request.animalCode}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close confirmation dialog
              Navigator.pop(context); // Close details sheet
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => const Center(child: CircularProgressIndicator()),
              );

              try {
                await Provider.of<AnimalService>(context, listen: false).approveEditRequest(request);
                if (mounted) {
                  Navigator.pop(context); // Close loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Solicitud aprobada y cambios aplicados exitosamente.'),
                    backgroundColor: AppColors.primaryGreen,
                  ));
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error al aprobar: $e'),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
            child: const Text('APROBAR', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmReject(AnimalEditRequest request) {
    final isDelete = request.requestType == 'delete';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isDelete ? 'Rechazar Eliminación' : 'Rechazar Modificación'),
        content: Text(
          isDelete
              ? '¿Confirmas que deseas rechazar la solicitud para eliminar al animal ${request.animalCode}?'
              : '¿Confirmas que deseas rechazar los cambios sugeridos para el animal ${request.animalCode}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close confirmation dialog
              Navigator.pop(context); // Close details sheet

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (ctx) => const Center(child: CircularProgressIndicator()),
              );

              try {
                await Provider.of<AnimalService>(context, listen: false).rejectEditRequest(request.id);
                if (mounted) {
                  Navigator.pop(context); // Close loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Solicitud rechazada.'),
                    backgroundColor: Colors.redAccent,
                  ));
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context); // Close loading indicator
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error al rechazar: $e'),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
            child: const Text('RECHAZAR', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_empty_rounded;
      case 'approved': return Icons.check_circle_outline_rounded;
      case 'rejected': return Icons.cancel_outlined;
      default: return Icons.help_outline_rounded;
    }
  }

  Widget _buildStatusBadge(String status) {
    String text = 'Pendiente';
    Color color = Colors.orange;

    if (status == 'approved') {
      text = 'Aprobada';
      color = Colors.green;
    } else if (status == 'rejected') {
      text = 'Rechazada';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
