import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'services/supabase_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui';
import 'register_menu.dart';

class RegisterAnimal extends StatefulWidget {
  const RegisterAnimal({super.key});

  @override
  State<RegisterAnimal> createState() => _RegisterAnimalState();
}

class _RegisterAnimalState extends State<RegisterAnimal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _locationController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();

  String? _selectedAnimalType;
  String? _selectedBreed;
  XFile? _selectedImage;
  Uint8List? _webImage;
  bool _isLoading = false;

  // Datos de tipos de animales y sus razas
  final Map<String, List<String>> _animalBreeds = {
    'Perro': [
      'Labrador Retriever', 'Pastor Alemán', 'Golden Retriever', 'Bulldog Francés',
      'Beagle', 'Poodle', 'Rottweiler', 'Yorkshire Terrier', 'Bichón Maltes','Dachshund',
      'Boxer', 'Husky Siberiano', 'Border Collie', 'Chihuahua', 'Mestizo'
    ],
    'Gato': [
      'Persa', 'Maine Coon', 'Siamés', 'Ragdoll', 'Bengalí', 'Abisinio',
      'Británico de Pelo Corto', 'Sphynx', 'Russian Blue', 'Mestizo'
    ],
    'Pájaro': [
      'Canario', 'Periquito', 'Cacatúa', 'Loro Gris Africano', 'Agapornis',
      'Ninfa', 'Jilguero', 'Diamante Mandarín', 'Loro Amazónico'
    ],
    'Caballo': [
      'Pura Sangre', 'Cuarto de Milla', 'Árabe', 'Andaluz', 'Frisón',
      'Appaloosa', 'Paint Horse', 'Mustang', 'Clydesdale'
    ],
    'Conejo': [
      'Holandés', 'Angora', 'Lop', 'Rex', 'Flemish Giant', 'Mini Rex',
      'Lionhead', 'Dutch', 'Californiano'
    ],
    'Hamster': [
      'Sirio', 'Ruso', 'Chino', 'Roborovski', 'Campbell'
    ],
    'Pez': [
      'Goldfish', 'Betta', 'Guppy', 'Neon Tetra', 'Ángel', 'Molly',
      'Platy', 'Corydora', 'Disco'
    ],
    'Reptil': [
      'Iguana Verde', 'Gecko Leopardo', 'Pitón Ball', 'Tortuga Rusa',
      'Dragón Barbudo', 'Camaleón', 'Boa Constrictor'
    ]
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _locationController.dispose();
    _ageController.dispose();
    _heightController.dispose();
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
          // Para web, usar bytes
          final bytes = await image.readAsBytes();
          setState(() {
            _webImage = bytes;
            _selectedImage = null;
          });
        } else {
          // Para móvil, usar XFile
          setState(() {
            _selectedImage = image;
            _webImage = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }

  void _registerAnimal() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedAnimalType == null || _selectedBreed == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona el tipo y raza del animal'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Verificar si el correo ya existe
        final emailExists = await SupabaseService.checkEmailExists(_emailController.text, 'animales');
        if (emailExists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este correo ya está registrado'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Subir imagen a Supabase Storage (opcional)
        String? imageUrl;
        if (_selectedImage != null || _webImage != null) {
          print('🔄 Subiendo imagen...');
          try {
            if (kIsWeb && _webImage != null) {
              imageUrl = await SupabaseService.uploadImageBytes(
                _webImage!,
                'animal-photos',
                _nameController.text.toLowerCase().replaceAll(' ', '_'),
                'jpg',
              );
            } else if (_selectedImage != null) {
              final bytes = await _selectedImage!.readAsBytes();
              final fileExt = _selectedImage!.path.split('.').last;
              imageUrl = await SupabaseService.uploadImageBytes(
                bytes,
                'animal-photos',
                _nameController.text.toLowerCase().replaceAll(' ', '_'),
                fileExt,
              );
            }
            
            if (imageUrl != null) {
              print('✅ Imagen subida exitosamente');
            } else {
              print('⚠️ No se pudo subir la imagen, continuando sin ella');
            }
          } catch (e) {
            print('⚠️ Error subiendo imagen: $e - Continuando sin imagen');
            imageUrl = null;
          }
        } else {
          print('ℹ️ No se seleccionó imagen, registrando sin foto');
        }

        // Registrar animal en la base de datos
        final result = await SupabaseService.registerAnimal(
          nombre: _nameController.text.trim(),
          correo: _emailController.text.trim(),
          password: _passwordController.text,
          ubicacion: _locationController.text.trim(),
          tipo: _selectedAnimalType!,
          raza: _selectedBreed!,
          edad: _ageController.text.trim(),
          altura: _heightController.text.trim(),
          fotoUrl: imageUrl,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('Animal "${_nameController.text}" registrado exitosamente'),
                  ],
                ),
                backgroundColor: const Color(0xFF2E7D32),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );

            // Navegar al login después de un breve delay
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al registrar el animal. Inténtalo de nuevo.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  SizedBox(height: 18),
                  // Header compacto
                  Container(
                    margin: EdgeInsets.only(bottom: 10),
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                      border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icon/goyo_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.pets,
                            size: 40,
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFE8F5E8)],
                    ).createShader(bounds),
                    child: const Text(
                      'Registro de Animal',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 3,
                        shadows: [
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
                  SizedBox(height: 6),
                  Text(
                    'Crea tu perfil de mascota',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.92),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 18),
                  
                  // Foto del animal (opcional)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: (_selectedImage != null || _webImage != null)
                            ? Colors.greenAccent.withOpacity(0.7)
                            : Colors.white.withOpacity(0.22),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      backgroundBlendMode: BlendMode.luminosity,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Foto de la Mascota',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
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
                        SizedBox(height: 12),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: Colors.white.withOpacity(0.1),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: (_selectedImage != null || _webImage != null)
                                      ? (kIsWeb && _webImage != null)
                                          ? Image.memory(
                                              _webImage!,
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 100,
                                            )
                                          : _selectedImage != null
                                              ? FutureBuilder<Uint8List>(
                                                  future: _selectedImage!.readAsBytes(),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasData) {
                                                      return Image.memory(
                                                        snapshot.data!,
                                                        fit: BoxFit.cover,
                                                        width: 100,
                                                        height: 100,
                                                      );
                                                    }
                                                    return const Icon(
                                                      Icons.pets,
                                                      size: 35,
                                                      color: Colors.white70,
                                                    );
                                                  },
                                                )
                                              : const Icon(
                                                  Icons.pets,
                                                  size: 35,
                                                  color: Colors.white70,
                                                )
                                      : const Icon(
                                          Icons.add_photo_alternate,
                                          size: 35,
                                          color: Colors.white70,
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
                        ),
                        if (_selectedImage == null && _webImage == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              'Opcional',
                              style: TextStyle(
                                color: Colors.blue[200],
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Formulario
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(24),
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
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: 'Nombre del Animal',
                              hint: 'Ej: Max, Luna, Firulais',
                              icon: Icons.pets,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'El nombre es obligatorio';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 10),
                            _buildTextField(
                              controller: _emailController,
                              label: 'Correo del Propietario',
                              hint: 'Ej: propietario@gmail.com',
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
                            SizedBox(height: 10),
                            _buildTextField(
                              controller: _passwordController,
                              label: 'Contraseña',
                              hint: 'Mínimo 6 caracteres',
                              icon: Icons.lock,
                              isPassword: true,
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
                            SizedBox(height: 10),
                            _buildTextField(
                              controller: _locationController,
                              label: 'Ubicación',
                              hint: 'Ej: Madrid, Barcelona, Valencia',
                              icon: Icons.location_on,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'La ubicación es obligatoria';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 10),
                            
                            // Tipo de animal
                            _buildDropdown(
                              value: _selectedAnimalType,
                              label: 'Tipo de Animal',
                              hint: 'Selecciona el tipo',
                              icon: Icons.category,
                              items: _animalBreeds.keys.toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedAnimalType = value;
                                  _selectedBreed = null;
                                });
                              },
                            ),
                            SizedBox(height: 10),
                            
                            // Raza
                            if (_selectedAnimalType != null)
                              _buildDropdown(
                                value: _selectedBreed,
                                label: 'Raza',
                                hint: 'Selecciona la raza',
                                icon: Icons.pets_outlined,
                                items: _animalBreeds[_selectedAnimalType] ?? [],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedBreed = value;
                                  });
                                },
                              ),
                            if (_selectedAnimalType != null) SizedBox(height: 10),
                            
                            // Edad y Altura
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _ageController,
                                    label: 'Edad',
                                    hint: '2 años, 6 meses...',
                                    icon: Icons.cake,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'La edad es obligatoria';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _heightController,
                                    label: 'Altura',
                                    hint: '50 cm, 1.2 metros...',
                                    icon: Icons.height,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'La altura es obligatoria';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 18),
                            
                            // Botón registrar
                            SizedBox(
                              width: double.infinity,
                              height: 38,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _registerAnimal,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 10,
                                  shadowColor: Colors.greenAccent.withOpacity(0.32),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.0,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                                          SizedBox(width: 8),
                                          const Text('Registrar Animal'),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 18),
                ],
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
    String? Function(String?)? validator,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
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
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      style: const TextStyle(color: Colors.white, fontSize: 16),
      dropdownColor: const Color(0xFF1B5E20),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
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
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items.map((String item) => DropdownMenuItem<String>(
          value: item,
          child: Text(item, style: const TextStyle(color: Colors.white)),
        )).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Este campo es obligatorio';
        }
        return null;
      },
    );
  }
}
