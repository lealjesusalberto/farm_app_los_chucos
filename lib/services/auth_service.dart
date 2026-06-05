import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_models.dart';
import '../firebase_options.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');

  AppUser? _currentUser;
  User? _firebaseUser;
  String? _errorMessage;
  List<AppUser> _allUsers = [];
  bool _isInitializing = true; // Nueva bandera para el splash

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _firebaseUser != null && _currentUser != null;
  bool get isInitializing => _isInitializing;
  String? get errorMessage => _errorMessage;
  List<AppUser> get allUsers => List.unmodifiable(_allUsers);

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    _auth.authStateChanges().listen((User? user) async {
      _firebaseUser = user;
      if (user != null) {
        // Cargar inmediatamente del caché para agilizar la persistencia offline/inicio rápido
        try {
          final prefs = await SharedPreferences.getInstance();
          final cachedProfile = prefs.getString('cached_user_profile_${user.uid}');
          if (cachedProfile != null) {
            final data = Map<String, dynamic>.from(jsonDecode(cachedProfile));
            _currentUser = AppUser.fromMap(user.uid, data);
            _isInitializing = false;
            notifyListeners();
          }
        } catch (e) {
          debugPrint('Error leyendo perfil de caché: $e');
        }

        await _loadUserProfile(user.uid);
        if (_currentUser != null && _currentUser!.canAdminUsers) {
          _listenToAllUsers();
        }
      } else {
        _currentUser = null;
        _allUsers = [];
      }
      _isInitializing = false;
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final snapshot = await _usersRef.child(uid).get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _currentUser = AppUser.fromMap(uid, data);
        
        // Guardar perfil fresco en caché local
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_user_profile_$uid', jsonEncode(data));
      } else if (_firebaseUser?.email == 'admin@loschucos.com') {
        await _usersRef.child(uid).set({
          'email': 'admin@loschucos.com',
          'name': 'Augusto Aldana',
          'role': 'presidente',
          'createdAt': ServerValue.timestamp,
        });
        
        // Limpieza automática del nodo con el UID viejo que olvidó la contraseña
        try {
          await _usersRef.child('xBGikw75aIVh4BP03mOvb3KJH3').remove();
        } catch (_) {}
        
        _currentUser = AppUser(
          id: uid,
          email: 'admin@loschucos.com',
          name: 'Augusto Aldana',
          role: UserRole.presidente,
        );
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<bool> login(String email, String password, bool rememberMe) async {
    try {
      _errorMessage = null;
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        if (rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('remembered_email', email.trim());
          await prefs.setBool('remember_me', true);
        } else {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('remembered_email');
          await prefs.setBool('remember_me', false);
        }

        await _loadUserProfile(credential.user!.uid);
        return _currentUser != null;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', false);
    if (_currentUser != null) {
      await prefs.remove('cached_user_profile_${_currentUser!.id}');
    }
    await _auth.signOut();
    _currentUser = null;
    _firebaseUser = null;
    notifyListeners();
  }

  // ... (Resto de métodos getAllUsers, registerUser, etc. se mantienen igual)
  void _listenToAllUsers() {
    _usersRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final usersMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        _allUsers = usersMap.entries.map((entry) {
          final data = Map<String, dynamic>.from(entry.value);
          return AppUser.fromMap(entry.key, data);
        }).toList();
        notifyListeners();
      }
    });
  }

  Future<bool> registerUser({required String email, required String password, required String name, required UserRole role}) async {
    FirebaseApp? tempApp;
    try {
      tempApp = await Firebase.initializeApp(name: 'Temp_${DateTime.now().ms}', options: DefaultFirebaseOptions.currentPlatform);
      final credential = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(email: email.trim(), password: password);
      if (credential.user != null) {
        await _usersRef.child(credential.user!.uid).set({'email': email.trim(), 'name': name, 'role': role.name, 'createdAt': ServerValue.timestamp});
        await tempApp.delete();
        return true;
      }
      return false;
    } catch (e) {
      if (tempApp != null) await tempApp.delete();
      return false;
    }
  }

  Future<void> deleteUser(String uid) async => await _usersRef.child(uid).remove();

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Correo ya registrado.';
      case 'weak-password': return 'Contraseña débil.';
      default: return 'Error: $code';
    }
  }
}

extension on DateTime { get ms => millisecondsSinceEpoch; }
