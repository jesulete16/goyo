import 'package:flutter/material.dart';
import 'dart:async';
import 'login.dart';
import 'menu_animal.dart';
import 'menu_veterinario.dart';
import 'services/user_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));    _animationController.forward();
    
    // Verificar si hay sesión guardada después de 3 segundos
    Timer(const Duration(seconds: 3), () async {
      await _checkRememberedSession();
    });
  }

  Future<void> _checkRememberedSession() async {
    try {
      // Verificar si hay una sesión guardada
      final session = await UserPreferences.getRememberedSession();
      
      if (session != null && mounted) {
        final userData = session['userData'] as Map<String, dynamic>;
        final userType = session['userType'] as String;
        
        print('🔍 Sesión encontrada: ${userData['nombre']} como $userType');
        
        // Navegar directamente al menú correspondiente
        if (userType == 'animal') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MenuAnimal(userData: userData),
            ),
          );
        } else if (userType == 'veterinario') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MenuVeterinario(userData: userData),
            ),
          );
        } else {
          // Tipo de usuario desconocido, ir al login
          _navigateToLogin();
        }
      } else {
        // No hay sesión guardada, ir al login
        _navigateToLogin();
      }
    } catch (e) {
      print('❌ Error verificando sesión guardada: $e');
      // En caso de error, ir al login
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente y glassmorphism
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D2818),
                  Color(0xFF1B5E20),
                  Color(0xFF2E7D32),
                  Color(0xFF1B5E20),
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo circular con borde y sombra
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.7),
                              width: 5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 32,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              width: 160,
                              height: 160,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.pets,
                                  size: 90,
                                  color: Colors.white,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Nombre de la app
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFE8F5E8)],
                          ).createShader(bounds),
                          child: const Text(
                            'GOYO',
                            style: TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 8,
                              fontFamily: 'Arial',
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Subtítulo veterinario
                        const Text(
                          'Veterinaria Digital',
                          style: TextStyle(
                            fontSize: 22,
                            color: Color(0xFF0D2818), // Mucho más oscuro
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Cuidado profesional para tus mascotas',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        // Indicador de carga con glow
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF81C784).withOpacity(0.4),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF81C784)),
                              strokeWidth: 5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Versión en la parte inferior
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Versión 1.0 2025',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white54,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}