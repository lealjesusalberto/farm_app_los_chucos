import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/app_colors.dart';
import '../models/user_models.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final users = authService.allUsers;

          if (users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return FadeInLeft(
                delay: Duration(milliseconds: index * 50),
                child: _buildUserCard(context, user),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Registrar Usuario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, AppUser user) {
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
          CircleAvatar(
            backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
            child: Icon(Icons.person, color: _getRoleColor(user.role)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(user.roleDisplayName, style: TextStyle(color: _getRoleColor(user.role), fontSize: 12, fontWeight: FontWeight.w600)),
                Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                onPressed: () => _showEditUserDialog(context, user),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () => _confirmDelete(context, user),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.presidente: return Colors.indigo;
      case UserRole.administradora: return Colors.blue;
      case UserRole.gerenteOperaciones: return Colors.teal;
      case UserRole.veterinario: return Colors.red;
      default: return Colors.orange;
    }
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole selectedRole = UserRole.gerenteOperaciones;
    bool obscureNewUserPassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Agregar Nuevo Usuario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre Completo')),
              const SizedBox(height: 15),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Correo Electrónico')),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: obscureNewUserPassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña (mín. 6 caracteres)',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureNewUserPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () => setModalState(() => obscureNewUserPassword = !obscureNewUserPassword),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<UserRole>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Rol en la Finca'),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(AppUser(id: '', email: '', name: '', role: role).roleDisplayName),
                  );
                }).toList(),
                onChanged: (val) => selectedRole = val!,
              ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty && emailController.text.isNotEmpty && passwordController.text.length >= 6) {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    final success = await authService.registerUser(
                      email: emailController.text,
                      password: passwordController.text,
                      name: nameController.text,
                      role: selectedRole,
                    );
                    
                    if (mounted) {
                      Navigator.pop(context);
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(authService.errorMessage ?? 'Error al registrar usuario'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                child: const Text('REGISTRAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    ),
  );
}

  void _showEditUserDialog(BuildContext context, AppUser user) {
    final nameController = TextEditingController(text: user.name);
    UserRole selectedRole = user.role;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Editar Usuario', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre Completo')),
              const SizedBox(height: 15),
              DropdownButtonFormField<UserRole>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Rol en la Finca'),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(AppUser(id: '', email: '', name: '', role: role).roleDisplayName),
                  );
                }).toList(),
                onChanged: (val) => selectedRole = val!,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      final authService = Provider.of<AuthService>(context, listen: false);
                      final success = await authService.updateUser(
                        user.id,
                        name: nameController.text,
                        role: selectedRole,
                      );
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error al actualizar usuario'), backgroundColor: Colors.red),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Usuario actualizado'), backgroundColor: Colors.green),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                  child: const Text('GUARDAR CAMBIOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

  void _confirmDelete(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content: Text('¿Está seguro de eliminar a ${user.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).deleteUser(user.id);
              Navigator.pop(context);
            },
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
