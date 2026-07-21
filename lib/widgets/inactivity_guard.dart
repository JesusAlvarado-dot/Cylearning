import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

// Tiempo sin ninguna interacción (toques, clics, scroll) antes de cerrar
// la sesión automáticamente, por seguridad en equipos compartidos.
const tiempoInactividadSesion = Duration(minutes: 20);

// Envuelve toda la app (vía MaterialApp.builder) y observa cualquier
// interacción del usuario para reiniciar el temporizador. No bloquea nada:
// solo "escucha" los eventos que ya iban a pasar hacia los widgets de abajo.
class InactivityGuard extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  const InactivityGuard({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<InactivityGuard> createState() => _InactivityGuardState();
}

class _InactivityGuardState extends State<InactivityGuard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _reiniciarTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reiniciarTimer() {
    _timer?.cancel();
    _timer = Timer(tiempoInactividadSesion, _cerrarPorInactividad);
  }

  void _cerrarPorInactividad() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    auth.logout();
    widget.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
      arguments:
          'Cerramos tu sesión por inactividad. Vuelve a iniciar sesión para continuar.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _reiniciarTimer(),
      onPointerMove: (_) => _reiniciarTimer(),
      onPointerSignal: (_) => _reiniciarTimer(),
      onPointerHover: (_) => _reiniciarTimer(),
      child: widget.child,
    );
  }
}
