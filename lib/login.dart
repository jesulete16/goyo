import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_menu.dart';
import 'menu_animal.dart';
import 'menu_veterinario.dart';
import 'services/user_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  String _selectedUserType = 'animal'; // 'animal' o 'veterinario'

  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoScale;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animaciones
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Iniciar animaciones
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _fadeController.forward();
    });
  }
  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }  Future<Map<String, dynamic>?> _fetchUserWithRetry(String tableName, String email) async {
    // Implementar mecanismo de reintento
    int maxRetries = 3;
    int retryCount = 0;
    int retryDelayMs = 1000; // 1 segundo inicial
    
    while (retryCount < maxRetries) {
      try {
        print('🔄 Intento ${retryCount + 1} de $maxRetries para buscar usuario...');
        
        // Usar headers específicos para mejorar CORS en Flutter Web
        final response = await Supabase.instance.client
            .from(tableName)
            .select('*')  // Especificar explícitamente qué seleccionar
            .eq('correo', email)
            .maybeSingle();
            
        return response;
      } catch (e) {
        retryCount++;
        print('🔄 Error en intento $retryCount: $e');
        
        if (retryCount >= maxRetries) {
          print('❌ Se agotaron los reintentos');
          rethrow; // Propagar la excepción después del último reintento
        }
        
        // Esperar con backoff exponencial antes de reintentar
        await Future.delayed(Duration(milliseconds: retryDelayMs));
        retryDelayMs *= 2; // Backoff exponencial
      }
    }
    
    return null;
  }

  // Verificar la conectividad con Supabase antes de intentar login
  Future<bool> _checkSupabaseConnectivity() async {
    try {
      // Intentamos una operación simple para verificar conectividad
      await Supabase.instance.client
          .from('_no_table') // Esta tabla no existe, solo queremos ver si hay conexión
          .select()
          .limit(1)
          .maybeSingle();
      
      return true; // Si llegamos aquí, hay conectividad (aunque dará error 404)
    } catch (e) {
      // Si el error es 404, significa que hay conexión pero la tabla no existe
      if (e.toString().contains('404') || e.toString().contains('not_found')) {
        return true;
      }
      
      // Cualquier otro error podría indicar problemas de conectividad
      print('⚠️ Problema de conectividad con Supabase: $e');
      return false;
    }
  }
  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        print('🔍 Intentando login para: ${_emailController.text.trim()}');
        print('🔍 Tipo de usuario: $_selectedUserType');
        
        // Verificar conectividad con Supabase primero
        bool isConnected = await _checkSupabaseConnectivity();
        if (!isConnected) {
          print('⚠️ No hay conectividad con Supabase');
          throw Exception('No se puede conectar a Supabase. Verifica tu conexión a internet.');
        }
        
        // Verificar credenciales en la tabla correspondiente
        final tableName = _selectedUserType == 'veterinario' ? 'veterinarios' : 'animales';
        
        // Primero buscar el usuario por correo con reintentos
        final userRecord = await _fetchUserWithRetry(
          tableName, 
          _emailController.text.trim()
        );

        if (userRecord != null) {
          print('🔍 Usuario encontrado: ${userRecord['nombre']}');
          
          // Verificar contraseña usando la función verify_password de la base de datos
          final passwordCheck = await Supabase.instance.client
              .rpc('verify_password', params: {
                'input_password': _passwordController.text,
                'stored_password': userRecord['contraseña']
              });
          
          print('🔑 Verificación de contraseña: $passwordCheck');
            if (passwordCheck == true) {
            print('✅ Login exitoso');
            
            // Guardar sesión si "Recuérdame" está marcado
            if (_rememberMe) {
              await UserPreferences.saveUserSession(
                userData: userRecord,
                userType: _selectedUserType,
              );
            }
            
            // Crear una sesión ficticia para navegación (sin autenticación real de Supabase)
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Text('¡Bienvenido ${userRecord['nombre']}!'),
                    ],
                  ),
                  backgroundColor: const Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              
              // Navegar según el tipo de usuario
              if (_selectedUserType == 'animal') {
                // Navegar al menú específico para animales
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => MenuAnimal(userData: userRecord),
                  ),
                );
              } else {
                // Navegar al menú específico para veterinarios
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => MenuVeterinario(userData: userRecord),
                  ),
                );
              }
            }
          } else {
            print('❌ Contraseña incorrecta');
            // Contraseña incorrecta
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 12),
                      const Text('Contraseña incorrecta'),
                    ],
                  ),
                  backgroundColor: Colors.red[700],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          }
        } else {
          print('❌ Usuario no encontrado');
          // Usuario no encontrado
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text('Correo no encontrado'),
                  ],
                ),
                backgroundColor: Colors.red[700],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }      } catch (e) {
        print('🚨 Error en login: $e');
        
        // Para evitar problemas en desarrollo, verificamos credenciales comunes
        // Esto es solo para desarrollo/pruebas, en producción debería quitarse
        if (e.toString().contains('Failed to fetch') && 
            _emailController.text.trim() == 'goyo@gmail.com' && 
            _passwordController.text == '123456') {
          
          print('⚠️ Error de conexión detectado, pero usando credenciales conocidas para desarrollo');
            // Crear datos de usuario mock para poder continuar 
          // Esto es solo para desarrollo, QUITAR EN PRODUCCIÓN
          if (_selectedUserType == 'animal') {
            final mockUserData = {
              'id': 'f0eebc99-9c0b-4ef8-bb6d-6bb9bd380a16',  // UUID de prueba
              'nombre': 'Max (Modo Desarrollo)',
              'correo': 'goyo@gmail.com',
              'foto_url': 'https://example.com/animal1.jpg',
              'ubicacion': 'Madrid',
              'tipo': 'Perro',
              'raza': 'Labrador Retriever',
              'edad': '3 años',
              'altura': '60 cm',
            };
            
            // Guardar sesión si "Recuérdame" está marcado
            if (_rememberMe) {
              await UserPreferences.saveUserSession(
                userData: mockUserData,
                userType: _selectedUserType,
              );
            }
            
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => MenuAnimal(userData: mockUserData),
              ),
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Iniciando sesión en modo de desarrollo (sin conexión)'),
                backgroundColor: Colors.orange,
              ),
            );
            return;          } else if (_emailController.text.trim() == 'carlos.martinez@goyo.vet' && 
                     _passwordController.text == '123456') {
            final mockVetData = {
              'id': 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
              'nombre': 'Dr. Carlos Martínez (Modo Desarrollo)',
              'correo': 'carlos.martinez@goyo.vet',
              'foto_url': 'https://example.com/veterinario1.jpg',
              'ubicacion': 'Madrid',
              'especialidad': 'Perro',
              'numero_colegiado': 'MAD-001',
              'años_experiencia': 15,
              'telefono': '+34 600 123 456',
            };
            
            // Guardar sesión si "Recuérdame" está marcado
            if (_rememberMe) {
              await UserPreferences.saveUserSession(
                userData: mockVetData,
                userType: _selectedUserType,
              );
            }
            
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => MenuVeterinario(userData: mockVetData),
              ),
            );
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Iniciando sesión en modo de desarrollo (sin conexión)'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
        }
        
        // Mensaje de error más específico según el tipo de error
        String errorMessage = 'Error en el inicio de sesión';
        
        if (e.toString().contains('Failed to fetch')) {
          errorMessage = 'Error de conexión a la base de datos. Verifica tu conexión a internet.';
        } else if (e.toString().contains('permission denied')) {
          errorMessage = 'Permisos insuficientes. Verifica que RLS esté desactivado en Supabase.';
        } else if (e.toString().contains('too many requests')) {
          errorMessage = 'Demasiadas solicitudes. Espera un momento e inténtalo de nuevo.';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 8),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController emailResetController = TextEditingController();
        bool isLoadingReset = false;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              title: Container(
                padding: const EdgeInsets.only(bottom: 10),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF2E7D32), width: 2),
                  ),
                ),
                child: const Text(
                  'Recuperar Contraseña',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: emailResetController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.email, color: Color(0xFF2E7D32)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoadingReset ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoadingReset ? null : () async {
                    if (emailResetController.text.isNotEmpty) {
                      setState(() {
                        isLoadingReset = true;
                      });
                      try {
                        await Supabase.instance.client.auth.resetPasswordForEmail(
                          emailResetController.text.trim()
                        );
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 12),
                                const Text('Correo de recuperación enviado'),
                              ],
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(child: Text('Error: ${e.toString()}')),
                              ],
                            ),
                            backgroundColor: Colors.red[700],
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      } finally {
                        setState(() {
                          isLoadingReset = false;
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: isLoadingReset 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Enviar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400,
                minHeight: 540,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo circular sin bordes blancos ni padding
                    AnimatedBuilder(
                      animation: _logoScale,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.07),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                                width: 110,
                                height: 110,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.pets,
                                    size: 60,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    // Título y subtítulo
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Color(0xFFE8F5E8)],
                            ).createShader(bounds),
                            child: const Text(
                              'GOYO',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 7,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 6,
                                    color: Colors.black38,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sistema Veterinario',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.92),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Formulario compacto con glassmorphism
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.22),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.13),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),                        child: Column(
                          children: [
                            // Selector de tipo de usuario
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.13),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.22),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedUserType = 'animal';
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _selectedUserType == 'animal'
                                              ? const Color(0xFF2E7D32)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.pets,
                                              color: _selectedUserType == 'animal'
                                                  ? Colors.white
                                                  : Colors.white.withOpacity(0.7),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Mascota',
                                              style: TextStyle(
                                                color: _selectedUserType == 'animal'
                                                    ? Colors.white
                                                    : Colors.white.withOpacity(0.7),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedUserType = 'veterinario';
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _selectedUserType == 'veterinario'
                                              ? const Color(0xFF2E7D32)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.local_hospital,
                                              color: _selectedUserType == 'veterinario'
                                                  ? Colors.white
                                                  : Colors.white.withOpacity(0.7),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Veterinario',
                                              style: TextStyle(
                                                color: _selectedUserType == 'veterinario'
                                                    ? Colors.white
                                                    : Colors.white.withOpacity(0.7),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Correo
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu correo';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Ingresa un correo válido';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Correo electrónico',
                                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF2E7D32)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.08),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Contraseña
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu contraseña';
                                }
                                if (value.length < 6) {
                                  return 'La contraseña debe tener al menos 6 caracteres';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2E7D32)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.08),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Opciones adicionales
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                      activeColor: const Color(0xFF2E7D32),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    const Text(
                                      'Recuérdame',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: _forgotPassword,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text(
                                    '¿Olvidaste tu contraseña?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Botón de login
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 7,
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text('INICIAR SESIÓN'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Enlace de registro
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿No tienes cuenta? ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.93),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          GestureDetector(                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => const RegisterMenu(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return SlideTransition(
                                      position: animation.drive(
                                        Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(
                                          CurveTween(curve: Curves.easeInOut),
                                        ),
                                      ),
                                      child: child,
                                    );
                                  },
                                  transitionDuration: const Duration(milliseconds: 300),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.white, Color(0xFFF8F8F8)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.10),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Regístrate',
                                style: TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}