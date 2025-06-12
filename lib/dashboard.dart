import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  final User user;
  final String userType; // 'veterinario' o 'animal'

  const DashboardScreen({
    super.key, 
    required this.user, 
    required this.userType,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  
  // Controlador para el PageView
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Cargar datos del usuario según su tipo (veterinario o animal)
  Future<void> _loadUserData() async {
    try {      final response = await Supabase.instance.client
          .from(widget.userType == 'veterinario' ? 'veterinarios' : 'animales')
          .select()
          .eq('correo', widget.user.email ?? '')
          .single();
      
      setState(() {
        _userData = response;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.pop(context); // Cierra el diálogo
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2E7D32),
          ),
        ),
      );
    }

    final String userName = _userData?['nombre'] ?? 'Usuario';
    final String userEmail = widget.user.email ?? 'correo@ejemplo.com';
    final String? photoUrl = _userData?['foto_url'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        title: Text(
          widget.userType == 'veterinario' ? 'Dashboard Veterinario' : 'Dashboard Mascota',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // TODO: Implementar notificaciones
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
              ),
              accountName: Text(
                userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? const Icon(Icons.person, size: 40, color: Color(0xFF2E7D32))
                    : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Color(0xFF2E7D32)),
              title: const Text('Panel Principal'),
              selected: _selectedIndex == 0,
              onTap: () {
                _onItemTapped(0);
                Navigator.pop(context);
              },
            ),
            if (widget.userType == 'animal')
              ListTile(
                leading: const Icon(Icons.medical_services, color: Color(0xFF2E7D32)),
                title: const Text('Mis Veterinarios'),
                selected: _selectedIndex == 1,
                onTap: () {
                  _onItemTapped(1);
                  Navigator.pop(context);
                },
              ),
            if (widget.userType == 'veterinario')
              ListTile(
                leading: const Icon(Icons.pets, color: Color(0xFF2E7D32)),
                title: const Text('Mis Pacientes'),
                selected: _selectedIndex == 1,
                onTap: () {
                  _onItemTapped(1);
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Color(0xFF2E7D32)),
              title: const Text('Citas'),
              selected: _selectedIndex == 2,
              onTap: () {
                _onItemTapped(2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Color(0xFF2E7D32)),
              title: const Text('Configuración'),
              selected: _selectedIndex == 3,
              onTap: () {
                _onItemTapped(3);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Cerrar Sesión'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          _buildHomeScreen(),
          widget.userType == 'veterinario' 
              ? _buildPatientsScreen() 
              : _buildVeterinariansScreen(),
          _buildAppointmentsScreen(),
          _buildSettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(widget.userType == 'veterinario' ? Icons.pets : Icons.medical_services),
            label: widget.userType == 'veterinario' ? 'Pacientes' : 'Veterinarios',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Citas',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  // PANTALLAS
  
  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de bienvenida
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2E7D32),
                    Color(0xFF1B5E20),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        backgroundImage: _userData?['foto_url'] != null
                            ? NetworkImage(_userData!['foto_url'])
                            : null,
                        child: _userData?['foto_url'] == null
                            ? const Icon(Icons.person, size: 30, color: Color(0xFF2E7D32))
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¡Bienvenido, ${_userData?['nombre'] ?? 'Usuario'}!',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              widget.userType == 'veterinario'
                                  ? 'Veterinario'
                                  : 'Dueño de mascota',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Citas\nPendientes',
                        '3',
                        Icons.calendar_today,
                      ),
                      _buildStatCard(
                        widget.userType == 'veterinario'
                            ? 'Pacientes\nActivos'
                            : 'Veterinarios',
                        widget.userType == 'veterinario' ? '15' : '2',
                        widget.userType == 'veterinario'
                            ? Icons.pets
                            : Icons.medical_services,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Próximas citas
          const Text(
            'Próximas Citas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _buildAppointmentCard(
            'Dr. García', 
            'Revisión General',
            DateTime.now().add(const Duration(days: 2)),
            'Clínica Veterinaria Central',
          ),
          _buildAppointmentCard(
            'Dr. Martínez', 
            'Vacunación',
            DateTime.now().add(const Duration(days: 5)),
            'Clínica Veterinaria Norte',
          ),
          
          const SizedBox(height: 20),
          
          // Otras secciones específicas según el tipo de usuario
          if (widget.userType == 'animal')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mis Veterinarios',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildVeterinarianCard(
                  'Dra. Rodríguez',
                  'Cardiología',
                  'https://images.unsplash.com/photo-1559839734-2b71ea197ec2',
                  '4.8',
                ),
                _buildVeterinarianCard(
                  'Dr. López',
                  'Dermatología',
                  'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d',
                  '4.5',
                ),
              ],
            ),
          
          if (widget.userType == 'veterinario')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mis Pacientes Recientes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildPatientCard(
                  'Max',
                  'Perro',
                  'Labrador',
                  '3 años',
                  'https://images.unsplash.com/photo-1543466835-00a7907e9de1',
                ),
                _buildPatientCard(
                  'Luna',
                  'Gato',
                  'Siamés',
                  '2 años',
                  'https://images.unsplash.com/photo-1615497001839-b0a0eac3274c',
                ),
              ],
            ),
            
          const SizedBox(height: 20),
          
          // Consejos de salud
          const Text(
            'Consejos de Salud',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _buildHealthTipCard(
            'Alimentación Saludable',
            'Una dieta balanceada es esencial para la salud de tu mascota. Asegúrate de proporcionar alimentos de calidad y adecuados para su edad y tamaño.',
            Icons.restaurant,
          ),
          _buildHealthTipCard(
            'Ejercicio Regular',
            'El ejercicio diario es importante para mantener a tu mascota saludable y prevenir la obesidad. Las caminatas y juegos activos son excelentes opciones.',
            Icons.directions_run,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsScreen() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 10, // Simulando 10 pacientes
      itemBuilder: (context, index) {
        final animalNames = ['Max', 'Luna', 'Rocky', 'Bella', 'Charlie', 'Lucy', 'Cooper', 'Daisy', 'Buddy', 'Molly'];
        final animalTypes = ['Perro', 'Gato', 'Perro', 'Gato', 'Perro', 'Conejo', 'Perro', 'Gato', 'Pájaro', 'Perro'];
        final animalBreeds = ['Labrador', 'Siamés', 'Bulldog', 'Persa', 'Golden Retriever', 'Holandés', 'Pastor Alemán', 'Maine Coon', 'Canario', 'Beagle'];
        final animalAges = ['2 años', '3 años', '1 año', '5 años', '4 años', '2 años', '6 años', '3 años', '1 año', '2 años'];
        
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  'https://source.unsplash.com/random/300x200/?${animalTypes[index].toLowerCase()}',
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.pets, size: 50, color: Colors.grey),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animalNames[index],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${animalTypes[index]} - ${animalBreeds[index]}'),
                    Text('Edad: ${animalAges[index]}'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Ver detalles del paciente
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Ver perfil'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVeterinariansScreen() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8, // Simulando 8 veterinarios
      itemBuilder: (context, index) {
        final vetNames = ['Dr. García', 'Dra. Rodríguez', 'Dr. López', 'Dra. Martínez', 'Dr. Fernández', 'Dra. Gómez', 'Dr. Pérez', 'Dra. Sánchez'];
        final specialties = ['Medicina General', 'Cardiología', 'Dermatología', 'Ortopedia', 'Neurología', 'Oftalmología', 'Oncología', 'Cirugía'];
        final ratings = ['4.9', '4.8', '4.7', '4.9', '4.6', '4.8', '4.7', '4.9'];
        final experience = ['10 años', '15 años', '8 años', '12 años', '20 años', '7 años', '9 años', '14 años'];
        
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage('https://source.unsplash.com/random/200x200/?doctor&sig=$index'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vetNames[index],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Especialidad: ${specialties[index]}',
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Experiencia: ${experience[index]}',
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            ratings[index],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: Agendar cita
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Agendar Cita'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              // TODO: Ver perfil
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2E7D32),
                              side: const BorderSide(color: Color(0xFF2E7D32)),
                            ),
                            child: const Text('Ver Perfil'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentsScreen() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 0,
            color: Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF2E7D32), size: 30),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gestión de Citas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.userType == 'veterinario'
                              ? 'Administra tus citas con pacientes'
                              : 'Programa y gestiona tus visitas veterinarias',
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Crear nueva cita
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('+ Nueva Cita'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Próximas'),
                    Tab(text: 'Completadas'),
                    Tab(text: 'Canceladas'),
                  ],
                  labelColor: Color(0xFF2E7D32),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Color(0xFF2E7D32),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildAppointmentsList('próximas'),
                      _buildAppointmentsList('completadas'),
                      _buildAppointmentsList('canceladas'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsList(String type) {
    // Simulamos diferentes cantidades de citas según el tipo
    int count = type == 'próximas' ? 5 : (type == 'completadas' ? 8 : 2);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      itemBuilder: (context, index) {
        // Datos simulados para las citas
        Map<String, dynamic> appointmentData;
        
        if (type == 'próximas') {
          final dates = [
            DateTime.now().add(const Duration(days: 1)),
            DateTime.now().add(const Duration(days: 3)),
            DateTime.now().add(const Duration(days: 5)),
            DateTime.now().add(const Duration(days: 7)),
            DateTime.now().add(const Duration(days: 10)),
          ];
          
          appointmentData = {
            'title': 'Cita con ${widget.userType == 'veterinario' ? 'Max (Labrador)' : 'Dr. García'}',
            'description': widget.userType == 'veterinario' 
                ? 'Chequeo de rutina - Paciente canino'
                : 'Revisión general y vacunas',
            'date': dates[index],
            'status': 'confirmada',
            'color': const Color(0xFF2E7D32),
          };
        } else if (type == 'completadas') {
          final dates = [
            DateTime.now().subtract(const Duration(days: 3)),
            DateTime.now().subtract(const Duration(days: 10)),
            DateTime.now().subtract(const Duration(days: 17)),
            DateTime.now().subtract(const Duration(days: 24)),
            DateTime.now().subtract(const Duration(days: 31)),
            DateTime.now().subtract(const Duration(days: 38)),
            DateTime.now().subtract(const Duration(days: 45)),
            DateTime.now().subtract(const Duration(days: 52)),
          ];
          
          appointmentData = {
            'title': 'Cita con ${widget.userType == 'veterinario' ? 'Luna (Siamés)' : 'Dr. Martínez'}',
            'description': widget.userType == 'veterinario' 
                ? 'Vacunación antirrábica'
                : 'Tratamiento dental',
            'date': dates[index],
            'status': 'completada',
            'color': Colors.blue,
          };
        } else {
          final dates = [
            DateTime.now().subtract(const Duration(days: 5)),
            DateTime.now().subtract(const Duration(days: 12)),
          ];
          
          appointmentData = {
            'title': 'Cita con ${widget.userType == 'veterinario' ? 'Rocky (Bulldog)' : 'Dra. Rodríguez'}',
            'description': widget.userType == 'veterinario' 
                ? 'Revisión dermatológica'
                : 'Consulta de seguimiento',
            'date': dates[index],
            'status': 'cancelada',
            'color': Colors.red,
          };
        }
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: appointmentData['color'].withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today,
                color: appointmentData['color'],
                size: 30,
              ),
            ),
            title: Text(
              appointmentData['title'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(appointmentData['description']),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${appointmentData['date'].day}/${appointmentData['date'].month}/${appointmentData['date'].year} - 10:00 AM',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: appointmentData['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    appointmentData['status'],
                    style: TextStyle(
                      color: appointmentData['color'],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () {
              // TODO: Ver detalles de la cita
            },
          ),
        );
      },
    );
  }

  Widget _buildSettingsScreen() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Configuración',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        
        // Sección de perfil
        const Text(
          'Perfil',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF2E7D32)),
                title: const Text('Editar perfil'),
                subtitle: const Text('Actualiza tu información personal'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navegar a la pantalla de edición de perfil
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.image, color: Color(0xFF2E7D32)),
                title: const Text('Cambiar foto de perfil'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Cambiar foto de perfil
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.lock, color: Color(0xFF2E7D32)),
                title: const Text('Cambiar contraseña'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Cambiar contraseña
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Sección de notificaciones
        const Text(
          'Notificaciones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active, color: Color(0xFF2E7D32)),
                title: const Text('Notificaciones push'),
                subtitle: const Text('Recibir notificaciones en tu dispositivo'),
                value: true, // TODO: Conectar con el estado real
                activeColor: const Color(0xFF2E7D32),
                onChanged: (value) {
                  // TODO: Cambiar preferencia de notificaciones push
                },
              ),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.email, color: Color(0xFF2E7D32)),
                title: const Text('Notificaciones por correo'),
                subtitle: const Text('Recibir notificaciones por correo electrónico'),
                value: true, // TODO: Conectar con el estado real
                activeColor: const Color(0xFF2E7D32),
                onChanged: (value) {
                  // TODO: Cambiar preferencia de notificaciones por correo
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Sección de preferencias
        const Text(
          'Preferencias',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode, color: Color(0xFF2E7D32)),
                title: const Text('Modo oscuro'),
                subtitle: const Text('Cambiar entre tema claro y oscuro'),
                value: false, // TODO: Conectar con el estado real
                activeColor: const Color(0xFF2E7D32),
                onChanged: (value) {
                  // TODO: Cambiar tema
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.language, color: Color(0xFF2E7D32)),
                title: const Text('Idioma'),
                subtitle: const Text('Español'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Cambiar idioma
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Sección de ayuda y soporte
        const Text(
          'Ayuda y Soporte',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.help, color: Color(0xFF2E7D32)),
                title: const Text('Centro de ayuda'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navegar al centro de ayuda
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.contact_support, color: Color(0xFF2E7D32)),
                title: const Text('Contactar soporte'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Contactar soporte
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info, color: Color(0xFF2E7D32)),
                title: const Text('Acerca de Goyo'),
                subtitle: const Text('Versión 1.0'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Mostrar información sobre la app
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // Sección de cuenta
        const Text(
          'Cuenta',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar sesión'),
            onTap: _logout,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // WIDGETS AUXILIARES
  
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(String doctorName, String reason, DateTime date, String location) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today,
                color: Color(0xFF2E7D32),
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(reason),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${date.day}/${date.month}/${date.year} - 10:00 AM',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVeterinarianCard(String name, String specialty, String imageUrl, String rating) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[200],
                    child: const Icon(Icons.person, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(specialty),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {
                // TODO: Ver perfil del veterinario
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(String name, String type, String breed, String age, String imageUrl) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[200],
                    child: const Icon(Icons.pets, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$type - $breed'),
                  const SizedBox(height: 4),
                  Text('Edad: $age'),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {
                // TODO: Ver perfil del paciente
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTipCard(String title, String content, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}