import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/config.dart';
import '../config/plataforma_stub.dart' if (dart.library.io) '../config/plataforma_io.dart';

class GoogleAuthService {
  static GoogleSignIn? _instancia;

  // Windows/desktop todavía no tiene flujo propio (llegará vía navegador).
  static bool get soportado => kIsWeb || esAndroidNativo;

  static GoogleSignIn get _signIn {
    return _instancia ??= GoogleSignIn(
      scopes: const ['email', 'profile'],
      // Web: el client ID Web va directo. Android: se detecta solo por el
      // package+SHA-1 registrados en Cloud Console; se pide serverClientId
      // (el mismo client ID Web) para que el idToken tenga un audience que
      // el backend puede verificar sin importar la plataforma de origen.
      clientId: kIsWeb ? Config.googleClientIdWeb : null,
      serverClientId: kIsWeb ? null : Config.googleClientIdWeb,
    );
  }

  // Abre el selector de cuentas de Google y devuelve el idToken para
  // mandarlo al backend (POST /api/auth/google). null = el usuario canceló.
  static Future<String?> iniciarSesion() async {
    if (!soportado) {
      throw Exception(
          'Iniciar sesión con Google no está disponible en esta plataforma todavía.');
    }
    final cuenta = await _signIn.signIn();
    if (cuenta == null) return null;
    final auth = await cuenta.authentication;
    if (auth.idToken == null) {
      throw Exception('Google no devolvió un token válido. Intenta de nuevo.');
    }
    return auth.idToken;
  }

  static Future<void> cerrarSesion() async {
    try {
      await _signIn.signOut();
    } catch (_) {}
  }
}
