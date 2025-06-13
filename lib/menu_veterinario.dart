import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'login.dart';
import 'solicitudes_veterinario.dart';
import 'editar_perfil_veterinario.dart';
import 'services/user_preferences.dart';

class MenuVeterinario extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MenuVeterinario({super.key, required this.userData});

  @override
  State<MenuVeterinario> createState() => _MenuVeterinarioState();
}

class _MenuVeterinarioState extends State<MenuVeterinario> with TickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _citasCalendario = {};
  List<Map<String, dynamic>> _citasDelDia = [];
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _conteoSolicitudesPendientes = 0;
  
  // Datos actualizables del veterinario
  late Map<String, dynamic> _veterinarioData;
  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    
    // Inicializar datos del veterinario
    _veterinarioData = Map<String, dynamic>.from(widget.userData);
    
    // Inicializar localización para fechas en español
    initializeDateFormatting('es_ES', null);
    
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
    
    _loadCitasVeterinario();
    _loadConteoSolicitudes();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCitasVeterinario() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔍 Cargando citas del veterinario: ${widget.userData['id']}');
      
      final response = await Supabase.instance.client
          .from('citas')
          .select('''
            id,
            fecha,
            hora_inicio,
            hora_fin,
            motivo,
            estado,
            precio,
            created_at,
            animales!inner(
              id,
              nombre,
              tipo,
              raza,
              correo
            )
          ''')
          .eq('veterinario_id', widget.userData['id'])
          .order('fecha', ascending: true)
          .order('hora_inicio', ascending: true);
      
      print('📋 Citas encontradas: ${response.length}');
      
      // Organizar citas por fecha
      Map<DateTime, List<Map<String, dynamic>>> citasPorFecha = {};
      
      for (var cita in response) {
        DateTime fechaCita = DateTime.parse(cita['fecha']);
        DateTime fechaSinHora = DateTime(fechaCita.year, fechaCita.month, fechaCita.day);
        
        if (citasPorFecha[fechaSinHora] == null) {
          citasPorFecha[fechaSinHora] = [];
        }
        citasPorFecha[fechaSinHora]!.add(cita);
      }
        setState(() {
        _citasCalendario = citasPorFecha;
        _isLoading = false;
        _errorMessage = null;
        // Cargar citas del día seleccionado
        _loadCitasDelDia(_selectedDay ?? DateTime.now());
      });
      
      // También actualizar el conteo de solicitudes
      _loadConteoSolicitudes();
    } catch (e) {
      print('🚨 Error cargando citas: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar citas: ${e.toString()}';
      });
    }
  }

  Future<void> _loadConteoSolicitudes() async {
    try {
      final response = await Supabase.instance.client
          .from('citas')
          .select('id')
          .eq('veterinario_id', widget.userData['id'])
          .eq('estado', 'pendiente');
      
      setState(() {
        _conteoSolicitudesPendientes = response.length;
      });
      
      print('📊 Solicitudes pendientes encontradas: $_conteoSolicitudesPendientes');
    } catch (e) {
      print('🚨 Error cargando conteo de solicitudes: $e');
    }
  }

  void _loadCitasDelDia(DateTime dia) {
    DateTime diaSinHora = DateTime(dia.year, dia.month, dia.day);
    setState(() {
      _citasDelDia = _citasCalendario[diaSinHora] ?? [];
    });
  }

  List<Map<String, dynamic>> _getCitasDelDia(DateTime dia) {
    DateTime diaSinHora = DateTime(dia.year, dia.month, dia.day);
    return _citasCalendario[diaSinHora] ?? [];
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B5E20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Limpiar sesión guardada
                await UserPreferences.clearUserSession();
                
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _actualizarEstadoCita(String citaId, String nuevoEstado) async {
    try {
      print('🔄 Actualizando cita $citaId a estado: $nuevoEstado');
      
      final response = await Supabase.instance.client
          .from('citas')
          .update({'estado': nuevoEstado})
          .eq('id', citaId)
          .select();
      
      if (response.isNotEmpty) {
        print('✅ Cita actualizada exitosamente');
        // Recargar las citas para mostrar el cambio
        await _loadCitasVeterinario();
        
        // Mostrar mensaje de confirmación
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    nuevoEstado == 'completada' ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    nuevoEstado == 'completada' 
                        ? 'Cita marcada como completada' 
                        : 'Cita cancelada',
                  ),
                ],
              ),
              backgroundColor: nuevoEstado == 'completada' 
                  ? Colors.green 
                  : Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('🚨 Error actualizando cita: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error al actualizar cita: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _mostrarConfirmacionEstado(Map<String, dynamic> cita, String nuevoEstado) {
    final isCompletar = nuevoEstado == 'completada';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B5E20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                isCompletar ? Icons.check_circle : Icons.cancel,
                color: isCompletar ? Colors.greenAccent : Colors.redAccent,
              ),
              const SizedBox(width: 8),
              Text(
                isCompletar ? 'Completar Cita' : 'Cancelar Cita',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que quieres ${isCompletar ? "marcar como completada" : "cancelar"} la cita?',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cita['hora_inicio']} - ${cita['hora_fin']}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Animal: ${cita['animales']?['nombre'] ?? 'Sin nombre'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Motivo: ${cita['motivo'] ?? 'Consulta general'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(              onPressed: () {
                Navigator.of(context).pop();
                _actualizarEstadoCita(cita['id'].toString(), nuevoEstado);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompletar ? Colors.greenAccent : Colors.redAccent,
                foregroundColor: Colors.black,
              ),
              child: Text(isCompletar ? 'Completar' : 'Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileHeader(bool isDesktop) {
    final fotoUrl = _veterinarioData['foto_url'] as String?;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isDesktop ? 32 : 28,
            backgroundColor: Colors.white,
            backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty)
                ? NetworkImage(fotoUrl)
                : null,
            child: (fotoUrl == null || fotoUrl.isEmpty)
                ? const Icon(Icons.person, color: Color(0xFF1B5E20), size: 32)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. ${_veterinarioData['nombre'] ?? ''}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isDesktop ? 18 : 15,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.medical_services, color: Colors.greenAccent, size: isDesktop ? 16 : 13),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _veterinarioData['especialidad'] ?? 'Veterinario',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isDesktop ? 13 : 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: const Color(0xFF0D2818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 4,
        automaticallyImplyLeading: true, // Solo muestra el icono de menú/desplazable
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1B5E20),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header compacto y elegante
            _buildProfileHeader(isDesktop),
            // Botón de editar perfil (VERSIÓN DE PRUEBA)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  print('🔧 Botón Editar Perfil presionado');
                  Navigator.pop(context);
                  
                  // Mostrar mensaje temporal para confirmar que funciona
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Botón de editar perfil funciona! Navegando...'),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 2),
                    ),
                  );
                    // Navegar a la página de editar perfil
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditarPerfilVeterinario(userData: _veterinarioData),
                    ),
                  ).then((result) {
                    if (result != null) {
                      print('🔄 Actualizando datos del veterinario con: $result');
                      setState(() {
                        // Actualizar los datos locales con los datos que vienen del editor
                        _veterinarioData = Map<String, dynamic>.from(result);
                      });
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Perfil actualizado correctamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  });
                },
                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                label: const Text(
                  'Editar Perfil',
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  elevation: 6,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.greenAccent),
              title: const Text('Mi Calendario', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: _buildBadgeIcon(Icons.pending_actions, Colors.orangeAccent, _conteoSolicitudesPendientes),
              title: const Text('Solicitudes', style: TextStyle(color: Colors.white)),              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SolicitudesVeterinario(userData: widget.userData),
                  ),
                );
                // Si hubo cambios en las solicitudes, recargar las citas
                if (result == true) {
                  _loadCitasVeterinario();
                }
              },
            ),
            const Divider(color: Colors.white30),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
              onTap: _logout,
            ),
          ],
        ),
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [                // Header ultra compacto y pequeño
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 14 : 10, vertical: isDesktop ? 10 : 8),
                  margin: EdgeInsets.symmetric(horizontal: isDesktop ? 12 : 8, vertical: isDesktop ? 4 : 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildSmallProfileAvatar(),
                      SizedBox(width: isDesktop ? 12 : 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_veterinarioData['nombre'] ?? 'Dr. Luis Miguel'}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isDesktop ? 16 : 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Row(
                              children: [
                                const Icon(Icons.medical_services, color: Colors.greenAccent, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  _veterinarioData['especialidad'] ?? 'Perro',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: isDesktop ? 11 : 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SolicitudesVeterinario(userData: widget.userData),
                                ),
                              );
                              // Si hubo cambios en las solicitudes, recargar las citas
                              if (result == true) {
                                _loadCitasVeterinario();
                              }
                            },
                            icon: _buildBadgeIcon(Icons.pending_actions, Colors.orangeAccent, _conteoSolicitudesPendientes),
                            tooltip: 'Solicitudes Pendientes',
                          ),
                          IconButton(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout, color: Colors.white70),
                            tooltip: 'Cerrar Sesión',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Contenido principal
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.greenAccent),
                              SizedBox(height: 16),
                              Text(
                                'Cargando calendario...',
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : _errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error, color: Colors.redAccent, size: 64),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadCitasVeterinario,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.greenAccent,
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('Reintentar'),
                                  ),
                                ],
                              ),
                            )                          : SingleChildScrollView(
                              padding: EdgeInsets.all(isDesktop ? 10 : 6),
                              child: Column(
                                children: [
                                  // Calendario
                                  _buildCalendar(isDesktop),
                                  SizedBox(height: isDesktop ? 12 : 8),
                                  // Citas del día seleccionado
                                  _buildCitasDelDia(isDesktop),
                                ],
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
  Widget _buildCalendar(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 10 : 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),child: TableCalendar<Map<String, dynamic>>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: _getCitasDelDia,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          // Días normales
          defaultTextStyle: const TextStyle(color: Colors.white),
          weekendTextStyle: const TextStyle(color: Colors.white70),
          // Día seleccionado
          selectedDecoration: const BoxDecoration(
            color: Colors.greenAccent,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          // Día de hoy
          todayDecoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          // Días con eventos (citas)
          markerDecoration: const BoxDecoration(
            color: Colors.orangeAccent,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          // Fondo del calendario
          outsideDaysVisible: false,
        ),        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white, size: 20),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white, size: 20),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.white70, fontSize: 12),
          weekendStyle: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _loadCitasDelDia(selectedDay);
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildCitasDelDia(bool isDesktop) {
    final fechaSeleccionada = _selectedDay ?? DateTime.now();
      return Container(
      padding: EdgeInsets.all(isDesktop ? 10 : 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 6),
              Text(
                'Citas del ${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 14 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_citasDelDia.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_citasDelDia.length} citas',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isDesktop ? 10 : 8),
          _citasDelDia.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      const Icon(Icons.event_busy, color: Colors.white54, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No hay citas programadas para este día',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isDesktop ? 16 : 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _citasDelDia.length,
                  itemBuilder: (context, index) {
                    final cita = _citasDelDia[index];
                    return _buildCitaCard(cita, isDesktop);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildCitaCard(Map<String, dynamic> cita, bool isDesktop) {
    final animal = cita['animales'];
    final horaInicio = cita['hora_inicio'];
    final horaFin = cita['hora_fin'];
    final estado = cita['estado'];
    final precio = cita['precio'];
    
    // Determinar color según el estado
    Color estadoColor;
    IconData estadoIcon;
    
    switch (estado) {
      case 'programada':
        estadoColor = Colors.orange;
        estadoIcon = Icons.schedule;
        break;
      case 'completada':
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        break;
      case 'cancelada':
        estadoColor = Colors.red;
        estadoIcon = Icons.cancel;
        break;
      case 'confirmada':
        estadoColor = Colors.blue;
        estadoIcon = Icons.verified;
        break;
      default:
        estadoColor = Colors.grey;
        estadoIcon = Icons.help;
    }    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 8 : 6),
      padding: EdgeInsets.all(isDesktop ? 10 : 8),
      decoration: BoxDecoration(
        color: estadoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: estadoColor.withOpacity(0.5),
          width: 1,
        ),        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la cita
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: estadoColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  estadoIcon,
                  color: estadoColor,
                  size: isDesktop ? 16 : 14,
                ),
              ),
              SizedBox(width: isDesktop ? 8 : 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$horaInicio - $horaFin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 13 : 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      animal?['nombre'] ?? 'Animal sin nombre',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isDesktop ? 11 : 9,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: estadoColor,
                  borderRadius: BorderRadius.circular(6),
                ),                child: Text(
                  estado.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: isDesktop ? 8 : 6),
          
          // Información del animal
          Container(
            padding: EdgeInsets.all(isDesktop ? 8 : 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.pets,
                        'Animal',
                        animal?['nombre'] ?? 'Sin nombre',
                        isDesktop,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 8 : 6),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.category,
                        'Tipo',
                        animal?['tipo'] ?? 'No especificado',
                        isDesktop,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 6 : 4),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.science,
                        'Raza',
                        animal?['raza'] ?? 'No especificada',
                        isDesktop,
                      ),                    ),
                    SizedBox(width: isDesktop ? 8 : 6),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.euro,
                        'Precio',
                        precio != null ? '€$precio' : 'Por determinar',
                        isDesktop,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 6 : 4),
                _buildInfoItem(
                  Icons.notes,
                  'Motivo',
                  cita['motivo'] ?? 'Consulta general',
                  isDesktop,
                  fullWidth: true,
                ),
              ],
            ),
          ),
          
          // Botones de acción (solo para citas programadas o confirmadas)
          if (estado == 'programada' || estado == 'confirmada') ...[
            SizedBox(height: isDesktop ? 8 : 6),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _mostrarConfirmacionEstado(cita, 'completada'),
                    icon: const Icon(Icons.check_circle, size: 14),
                    label: Text(
                      'Completar',
                      style: TextStyle(fontSize: isDesktop ? 10 : 8),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        vertical: isDesktop ? 6 : 4,
                        horizontal: isDesktop ? 8 : 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),                SizedBox(width: isDesktop ? 6 : 4),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _mostrarConfirmacionEstado(cita, 'cancelada'),
                    icon: const Icon(Icons.cancel, size: 14),
                    label: Text(
                      'Cancelar',
                      style: TextStyle(fontSize: isDesktop ? 10 : 8),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isDesktop ? 6 : 4,
                        horizontal: isDesktop ? 8 : 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, bool isDesktop, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white70,
                size: isDesktop ? 12 : 10,
              ),
              SizedBox(width: isDesktop ? 4 : 3),
              Text(
                label,                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isDesktop ? 9 : 7,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 3 : 2),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 10 : 8,
              fontWeight: FontWeight.bold,
            ),
            maxLines: fullWidth ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  Widget _buildBadgeIcon(IconData icon, Color color, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: color, size: 24),
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 1),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                count > 9 ? '+9' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );  }
  Widget _buildSmallProfileAvatar() {
    final fotoUrl = _veterinarioData['foto_url'];
    
    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.network(
            fotoUrl,
            width: 36,
            height: 36,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.local_hospital, 
                color: Color(0xFF1B5E20), 
                size: 20
              );
            },
          ),
        ),
      );
    } else {
      // Foto por defecto si no hay URL
      return const CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white,
        child: Icon(Icons.local_hospital, color: Color(0xFF1B5E20), size: 20),
      );
    }
  }
}