import 'package:flutter/material.dart';

class MenuAnimal extends StatelessWidget {
  final Map<String, dynamic> userData;

  const MenuAnimal({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menú Animal - ${userData['nombre']}'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Menú de Animal - En construcción',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}