import 'package:flutter/foundation.dart';

/// Configuración específica para Flutter Web
class WebConfig {
  static void configure() {
    if (kIsWeb) {
      // Configuraciones específicas para web
      debugPrint('🌐 Configurando Flutter para Web...');
      
      // Deshabilitar debug prints en producción web
      if (kReleaseMode) {
        debugPrint = (String? message, {int? wrapWidth}) {
          // No hacer nada en release mode
        };
      }
    }
  }
  
  /// Maneja errores específicos de Flutter Web
  static bool handleWebError(dynamic error) {
    if (!kIsWeb) return false;
    
    final errorMessage = error.toString().toLowerCase();
    
    // Errores conocidos de Flutter Web que pueden ser ignorados
    final ignoredErrors = [
      'the targeted input element must be the active input element',
      'position helper',
      'pointer binding',
      'targetelement == domelement',
      'input element',
      'active element',
    ];
    
    for (final ignoredError in ignoredErrors) {
      if (errorMessage.contains(ignoredError)) {
        debugPrint('🛡️ Error de Flutter Web filtrado: $ignoredError');
        return true; // Error manejado, no propagar
      }
    }
    
    return false; // Error no manejado, propagar normalmente
  }
  
  /// Configura el manejo de errores para Flutter Web
  static void setupErrorHandling() {
    if (!kIsWeb) return;
    
    // Configurar manejo de errores de Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      if (!handleWebError(details.exception)) {
        // Solo mostrar errores que no sean de Flutter Web
        FlutterError.presentError(details);
      }
    };
    
    debugPrint('✅ Manejo de errores de Flutter Web configurado');
  }
}
