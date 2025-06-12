# 🐾 GOYO - Sistema Veterinario

Una aplicación Flutter moderna para la gestión veterinaria con interfaz premium y funcionalidades completas para veterinarios y dueños de mascotas.

![Flutter](https://img.shields.io/badge/Flutter-3.27.1-blue.svg)
![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%20|%20Android%20|%20Web%20|%20Desktop-lightgrey.svg)

## ✨ Características Principales

### 🎨 Interfaz de Usuario Premium
- **Diseño Glassmorphism**: Interfaz moderna con efectos de vidrio y transparencias
- **Animaciones Fluidas**: Transiciones suaves y efectos visuales atractivos
- **Responsive Design**: Optimizado para móvil, tablet y desktop
- **Iconos Personalizados**: Logo personalizado generado para todas las plataformas

### 🔐 Sistema de Autenticación
- **Login Seguro**: Autenticación con Supabase
- **Registro Dual**: Perfiles separados para veterinarios y dueños de mascotas
- **Recuperación de Contraseña**: Sistema de reset por email
- **Validación de Credenciales**: Verificación de número colegial para veterinarios

### 📱 Funcionalidades Veterinarios
- **Registro Profesional**: Con especialidad, número colegial y experiencia
- **Dashboard Personalizado**: Panel de control con estadísticas
- **Gestión de Pacientes**: Lista y seguimiento de animales
- **Historial Médico**: Registro completo de consultas y tratamientos

### 🐕 Funcionalidades Dueños de Mascotas
- **Registro de Mascotas**: Con fotos, raza, edad y características
- **Búsqueda de Veterinarios**: Por ubicación y especialidad
- **Citas Médicas**: Programación y seguimiento
- **Historial de Salud**: Registro completo de la mascota

### 🖼️ Gestión de Imágenes
- **Subida de Fotos**: Para perfiles y mascotas
- **Almacenamiento en la Nube**: Integrado con Supabase Storage
- **Optimización Automática**: Redimensionamiento y compresión
- **Soporte Multiplataforma**: Web, móvil y desktop

## 🏗️ Arquitectura Técnica

### Frontend
- **Flutter 3.27.1**: Framework multiplataforma
- **Material Design 3**: Sistema de diseño moderno
- **Animaciones Personalizadas**: Controllers y Tweens
- **Responsive Layout**: Adaptive UI para todos los tamaños

### Backend
- **Supabase**: Backend as a Service
- **PostgreSQL**: Base de datos relacional
- **Real-time**: Actualizaciones en tiempo real
- **Storage**: Almacenamiento de archivos

### Arquitectura de Datos
```
📁 Database Schema
├── 👨‍⚕️ veterinarios
│   ├── id (UUID, PK)
│   ├── nombre (TEXT)
│   ├── correo (TEXT, UNIQUE)
│   ├── contraseña (TEXT, ENCRYPTED)
│   ├── ubicacion (TEXT)
│   ├── especialidad (TEXT)
│   ├── numero_colegiado (TEXT)
│   ├── años_experiencia (INTEGER)
│   ├── telefono (TEXT)
│   └── foto_url (TEXT)
│
└── 🐾 animales
    ├── id (UUID, PK)
    ├── nombre (TEXT)
    ├── correo (TEXT, UNIQUE)
    ├── contraseña (TEXT, ENCRYPTED)
    ├── ubicacion (TEXT)
    ├── tipo (TEXT)
    ├── raza (TEXT)
    ├── edad (TEXT)
    ├── altura (TEXT)
    └── foto_url (TEXT)
```

## 📁 Estructura del Proyecto

```
lib/
├── 🏠 main.dart                 # Punto de entrada de la aplicación
├── 🖥️ dashboard.dart            # Panel principal dual (vet/animal)
├── 🔐 login.dart                # Pantalla de inicio de sesión
├── 📋 register_menu.dart        # Menú de selección de registro
├── 🐕 register_animal.dart      # Registro de mascotas
├── 👨‍⚕️ register_veterinario.dart # Registro de veterinarios
├── ⭐ splashscreen.dart         # Pantalla de carga inicial
└── 🔧 services/
    ├── auth_service.dart        # Servicio de autenticación
    └── supabase_service.dart    # Cliente de Supabase
```

## 🚀 Instalación y Configuración

### Prerrequisitos
- Flutter SDK 3.27.1 o superior
- Dart SDK 3.6.0 o superior
- Editor: VS Code o Android Studio
- Cuenta de Supabase (para backend)

### 1. Clonar el Repositorio
```bash
git clone https://github.com/tu-usuario/goyo.git
cd goyo
```

### 2. Instalar Dependencias
```bash
flutter pub get
```

### 3. Configurar Supabase
1. Crear un proyecto en [Supabase](https://supabase.com)
2. Ejecutar los scripts SQL:
   - `supabase_database.sql` - Esquema de la base de datos
   - `supabase_sample_data.sql` - Datos de ejemplo
3. Actualizar las credenciales en `lib/main.dart`:
   ```dart
   await Supabase.initialize(
     url: 'TU_SUPABASE_URL',
     anonKey: 'TU_SUPABASE_ANON_KEY',
   );
   ```

### 4. Generar Iconos (Opcional)
```bash
dart run flutter_launcher_icons
```

### 5. Ejecutar la Aplicación
```bash
# Desarrollo
flutter run

# Web
flutter run -d chrome

# Producción
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web
```

## 📱 Capturas de Pantalla

### 🔐 Login Premium
- Diseño glassmorphism con gradientes
- Animación del logo al iniciar
- Validación en tiempo real

### 📋 Registro Inteligente
- Formularios adaptativos por tipo de usuario
- Subida de imágenes drag & drop
- Validación de credenciales profesionales

### 🖥️ Dashboard Dual
- Interfaz diferenciada por rol
- Estadísticas en tiempo real
- Navegación intuitiva

## 🔧 Tecnologías Utilizadas

| Categoría | Tecnología | Versión |
|-----------|------------|---------|
| **Framework** | Flutter | 3.27.1 |
| **Lenguaje** | Dart | 3.6.0 |
| **Backend** | Supabase | 2.8.0 |
| **Base de Datos** | PostgreSQL | 15+ |
| **Autenticación** | Supabase Auth | 2.13.0 |
| **Storage** | Supabase Storage | 2.4.0 |
| **Imágenes** | Image Picker | 1.0.4 |
| **Iconos** | Flutter Launcher Icons | 0.13.1 |

## 🎯 Roadmap Futuro

### Fase 2 - Funcionalidades Avanzadas
- [ ] 💬 Chat en tiempo real veterinario-cliente
- [ ] 📊 Analytics y reportes avanzados
- [ ] 🔔 Sistema de notificaciones push
- [ ] 📱 App móvil nativa optimizada

### Fase 3 - Integraciones
- [ ] 💳 Pagos en línea (Stripe)
- [ ] 📧 Notificaciones por email
- [ ] 🗓️ Integración con calendarios
- [ ] 🏥 Integración con sistemas hospitalarios

### Fase 4 - Inteligencia Artificial
- [ ] 🤖 Diagnóstico asistido por IA
- [ ] 📈 Predicción de enfermedades
- [ ] 🎯 Recomendaciones personalizadas
- [ ] 📝 Transcripción automática de consultas

## 👥 Contribuciones

¡Las contribuciones son bienvenidas! Por favor, revisa las [guías de contribución](CONTRIBUTING.md) antes de enviar un PR.

### Proceso de Contribución
1. Fork el proyecto
2. Crea una rama feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 📞 Contacto y Soporte

- **Desarrollador**: Goyo Development Team
- **Email**: goyo.dev@example.com
- **Issues**: [GitHub Issues](https://github.com/tu-usuario/goyo/issues)
- **Documentación**: [Wiki del Proyecto](https://github.com/tu-usuario/goyo/wiki)

## 🙏 Agradecimientos

- [Flutter Team](https://flutter.dev) por el increíble framework
- [Supabase](https://supabase.com) por el backend como servicio
- [Material Design](https://material.io) por las guías de diseño
- Comunidad Flutter por el soporte constante

---

<div align="center">
  <b>Hecho con ❤️ para el cuidado animal</b>
  <br>
  <sub>© 2025 GOYO. Todos los derechos reservados.</sub>
</div>
