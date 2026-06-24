# CyLearn Flutter - Desktop Edition

## 📦 Información del Proyecto

**CyLearn** es una plataforma educativa de ciberseguridad gamificada, ahora disponible como aplicación de escritorio con Flutter.

### ✨ Características

- ✅ **Autenticación**: Login y registro de usuarios
- ✅ **Niveles y Lecciones**: Sistema progresivo de aprendizaje
- ✅ **Ejercicios Interactivos**: Preguntas múltiples con retroalimentación
- ✅ **Perfil de Usuario**: Gestión de cuenta personal
- ✅ **Panel de Admin**: Herramientas de administración
- ✅ **Diseño Moderno**: Tema oscuro tipo ciberpunk

## 🏗️ Estructura del Proyecto

```
lib/
├── main.dart                 # Entrada principal
├── models/
│   └── models.dart          # Modelos de datos (Usuario, Nivel, Leccion, Ejercicio)
├── services/
│   └── api_service.dart     # Cliente HTTP para APIs REST
├── providers/
│   └── auth_provider.dart   # State management con Provider
├── screens/
│   ├── login_screen.dart
│   ├── registro_screen.dart
│   ├── niveles_screen.dart
│   ├── nivel_detail_screen.dart
│   ├── leccion_screen.dart
│   ├── ejercicios_screen.dart
│   ├── perfil_screen.dart
│   └── admin_screen.dart
└── widgets/                  # [Componentes reutilizables - próximamente]

windows/                       # Configuración para Windows desktop
pubspec.yaml                   # Dependencias Flutter
```

## 🚀 Requisitos Previos

- **Flutter 3.0+** instalado
- **Windows SDK** (incluido con Flutter)
- **Visual Studio 2022** o **Visual Studio Build Tools**
- **Backend Node.js** corriendo en `http://localhost:3000`

## 📋 Configuración

### 1. Instalar Dependencias

```bash
cd D:\cylearn_flutter
flutter pub get
```

### 2. Habilitar Soporte Windows

```bash
flutter config --enable-windows-desktop
```

### 3. Configurar la API

Edita `lib/services/api_service.dart` si tu backend está en una URL diferente:

```dart
static const String baseUrl = 'http://localhost:3000/api';
```

## ▶️ Ejecutar la Aplicación

### Desarrollo (Debug)

```bash
cd D:\cylearn_flutter
flutter run -d windows
```

### Compilación (Release)

```bash
cd D:\cylearn_flutter
flutter build windows --release
```

El ejecutable compilado estará en:
```
build\windows\runner\Release\cylearn_flutter.exe
```

## 🔌 Conexión con Backend

La app se conecta a los siguientes endpoints del backend Node.js:

### Autenticación
- `POST /api/auth/login` - Iniciar sesión
- `POST /api/auth/registro` - Crear cuenta

### Contenido Educativo
- `GET /api/student/niveles` - Obtener niveles
- `GET /api/student/niveles/{nivelId}/lecciones` - Lecciones de un nivel
- `GET /api/student/lecciones/{leccionId}` - Detalle de lección
- `GET /api/exercises` - Obtener ejercicios
- `POST /api/student/ejercicios/{ejercicioId}/responder` - Enviar respuesta

**Nota**: Asegúrate que tu backend Node.js esté corriendo antes de iniciar la app.

## 🎨 Personalización

### Colores y Tema

Los colores principales están definidos en las pantallas:
- Azul oscuro: `Color(0xFF0f3460)`
- Gris oscuro: `Color(0xFF1a1a2e)`
- Cyan (primario): `Colors.cyan`

Para cambiar el tema globalmente, edita `main.dart`:

```dart
theme: ThemeData(
  primaryColor: Color(0xFF0f3460),
  // ... más colores
)
```

## 🔐 Variables de Entorno

Crea un archivo `.env` (próximamente soportado):

```env
API_URL=http://localhost:3000/api
APP_NAME=CyLearn
VERSION=1.0.0
```

## 📦 Empaquetamiento

### Para distribución

```bash
flutter build windows --release
```

### Crear instalador (Windows Installer)

Se puede usar **NSIS** o **WiX Toolset**:

```bash
# Instalación de NSIS (requiere descargar)
# Luego crear script .nsi para crear MSI
```

## 🐛 Solución de Problemas

### "No Windows desktop project configured"

```bash
flutter create . --platforms windows
```

### "pub get" falla

```bash
flutter pub cache clean
flutter pub get
```

### Errores de compilación C++

Asegúrate de tener Visual Studio Build Tools:
```bash
flutter doctor
```

### Conexión rechazada con backend

Verifica que:
1. El backend Node.js esté corriendo: `npm run dev`
2. Esté en puerto 3000: `http://localhost:3000`
3. El firewall permita conexiones localhost

## 📱 Próximas Mejoras

- [ ] Soporte para Android/iOS
- [ ] Modo offline con sync
- [ ] Notificaciones locales
- [ ] Estadísticas de progreso mejoradas
- [ ] Multiplayer/competencias
- [ ] Temas personalizables

## 🔗 Enlaces Útiles

- [Flutter Docs](https://flutter.dev/docs)
- [Flutter Windows Desktop](https://flutter.dev/docs/development/platform-integration/windows)
- [Provider Pattern](https://pub.dev/packages/provider)
- [HTTP Package](https://pub.dev/packages/http)

## 📄 Licencia

Este proyecto es parte de **CyLearn** - Plataforma Educativa de Ciberseguridad

---

**⏱️ Migración completada en ~3 horas desde React a Flutter Desktop**

Para iniciar el desarrollo:
```bash
cd D:\cylearn_flutter
flutter run -d windows
```

¡Listo para aprender ciberseguridad! 🛡️
