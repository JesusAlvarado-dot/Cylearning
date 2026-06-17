import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('🌟', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 12),
                  const Text(
                    '¡Únete a CyLearn!',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Crea tu cuenta y empieza a aprender',
                    style: TextStyle(fontSize: 15, color: Color(0xFFC8E6C9)),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Crear cuenta 🎉',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildField(
                          controller: _nombreController,
                          label: 'Tu nombre',
                          icon: Icons.person_rounded,
                          color: const Color(0xFF4CAF50),
                          fillColor: const Color(0xFFF1F8E9),
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: _emailController,
                          label: 'Correo electrónico',
                          icon: Icons.email_rounded,
                          color: const Color(0xFF4CAF50),
                          fillColor: const Color(0xFFF1F8E9),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _contrasenaController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(
                              Icons.lock_rounded,
                              color: Color(0xFF4CAF50),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: const Color(0xFF4CAF50),
                              ),
                              onPressed: () =>
                                  setState(() => _obscureText = !_obscureText),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF4CAF50),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF1F8E9),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _confirmController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            labelText: 'Confirmar contraseña',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFF4CAF50),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF4CAF50),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF1F8E9),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            if (auth.error.isNotEmpty) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEEEE),
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Text('❌ '),
                                    Expanded(
                                      child: Text(
                                        auth.error,
                                        style:
                                            const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                onPressed: auth.cargando
                                    ? null
                                    : () async {
                                        if (_nombreController.text
                                            .trim()
                                            .isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content:
                                                Text('Escribe tu nombre 😊'),
                                          ));
                                          return;
                                        }
                                        if (_contrasenaController.text !=
                                            _confirmController.text) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Las contraseñas no coinciden ❌'),
                                          ));
                                          return;
                                        }
                                        final navigator =
                                            Navigator.of(context);
                                        final messenger =
                                            ScaffoldMessenger.of(context);
                                        await auth.registro(
                                          _nombreController.text.trim(),
                                          _emailController.text.trim(),
                                          _contrasenaController.text,
                                        );
                                        if (!mounted) return;
                                        if (auth.registroExitoso) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                '🎉 ¡Cuenta creada! Ya puedes iniciar sesión',
                                              ),
                                              backgroundColor:
                                                  Color(0xFF4CAF50),
                                            ),
                                          );
                                          navigator
                                              .pushReplacementNamed('/login');
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                ),
                                child: auth.cargando
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        '🌟 ¡Crear cuenta!',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.of(context)
                              .pushReplacementNamed('/login'),
                          child: const Text(
                            '¿Ya tienes cuenta? ¡Inicia sesión!',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w600,
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    required Color fillColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 2),
        ),
        filled: true,
        fillColor: fillColor,
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _contrasenaController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}
