import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditarPerfilVeterinario extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditarPerfilVeterinario({super.key, required this.userData});

  @override
  State<EditarPerfilVeterinario> createState() => _EditarPerfilVeterinarioState();
}

class _EditarPerfilVeterinarioState extends State<EditarPerfilVeterinario> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _correoController;
  late TextEditingController _telefonoController;
  late TextEditingController _ubicacionController;
  late TextEditingController _numeroColegiadoController;
  late TextEditingController _anosExperienciaController;
  
  String? _especialidadSeleccionada;
  bool _isLoading = false;
  bool _hasChanges = false;

  final List<String> _especialidades = [
    'General',
    'Perro',
    'Gato',
    'Ave',
    'Pez',
    'Reptil',
    'Roedor',
    'Exóticos',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nombreController = TextEditingController(text: widget.userData['nombre'] ?? '');
    _correoController = TextEditingController(text: widget.userData['correo'] ?? '');
    _telefonoController = TextEditingController(text: widget.userData['telefono'] ?? '');
    _ubicacionController = TextEditingController(text: widget.userData['ubicacion'] ?? '');
    _numeroColegiadoController = TextEditingController(text: widget.userData['numero_colegiado'] ?? '');    _anosExperienciaController = TextEditingController(text: widget.userData['años_experiencia']?.toString() ?? '');
    _especialidadSeleccionada = widget.userData['especialidad'] ?? 'General';

    // Detectar cambios en los campos
    _nombreController.addListener(_onFieldChanged);
    _correoController.addListener(_onFieldChanged);
    _telefonoController.addListener(_onFieldChanged);
    _ubicacionController.addListener(_onFieldChanged);
    _numeroColegiadoController.addListener(_onFieldChanged);
    _anosExperienciaController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();    _telefonoController.dispose();
    _ubicacionController.dispose();
    _numeroColegiadoController.dispose();
    _anosExperienciaController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('🔄 Guardando cambios del perfil veterinario...');
      
      final updates = {
        'nombre': _nombreController.text.trim(),
        'correo': _correoController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'ubicacion': _ubicacionController.text.trim(),
        'numero_colegiado': _numeroColegiadoController.text.trim(),
        'años_experiencia': int.tryParse(_anosExperienciaController.text.trim()) ?? 0,
        'especialidad': _especialidadSeleccionada,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await Supabase.instance.client
          .from('veterinarios')
          .update(updates)
          .eq('id', widget.userData['id']);

      print('✅ Perfil actualizado exitosamente');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Devolver los datos actualizados
        Navigator.pop(context, {...widget.userData, ...updates});
      }
    } catch (e) {
      print('❌ Error al actualizar perfil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al actualizar perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _guardarCambios,
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header con avatar
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.local_hospital, color: Color(0xFF1B5E20), size: 50),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Dr. ${_nombreController.text}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _especialidadSeleccionada ?? 'Veterinario',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Formulario
                      _buildFormField(
                        'Nombre Completo',
                        _nombreController,
                        Icons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildFormField(
                        'Correo Electrónico',
                        _correoController,
                        Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El correo es obligatorio';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Ingresa un correo válido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildFormField(
                        'Teléfono',
                        _telefonoController,
                        Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El teléfono es obligatorio';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildFormField(
                        'Ubicación/Clínica',
                        _ubicacionController,
                        Icons.location_on,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La ubicación es obligatoria';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildFormField(
                        'Número de Colegiado',
                        _numeroColegiadoController,
                        Icons.badge,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El número de colegiado es obligatorio';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      _buildFormField(
                        'Años de Experiencia',
                        _anosExperienciaController,
                        Icons.work,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Los años de experiencia son obligatorios';
                          }
                          if (int.tryParse(value) == null || int.parse(value) < 0) {
                            return 'Ingresa un número válido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Dropdown de especialidad
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.medical_services, color: Colors.white.withOpacity(0.8)),
                                const SizedBox(width: 12),
                                const Text(
                                  'Especialidad',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _especialidadSeleccionada,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: _especialidades.map((especialidad) {
                                return DropdownMenuItem(
                                  value: especialidad,
                                  child: Text(especialidad),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _especialidadSeleccionada = value;
                                  _hasChanges = true;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecciona una especialidad';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Botones de acción
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading || !_hasChanges ? null : _guardarCambios,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Guardar Cambios',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.8)),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
