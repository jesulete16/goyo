import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'login.dart';

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
  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    
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
    } catch (e) {
      print('🚨 Error cargando citas: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar citas: ${e.toString()}';
      });
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
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D2818),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1B5E20),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.local_hospital, color: Color(0xFF1B5E20), size: 40),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Dr. ${widget.userData['nombre'] ?? ''}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    widget.userData['especialidad'] ?? 'Veterinario',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.greenAccent),
              title: const Text('Mi Calendario', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
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
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(isDesktop ? 20 : 12),
                  margin: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 8, vertical: isDesktop ? 12 : 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.local_hospital, color: Color(0xFF1B5E20), size: 28),
                      ),
                      SizedBox(width: isDesktop ? 16 : 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. ${widget.userData['nombre']}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isDesktop ? 20 : 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.medical_services, color: Colors.greenAccent, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  widget.userData['especialidad'] ?? 'Veterinario',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: isDesktop ? 12 : 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.white70),
                        tooltip: 'Cerrar Sesión',
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
                            )
                          : SingleChildScrollView(
                              padding: EdgeInsets.all(isDesktop ? 16 : 12),
                              child: Column(
                                children: [
                                  // Calendario
                                  _buildCalendar(isDesktop),
                                  SizedBox(height: isDesktop ? 20 : 16),
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
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),      child: TableCalendar<Map<String, dynamic>>(
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
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.white70),
          weekendStyle: TextStyle(color: Colors.white70),
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
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Citas del ${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_citasDelDia.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_citasDelDia.length} citas',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isDesktop ? 16 : 12),
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
    }

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 12 : 8),
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        color: estadoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: estadoColor.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: estadoColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  estadoIcon,
                  color: estadoColor,
                  size: isDesktop ? 20 : 18,
                ),
              ),
              SizedBox(width: isDesktop ? 12 : 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$horaInicio - $horaFin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 16 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      animal?['nombre'] ?? 'Animal sin nombre',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isDesktop ? 14 : 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: estadoColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  estado.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: isDesktop ? 12 : 8),
          
          // Información del animal
          Container(
            padding: EdgeInsets.all(isDesktop ? 12 : 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
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
                    SizedBox(width: isDesktop ? 12 : 8),
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
                SizedBox(height: isDesktop ? 8 : 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.science,
                        'Raza',
                        animal?['raza'] ?? 'No especificada',
                        isDesktop,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 12 : 8),
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
                SizedBox(height: isDesktop ? 8 : 6),
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
                size: isDesktop ? 14 : 12,
              ),
              SizedBox(width: isDesktop ? 6 : 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isDesktop ? 11 : 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 4 : 2),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 12 : 10,
              fontWeight: FontWeight.bold,
            ),
            maxLines: fullWidth ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}