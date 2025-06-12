import 'package:flutter/material.dart';

class MenuVeterinario extends StatelessWidget {
  final Map<String, dynamic> userData;

  const MenuVeterinario({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menú Veterinario - ${userData['nombre']}'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Menú de Veterinario - En construcción',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}