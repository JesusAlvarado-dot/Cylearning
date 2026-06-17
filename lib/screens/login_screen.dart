import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _obscureText = true;

  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C4DFF), Color(0xFF448AFF), Color(0xFF26C6DA)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Floating emojis row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      AnimatedBuilder(
                        animation: _floatAnim,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, _floatAnim.value),
                          child: child,
                        ),
                        child: const Text('🔐',
                            style: TextStyle(fontSize: 28)),
                      ),
                      AnimatedBuilder(
                        animation: _bounceAnim,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, _bounceAnim.value),
                          child: child,
                        ),
                        child: const Text('🛡️',
                            style: TextStyle(fontSize: 90)),
                      ),
                      AnimatedBuilder(
                        animation: _floatAnim,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, -_floatAnim.value),
                          child: child,
                        ),
                        child: const Text('⭐',
                            style: TextStyle(fontSize: 28)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'CyLearn',
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 3,
                      shadows: [
                        Shadow(
                          color: Color(0x44000000),
                          offset: Offset(2, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    '¡Aprende ciberseguridad jugando!',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFFE0E0FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C4DFF).withValues(alpha: 0.25),
                          blurRadius: 40,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '¡Hola de nuevo! 👋',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2D1B69),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Inicia sesión para continuar tu aventura',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        _FunTextField(
                          controller: _emailController,
                          label: 'Correo electrónico',
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        _FunPasswordField(
                          controller: _contrasenaController,
                          obscure: _obscureText,
                          onToggle: () => setState(
                              () => _obscureText = !_obscureText),
                        ),
                        const SizedBox(height: 20),
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            if (auth.error.isNotEmpty) {
                              return _ErrorBox(message: auth.error);
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return _LoginButton(
                              loading: auth.cargando,
                              onTap: () async {
                                final navigator = Navigator.of(context);
                                await auth.login(
                                  _emailController.text.trim(),
                                  _contrasenaController.text,
                                );
                                if (!mounted) return;
                                if (auth.isAuthenticated) {
                                  final ruta =
                                      auth.usuario?.rol == 'admin'
                                          ? '/admin'
                                          : '/niveles';
                                  navigator.pushReplacementNamed(ruta);
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => Navigator.of(context)
                              .pushNamed('/registro'),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F0FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              '¿Eres nuevo? ¡Regístrate aquí! 🌟',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF7C4DFF),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _floatCtrl.dispose();
    _emailController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }
}

class _FunTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;

  const _FunTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF7C4DFF)),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFF7C4DFF), width: 2.5),
        ),
        filled: true,
        fillColor: const Color(0xFFF3F0FF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}

class _FunPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _FunPasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock_rounded,
            color: Color(0xFF7C4DFF)),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: const Color(0xFF7C4DFF),
          ),
          onPressed: onToggle,
        ),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFF7C4DFF), width: 2.5),
        ),
        filled: true,
        fillColor: const Color(0xFFF3F0FF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200, width: 1.5),
      ),
      child: Row(
        children: [
          const Text('❌ ', style: TextStyle(fontSize: 18)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _LoginButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        decoration: BoxDecoration(
          gradient: loading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                ),
          color: loading ? Colors.grey.shade300 : null,
          borderRadius: BorderRadius.circular(18),
          boxShadow: loading
              ? []
              : [
                  const BoxShadow(
                    color: Color(0x557C4DFF),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3),
                )
              : const Text(
                  '🚀  ¡Entrar!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
