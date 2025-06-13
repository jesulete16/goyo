import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class CitaCalendar extends StatefulWidget {
  final Map<String, dynamic> veterinario;
  final Map<String, dynamic> animalData;

  const CitaCalendar({
    super.key,
    required this.veterinario,
    required this.animalData,
  });

  @override
  State<CitaCalendar> createState() => _CitaCalendarState();
}

class _CitaCalendarState extends State<CitaCalendar> with TickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
  DateTime displayedMonth = DateTime.now();
  List<String> horasDisponibles = [];
  bool isLoadingHoras = false;
  String? selectedHora;
  String? selectedMotivo;
  double? selectedPrecio;
  
  // Estados del flujo de selección
  int currentStep = 0; // 0: Calendar, 1: Motivo, 2: Hora
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  // Lista de motivos y precios
  final List<Map<String, dynamic>> motivosYPrecios = [
    {'motivo': 'Revisión general', 'precio': 35.00, 'icono': Icons.health_and_safety},
    {'motivo': 'Vacunación', 'precio': 40.00, 'icono': Icons.vaccines},
    {'motivo': 'Desparasitación', 'precio': 25.00, 'icono': Icons.bug_report},
    {'motivo': 'Control post-operatorio', 'precio': 60.00, 'icono': Icons.healing},
    {'motivo': 'Cirugía menor', 'precio': 150.00, 'icono': Icons.medical_services},
    {'motivo': 'Esterilización', 'precio': 120.00, 'icono': Icons.pets},
    {'motivo': 'Problemas digestivos', 'precio': 55.00, 'icono': Icons.sick},
    {'motivo': 'Revisión dental', 'precio': 40.00, 'icono': Icons.medication},
    {'motivo': 'Control de salud', 'precio': 30.00, 'icono': Icons.monitor_heart},
    {'motivo': 'Emergencia', 'precio': 80.00, 'icono': Icons.emergency},
    {'motivo': 'Consulta especializada', 'precio': 70.00, 'icono': Icons.psychology},
    {'motivo': 'Análisis clínicos', 'precio': 50.00, 'icono': Icons.biotech},
  ];
  // Horarios fijos del veterinario (9:00-13:00 y 17:00-20:00)
  final List<String> horarioManana = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00'
  ];
  
  final List<String> horarioTarde = [
    '17:00', '17:30', '18:00', '18:30', '19:00', '19:30',
    '20:00'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
    
    // Cargar horas disponibles para hoy por defecto
    _loadHorasDisponibles(selectedDate);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _stopAutoRefresh(); // Detener auto-actualización al cerrar el widget
    super.dispose();
  }  Future<void> _loadHorasDisponibles(DateTime fecha) async {
    setState(() {
      isLoadingHoras = true;
      selectedHora = null; // Reset hora seleccionada
      // No reseteamos el motivo si estamos en el paso de selección de hora (paso 2)
      if (currentStep != 2) {
        selectedMotivo = null;
        selectedPrecio = null;
      }
    });try {
      print('🔍 Cargando horas disponibles para: ${fecha.toString().split(' ')[0]}');
      
      // Verificar que no sea fin de semana
      if (fecha.weekday == 6 || fecha.weekday == 7) {
        print('⚠️ Fin de semana detectado, no hay horas disponibles');
        setState(() {
          horasDisponibles = [];
          isLoadingHoras = false;
        });
        return;
      }
        // Verificar horarios del veterinario para este día
      final diaSemana = fecha.weekday; // 1=Lunes, 7=Domingo
      print('📅 Día de la semana: $diaSemana');
      
      final horariosResponse = await Supabase.instance.client
          .from('horarios_veterinario')
          .select('*')
          .eq('veterinario_id', widget.veterinario['id'])
          .eq('dia_semana', diaSemana);
        print('⏰ Horarios encontrados: $horariosResponse');
      
      // Usar horarios de la BD si existen, sino usar horarios por defecto
      List<String> todasLasHoras;
      if (horariosResponse.isNotEmpty) {
        // Si hay horarios específicos en la BD, usar esos horarios
        // Por ahora usar los horarios por defecto hasta implementar la lógica completa
        todasLasHoras = [...horarioManana, ...horarioTarde];
      } else {
        // Usar horarios por defecto
        todasLasHoras = [...horarioManana, ...horarioTarde];
      }      // Obtener citas ya reservadas para esta fecha y veterinario
      final citasResponse = await Supabase.instance.client
          .from('citas')
          .select('hora_inicio, hora_fin, animal_id, estado')
          .eq('veterinario_id', widget.veterinario['id'])
          .eq('fecha', fecha.toString().split(' ')[0]) // Solo fecha YYYY-MM-DD
          .inFilter('estado', ['programada', 'confirmada']); // Solo citas activas
      
      print('📋 Citas ocupadas: $citasResponse');
      
      // Procesar horas ocupadas - normalizar formato y crear lista de intervalos ocupados
      List<String> horasOcupadas = [];
      
      for (var cita in citasResponse) {
        String horaInicio = cita['hora_inicio'].toString();
        String horaFin = cita['hora_fin'].toString();
        
        // Normalizar formato (quitar segundos si los tiene)
        // De "10:00:00" a "10:00", o mantener "10:00" como está
        if (horaInicio.contains(':')) {
          List<String> partes = horaInicio.split(':');
          horaInicio = '${partes[0]}:${partes[1]}';
        }
        if (horaFin.contains(':')) {
          List<String> partes = horaFin.split(':');
          horaFin = '${partes[0]}:${partes[1]}';
        }
        
        print('🚫 Hora ocupada detectada: $horaInicio - $horaFin (Animal: ${cita['animal_id']})');
        
        // Agregar todas las horas en el rango ocupado
        // Por ejemplo, si la cita es de 10:00 a 10:30, marcar 10:00 como ocupada
        horasOcupadas.add(horaInicio);
        
        // Si la cita dura más de 30 minutos, marcar también horas intermedias
        try {
          final inicio = DateTime.parse('2000-01-01 $horaInicio:00');
          final fin = DateTime.parse('2000-01-01 $horaFin:00');
          
          DateTime actual = inicio;
          while (actual.isBefore(fin)) {
            String horaActual = '${actual.hour.toString().padLeft(2, '0')}:${actual.minute.toString().padLeft(2, '0')}';
            if (!horasOcupadas.contains(horaActual)) {
              horasOcupadas.add(horaActual);
            }
            actual = actual.add(const Duration(minutes: 30)); // Incremento de 30 minutos
          }
        } catch (e) {
          print('⚠️ Error procesando horario: $e');
          // Si hay error en el parsing, al menos agregar la hora de inicio
          if (!horasOcupadas.contains(horaInicio)) {
            horasOcupadas.add(horaInicio);
          }
        }
      }
      
      print('🚫 Lista final de horas ocupadas: $horasOcupadas');
        // Filtrar horas pasadas si es hoy
      final now = DateTime.now();
      final isToday = fecha.year == now.year && 
                     fecha.month == now.month && 
                     fecha.day == now.day;
      
      List<String> disponibles = todasLasHoras.where((hora) {
        // Filtrar horas ocupadas (comparación exacta)
        if (horasOcupadas.contains(hora)) {
          print('🚫 Hora $hora está ocupada, se excluye de disponibles');
          return false;
        }
        
        // Si es hoy, filtrar horas pasadas
        if (isToday) {
          final horaDateTime = DateTime(
            fecha.year, 
            fecha.month, 
            fecha.day, 
            int.parse(hora.split(':')[0]), 
            int.parse(hora.split(':')[1])
          );
          if (horaDateTime.isBefore(now.add(const Duration(minutes: 30)))) {
            print('🕐 Hora $hora ya pasó, se excluye de disponibles');
            return false;
          }
        }
        
        return true;
      }).toList();
        setState(() {
        horasDisponibles = disponibles;
        isLoadingHoras = false;
        
        // Si el usuario ya ha seleccionado un motivo y no hay horas disponibles,
        // informamos al usuario pero no cambiamos de paso
        if (currentStep == 2 && disponibles.isEmpty) {
          // Mostrar mensaje indicando que no hay horas para este día
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay horas disponibles para el motivo seleccionado en este día'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
      
      print('✅ Horas disponibles: $disponibles');
      
    } catch (e) {
      print('🚨 Error cargando horas: $e');
      setState(() {
        horasDisponibles = [];
        isLoadingHoras = false;
      });
    }  }  Future<void> _confirmarCita() async {
    if (selectedHora == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una hora'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (selectedMotivo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un motivo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.greenAccent),
      ),
    );
    
    try {
      print('📝 Creando cita...');
      print('🏥 Veterinario: ${widget.veterinario['nombre']} (ID: ${widget.veterinario['id']})');
      print('🐾 Animal: ${widget.animalData['nombre']} (ID: ${widget.animalData['id']})');
      print('📅 Fecha: ${selectedDate.toString().split(' ')[0]}');
      print('⏰ Hora inicio: $selectedHora');
      print('📋 Motivo: $selectedMotivo');
      print('💰 Precio: $selectedPrecio€');
      
      // Calcular hora_fin (30 minutos después de hora_inicio)
      final horaInicioParts = selectedHora!.split(':');
      final horaInicio = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        int.parse(horaInicioParts[0]),
        int.parse(horaInicioParts[1]),
      );
      final horaFin = horaInicio.add(const Duration(minutes: 30));
      final horaFinString = '${horaFin.hour.toString().padLeft(2, '0')}:${horaFin.minute.toString().padLeft(2, '0')}';
      
      print('⏰ Hora fin calculada: $horaFinString');
        // Verificar que los IDs no sean null
      if (widget.animalData['id'] == null || widget.veterinario['id'] == null) {
        throw Exception('Error: IDs de animal o veterinario no válidos');
      }
      
      // VALIDACIÓN ADICIONAL: Verificar que la hora sigue disponible antes de insertar
      // Esto previene condiciones de carrera cuando múltiples usuarios intentan reservar la misma hora
      print('🔍 Validación final: verificando que la hora $selectedHora sigue disponible...');
      
      final verificacionCitas = await Supabase.instance.client
          .from('citas')
          .select('id, hora_inicio, animal_id')
          .eq('veterinario_id', widget.veterinario['id'])
          .eq('fecha', selectedDate.toString().split(' ')[0])
          .eq('hora_inicio', '$selectedHora:00')
          .inFilter('estado', ['programada', 'confirmada']);
      
      if (verificacionCitas.isNotEmpty) {
        print('❌ La hora $selectedHora ya fue reservada por otro usuario');
        throw Exception('HORA_OCUPADA: Esta hora ya fue reservada por otro usuario. Por favor, selecciona otra hora.');
      }
      
      print('✅ Hora $selectedHora confirmada como disponible, procediendo con la creación...');
      
      // Crear la cita en la base de datos
      final citaData = {
        'animal_id': widget.animalData['id'],
        'veterinario_id': widget.veterinario['id'],
        'fecha': selectedDate.toString().split(' ')[0], // YYYY-MM-DD
        'hora_inicio': '$selectedHora:00', // Asegurar formato HH:MM:SS
        'hora_fin': '$horaFinString:00',   // Asegurar formato HH:MM:SS
        'estado': 'programada',
        'motivo': selectedMotivo,
        'precio': selectedPrecio,
      };
      
      print('📊 Datos a insertar: $citaData');
      
      final response = await Supabase.instance.client
          .from('citas')
          .insert(citaData)
          .select(); // Seleccionar la cita creada para confirmar
      
      print('✅ Cita creada exitosamente: $response');
      
      // Cerrar loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {                  // Cerrar el calendario
        Navigator.of(context).pop();
        
        // Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¡Cita confirmada!',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${selectedDate.toString().split(' ')[0]} a las $selectedHora',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        '$selectedMotivo - ${selectedPrecio?.toStringAsFixed(2)}€',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Dr. ${widget.veterinario['nombre']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
    } catch (e) {
      print('🚨 Error creando cita: $e');
      
      // Cerrar loading dialog si está abierto
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        String errorMessage = 'Error al crear la cita';
          // Personalizar mensaje según el error
        if (e.toString().contains('check_no_fin_semana')) {
          errorMessage = 'No se pueden agendar citas en fines de semana';
        } else if (e.toString().contains('check_horario_valido')) {
          errorMessage = 'Horario no válido. Horarios: 9:00-13:30 y 17:00-20:30';
        } else if (e.toString().contains('unique_veterinario_fecha_hora')) {
          errorMessage = 'Esta hora ya está ocupada. Selecciona otra hora.';
        } else if (e.toString().contains('HORA_OCUPADA')) {
          errorMessage = 'Esta hora fue reservada por otro usuario. Selecciona otra hora.';
          // Recargar horas disponibles para actualizar la vista
          _loadHorasDisponibles(selectedDate);
        } else if (e.toString().contains('IDs')) {
          errorMessage = 'Error en los datos del animal o veterinario';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Error al crear cita',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        errorMessage,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  // Auto-actualización de horas disponibles cada 30 segundos (solo en paso de selección de hora)
  Timer? _autoRefreshTimer;
  
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel(); // Cancelar timer anterior si existe
    
    if (currentStep == 2) { // Solo en el paso de selección de hora
      _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (mounted && currentStep == 2) {
          print('🔄 Auto-actualizando horas disponibles...');
          _loadHorasDisponibles(selectedDate);
        } else {
          timer.cancel();
        }
      });
    }
  }
  
  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: isDesktop ? 600 : MediaQuery.of(context).size.width * 0.9,
          height: isDesktop ? 700 : MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.greenAccent.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.1),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.greenAccent, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Agendar Cita',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isDesktop ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Dr. ${widget.veterinario['nombre']}',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: isDesktop ? 14 : 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [                          // Contenido según el paso actual
                          if (currentStep == 0) ...[
                            // Paso 1: Selección de fecha
                            Expanded(
                              flex: 3,
                              child: _buildCalendar(isDesktop),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Botón para continuar al siguiente paso
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(                                onPressed: () {
                                  _stopAutoRefresh(); // Detener auto-actualización al cambiar paso
                                  setState(() {
                                    currentStep = 1; // Avanzar al paso de selección de motivo
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.greenAccent,
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(
                                    vertical: isDesktop ? 16 : 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 6,
                                ),
                                child: Text(
                                  'Continuar - ${selectedDate.toString().split(' ')[0]}',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 16 : 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ] else if (currentStep == 1) ...[
                            // Paso 2: Selección de motivo
                            Expanded(
                              flex: 3,
                              child: _buildMotivosDisponibles(isDesktop),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Botones para volver atrás o continuar
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(                                    onPressed: () {
                                      _stopAutoRefresh(); // Detener auto-actualización
                                      setState(() {
                                        currentStep = 0; // Volver a selección de fecha
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[700],
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: isDesktop ? 16 : 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Volver',
                                      style: TextStyle(
                                        fontSize: isDesktop ? 16 : 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else if (currentStep == 2) ...[
                            // Paso 3: Selección de hora
                            Expanded(
                              flex: 1,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Resumen de la cita',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isDesktop ? 18 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: Colors.greenAccent,
                                          size: isDesktop ? 20 : 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Fecha: ${selectedDate.toString().split(' ')[0]}',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isDesktop ? 14 : 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.medical_services,
                                          color: Colors.greenAccent,
                                          size: isDesktop ? 20 : 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Motivo: $selectedMotivo',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isDesktop ? 14 : 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.euro,
                                          color: Colors.greenAccent,
                                          size: isDesktop ? 20 : 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Precio: ${selectedPrecio?.toStringAsFixed(2)}€',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isDesktop ? 14 : 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Selección de hora
                            Expanded(
                              flex: 2,
                              child: _buildHorasDisponibles(isDesktop),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Botones para volver atrás o confirmar
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: ElevatedButton(                                    onPressed: () {
                                      _stopAutoRefresh(); // Detener auto-actualización
                                      setState(() {
                                        currentStep = 1; // Volver a selección de motivo
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[700],
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: isDesktop ? 16 : 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Volver',
                                      style: TextStyle(
                                        fontSize: isDesktop ? 16 : 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: selectedHora != null ? _confirmarCita : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: selectedHora != null 
                                          ? Colors.greenAccent 
                                          : Colors.grey,
                                      foregroundColor: selectedHora != null 
                                          ? Colors.black 
                                          : Colors.white70,
                                      padding: EdgeInsets.symmetric(
                                        vertical: isDesktop ? 16 : 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: selectedHora != null ? 6 : 0,
                                    ),
                                    child: Text(
                                      selectedHora != null 
                                          ? 'Confirmar Cita - $selectedHora'
                                          : 'Selecciona una hora',
                                      style: TextStyle(
                                        fontSize: isDesktop ? 16 : 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header del mes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    displayedMonth = DateTime(displayedMonth.year, displayedMonth.month - 1);
                  });
                },
                icon: const Icon(Icons.chevron_left, color: Colors.white),
              ),
              Text(
                '${_getMonthName(displayedMonth.month)} ${displayedMonth.year}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    displayedMonth = DateTime(displayedMonth.year, displayedMonth.month + 1);
                  });
                },
                icon: const Icon(Icons.chevron_right, color: Colors.white),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Días de la semana
          Row(
            children: ['L', 'M', 'X', 'J', 'V', 'S', 'D'].map((day) => 
              Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 14 : 12,
                    ),
                  ),
                ),
              ),
            ).toList(),
          ),
          
          const SizedBox(height: 8),
          
          // Grid de días
          Expanded(
            child: _buildDaysGrid(isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysGrid(bool isDesktop) {
    final firstDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;
    
    List<Widget> dayWidgets = [];
    
    // Espacios vacíos para los días anteriores al primer día del mes
    for (int i = 1; i < firstWeekday; i++) {
      dayWidgets.add(Container());
    }
      // Días del mes
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(displayedMonth.year, displayedMonth.month, day);
      final isToday = date.year == DateTime.now().year &&
                     date.month == DateTime.now().month &&
                     date.day == DateTime.now().day;
      final isSelected = date.year == selectedDate.year &&
                        date.month == selectedDate.month &&
                        date.day == selectedDate.day;
      final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
      final isWeekend = date.weekday == 6 || date.weekday == 7; // Sábado=6, Domingo=7
      final isDisabled = isPast || isWeekend;
        dayWidgets.add(
        GestureDetector(
          onTap: isDisabled ? null : () {
            setState(() {
              selectedDate = date;
            });
            _loadHorasDisponibles(date);
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Colors.greenAccent
                  : isToday 
                      ? Colors.greenAccent.withOpacity(0.3)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(color: Colors.greenAccent, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: isDisabled 
                      ? Colors.white30
                      : isSelected 
                          ? Colors.black
                          : Colors.white,
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                  fontSize: isDesktop ? 14 : 12,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return GridView.count(
      crossAxisCount: 7,
      children: dayWidgets,
    );
  }

  Widget _buildHorasDisponibles(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Horas disponibles - ${selectedDate.toString().split(' ')[0]}',
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 16 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          if (isLoadingHoras)
            const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          else if (horasDisponibles.isEmpty)
            Center(
              child: Text(
                'No hay horas disponibles',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isDesktop ? 14 : 12,
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 4 : 3,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: horasDisponibles.length,
                itemBuilder: (context, index) {
                  final hora = horasDisponibles[index];
                  final isSelected = hora == selectedHora;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedHora = hora;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.greenAccent
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected 
                              ? Colors.greenAccent
                              : Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          hora,
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: isDesktop ? 14 : 12,
                          ),
                        ),
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

  Widget _buildMotivosDisponibles(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Motivo de la visita - ${selectedDate.toString().split(' ')[0]}',
            style: TextStyle(
              color: Colors.white,
              fontSize: isDesktop ? 16 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Expanded(
            child: ListView.builder(
              itemCount: motivosYPrecios.length,
              itemBuilder: (context, index) {
                final motivo = motivosYPrecios[index];
                final isSelected = motivo['motivo'] == selectedMotivo;
                
                return GestureDetector(                  onTap: () {
                    setState(() {
                      selectedMotivo = motivo['motivo'];
                      selectedPrecio = motivo['precio'];
                      currentStep = 2; // Avanzar al siguiente paso (selección de hora)
                    });
                    _loadHorasDisponibles(selectedDate); // Cargar horas disponibles
                    _startAutoRefresh(); // Iniciar auto-actualización de horas
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.greenAccent
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? Colors.greenAccent
                            : Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          motivo['icono'] as IconData,
                          color: isSelected ? Colors.black : Colors.white,
                          size: isDesktop ? 24 : 20,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            motivo['motivo'],
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: isDesktop ? 16 : 14,
                            ),
                          ),
                        ),
                        Text(
                          '${motivo['precio'].toStringAsFixed(2)}€',
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: isDesktop ? 16 : 14,
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

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }
}