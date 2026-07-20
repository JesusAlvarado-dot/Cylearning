import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import condicional: en web (sin dart:io) usa el stub que devuelve false;
// en plataformas nativas consulta Platform.isAndroid de verdad.
import 'plataforma_stub.dart' if (dart.library.io) 'plataforma_io.dart';

class Config {
  // API
  static String get apiUrl {
    final url = dotenv.env['API_URL'] ?? 'http://localhost:3000/api';

    // El emulador de Android no comparte el "localhost" con la PC: ese nombre
    // dentro del emulador se refiere a sí mismo, no al host. 10.0.2.2 es la
    // IP especial que el emulador mapea al localhost de la máquina anfitriona.
    if (!kIsWeb && esAndroidNativo) {
      return url
          .replaceFirst('localhost', '10.0.2.2')
          .replaceFirst('127.0.0.1', '10.0.2.2');
    }

    return url;
  }

  // App Info
  static String get appName {
    return dotenv.env['APP_NAME'] ?? 'CyLearn';
  }

  static String get version {
    return dotenv.env['VERSION'] ?? '1.0.0';
  }

  // Debug Mode
  static bool get isDebug {
    return dotenv.env['DEBUG'] == 'true';
  }

  // API Settings
  static int get apiTimeout {
    return int.parse(dotenv.env['API_TIMEOUT'] ?? '30');
  }

  // URL pública de la web desplegada, usada para armar links que cualquiera
  // pueda abrir (invitaciones de organización), a diferencia de apiUrl que
  // puede apuntar a localhost/10.0.2.2 en desarrollo.
  static String get appUrl {
    final url = dotenv.env['APP_URL'] ?? 'https://cylearn-web.onrender.com';
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  // Client ID del cliente OAuth "Web" de Google Cloud Console. Se usa tanto
  // para iniciar sesión en Web como de serverClientId en Android, para que
  // el backend verifique el idToken con un único audience.
  static String get googleClientIdWeb {
    return dotenv.env['GOOGLE_CLIENT_ID_WEB'] ?? '';
  }

  // Display all config (para debugging)
  static void printConfig() {
    if (isDebug) {
      debugPrint('=== CyLearn Configuration ===');
      debugPrint('API URL: $apiUrl');
      debugPrint('App Name: $appName');
      debugPrint('Version: $version');
      debugPrint('Debug Mode: $isDebug');
      debugPrint('API Timeout: $apiTimeout segundos');
      debugPrint('=============================');
    }
  }
}
