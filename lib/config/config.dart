import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // API
  static String get apiUrl {
    return dotenv.env['API_URL'] ?? 'http://localhost:3000/api';
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
