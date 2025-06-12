import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtener el cliente de Supabase
  SupabaseClient get supabase => _supabase;

  // Obtener el usuario actual
  User? get currentUser => _supabase.auth.currentUser;

  // Stream para escuchar cambios de autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Iniciar sesión con email y contraseña
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Registrar usuario con email y contraseña
  Future<AuthResponse> signUpWithEmailAndPassword({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Recuperar contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Verificar si el usuario está autenticado
  bool get isAuthenticated => currentUser != null;

  // Obtener información del usuario
  Map<String, dynamic>? get userMetadata => currentUser?.userMetadata;

  // Actualizar perfil del usuario
  Future<UserResponse> updateProfile({
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(data: data),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
