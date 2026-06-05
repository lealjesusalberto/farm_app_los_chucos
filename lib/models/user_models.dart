enum UserRole { 
  presidente, 
  administradora, 
  gerenteOperaciones, 
  operadorOrdeno, 
  desmatonador, 
  fumigador, 
  veterinario 
}

class AppUser {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? profileImageUrl;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.profileImageUrl,
  });

  // Serialización para Firebase
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.name,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.operadorOrdeno,
      ),
      profileImageUrl: map['profileImageUrl'],
    );
  }

  String get roleDisplayName {
    switch (role) {
      case UserRole.presidente: return 'Presidente';
      case UserRole.administradora: return 'Administradora';
      case UserRole.gerenteOperaciones: return 'Gerente de Operaciones';
      case UserRole.operadorOrdeno: return 'Operador de Ordeño y Quesería';
      case UserRole.desmatonador: return 'Desmatonador';
      case UserRole.fumigador: return 'Fumigador';
      case UserRole.veterinario: return 'Veterinario';
    }
  }

  // Permisos detallados
  bool get canManageFinance => role == UserRole.presidente || role == UserRole.administradora;
  
  bool get canManageGenetics => role == UserRole.presidente;
  
  bool get canManageInventory => role == UserRole.presidente || role == UserRole.administradora;

  bool get canManageAnimalInventory => role == UserRole.presidente || role == UserRole.administradora || role == UserRole.gerenteOperaciones;
  
  bool get canRegisterProduction => role == UserRole.presidente || role == UserRole.administradora || role == UserRole.operadorOrdeno;
  
  bool get canRegisterSanity => role == UserRole.presidente || role == UserRole.veterinario;
  
  bool get canManageLand => role == UserRole.presidente || role == UserRole.desmatonador || role == UserRole.fumigador;
  
  bool get canAdminUsers => role == UserRole.presidente;
  
  // Accesos generales a los módulos contenedores
  bool get canAccessAnimalModule => canManageAnimalInventory || canManageGenetics || canRegisterProduction || canRegisterSanity;
}
