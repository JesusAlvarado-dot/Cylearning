import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';

const _kBg     = Color(0xFFFFF9F2);
const _kPurple = Color(0xFF6B46F6);
const _kDark   = Color(0xFF1C1140);
const _kMuted  = Color(0xFF8E8EA9);
const _kYellow = Color(0xFFFFCC00);
const _kGreen  = Color(0xFF059669);

class RegistroScreen extends StatefulWidget {
  // Código que llega por link de invitación (.../#/unirse?codigo=X):
  // se aplica automáticamente y no se pide en el formulario
  final String? codigoInvitacion;
  const RegistroScreen({super.key, this.codigoInvitacion});
  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _codigoCtrl  = TextEditingController();
  bool _obscure = true;

  // Info de la organización cuando se llega por link de invitación
  InfoInvitacion? _invitacion;
  bool _invitacionInvalida = false;

  bool get _vieneDeInvitacion =>
      widget.codigoInvitacion != null &&
      widget.codigoInvitacion!.trim().isNotEmpty;

  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    // Sin esto, registroExitoso=true de una visita anterior cierra la pantalla
    // (síncrono, antes del primer build; no notifica listeners)
    context.read<AuthProvider>().limpiarEstado();
    _floatCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    if (_vieneDeInvitacion) {
      _codigoCtrl.text = widget.codigoInvitacion!.trim();
      _cargarInvitacion();
    }
  }

  Future<void> _cargarInvitacion() async {
    try {
      final info = await ApiService.validarCodigoOrganizacion(
          widget.codigoInvitacion!.trim());
      if (!mounted) return;
      setState(() => _invitacion = info);
    } catch (_) {
      if (!mounted) return;
      setState(() => _invitacionInvalida = true);
    }
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _codigoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── Blobs ─────────────────────────────────────────────────────
          _blob(220, _kGreen.withValues(alpha: 0.07), top: -70, left: -60),
          _blob(140, _kYellow.withValues(alpha: 0.2), top: 200, right: -50),
          _blob(160, _kPurple.withValues(alpha: 0.07), bottom: -50, left: -40),
          _blob(70,  _kGreen.withValues(alpha: 0.1), bottom: 100, right: 20),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // ── Back + mascot ──────────────────────────────────────
                  Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(
                            color: _kDark.withValues(alpha: 0.07),
                            blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18, color: _kDark),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),

                  // Floating mascot
                  AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _floatAnim.value), child: child),
                    child: Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                          color: _kGreen.withValues(alpha: 0.2),
                          blurRadius: 22, offset: const Offset(0, 10))],
                      ),
                      child: const Center(
                        child: Text('🚀', style: TextStyle(fontSize: 44))),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('¡Únete a CyLearn!',
                    style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900, color: _kDark)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('¡Crea tu cuenta y empieza a aprender! 🎮',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: Color(0xFF065F46))),
                  ),
                  const SizedBox(height: 24),

                  // ── Card form ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(
                        color: _kGreen.withValues(alpha: 0.08),
                        blurRadius: 30, offset: const Offset(0, 10))],
                    ),
                    child: Consumer<AuthProvider>(
                      builder: (_, auth, __) {
                        // Auto-go-back on success. Si se llegó por link de
                        // invitación no hay pantalla debajo: ir al login en
                        // vez de hacer pop (que cerraría la app)
                        if (auth.registroExitoso) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              final nav = Navigator.of(context);
                              if (nav.canPop()) {
                                nav.pop();
                              } else {
                                nav.pushReplacementNamed('/login');
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    '🎉 ¡Cuenta creada! Inicia sesión para jugar.',
                                    style: TextStyle(fontWeight: FontWeight.w700)),
                                  backgroundColor: _kGreen,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          });
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _RegField(ctrl: _nameCtrl, label: 'Tu nombre', emoji: '👤'),
                            const SizedBox(height: 12),
                            _RegField(ctrl: _emailCtrl, label: 'Correo electrónico',
                              emoji: '📧', type: TextInputType.emailAddress),
                            const SizedBox(height: 12),
                            _RegPasswordField(
                              ctrl: _passCtrl, obscure: _obscure,
                              onToggle: () => setState(() => _obscure = !_obscure)),
                            const SizedBox(height: 12),
                            _RegField(ctrl: _confirmCtrl,
                              label: 'Confirmar contraseña', emoji: '✅',
                              obscureText: true),
                            const SizedBox(height: 12),
                            if (_vieneDeInvitacion) ...[
                              // Invitación por link: el código ya viene puesto
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _invitacionInvalida
                                      ? const Color(0xFFFEF2F2)
                                      : const Color(0xFFEFEBFF),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: _invitacionInvalida
                                          ? const Color(0xFFFCA5A5)
                                          : _kPurple.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                        _invitacionInvalida
                                            ? '❌'
                                            : (_invitacion?.tipo == 'docente'
                                                ? '🧑‍🏫'
                                                : '🏫'),
                                        style:
                                            const TextStyle(fontSize: 22)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _invitacionInvalida
                                            ? 'Este link de invitación ya no es válido. Pide uno nuevo a tu organización.'
                                            : _invitacion == null
                                                ? 'Verificando invitación...'
                                                : _invitacion!.tipo == 'docente'
                                                    ? 'Te unirás a "${_invitacion!.nombre}" como PROFESOR 🎓'
                                                    : 'Te unirás a "${_invitacion!.nombre}" 🎉',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: _kDark,
                                            height: 1.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              _RegField(ctrl: _codigoCtrl,
                                label: 'Código de organización (opcional)',
                                emoji: '🏫'),
                              const SizedBox(height: 6),
                              const Text(
                                'Si tu escuela u organización te dio un código, '
                                'escríbelo para unirte a su contenido',
                                style: TextStyle(fontSize: 11, color: _kMuted),
                              ),
                            ],
                            const SizedBox(height: 18),
                            if (auth.error.isNotEmpty) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFFCA5A5), width: 1),
                                ),
                                child: Row(children: [
                                  const Text('❌', style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(auth.error,
                                    style: const TextStyle(
                                      color: Color(0xFFB91C1C),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600))),
                                ]),
                              ),
                            ],
                            _GameRegButton(
                              loading: auth.cargando,
                              onTap: () {
                                if (_passCtrl.text != _confirmCtrl.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Las contraseñas no coinciden'),
                                      backgroundColor: Colors.red.shade600,
                                    ),
                                  );
                                  return;
                                }
                                auth.registro(
                                  _nameCtrl.text.trim(),
                                  _emailCtrl.text.trim(),
                                  _passCtrl.text,
                                  codigoOrganizacion: _codigoCtrl.text,
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3CD),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _kYellow, width: 1.5),
                                ),
                                child: const Text('¿Ya tienes cuenta? ¡Entra! 🏆',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF7A5800),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                              ),
                            ),
                          ],
                        );
                      },
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

class _RegField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String emoji;
  final TextInputType type;
  final bool obscureText;

  const _RegField({
    required this.ctrl,
    required this.label,
    required this.emoji,
    this.type = TextInputType.text,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: type,
    obscureText: obscureText,
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
      fillColor: const Color(0xFFF0FDF4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kGreen, width: 2),
      ),
    ),
  );
}

class _RegPasswordField extends StatelessWidget {
  final TextEditingController ctrl;
  final bool obscure;
  final VoidCallback onToggle;
  const _RegPasswordField({
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
      fillColor: const Color(0xFFF0FDF4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _kGreen, width: 2),
      ),
    ),
  );
}

class _GameRegButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GameRegButton({required this.loading, required this.onTap});

  @override
  State<_GameRegButton> createState() => _GameRegButtonState();
}

class _GameRegButtonState extends State<_GameRegButton>
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
          color: widget.loading ? _kGreen.withValues(alpha: 0.7) : _kGreen,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
            color: _kGreen.withValues(alpha: 0.4),
            blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: widget.loading
              ? const SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
              : const Text('¡Crear mi cuenta! 🎉',
                  style: TextStyle(
                    color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.w800)),
        ),
      ),
    ),
  );
}
