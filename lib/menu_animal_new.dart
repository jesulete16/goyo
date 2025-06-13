import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'cita_calendar.dart';

class MenuAnimal extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MenuAnimal({super.key, required this.userData});

  @override
  State<MenuAnimal> createState() => _MenuAnimalState();
}

class _MenuAnimalState extends State<MenuAnimal> with TickerProviderStateMixin {
  List<Map<String, dynamic>> veterinarios = [];
  List<Map<String, dynamic>> misCitas = [];
  bool isLoading = true;
  bool isLoadingCitas = false;
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    
    _loadVeterinarios();
    _loadMisCitas();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVeterinarios() async {
    try {
      print('🔍 Cargando veterinarios...');
      
      final response = await Supabase.instance.client
          .from('veterinarios')
          .select('id, nombre, correo, ubicacion, especialidad, años_experiencia, telefono, foto_url, numero_colegiado')
          .order('nombre');
      
      print('📋 Veterinarios encontrados: ${response.length}');
      
      setState(() {
        veterinarios = List<Map<String, dynamic>>.from(response);
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      print('🚨 Error cargando veterinarios: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error al cargar veterinarios: ${e.toString()}';
      });
    }
  }

  Future<void> _loadMisCitas() async {
    setState(() => isLoadingCitas = true);
    
    try {
      print('🔍 Cargando citas del animal: ${widget.userData['id']}');
      
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
            veterinarios!inner(
              id,
              nombre,
              especialidad,
              telefono
            )
          ''')
          .eq('animal_id', widget.userData['id'])
          .order('fecha', ascending: false)
          .order('hora_inicio', ascending: false);
      
      print('📋 Citas encontradas: ${response.length}');
      
      setState(() {
        misCitas = List<Map<String, dynamic>>.from(response);
        isLoadingCitas = false;
      });
    } catch (e) {
      print('🚨 Error cargando citas: $e');
      setState(() {
        misCitas = [];
        isLoadingCitas = false;
      });
    }
  }

  void _pedirCita(Map<String, dynamic> veterinario) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CitaCalendar(
          veterinario: veterinario,
          animalData: widget.userData,
        );
      },
    ).then((_) {
      // Recargar las citas después de cerrar el calendario
      _loadMisCitas();
    });
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
                // Header con información del animal
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
                      CircleAvatar(
                        radius: isDesktop ? 25 : 20,
                        backgroundColor: Colors.greenAccent.withOpacity(0.2),
                        child: Icon(
                          Icons.pets,
                          color: Colors.greenAccent,
                          size: isDesktop ? 30 : 24,
                        ),
                      ),
                      SizedBox(width: isDesktop ? 16 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hola, ${widget.userData['nombre']}!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isDesktop ? 22 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Gestiona tus citas veterinarias',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: isDesktop ? 14 : 12,
                              ),
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
                
                // TabBar
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 20 : 16,
                    vertical: isDesktop ? 20 : 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.greenAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 16 : 14,
                    ),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.medical_services),
                        text: 'Veterinarios',
                      ),
                      Tab(
                        icon: Icon(Icons.calendar_today),
                        text: 'Mis Citas',
                      ),
                    ],
                  ),
                ),
                
                // TabBarView content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Pestaña de Veterinarios
                      _buildVeterinariosTab(isDesktop),
                      // Pestaña de Mis Citas
                      _buildMisCitasTab(isDesktop),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVeterinariosTab(bool isDesktop) {
    return Column(
      children: [
        // Título de veterinarios
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 16),
          child: Row(
            children: [
              const Icon(
                Icons.medical_services,
                color: Colors.greenAccent,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Veterinarios Disponibles',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (!isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${veterinarios.length} disponibles',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Lista de veterinarios
        Expanded(
          child: _buildVeterinariosContent(isDesktop),
        ),
      ],
    );
  }

  Widget _buildMisCitasTab(bool isDesktop) {
    return Column(
      children: [
        // Título de mis citas
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 16),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.blueAccent,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Mis Citas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              if (!isLoadingCitas)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${misCitas.length} citas',
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Lista de citas
        Expanded(
          child: _buildCitasContent(isDesktop),
        ),
      ],
    );
  }

  Widget _buildVeterinariosContent(bool isDesktop) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.greenAccent),
            SizedBox(height: 16),
            Text(
              'Cargando veterinarios...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                _loadVeterinarios();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (veterinarios.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: Colors.white54, size: 64),
            SizedBox(height: 16),
            Text(
              'No hay veterinarios disponibles',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Vuelve a intentarlo más tarde',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVeterinarios,
      color: Colors.greenAccent,
      child: GridView.builder(
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktop ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
          childAspectRatio: isDesktop ? 1.1 : 1.2,
          crossAxisSpacing: isDesktop ? 20 : 12,
          mainAxisSpacing: isDesktop ? 20 : 12,
        ),
        itemCount: veterinarios.length,
        itemBuilder: (context, index) {
          final veterinario = veterinarios[index];
          return _buildVeterinarioCard(veterinario, isDesktop);
        },
      ),
    );
  }

  Widget _buildCitasContent(bool isDesktop) {
    if (isLoadingCitas) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 16),
            Text(
              'Cargando citas...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (misCitas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, color: Colors.white54, size: 64),
            const SizedBox(height: 16),
            const Text(
              'No tienes citas programadas',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agenda una cita con un veterinario',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _tabController.animateTo(0); // Ir a la pestaña de veterinarios
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Agendar Cita'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMisCitas,
      color: Colors.blueAccent,
      child: ListView.builder(
        padding: EdgeInsets.all(isDesktop ? 20 : 16),
        itemCount: misCitas.length,
        itemBuilder: (context, index) {
          final cita = misCitas[index];
          return _buildCitaCard(cita, isDesktop);
        },
      ),
    );
  }

  Widget _buildVeterinarioCard(Map<String, dynamic> veterinario, bool isDesktop) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(isDesktop ? 24 : 16),
          border: Border.all(
            color: Colors.greenAccent.withOpacity(0.25),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.13),
              blurRadius: isDesktop ? 28 : 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isDesktop ? 24 : 16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 22 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con foto y nombre
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: isDesktop ? 34 : 26,
                        backgroundColor: Colors.greenAccent.withOpacity(0.18),
                        backgroundImage: veterinario['foto_url'] != null
                            ? NetworkImage(veterinario['foto_url'])
                            : null,
                        child: veterinario['foto_url'] == null
                            ? Icon(
                                Icons.person,
                                color: Colors.greenAccent,
                                size: isDesktop ? 38 : 28,
                              )
                            : null,
                      ),
                      SizedBox(width: isDesktop ? 16 : 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    veterinario['nombre'] ?? 'Sin nombre',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isDesktop ? 18 : 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if ((veterinario['especialidad'] ?? '').toString().toLowerCase() == 'general')
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Tooltip(
                                      message: 'Veterinario general',
                                      child: Icon(Icons.verified, color: Colors.blue[200], size: isDesktop ? 18 : 14),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.medical_services, color: Colors.greenAccent, size: isDesktop ? 15 : 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    veterinario['especialidad'] ?? 'General',
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: isDesktop ? 13 : 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Información del veterinario
                  _buildInfoRow(Icons.location_on, veterinario['ubicacion'], isDesktop),
                  SizedBox(height: isDesktop ? 8 : 6),
                  _buildInfoRow(Icons.star, '${veterinario['años_experiencia'] ?? 0} años de experiencia', isDesktop),
                  SizedBox(height: isDesktop ? 8 : 6),
                  _buildInfoRow(Icons.badge, veterinario['numero_colegiado'], isDesktop),
                  SizedBox(height: isDesktop ? 8 : 6),
                  _buildInfoRow(Icons.phone, veterinario['telefono'], isDesktop),
                  const Spacer(),
                  // Botón pedir cita
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _pedirCita(veterinario),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isDesktop ? 14 : 10),
                        ),
                        padding: EdgeInsets.symmetric(vertical: isDesktop ? 13 : 10),
                        elevation: 6,
                        shadowColor: Colors.greenAccent.withOpacity(0.18),
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isDesktop ? 15 : 12,
                        ),
                      ),
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: const Text('Pedir Cita'),
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

  Widget _buildCitaCard(Map<String, dynamic> cita, bool isDesktop) {
    final veterinario = cita['veterinarios'];
    final fecha = DateTime.parse(cita['fecha']);
    final horaInicio = cita['hora_inicio'];
    final horaFin = cita['hora_fin'];
    final estado = cita['estado'];
    final precio = cita['precio'];
    
    // Determinar color según el estado
    Color estadoColor;
    IconData estadoIcon;
    switch (estado) {
      case 'programada':
        estadoColor = Colors.blueAccent;
        estadoIcon = Icons.schedule;
        break;
      case 'completada':
        estadoColor = Colors.greenAccent;
        estadoIcon = Icons.check_circle;
        break;
      case 'cancelada':
        estadoColor = Colors.redAccent;
        estadoIcon = Icons.cancel;
        break;
      default:
        estadoColor = Colors.grey;
        estadoIcon = Icons.help;
    }

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        border: Border.all(
          color: estadoColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: isDesktop ? 20 : 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header de la cita
                Row(
                  children: [
                    CircleAvatar(
                      radius: isDesktop ? 25 : 20,
                      backgroundColor: estadoColor.withOpacity(0.2),
                      child: Icon(
                        estadoIcon,
                        color: estadoColor,
                        size: isDesktop ? 28 : 22,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. ${veterinario?['nombre'] ?? 'Sin nombre'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isDesktop ? 18 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            veterinario?['especialidad'] ?? 'General',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: isDesktop ? 14 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: estadoColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        estado.toUpperCase(),
                        style: TextStyle(
                          color: estadoColor,
                          fontSize: isDesktop ? 12 : 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: isDesktop ? 16 : 12),
                
                // Información de la cita
                Container(
                  padding: EdgeInsets.all(isDesktop ? 16 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildCitaInfoItem(
                              Icons.calendar_month,
                              'Fecha',
                              '${fecha.day}/${fecha.month}/${fecha.year}',
                              isDesktop,
                            ),
                          ),
                          SizedBox(width: isDesktop ? 16 : 12),
                          Expanded(
                            child: _buildCitaInfoItem(
                              Icons.access_time,
                              'Hora',
                              '$horaInicio - $horaFin',
                              isDesktop,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isDesktop ? 12 : 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCitaInfoItem(
                              Icons.notes,
                              'Motivo',
                              cita['motivo'] ?? 'Consulta general',
                              isDesktop,
                            ),
                          ),
                          SizedBox(width: isDesktop ? 16 : 12),
                          Expanded(
                            child: _buildCitaInfoItem(
                              Icons.euro,
                              'Precio',
                              precio != null ? '€$precio' : 'Por determinar',
                              isDesktop,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Botones de acción (solo para citas programadas)
                if (estado == 'programada') ...[
                  SizedBox(height: isDesktop ? 16 : 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelarCita(cita['id']),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            foregroundColor: Colors.redAccent,
                            padding: EdgeInsets.symmetric(vertical: isDesktop ? 12 : 10),
                          ),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Cancelar'),
                        ),
                      ),
                      SizedBox(width: isDesktop ? 12 : 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _contactarVeterinario(veterinario),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: isDesktop ? 12 : 10),
                          ),
                          icon: const Icon(Icons.phone, size: 18),
                          label: const Text('Contactar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCitaInfoItem(IconData icon, String label, String value, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white70,
              size: isDesktop ? 16 : 14,
            ),
            SizedBox(width: isDesktop ? 8 : 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: isDesktop ? 12 : 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: isDesktop ? 6 : 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isDesktop ? 14 : 12,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _cancelarCita(String citaId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B5E20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.cancel, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Cancelar Cita', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que quieres cancelar esta cita?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _confirmarCancelacion(citaId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sí, Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmarCancelacion(String citaId) async {
    try {
      await Supabase.instance.client
          .from('citas')
          .update({'estado': 'cancelada'})
          .eq('id', citaId);
      
      // Recargar las citas
      _loadMisCitas();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita cancelada exitosamente'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar la cita: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _contactarVeterinario(Map<String, dynamic>? veterinario) {
    if (veterinario == null) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B5E20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.phone, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Contactar Dr. ${veterinario['nombre']}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Teléfono: ${veterinario['telefono'] ?? 'No disponible'}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                'Especialidad: ${veterinario['especialidad'] ?? 'General'}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar', style: TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String? text, bool isDesktop) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: isDesktop ? 16 : 14,
        ),
        SizedBox(width: isDesktop ? 8 : 6),
        Expanded(
          child: Text(
            text ?? 'No disponible',
            style: TextStyle(
              color: Colors.white70,
              fontSize: isDesktop ? 13 : 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
