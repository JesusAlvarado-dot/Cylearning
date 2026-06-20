import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './config/config.dart';
import './services/api_service.dart';
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
import './models/models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  Config.printConfig();
  ApiService.initialize();
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
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                builder: (_) => Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.cargando) {
                      return const Scaffold(
                        backgroundColor: Color(0xFF6C63FF),
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🛡️', style: TextStyle(fontSize: 80)),
                              SizedBox(height: 24),
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                'Cargando...',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return auth.isAuthenticated
                        ? const NivelesScreen()
                        : const LoginScreen();
                  },
                ),
              );
            case '/login':
              return MaterialPageRoute(settings: settings, builder: (_) => const LoginScreen());
            case '/registro':
              return MaterialPageRoute(settings: settings, builder: (_) => const RegistroScreen());
            case '/niveles':
              return MaterialPageRoute(settings: settings, builder: (_) => const NivelesScreen());
            case '/nivel':
              final nivel = settings.arguments as Nivel;
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => NivelDetailScreen(nivel: nivel),
              );
            case '/leccion':
              final leccion = settings.arguments as Leccion;
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => LeccionScreen(leccion: leccion),
              );
            case '/ejercicios':
              final leccionId = settings.arguments as String?;
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => EjerciciosScreen(leccionId: leccionId),
              );
            case '/prueba-final':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => PruebaFinalScreen(
                  nivel: args['nivel'] as Nivel,
                  lecciones: args['lecciones'] as List<Leccion>,
                ),
              );
            case '/perfil':
              return MaterialPageRoute(settings: settings, builder: (_) => const PerfilScreen());
            case '/admin':
              return MaterialPageRoute(settings: settings, builder: (_) => const AdminScreen());
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
