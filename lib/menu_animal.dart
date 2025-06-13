import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'cita_calendar.dart';
import 'perfil_animal.dart';

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
  }  Future<void> _loadVeterinarios() async {
    try {
      print('🔍 Cargando veterinarios...');
      
      // Obtener el tipo del animal actual
      String tipoAnimal = widget.userData['tipo']?.toString() ?? '';
      print('🐾 Tipo del animal original: "$tipoAnimal"');
      
      // Capitalizar primera letra para coincidir con la BD
      String tipoAnimalCapitalizado = tipoAnimal.isNotEmpty 
          ? tipoAnimal[0].toUpperCase() + tipoAnimal.substring(1).toLowerCase()
          : '';
      print('🐾 Tipo del animal capitalizado: "$tipoAnimalCapitalizado"');
      print('📋 Datos completos del animal: ${widget.userData}');
      
      // Primero, cargar TODOS los veterinarios para ver qué especialidades existen
      final todosVeterinarios = await Supabase.instance.client
          .from('veterinarios')
          .select('id, nombre, especialidad');
      
      print('🔍 TODOS los veterinarios en BD:');
      for (var vet in todosVeterinarios) {
        print('   - ${vet['nombre']}: especialidad = "${vet['especialidad']}"');
      }
      
      // Ahora aplicar el filtro con la capitalización correcta
      var query = Supabase.instance.client
          .from('veterinarios')
          .select('id, nombre, correo, ubicacion, especialidad, años_experiencia, telefono, foto_url, numero_colegiado');
      
      List<dynamic> response;
      
      if (tipoAnimalCapitalizado.isNotEmpty) {
        print('🔍 Aplicando filtro para tipo: "$tipoAnimalCapitalizado"');
        // Usar filtro OR con capitalización correcta
        try {
          response = await query.or('especialidad.eq.General,especialidad.eq.$tipoAnimalCapitalizado').order('nombre');
          print('✅ Filtro OR funcionó: ${response.length} veterinarios');
        } catch (e) {
          print('❌ Error con filtro OR: $e');
          // Si falla, intentar con filtro manual
          final todosVets = await Supabase.instance.client
              .from('veterinarios')
              .select('id, nombre, correo, ubicacion, especialidad, años_experiencia, telefono, foto_url, numero_colegiado')
              .order('nombre');
          
          response = todosVets.where((vet) => 
            vet['especialidad']?.toString() == 'General' || 
            vet['especialidad']?.toString() == tipoAnimalCapitalizado
          ).toList();
          print('✅ Filtro manual aplicado: ${response.length} veterinarios');
        }
      } else {
        print('⚠️ Sin tipo de animal, mostrando solo generales');
        response = await query.eq('especialidad', 'General').order('nombre');
      }
      
      print('📋 Veterinarios filtrados para "$tipoAnimalCapitalizado": ${response.length}');
      for (var vet in response) {
        print('   ✅ ${vet['nombre']}: especialidad = "${vet['especialidad']}"');
      }
      
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

  void _abrirPerfil() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PerfilAnimal(
          userData: widget.userData,
          onUserDataUpdated: (Map<String, dynamic> nuevosUserData) {
            // Actualizar los datos del usuario en el estado local
            setState(() {
              // No podemos modificar widget.userData directamente, 
              // pero podemos actualizar campos específicos si es necesario
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final fotoPerfil = widget.userData['foto_url'];
    final tipoAnimal = widget.userData['tipo']?.toString() ?? '';
    
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
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.greenAccent.withOpacity(0.2),
                    backgroundImage: fotoPerfil != null && fotoPerfil.isNotEmpty ? NetworkImage(fotoPerfil) : null,
                    child: (fotoPerfil == null || fotoPerfil.isEmpty)
                        ? const Icon(Icons.pets, color: Colors.greenAccent, size: 40)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.userData['nombre'] ?? '',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    tipoAnimal.isNotEmpty ? tipoAnimal : 'Animal',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),            ListTile(
              leading: const Icon(Icons.home, color: Colors.greenAccent),
              title: const Text('Inicio', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.pets, color: Colors.blueAccent),
              title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _abrirPerfil();
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
              children: [                // Header profesional
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
                    children: [                      CircleAvatar(
                        radius: isDesktop ? 24 : 20,
                        backgroundColor: Colors.greenAccent.withOpacity(0.18),
                        backgroundImage: fotoPerfil != null && fotoPerfil.isNotEmpty ? NetworkImage(fotoPerfil) : null,
                        child: (fotoPerfil == null || fotoPerfil.isEmpty)
                            ? Icon(Icons.pets, color: Colors.greenAccent, size: isDesktop ? 24 : 18)
                            : null,
                      ),
                      SizedBox(width: isDesktop ? 16 : 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [                            Text(
                              '¡Hola, ${widget.userData['nombre']}!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isDesktop ? 20 : 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(Icons.pets, color: Colors.greenAccent, size: isDesktop ? 14 : 12),
                                const SizedBox(width: 4),
                                Text(
                                  tipoAnimal.isNotEmpty ? tipoAnimal : 'Animal',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: isDesktop ? 12 : 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _abrirPerfil,
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        tooltip: 'Editar Perfil',
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
                    horizontal: isDesktop ? 16 : 12,
                    vertical: isDesktop ? 12 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,                    indicator: BoxDecoration(
                      color: Colors.greenAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 14 : 12,
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
  }  Widget _buildVeterinariosTab(bool isDesktop) {
    // Obtener el tipo del animal para el título
    String tipoAnimal = widget.userData['tipo']?.toString() ?? '';
    String tituloVeterinarios = tipoAnimal.isNotEmpty 
        ? 'Veterinarios para ${tipoAnimal.toLowerCase()}s'
        : 'Veterinarios Disponibles';
    
    return Column(
      children: [        // Título de veterinarios
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 12),
          child: Row(
            children: [
              const Icon(
                Icons.medical_services,
                color: Colors.greenAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tituloVeterinarios,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
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
      children: [        // Título de mis citas
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 12),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.blueAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Mis Citas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
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
      color: Colors.greenAccent,      child: GridView.builder(
        padding: EdgeInsets.all(isDesktop ? 16 : 12),        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktop ? 4 : (MediaQuery.of(context).size.width > 600 ? 3 : 2),
          childAspectRatio: isDesktop ? 0.85 : 0.95,
          crossAxisSpacing: isDesktop ? 12 : 8,
          mainAxisSpacing: isDesktop ? 12 : 8,
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
      color: Colors.blueAccent,      child: ListView.builder(
        padding: EdgeInsets.all(isDesktop ? 16 : 12),
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
        curve: Curves.easeInOut,        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(isDesktop ? 14 : 10),
          border: Border.all(
            color: Colors.greenAccent.withOpacity(0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: isDesktop ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isDesktop ? 14 : 10),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 12 : 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con foto y nombre
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [                      CircleAvatar(
                        radius: isDesktop ? 20 : 16,
                        backgroundColor: Colors.greenAccent.withOpacity(0.18),
                        backgroundImage: veterinario['foto_url'] != null
                            ? NetworkImage(veterinario['foto_url'])
                            : null,
                        child: veterinario['foto_url'] == null
                            ? Icon(
                                Icons.person,
                                color: Colors.greenAccent,
                                size: isDesktop ? 22 : 18,
                              )
                            : null,
                      ),
                      SizedBox(width: isDesktop ? 8 : 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    veterinario['nombre'] ?? 'Sin nombre',                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isDesktop ? 13 : 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                    maxLines: 1,
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
                            Container(                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [                                  Icon(Icons.medical_services, color: Colors.greenAccent, size: isDesktop ? 10 : 8),
                                  const SizedBox(width: 2),
                                  Text(
                                    veterinario['especialidad'] ?? 'General',
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: isDesktop ? 9 : 7,
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
                  ),                  const SizedBox(height: 6),
                  // Información del veterinario
                  _buildInfoRow(Icons.location_on, veterinario['ubicacion'], isDesktop),
                  SizedBox(height: isDesktop ? 3 : 2),
                  _buildInfoRow(Icons.star, '${veterinario['años_experiencia'] ?? 0} años', isDesktop),
                  SizedBox(height: isDesktop ? 3 : 2),
                  _buildInfoRow(Icons.phone, veterinario['telefono'], isDesktop),
                  const Spacer(),
                  // Botón pedir cita
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _pedirCita(veterinario),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isDesktop ? 10 : 8),
                        ),                        padding: EdgeInsets.symmetric(vertical: isDesktop ? 8 : 6),
                        elevation: 3,
                        shadowColor: Colors.greenAccent.withOpacity(0.12),
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isDesktop ? 11 : 9,
                        ),
                      ),                      icon: const Icon(Icons.calendar_month, size: 14),
                      label: const Text('Cita'),
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
    IconData estadoIcon;    switch (estado) {
      case 'programada':
        estadoColor = Colors.orange; // Amarillo/naranja para programada
        estadoIcon = Icons.schedule;
        break;
      case 'completada':
        estadoColor = Colors.green; // Verde para completada
        estadoIcon = Icons.check_circle;
        break;
      case 'cancelada':
        estadoColor = Colors.red; // Rojo para cancelada
        estadoIcon = Icons.cancel;
        break;
      case 'confirmada':
        estadoColor = Colors.blue; // Azul para confirmada
        estadoIcon = Icons.verified;
        break;
      default:
        estadoColor = Colors.grey;
        estadoIcon = Icons.help;
    }    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 12 : 8),      decoration: BoxDecoration(
        color: estadoColor.withOpacity(0.1), // Fondo con tinte del color del estado
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        border: Border.all(
          color: estadoColor.withOpacity(0.5), // Borde más visible
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: isDesktop ? 15 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 16 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header de la cita
                Row(
                  children: [                    CircleAvatar(
                      radius: isDesktop ? 20 : 16,
                      backgroundColor: estadoColor.withOpacity(0.2),
                      child: Icon(
                        estadoIcon,
                        color: estadoColor,
                        size: isDesktop ? 22 : 18,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 12 : 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [                          Text(
                            'Dr. ${veterinario?['nombre'] ?? 'Sin nombre'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isDesktop ? 15 : 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            veterinario?['especialidad'] ?? 'General',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: isDesktop ? 12 : 10,
                            ),
                          ),
                        ],
                      ),
                    ),                    Container(                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 12 : 8, 
                        vertical: isDesktop ? 6 : 4
                      ),
                      decoration: BoxDecoration(
                        color: estadoColor, // Fondo sólido del color del estado
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: estadoColor.withOpacity(0.25),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            estadoIcon,
                            color: Colors.white,
                            size: isDesktop ? 12 : 10,
                          ),
                          SizedBox(width: isDesktop ? 4 : 2),
                          Text(
                            estado.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isDesktop ? 10 : 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
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
                      ),                      SizedBox(height: isDesktop ? 8 : 6),
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
                          SizedBox(width: isDesktop ? 12 : 8),
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
                  SizedBox(height: isDesktop ? 12 : 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelarCita(cita['id']),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            foregroundColor: Colors.redAccent,                            padding: EdgeInsets.symmetric(vertical: isDesktop ? 8 : 6),
                          ),
                          icon: const Icon(Icons.cancel, size: 14),
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
                          ),                          icon: const Icon(Icons.phone, size: 18),
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
              icon,            color: Colors.white70,
            size: isDesktop ? 12 : 10,
          ),
          SizedBox(width: isDesktop ? 6 : 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: isDesktop ? 10 : 8,
              fontWeight: FontWeight.w500,
            ),
          ),
          ],
        ),        SizedBox(height: isDesktop ? 4 : 3),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isDesktop ? 12 : 10,
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
      children: [        Icon(
          icon,
          color: Colors.white70,
          size: isDesktop ? 10 : 8,
        ),
        SizedBox(width: isDesktop ? 4 : 3),
        Expanded(
          child: Text(
            text ?? 'No disponible',
            style: TextStyle(
              color: Colors.white70,
              fontSize: isDesktop ? 9 : 7,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
