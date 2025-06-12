import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Wrapper que maneja problemas comunes de Flutter Web
class FlutterWebWrapper extends StatefulWidget {
  final Widget child;

  const FlutterWebWrapper({
    super.key,
    required this.child,
  });

  @override
  State<FlutterWebWrapper> createState() => _FlutterWebWrapperState();
}

class _FlutterWebWrapperState extends State<FlutterWebWrapper> {
  @override
  void initState() {
    super.initState();
    
    // Configuración específica para Flutter Web
    if (kIsWeb) {
      // Agregar listener para manejar errores de elementos activos
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupWebErrorHandling();
      });
    }
  }

  void _setupWebErrorHandling() {
    // Configurar manejo de errores específicos de web
    FlutterError.onError = (FlutterErrorDetails details) {
      final exception = details.exception;
      
      // Filtrar errores conocidos de Flutter Web
      if (exception.toString().contains('position helper') ||
          exception.toString().contains('input element') ||
          exception.toString().contains('active element') ||
          exception.toString().contains('pointer binding')) {
        // Log del error pero no hacer crash
        if (kDebugMode) {
          print('Flutter Web Error filtrado: ${exception.toString()}');
        }
        return;
      }
      
      // Para otros errores, usar el handler por defecto
      FlutterError.presentError(details);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return GestureDetector(
        // Manejar taps para evitar problemas de elementos activos
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Focus(
          autofocus: false,
          child: widget.child,
        ),
      );
    }
    
    return widget.child;
  }
}
