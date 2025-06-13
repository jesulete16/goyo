import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splashscreen.dart';
import 'login.dart';
import 'widgets/flutter_web_wrapper.dart';
import 'config/web_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar Flutter Web si estamos en web
  if (kIsWeb) {
    WebConfig.configure();
    WebConfig.setupErrorHandling();
  }
  
  // Fix para Flutter Web - Deshabilitar elementos de entrada activos problemáticos
  if (kIsWeb) {
    // Configuración específica para Flutter Web
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Forzar el foco inicial para evitar problemas de elementos activos
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }
  
  await Supabase.initialize(
    url: 'https://grssfmgkbuflvpqtcaoh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdyc3NmbWdrYnVmbHZwcXRjYW9oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk2Mzc4NDEsImV4cCI6MjA2NTIxMzg0MX0.a61pgd9vNkXhWxwP1soXth8Ih7VG8spIsSlTq-mln7E',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Goyo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
        // Configuración específica para Flutter Web
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: const FlutterWebWrapper(child: SplashScreen()),
      debugShowCheckedModeBanner: false,
      // Configuración de navegación para Flutter Web
      builder: (context, child) {
        if (kIsWeb) {
          // Wrapper específico para Flutter Web
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0), // Forzar escala de texto fija
            ),
            child: child!,
          );
        }
        return child!;
      },      routes: {
        '/login': (context) => const FlutterWebWrapper(child: LoginScreen()),
      },
    );
  }
}

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  // Subir imagen desde bytes (para web y móvil)
  static Future<String?> uploadImageBytes(Uint8List bytes, String bucket, String fileName, String extension) async {
    try {
      final uniqueFileName = '${fileName}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      await client.storage.from(bucket).uploadBinary(
        uniqueFileName,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      
      final publicUrl = client.storage.from(bucket).getPublicUrl(uniqueFileName);
      return publicUrl;
    } catch (e) {
      print('Error uploading image bytes: $e');
      return null;
    }
  }
  
  // Registrar animal en la base de datos
  static Future<Map<String, dynamic>?> registerAnimal({
    required String nombre,
    required String correo,
    required String password,
    required String ubicacion,
    required String tipo,
    required String raza,
    required String edad,
    required String altura,
    String? fotoUrl,
  }) async {
    try {
      final response = await client.from('animales').insert({
        'nombre': nombre,
        'correo': correo,
        'contraseña': password,
        'ubicacion': ubicacion,
        'tipo': tipo,
        'raza': raza,
        'edad': edad,
        'altura': altura,
        'foto_url': fotoUrl,
      }).select().single();
      
      return response;
    } catch (e) {
      print('Error registering animal: $e');
      return null;
    }
  }
  
  // Registrar veterinario en la base de datos
  static Future<Map<String, dynamic>?> registerVeterinario({
    required String nombre,
    required String correo,
    required String password,
    required String ubicacion,
    required String especialidad,
    required String numeroColegiado,
    required int anosExperiencia,
    required String telefono,
    String? fotoUrl,
  }) async {
    try {
      final response = await client.from('veterinarios').insert({
        'nombre': nombre,
        'correo': correo,
        'contraseña': password,
        'ubicacion': ubicacion,
        'especialidad': especialidad,
        'numero_colegiado': numeroColegiado,
        'años_experiencia': anosExperiencia,
        'telefono': telefono,
        'foto_url': fotoUrl,
      }).select().single();
      
      return response;
    } catch (e) {
      print('Error registering veterinario: $e');
      return null;
    }
  }
  
  // Verificar si un correo ya existe
  static Future<bool> checkEmailExists(String email, String table) async {
    try {
      final response = await client
          .from(table)
          .select('correo')
          .eq('correo', email)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }
}
