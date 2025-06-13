import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class PerfilAnimal extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onUserDataUpdated;

  const PerfilAnimal({
    super.key,
    required this.userData,
    required this.onUserDataUpdated,
  });

  @override
  State<PerfilAnimal> createState() => _PerfilAnimalState();
}

class _PerfilAnimalState extends State<PerfilAnimal> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _correoController;
  late TextEditingController _ubicacionController;
  late TextEditingController _razaController;
  late TextEditingController _edadController;
  late TextEditingController _alturaController;
  late TextEditingController _contrasenaController;
  
  String? _tipoSeleccionado;
  bool _isLoading = false;
  bool _isEditingPassword = false;
  String? _nuevaFotoUrl;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Lista de tipos de animales disponibles
  final List<String> tiposAnimales = [
    'Perro',
    'Gato', 
    'Pájaro',
    'Conejo',
    'Caballo',
    'Otro'
  ];

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores con datos actuales
    _nombreController = TextEditingController(text: widget.userData['nombre'] ?? '');
    _correoController = TextEditingController(text: widget.userData['correo'] ?? '');
    _ubicacionController = TextEditingController(text: widget.userData['ubicacion'] ?? '');
    _razaController = TextEditingController(text: widget.userData['raza'] ?? '');
    _edadController = TextEditingController(text: widget.userData['edad'] ?? '');
    _alturaController = TextEditingController(text: widget.userData['altura'] ?? '');
    _contrasenaController = TextEditingController();
    
    _tipoSeleccionado = widget.userData['tipo'];
    _nuevaFotoUrl = widget.userData['foto_url'];
    
    // Animación
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
    _nombreController.dispose();
    _correoController.dispose();
    _ubicacionController.dispose();
    _razaController.dispose();
    _edadController.dispose();
    _alturaController.dispose();
    _contrasenaController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 70,
      );
      
      if (image != null) {
        // Aquí podrías subir la imagen a Supabase Storage
        // Por ahora, solo simulamos la URL
        setState(() {
          _nuevaFotoUrl = image.path; // En producción sería la URL de Supabase
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto seleccionada (funcionalidad de subida pendiente)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      print('💾 Guardando cambios del perfil...');
      
      // Preparar datos para actualizar
      Map<String, dynamic> datosActualizados = {
        'nombre': _nombreController.text.trim(),
        'correo': _correoController.text.trim(),
        'ubicacion': _ubicacionController.text.trim(),
        'tipo': _tipoSeleccionado,
        'raza': _razaController.text.trim(),
        'edad': _edadController.text.trim(),
        'altura': _alturaController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Solo incluir foto si se cambió
      if (_nuevaFotoUrl != widget.userData['foto_url']) {
        datosActualizados['foto_url'] = _nuevaFotoUrl;
      }
      
      // Solo incluir contraseña si se está editando
      if (_isEditingPassword && _contrasenaController.text.isNotEmpty) {
        // En producción, deberías hashear la contraseña
        datosActualizados['contraseña'] = _contrasenaController.text;
      }
      
      // Actualizar en Supabase
      await Supabase.instance.client
          .from('animales')
          .update(datosActualizados)
          .eq('id', widget.userData['id']);
      
      // Actualizar datos locales
      Map<String, dynamic> nuevosUserData = Map<String, dynamic>.from(widget.userData);
      nuevosUserData.addAll(datosActualizados);
      
      // Notificar al widget padre
      widget.onUserDataUpdated(nuevosUserData);
      
      print('✅ Perfil actualizado exitosamente');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(nuevosUserData);
      }
    } catch (e) {
      print('🚨 Error actualizando perfil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al actualizar perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D2818),
      body: Container(
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
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(isDesktop ? 20 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        tooltip: 'Volver',
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.edit,
                        color: Colors.blueAccent,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Editar Perfil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      // Botón guardar en el header
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _guardarCambios,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 20 : 16,
                            vertical: isDesktop ? 12 : 10,
                          ),
                        ),
                        icon: _isLoading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(Icons.save, size: 18),
                        label: Text(_isLoading ? 'Guardando...' : 'Guardar'),
                      ),
                    ],
                  ),
                ),
                
                // Formulario
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 24 : 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Foto de perfil
                          _buildFotoPerfilSection(isDesktop),
                          SizedBox(height: isDesktop ? 32 : 24),
                          
                          // Información básica
                          _buildSeccionFormulario(
                            'Información Básica',
                            Icons.info,
                            [
                              _buildCampoTexto(
                                controller: _nombreController,
                                label: 'Nombre',
                                icon: Icons.pets,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'El nombre es obligatorio';
                                  }
                                  return null;
                                },
                              ),
                              _buildCampoTexto(
                                controller: _correoController,
                                label: 'Correo electrónico',
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'El correo es obligatorio';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Ingresa un correo válido';
                                  }
                                  return null;
                                },
                              ),
                              _buildDropdownTipo(),
                            ],
                            isDesktop,
                          ),
                          
                          SizedBox(height: isDesktop ? 24 : 16),
                          
                          // Información física
                          _buildSeccionFormulario(
                            'Información Física',
                            Icons.straighten,
                            [
                              _buildCampoTexto(
                                controller: _razaController,
                                label: 'Raza',
                                icon: Icons.category,
                              ),
                              _buildCampoTexto(
                                controller: _edadController,
                                label: 'Edad',
                                icon: Icons.cake,
                                hint: 'Ej: 3 años',
                              ),
                              _buildCampoTexto(
                                controller: _alturaController,
                                label: 'Altura',
                                icon: Icons.height,
                                hint: 'Ej: 50 cm',
                              ),
                            ],
                            isDesktop,
                          ),
                          
                          SizedBox(height: isDesktop ? 24 : 16),
                          
                          // Ubicación
                          _buildSeccionFormulario(
                            'Ubicación',
                            Icons.location_on,
                            [
                              _buildCampoTexto(
                                controller: _ubicacionController,
                                label: 'Ubicación',
                                icon: Icons.place,
                                hint: 'Ciudad, País',
                              ),
                            ],
                            isDesktop,
                          ),
                          
                          SizedBox(height: isDesktop ? 24 : 16),
                          
                          // Seguridad
                          _buildSeccionSeguridad(isDesktop),
                          
                          SizedBox(height: isDesktop ? 40 : 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFotoPerfilSection(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: isDesktop ? 60 : 50,
                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                backgroundImage: _nuevaFotoUrl != null && _nuevaFotoUrl!.isNotEmpty
                    ? NetworkImage(_nuevaFotoUrl!)
                    : null,
                child: _nuevaFotoUrl == null || _nuevaFotoUrl!.isEmpty
                    ? Icon(
                        Icons.pets,
                        color: Colors.blueAccent,
                        size: isDesktop ? 60 : 50,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _seleccionarFoto,
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    iconSize: isDesktop ? 24 : 20,
                    padding: EdgeInsets.all(isDesktop ? 8 : 6),
                    constraints: BoxConstraints(
                      minWidth: isDesktop ? 40 : 32,
                      minHeight: isDesktop ? 40 : 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 16 : 12),
          Text(
            'Toca el ícono de cámara para cambiar tu foto',
            style: TextStyle(
              color: Colors.white70,
              fontSize: isDesktop ? 14 : 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionFormulario(
    String titulo,
    IconData icono,
    List<Widget> campos,
    bool isDesktop,
  ) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: Colors.blueAccent, size: 24),
              const SizedBox(width: 12),
              Text(
                titulo,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 20 : 16),
          ...campos.map((campo) => Padding(
            padding: EdgeInsets.only(bottom: isDesktop ? 16 : 12),
            child: campo,
          )),
        ],
      ),
    );
  }

  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        suffixIcon: suffix,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownTipo() {
    return DropdownButtonFormField<String>(
      value: _tipoSeleccionado,
      style: const TextStyle(color: Colors.white),
      dropdownColor: const Color(0xFF1B5E20),
      decoration: InputDecoration(
        labelText: 'Tipo de animal',
        prefixIcon: const Icon(Icons.pets, color: Colors.blueAccent),
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      items: tiposAnimales.map((tipo) => DropdownMenuItem(
        value: tipo,
        child: Text(tipo, style: const TextStyle(color: Colors.white)),
      )).toList(),
      onChanged: (value) {
        setState(() {
          _tipoSeleccionado = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Selecciona el tipo de animal';
        }
        return null;
      },
    );
  }

  Widget _buildSeccionSeguridad(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: Colors.blueAccent, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Seguridad',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: _isEditingPassword,
                onChanged: (value) {
                  setState(() {
                    _isEditingPassword = value;
                    if (!value) {
                      _contrasenaController.clear();
                    }
                  });
                },
                activeColor: Colors.blueAccent,
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 12 : 8),
          Text(
            _isEditingPassword 
                ? 'Ingresa una nueva contraseña'
                : 'Activa el interruptor para cambiar tu contraseña',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (_isEditingPassword) ...[
            SizedBox(height: isDesktop ? 20 : 16),
            _buildCampoTexto(
              controller: _contrasenaController,
              label: 'Nueva contraseña',
              icon: Icons.lock,
              obscureText: true,
              validator: (value) {
                if (_isEditingPassword && (value == null || value.length < 6)) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }
}
