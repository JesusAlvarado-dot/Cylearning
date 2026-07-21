import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './config/config.dart';
import './services/api_service.dart';
import './services/notification_service.dart';
import './providers/auth_provider.dart';
import './screens/login_screen.dart';
import './screens/registro_screen.dart';
import './screens/niveles_screen.dart';
import './screens/nivel_detail_screen.dart';
import './screens/leccion_screen.dart';
import './screens/ejercicios_screen.dart';
import './screens/prueba_final_screen.dart';
import './screens/perfil_screen.dart';
import './screens/admin_screen.dart';
import './screens/ranking_screen.dart';
import './screens/mis_reportes_screen.dart';
import './models/models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  Config.printConfig();
  ApiService.initialize();
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: 'CyLearn',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF0F4FF),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          // Link de invitación de organización: .../#/unirse?codigo=XXXXXX
          // (Web) o cylearn://app/unirse?codigo=XXXXXX (deep link Android
          // nativo, si se abre desde una app que ya tenga el esquema
          // registrado) — el engine de Flutter entrega "/unirse?codigo=..."
          // como ruta en ambos casos.
          final uri = Uri.tryParse(settings.name ?? '');
          if (uri != null &&
              (uri.path == '/unirse' || uri.path == 'unirse')) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => RegistroScreen(
                codigoInvitacion: uri.queryParameters['codigo'],
              ),
            );
          }

          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                builder: (_) => Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.cargando) return const _CargandoApp();
                    if (!auth.isAuthenticated) return const LoginScreen();
                    final rol = auth.usuario?.rol;
                    if (rol == 'admin' || rol == 'organizador') {
                      return const AdminScreen();
                    }
                    return const NivelesScreen();
                  },
                ),
              );
            case '/login':
              return MaterialPageRoute(settings: settings, builder: (_) => const LoginScreen());
            case '/registro':
              return MaterialPageRoute(settings: settings, builder: (_) => const RegistroScreen());
            // Las siguientes rutas requieren sesión iniciada: si alguien abre
            // el link directo (compartido, guardado, etc.) sin haber iniciado
            // sesión antes, _RutaProtegida muestra el login con un aviso en
            // vez de intentar cargar la pantalla sin datos de usuario.
            case '/niveles':
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => _RutaProtegida(builder: (_) => const NivelesScreen()),
              );
            case '/nivel':
              final nivel = settings.arguments as Nivel?;
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => _RutaProtegida(
                  builder: (_) => nivel != null
                      ? NivelDetailScreen(nivel: nivel)
                      : const NivelesScreen(),
                ),
              );
            case '/leccion':
              final leccion = settings.arguments as Leccion?;
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => _RutaProtegida(
                  builder: (_) => leccion != null
                      ? LeccionScreen(leccion: leccion)
                      : const NivelesScreen(),
                ),
              );
            case '/ejercicios':
              final leccionId = settings.arguments as String?;
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => _RutaProtegida(
                  builder: (_) => EjerciciosScreen(leccionId: leccionId),
                ),
              );
            case '/prueba-final':
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => _RutaProtegida(
                  builder: (_) => args != null
                      ? PruebaFinalScreen(
                          nivel: args['nivel'] as Nivel,
                          lecciones: args['lecciones'] as List<Leccion>,
                        )
                      : const NivelesScreen(),
                ),
              );
            case '/perfil':
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => _RutaProtegida(builder: (_) => const PerfilScreen()),
              );
            case '/admin':
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => _RutaProtegida(builder: (_) => const AdminScreen()),
              );
            case '/ranking':
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => _RutaProtegida(builder: (_) => const RankingScreen()),
              );
            case '/mis-reportes':
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => _RutaProtegida(builder: (_) => const MisReportesScreen()),
              );
            default:
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Ruta no encontrada')),
                ),
              );
          }
        },
      ),
    );
  }
}

// Envuelve una pantalla que requiere sesión iniciada. Se usa en rutas que
// alguien podría abrir directo por URL (compartida, favorito, recargada)
// sin pasar antes por el login.
class _RutaProtegida extends StatelessWidget {
  final WidgetBuilder builder;
  const _RutaProtegida({required this.builder});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.cargando) return const _CargandoApp();
        if (!auth.isAuthenticated) {
          return const LoginScreen(
            mensajeAcceso: 'Primero debes iniciar sesión para continuar',
          );
        }
        return builder(context);
      },
    );
  }
}

class _CargandoApp extends StatelessWidget {
  const _CargandoApp();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF6C63FF),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🛡️', style: TextStyle(fontSize: 80)),
          SizedBox(height: 24),
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text('Cargando...', style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    ),
  );
}
