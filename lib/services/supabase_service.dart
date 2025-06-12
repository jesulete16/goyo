import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  // Subir imagen al storage de Supabase
  static Future<String?> uploadImage(File imageFile, String bucket, String fileName) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final uniqueFileName = '${fileName}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      await client.storage.from(bucket).uploadBinary(
        uniqueFileName,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      
      final publicUrl = client.storage.from(bucket).getPublicUrl(uniqueFileName);
      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
  
  // Subir imagen desde bytes (para web)
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
  }  // Registrar animal en la base de datos
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
      print('📤 Preparando datos para insertar animal...');
      
      final insertData = {
        'nombre': nombre,
        'correo': correo,
        'contraseña': password, // Se encriptará automáticamente por el trigger
        'ubicacion': ubicacion,
        'tipo': tipo,
        'raza': raza,
        'edad': edad,
        'altura': altura,
        'foto_url': fotoUrl,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      print('📤 Enviando datos a Supabase: $insertData');
      
      final response = await client.from('animales').insert(insertData).select().single();
      
      print('✅ Animal registrado exitosamente: $response');
      return response;
    } catch (e) {
      print('🚨 ERROR registrando animal: $e');
      if (e.toString().contains('42501')) {
        print('🚨 ERROR RLS: Problema con Row Level Security');
        print('💡 SOLUCIÓN: Ejecutar script de corrección RLS en Supabase');
      }
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
