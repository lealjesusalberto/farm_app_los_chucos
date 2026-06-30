import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Esperar al menos el tiempo de animación
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Esperar a que Firebase y el perfil terminen de inicializar (máximo 8 segundos)
    int checks = 0;
    while (authService.isInitializing && checks < 16) {
      await Future.delayed(const Duration(milliseconds: 500));
      checks++;
    }

    if (mounted) {
      if (authService.isAuthenticated) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/dashboard_bg.png', // Using dashboard_bg.png as a farm background
            fit: BoxFit.cover,
          ),
          // Soft white gradient from top fading down
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.85),
                  Colors.white.withOpacity(0.4),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.55, 0.8],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 50.0),
                  child: FadeInDown(
                    duration: const Duration(milliseconds: 1500),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 220,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 60.0),
                  child: FadeIn(
                    delay: const Duration(milliseconds: 1000),
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
