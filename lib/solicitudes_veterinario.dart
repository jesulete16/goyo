import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'login.dart';

class SolicitudesVeterinario extends StatefulWidget {
  final Map<String, dynamic> userData;

  const SolicitudesVeterinario({super.key, required this.userData});

  @override
  State<SolicitudesVeterinario> createState() => _SolicitudesVeterinarioState();
}

class _SolicitudesVeterinarioState extends State<SolicitudesVeterinario> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _solicitudesPendientes = [];
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
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
    
    _loadSolicitudesPendientes();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSolicitudesPendientes() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔍 Cargando solicitudes pendientes para veterinario: ${widget.userData['id']}');
      
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
          .eq('estado', 'solicitada')
          .order('created_at', ascending: false);
      
      print('📋 Solicitudes encontradas: ${response.length}');
      
      setState(() {
        _solicitudesPendientes = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      print('🚨 Error cargando solicitudes: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar solicitudes: ${e.toString()}';
      });
    }
  }

  Future<void> _responderSolicitud(String citaId, String nuevoEstado, Map<String, dynamic> solicitud) async {
    try {
      print('🔄 Respondiendo solicitud $citaId con estado: $nuevoEstado');
      
      final response = await Supabase.instance.client
          .from('citas')
          .update({'estado': nuevoEstado})
          .eq('id', citaId)
          .select();
      
      if (response.isNotEmpty) {
        print('✅ Solicitud respondida exitosamente');
        
        // Recargar las solicitudes para quitar la que se acaba de responder
        await _loadSolicitudesPendientes();
        
        // Mostrar mensaje de confirmación
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    nuevoEstado == 'programada' ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    nuevoEstado == 'programada' 
                        ? 'Cita aceptada y programada' 
                        : 'Cita denegada',
                  ),
                ],
              ),
              backgroundColor: nuevoEstado == 'programada' 
                  ? Colors.green 
                  : Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('🚨 Error respondiendo solicitud: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error al responder solicitud: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _mostrarConfirmacionRespuesta(Map<String, dynamic> solicitud, String accion) {
    final isAceptar = accion == 'programada';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B5E20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                isAceptar ? Icons.check_circle : Icons.cancel,
                color: isAceptar ? Colors.greenAccent : Colors.redAccent,
              ),
              const SizedBox(width: 8),
              Text(
                isAceptar ? 'Aceptar Solicitud' : 'Denegar Solicitud',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que quieres ${isAceptar ? "aceptar" : "denegar"} esta solicitud de cita?',
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
                      'Fecha: ${solicitud['fecha']}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Hora: ${solicitud['hora_inicio']} - ${solicitud['hora_fin']}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Animal: ${solicitud['animales']?['nombre'] ?? 'Sin nombre'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Tipo: ${solicitud['animales']?['tipo'] ?? 'No especificado'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      'Motivo: ${solicitud['motivo'] ?? 'Consulta general'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (isAceptar) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.greenAccent, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'La cita aparecerá como "programada" en tu calendario.',
                          style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _responderSolicitud(
                  solicitud['id'].toString(), 
                  isAceptar ? 'programada' : 'cancelada',
                  solicitud
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isAceptar ? Colors.greenAccent : Colors.redAccent,
                foregroundColor: isAceptar ? Colors.black : Colors.white,
              ),
              child: Text(isAceptar ? 'Aceptar' : 'Denegar'),
            ),
          ],
        );
      },
    );
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
            ListTile(
              leading: const Icon(Icons.pending_actions, color: Colors.orangeAccent),
              title: const Text('Solicitudes', style: TextStyle(color: Colors.white)),
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
                        child: Icon(Icons.pending_actions, color: Color(0xFF1B5E20), size: 28),
                      ),
                      SizedBox(width: isDesktop ? 16 : 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Solicitudes Pendientes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isDesktop ? 20 : 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.notifications_active, color: Colors.orangeAccent, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${_solicitudesPendientes.length} solicitudes',
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
                        onPressed: _loadSolicitudesPendientes,
                        icon: const Icon(Icons.refresh, color: Colors.white70),
                        tooltip: 'Actualizar',
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
                              CircularProgressIndicator(color: Colors.orangeAccent),
                              SizedBox(height: 16),
                              Text(
                                'Cargando solicitudes...',
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
                                    onPressed: _loadSolicitudesPendientes,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orangeAccent,
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('Reintentar'),
                                  ),
                                ],
                              ),
                            )
                          : _solicitudesPendientes.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.inbox,
                                        color: Colors.white54,
                                        size: 80,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No hay solicitudes pendientes',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: isDesktop ? 18 : 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Las nuevas solicitudes de cita aparecerán aquí',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: isDesktop ? 14 : 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.all(isDesktop ? 16 : 12),
                                  itemCount: _solicitudesPendientes.length,
                                  itemBuilder: (context, index) {
                                    final solicitud = _solicitudesPendientes[index];
                                    return _buildSolicitudCard(solicitud, isDesktop);
                                  },
                                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolicitudCard(Map<String, dynamic> solicitud, bool isDesktop) {
    final animal = solicitud['animales'];
    final fecha = solicitud['fecha'];
    final horaInicio = solicitud['hora_inicio'];
    final horaFin = solicitud['hora_fin'];
    final precio = solicitud['precio'];
    final createdAt = DateTime.parse(solicitud['created_at']);
    final tiempoTranscurrido = DateTime.now().difference(createdAt);
    
    String tiempoTexto;
    if (tiempoTranscurrido.inDays > 0) {
      tiempoTexto = 'Hace ${tiempoTranscurrido.inDays} día${tiempoTranscurrido.inDays > 1 ? 's' : ''}';
    } else if (tiempoTranscurrido.inHours > 0) {
      tiempoTexto = 'Hace ${tiempoTranscurrido.inHours} hora${tiempoTranscurrido.inHours > 1 ? 's' : ''}';
    } else if (tiempoTranscurrido.inMinutes > 0) {
      tiempoTexto = 'Hace ${tiempoTranscurrido.inMinutes} minuto${tiempoTranscurrido.inMinutes > 1 ? 's' : ''}';
    } else {
      tiempoTexto = 'Hace un momento';
    }

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 16 : 12),
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orangeAccent.withOpacity(0.5),
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
          // Header de la solicitud
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.pending_actions,
                  color: Colors.orangeAccent,
                  size: isDesktop ? 20 : 18,
                ),
              ),
              SizedBox(width: isDesktop ? 12 : 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nueva Solicitud',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 16 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      tiempoTexto,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isDesktop ? 12 : 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PENDIENTE',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: isDesktop ? 12 : 8),
          
          // Información de la cita
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
                        Icons.calendar_today,
                        'Fecha',
                        fecha ?? 'No especificada',
                        isDesktop,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 12 : 8),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.access_time,
                        'Hora',
                        '$horaInicio - $horaFin',
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
                  solicitud['motivo'] ?? 'Consulta general',
                  isDesktop,
                  fullWidth: true,
                ),
                SizedBox(height: isDesktop ? 8 : 6),
                _buildInfoItem(
                  Icons.email,
                  'Contacto',
                  animal?['correo'] ?? 'Sin email',
                  isDesktop,
                  fullWidth: true,
                ),
              ],
            ),
          ),
          
          SizedBox(height: isDesktop ? 12 : 8),
          
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarConfirmacionRespuesta(solicitud, 'programada'),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: Text(
                    'Aceptar',
                    style: TextStyle(fontSize: isDesktop ? 12 : 10),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      vertical: isDesktop ? 8 : 6,
                      horizontal: isDesktop ? 12 : 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: isDesktop ? 8 : 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _mostrarConfirmacionRespuesta(solicitud, 'cancelada'),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: Text(
                    'Denegar',
                    style: TextStyle(fontSize: isDesktop ? 12 : 10),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: isDesktop ? 8 : 6,
                      horizontal: isDesktop ? 12 : 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
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
