import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const String _keyRememberMe = 'remember_me';
  static const String _keyUserData = 'user_data';
  static const String _keyUserType = 'user_type';

  // Guardar los datos del usuario cuando marque "Recuérdame"
  static Future<void> saveUserSession({
    required Map<String, dynamic> userData,
    required String userType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool(_keyRememberMe, true);
    await prefs.setString(_keyUserData, jsonEncode(userData));
    await prefs.setString(_keyUserType, userType);
    
    print('✅ Sesión guardada: ${userData['nombre']} como $userType');
  }

  // Verificar si hay una sesión guardada
  static Future<bool> hasRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  // Obtener los datos del usuario guardado
  static Future<Map<String, dynamic>?> getRememberedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    if (!rememberMe) return null;
    
    final userDataString = prefs.getString(_keyUserData);
    if (userDataString == null) return null;
    
    try {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error al decodificar datos del usuario: $e');
      return null;
    }
  }

  // Obtener el tipo de usuario guardado
  static Future<String?> getRememberedUserType() async {
    final prefs = await SharedPreferences.getInstance();
    
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    if (!rememberMe) return null;
    
    return prefs.getString(_keyUserType);
  }

  // Obtener sesión completa (datos + tipo)
  static Future<Map<String, dynamic>?> getRememberedSession() async {
    final userData = await getRememberedUserData();
    final userType = await getRememberedUserType();
    
    if (userData != null && userType != null) {
      return {
        'userData': userData,
        'userType': userType,
      };
    }
    
    return null;
  }

  // Limpiar la sesión guardada (cuando el usuario haga logout)
  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_keyRememberMe);
    await prefs.remove(_keyUserData);
    await prefs.remove(_keyUserType);
    
    print('🗑️ Sesión eliminada');
  }

  // Verificar si los datos guardados siguen siendo válidos (opcional)
  static Future<bool> isSessionValid() async {
    try {
      final session = await getRememberedSession();
      if (session == null) return false;
      
      final userData = session['userData'] as Map<String, dynamic>;
      final userType = session['userType'] as String;
      
      // Verificar que los datos esenciales estén presentes
      return userData.containsKey('id') && 
             userData.containsKey('nombre') && 
             userData.containsKey('correo') && 
             (userType == 'animal' || userType == 'veterinario');
    } catch (e) {
      print('❌ Error validando sesión: $e');
      return false;
    }
  }
}
