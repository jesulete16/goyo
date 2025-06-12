import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'register_menu.dart';
import 'login.dart';
import 'widgets/flutter_web_wrapper.dart';

class RegisterVeterinario extends StatefulWidget {
  const RegisterVeterinario({super.key});

  @override
  State<RegisterVeterinario> createState() => _RegisterVeterinarioState();
}

class _RegisterVeterinarioState extends State<RegisterVeterinario> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _locationController = TextEditingController();
  final _collegeNumberController = TextEditingController();
  final _experienceController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String? _selectedSpecialty;
  XFile? _selectedImage;
  Uint8List? _webImage;
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Especialidades veterinarias según el esquema de la base de datos
  final List<String> _specialties = [
    'General',
    'Perro',
    'Gato',
    'Pájaro',
    'Caballo',
    'Conejo',
    'Hamster',
    'Pez',
    'Reptil',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _locationController.dispose();
    _collegeNumberController.dispose();
    _experienceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webImage = bytes;
            _selectedImage = null;
          });
        } else {
          setState(() {
            _selectedImage = image;
            _webImage = null;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Error al seleccionar imagen: $e', isError: true);
    }
  }
  Future<String?> _uploadImage() async {
    try {
      if (_webImage == null && _selectedImage == null) return null;

      final supabase = Supabase.instance.client;
      
      // Generar nombre único para el archivo
      final String fileName = 'vet_${DateTime.now().millisecondsSinceEpoch}_${_nameController.text.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')}';
      
      Uint8List imageBytes;
      String fileExtension = 'jpg';
      
      if (kIsWeb && _webImage != null) {
        imageBytes = _webImage!;      } else if (_selectedImage != null) {
        imageBytes = await _selectedImage!.readAsBytes();
        final String originalExtension = _selectedImage!.path.split('.').last.toLowerCase();
        if (['jpg', 'jpeg', 'png', 'webp'].contains(originalExtension)) {
          fileExtension = originalExtension;
        }
      } else {
        return null;
      }

      final String fullFileName = '$fileName.$fileExtension';
      
      // Intentar subir a storage con manejo de errores mejorado
      try {
        await supabase.storage
            .from('veterinario-photos')
            .uploadBinary(
              fullFileName,
              imageBytes,
              fileOptions: FileOptions(
                cacheControl: '3600',
                upsert: true, // Permitir sobrescribir si existe
                contentType: 'image/$fileExtension',
              ),
            );
      } catch (storageError) {
        print('Error de storage: $storageError');
        
        // Si falla el primer intento, intentar con un bucket público o crear el archivo
        if (storageError.toString().contains('row-level security') || 
            storageError.toString().contains('Unauthorized')) {
          
          // Intentar con un nombre más simple
          final String simpleFileName = 'vet_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
          
          await supabase.storage
              .from('veterinario-photos')
              .uploadBinary(
                simpleFileName,
                imageBytes,
                fileOptions: FileOptions(
                  cacheControl: '3600',
                  upsert: true,
                  contentType: 'image/$fileExtension',
                ),
              );
          
          final String publicUrl = supabase.storage
              .from('veterinario-photos')
              .getPublicUrl(simpleFileName);
          
          return publicUrl;
        } else {
          rethrow;
        }
      }

      final String publicUrl = supabase.storage
          .from('veterinario-photos')
          .getPublicUrl(fullFileName);

      return publicUrl;
    } catch (e) {
      print('Error general uploading image: $e');
      
      // Si todo falla, devolver una URL por defecto o null
      if (e.toString().contains('row-level security') || 
          e.toString().contains('Unauthorized')) {
        print('Problema de permisos de storage, continuando sin imagen...');
        return null; // Permitir registro sin imagen en caso de problemas de permisos
      }
      
      return null;
    }
  }

  Future<bool> _checkEmailExists(String email) async {
    try {
      final response = await Supabase.instance.client
          .from('veterinarios')
          .select('correo')
          .eq('correo', email)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }
  void _registerVeterinario() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSpecialty == null) {
      _showSnackBar('Por favor selecciona una especialidad', isError: true);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Las contraseñas no coinciden', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar si el correo ya existe
      final emailExists = await _checkEmailExists(_emailController.text.trim());
      if (emailExists) {
        _showSnackBar('Este correo ya está registrado', isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Intentar subir imagen (opcional)
      String? imageUrl;
      if (_selectedImage != null || _webImage != null) {
        try {
          imageUrl = await _uploadImage();
          if (imageUrl == null) {
            _showSnackBar('Advertencia: No se pudo subir la imagen, pero el registro continuará', isError: false);
          }
        } catch (e) {
          print('Error al subir imagen, continuando sin ella: $e');
          _showSnackBar('Advertencia: Problema con la imagen, registrando sin foto', isError: false);
        }
      }      // Registrar veterinario en la base de datos
      print('🔵 Iniciando registro de veterinario...');
      print('📧 Email: ${_emailController.text.trim()}');
      print('👤 Nombre: ${_nameController.text.trim()}');
      print('🏥 Especialidad: $_selectedSpecialty');
      
      final veterinarioData = {
        'nombre': _nameController.text.trim(),
        'correo': _emailController.text.trim(),
        'contraseña': _passwordController.text, // Se encriptará automáticamente por el trigger
        'ubicacion': _locationController.text.trim(),
        'especialidad': _selectedSpecialty!,
        'numero_colegiado': _collegeNumberController.text.trim(),
        'años_experiencia': int.parse(_experienceController.text.trim()),
        'telefono': _phoneController.text.trim(),
        'foto_url': imageUrl,
      };
      
      print('📝 Datos a insertar: $veterinarioData');
      
      final response = await Supabase.instance.client
          .from('veterinarios')
          .insert(veterinarioData);
      
      print('✅ Respuesta de Supabase: $response');
      print('🎉 Veterinario registrado exitosamente en la base de datos');if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        _showSnackBar('Veterinario "${_nameController.text}" registrado exitosamente');
        
        // Navegar al login después de un breve delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          // Usar Navigator.pushReplacement en lugar de pushNamedAndRemoveUntil para mejor compatibilidad web
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const FlutterWebWrapper(child: LoginScreen()),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        _showSnackBar('Error al registrar: ${e.toString()}', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[700] : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: const Color(0xFF0D2818),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Botón volver arriba a la izquierda
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 26),
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const RegisterMenu(),
                            ),
                          );
                        },
                        tooltip: 'Volver',
                      ),
                    ),
                    // Header compacto dentro del scroll
                    SizedBox(height: isDesktop ? 18 : 10),
                    Container(
                      margin: EdgeInsets.only(bottom: isDesktop ? 10 : 6),
                      width: isDesktop ? 70 : 54,
                      height: isDesktop ? 70 : 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.07),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          width: isDesktop ? 70 : 54,
                          height: isDesktop ? 70 : 54,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.pets,
                              size: isDesktop ? 40 : 32,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: isDesktop ? 10 : 6),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Color(0xFFE8F5E8)],
                      ).createShader(bounds),
                      child: Text(
                        'Registro de Veterinario',
                        style: TextStyle(
                          fontSize: isDesktop ? 22 : 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 3,
                          shadows: const [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 6,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 6 : 3),
                    Text(
                      'Crea tu perfil profesional',
                      style: TextStyle(
                        fontSize: isDesktop ? 13 : 10,
                        color: Colors.white.withOpacity(0.92),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isDesktop ? 18 : 10),
                    // Foto de perfil
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: EdgeInsets.all(isDesktop ? 14 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(isDesktop ? 24 : 18),
                        border: Border.all(
                          color: (_selectedImage != null || _webImage != null)
                              ? Colors.greenAccent.withOpacity(0.7)
                              : Colors.white.withOpacity(0.22),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.16),
                            blurRadius: isDesktop ? 24 : 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        backgroundBlendMode: BlendMode.luminosity,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Foto de Perfil',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isDesktop ? 15 : 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.7,
                              shadows: const [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isDesktop ? 10 : 7),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 350),
                                  width: isDesktop ? 70 : 54,
                                  height: isDesktop ? 70 : 54,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.13),
                                    borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
                                    border: Border.all(
                                      color: (_selectedImage != null || _webImage != null)
                                          ? Colors.greenAccent.withOpacity(0.7)
                                          : Colors.white.withOpacity(0.22),
                                      width: 2.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.10),
                                        blurRadius: isDesktop ? 12 : 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(isDesktop ? 14 : 10),
                                    child: (_selectedImage != null || _webImage != null)
                                        ? (kIsWeb && _webImage != null
                                            ? Image.memory(
                                                _webImage!,
                                                width: isDesktop ? 70 : 54,
                                                height: isDesktop ? 70 : 54,
                                                fit: BoxFit.cover,
                                              )
                                            : FutureBuilder<Uint8List>(
                                                future: _selectedImage!.readAsBytes(),
                                                builder: (context, snapshot) {
                                                  if (snapshot.hasData) {
                                                    return Image.memory(
                                                      snapshot.data!,
                                                      width: isDesktop ? 70 : 54,
                                                      height: isDesktop ? 70 : 54,
                                                      fit: BoxFit.cover,
                                                    );
                                                  } else {
                                                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                                                  }
                                                },
                                              ))
                                        : Center(
                                            child: Icon(
                                              Icons.person_outline_rounded,
                                              size: isDesktop ? 32 : 24,
                                              color: Colors.white.withOpacity(0.7),
                                            ),
                                          ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    opacity: 1.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent.withOpacity(0.85),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.18),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(5),
                                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),                          if (_selectedImage == null && _webImage == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                'Opcional',
                                style: TextStyle(
                                  color: Colors.blue[200],
                                  fontSize: isDesktop ? 10 : 9,
                                  fontWeight: FontWeight.w600,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: isDesktop ? 10 : 7),
                    // Card principal glassmorphism premium
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isDesktop ? 18 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(isDesktop ? 24 : 18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.22),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.13),
                            blurRadius: isDesktop ? 24 : 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        backgroundBlendMode: BlendMode.luminosity,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(isDesktop ? 24 : 18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTextField(
                                controller: _nameController,
                                label: 'Nombre Completo',
                                hint: 'Dr. Juan Pérez',
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El nombre es obligatorio';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isDesktop ? 10 : 7),
                              _buildTextField(
                                controller: _emailController,
                                label: 'Correo Electrónico',
                                hint: 'ejemplo@veterinaria.com',
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El correo es obligatorio';
                                  }
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                    return 'Ingresa un correo válido';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isDesktop ? 10 : 7),
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Contraseña',
                                hint: 'Mínimo 6 caracteres',
                                icon: Icons.lock,
                                isPassword: true,
                                isPasswordVisible: _passwordVisible,
                                onTogglePassword: () => setState(() => _passwordVisible = !_passwordVisible),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'La contraseña es obligatoria';
                                  }
                                  if (value.length < 6) {
                                    return 'La contraseña debe tener al menos 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isDesktop ? 10 : 7),
                              _buildTextField(
                                controller: _confirmPasswordController,
                                label: 'Confirmar Contraseña',
                                hint: 'Repite la contraseña',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                isPasswordVisible: _confirmPasswordVisible,
                                onTogglePassword: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Confirma tu contraseña';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Las contraseñas no coinciden';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isDesktop ? 10 : 7),
                              _buildTextField(
                                controller: _locationController,
                                label: 'Ubicación',
                                hint: 'Madrid, Barcelona, Valencia...',
                                icon: Icons.location_on,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'La ubicación es obligatoria';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isDesktop ? 10 : 7),
                              _buildDropdown(
                                value: _selectedSpecialty,
                                label: 'Especialidad',
                                hint: 'Selecciona tu especialidad',
                                icon: Icons.medical_services,
                                items: _specialties,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSpecialty = value;
                                  });
                                },
                              ),
                              SizedBox(height: isDesktop ? 10 : 7),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _collegeNumberController,
                                      label: 'Nº Colegiado',
                                      hint: 'MAD-001',
                                      icon: Icons.badge,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Número obligatorio';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: isDesktop ? 12 : 7),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _experienceController,
                                      label: 'Años Experiencia',
                                      hint: '5',
                                      icon: Icons.star,
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Campo obligatorio';
                                        }
                                        if (int.tryParse(value) == null) {
                                          return 'Solo números';
                                        }
                                        if (int.parse(value) < 0) {
                                          return 'Debe ser positivo';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isDesktop ? 10 : 7),
                              _buildTextField(
                                controller: _phoneController,
                                label: 'Teléfono',
                                hint: '+34 600 123 456',
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'El teléfono es obligatorio';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: isDesktop ? 18 : 10),
                              // Botón de registro premium
                              SizedBox(
                                width: double.infinity,
                                height: isDesktop ? 38 : 32,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _registerVeterinario,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(isDesktop ? 12 : 10),
                                    ),
                                    elevation: 10,
                                    shadowColor: Colors.greenAccent.withOpacity(0.32),
                                    textStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isDesktop ? 13 : 11,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          width: isDesktop ? 18 : 14,
                                          height: isDesktop ? 18 : 14,
                                          child: const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.0,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                                            SizedBox(width: isDesktop ? 8 : 5),
                                            const Text('Registrarme'),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isDesktop ? 18 : 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool? isPasswordVisible,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && !(isPasswordVisible ?? false),
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
      cursorColor: Colors.greenAccent,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.13),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white70),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  (isPasswordVisible ?? false) ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.greenAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF1B5E20),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.greenAccent),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.13),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white70),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.greenAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Selecciona una especialidad' : null,
    );
  }
}