import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

const _kBg      = Color(0xFFFFF9F2);
const _kPurple  = Color(0xFF6B46F6);
const _kDark    = Color(0xFF1C1140);
const _kMuted   = Color(0xFF8E8EA9);
const _kYellow  = Color(0xFFFFCC00);
const _kGreen   = Color(0xFF059669);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _recordar = false;

  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;
  late AnimationController _starsCtrl;
  late Animation<double> _starsAnim;

  @override
  void initState() {
    super.initState();
    // Limpiar errores de una pantalla anterior (p. ej. registro)
    context.read<AuthProvider>().limpiarEstado();
    _floatCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _starsCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _starsAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _starsCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _starsCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── Decorative blobs ───────────────────────────────────────────
          _blob(240, _kPurple.withValues(alpha: 0.07), top: -80, right: -70),
          _blob(120, _kYellow.withValues(alpha: 0.22), top: 160, left: -40),
          _blob(180, _kGreen.withValues(alpha: 0.07), bottom: -60, right: -50),
          _blob(70,  _kPurple.withValues(alpha: 0.09), bottom: 120, left: 30),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // ── Mascot + stars ─────────────────────────────────────
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _starsAnim,
                    builder: (_, __) => Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow ring
                        Container(
                          width: 140, height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _kPurple.withValues(alpha: 0.07),
                          ),
                        ),
                        // Floating shield
                        AnimatedBuilder(
                          animation: _floatAnim,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, _floatAnim.value),
                            child: child,
                          ),
                          child: Container(
                            width: 110, height: 110,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFEBFF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _kPurple.withValues(alpha: 0.25),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('🛡️', style: TextStyle(fontSize: 52)),
                            ),
                          ),
                        ),
                        // Stars orbiting
                        Positioned(top: 10, right: 16,
                          child: Opacity(opacity: _starsAnim.value,
                            child: const Text('✨', style: TextStyle(fontSize: 20)))),
                        Positioned(bottom: 14, left: 12,
                          child: Opacity(opacity: 1.1 - _starsAnim.value,
                            child: const Text('⭐', style: TextStyle(fontSize: 16)))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text('CyLearn', style: TextStyle(
                    fontSize: 40, fontWeight: FontWeight.w900,
                    color: _kDark, letterSpacing: 0.5,
                  )),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _kYellow.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('¡Aprende a ser un héroe digital! 🚀',
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700,
                        color: Color(0xFF7A5800),
                      )),
                  ),
                  const SizedBox(height: 28),

                  // ── Login card ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _kPurple.withValues(alpha: 0.08),
                          blurRadius: 30, offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(children: [
                          Text('👋', style: TextStyle(fontSize: 28)),
                          SizedBox(width: 10),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('¡Hola de nuevo!', style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900, color: _kDark)),
                            Text('Inicia sesión para continuar', style: TextStyle(
                              fontSize: 12, color: _kMuted)),
                          ]),
                        ]),
                        const SizedBox(height: 22),
                        _GameField(
                          ctrl: _emailCtrl,
                          label: 'Correo electrónico',
                          emoji: '📧',
                          type: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _GamePasswordField(
                          ctrl: _passwordCtrl,
                          obscure: _obscure,
                          onToggle: () => setState(() => _obscure = !_obscure),
                        ),
                        const SizedBox(height: 10),
                        // Recordarme — mantiene la sesión al cerrar la app
                        GestureDetector(
                          onTap: () => setState(() => _recordar = !_recordar),
                          child: Row(
                            children: [
                              Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                  color: _recordar ? _kPurple : Colors.white,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: _recordar
                                        ? _kPurple
                                        : const Color(0xFFD1D5DB),
                                    width: 2,
                                  ),
                                ),
                                child: _recordar
                                    ? const Icon(Icons.check_rounded,
                                        size: 16, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Recordarme en este equipo',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Consumer<AuthProvider>(
                          builder: (_, auth, __) => auth.error.isNotEmpty
                              ? _ErrorBanner(auth.error)
                              : const SizedBox.shrink(),
                        ),
                        Consumer<AuthProvider>(
                          builder: (_, auth, __) => _GameButton(
                            label: '¡Entrar a la aventura! 🎮',
                            loading: auth.cargando,
                            color: _kPurple,
                            onTap: () => _doLogin(auth),
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushNamed('/registro'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _kYellow, width: 1.5),
                            ),
                            child: const Text('¿Eres nuevo? ¡Únete gratis! 🌟',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF7A5800),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              )),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doLogin(AuthProvider auth) async {
    final nav = Navigator.of(context);
    await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text,
        recordar: _recordar);
    if (!mounted) return;
    if (!auth.isAuthenticated) return;

    if (auth.usuario?.rol == 'admin') {
      nav.pushReplacementNamed('/admin');
      return;
    }

    // Load progress then navigate to the current caminito
    await auth.loadProgreso();
    if (!mounted) return;

    try {
      final niveles = await ApiService.getNiveles();
      if (!mounted) return;
      // Sort by orden to guarantee order
      niveles.sort((a, b) => a.orden.compareTo(b.orden));
      // First nivel not yet completed
      final current = niveles.firstWhere(
        (n) => !auth.isNivelCompletado(n.id),
        orElse: () => niveles.last,
      );
      nav.pushReplacementNamed('/niveles');
      nav.pushNamed('/nivel', arguments: current);
    } catch (_) {
      // Fallback to niveles grid if fetch fails
      nav.pushReplacementNamed('/niveles');
    }
  }

  Widget _blob(double size, Color color,
      {double? top, double? bottom, double? left, double? right}) =>
      Positioned(
        top: top, bottom: bottom, left: left, right: right,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
}

// ─── Shared game widgets used in login + registro ─────────────────────────────

class _GameField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String emoji;
  final TextInputType type;

  const _GameField({
    required this.ctrl,
    required this.label,
    required this.emoji,
    this.type = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: type,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kDark),
    decoration: InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(color: _kMuted, fontWeight: FontWeight.w500),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: const Color(0xFFF8F5FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kPurple, width: 2),
      ),
    ),
  );
}

class _GamePasswordField extends StatelessWidget {
  final TextEditingController ctrl;
  final bool obscure;
  final VoidCallback onToggle;

  const _GamePasswordField({
    required this.ctrl,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    obscureText: obscure,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kDark),
    decoration: InputDecoration(
      hintText: 'Contraseña',
      hintStyle: const TextStyle(color: _kMuted, fontWeight: FontWeight.w500),
      prefixIcon: const Padding(
        padding: EdgeInsets.only(left: 14, right: 10),
        child: Text('🔑', style: TextStyle(fontSize: 20)),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: GestureDetector(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Text(obscure ? '👁️' : '🙈', style: const TextStyle(fontSize: 18)),
        ),
      ),
      filled: true,
      fillColor: const Color(0xFFF8F5FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kPurple, width: 2),
      ),
    ),
  );
}

class _GameButton extends StatefulWidget {
  final String label;
  final bool loading;
  final Color color;
  final VoidCallback onTap;

  const _GameButton({
    required this.label,
    required this.loading,
    required this.color,
    required this.onTap,
  });

  @override
  State<_GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<_GameButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 120),
      lowerBound: 0.95, upperBound: 1.0, value: 1.0,
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: widget.loading ? null : (_) => _ctrl.reverse(),
    onTapUp: widget.loading ? null : (_) { _ctrl.forward(); widget.onTap(); },
    onTapCancel: () => _ctrl.forward(),
    child: ScaleTransition(
      scale: _ctrl,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: widget.loading ? widget.color.withValues(alpha: 0.7) : widget.color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: widget.loading
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
              : Text(widget.label, style: const TextStyle(
                  color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.w800, letterSpacing: 0.3)),
        ),
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
    ),
    child: Row(children: [
      const Text('❌', style: TextStyle(fontSize: 18)),
      const SizedBox(width: 8),
      Expanded(child: Text(message, style: const TextStyle(
        color: Color(0xFFB91C1C), fontSize: 13, fontWeight: FontWeight.w600))),
    ]),
  );
}
