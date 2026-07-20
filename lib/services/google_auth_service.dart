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
      // Solo Web necesita el client ID para inicializar su SDK de JS;
      // Android lo detecta solo por el package+SHA-1 registrados en Cloud Console.
      clientId: kIsWeb ? Config.googleClientIdWeb : null,
    );
  }

  // Abre el selector de cuentas de Google y devuelve el access token para
  // mandarlo al backend (POST /api/auth/google). null = el usuario canceló.
  // Se usa access token (no idToken): desde que Google migró a Identity
  // Services, el signIn() imperativo en Web ya no entrega idToken —
  // solo lo hace el botón oficial renderizado por Google, que no usamos
  // porque tenemos un botón propio. El access token sí es confiable en
  // ambas plataformas.
  static Future<String?> iniciarSesion() async {
    if (!soportado) {
      throw Exception(
          'Iniciar sesión con Google no está disponible en esta plataforma todavía.');
    }
    final cuenta = await _signIn.signIn();
    if (cuenta == null) return null;
    final auth = await cuenta.authentication;
    if (auth.accessToken == null) {
      throw Exception('Google no devolvió un token válido. Intenta de nuevo.');
    }
    return auth.accessToken;
  }

  static Future<void> cerrarSesion() async {
    try {
      await _signIn.signOut();
    } catch (_) {}
  }
}
