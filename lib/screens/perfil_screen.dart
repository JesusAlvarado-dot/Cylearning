import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.usuario == null) {
            return const Center(
              child: Text('No autenticado',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          final usuario = auth.usuario!;
          final inicial = usuario.nombre.isNotEmpty
              ? usuario.nombre[0].toUpperCase()
              : '?';
          final isAdmin = usuario.rol == 'admin';

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF3E3799)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 56,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.25),
                            child: Text(
                              inicial,
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (isAdmin)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFD93D),
                                shape: BoxShape.circle,
                              ),
                              child: const Text('👑',
                                  style: TextStyle(fontSize: 16)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        usuario.nombre,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        usuario.email,
                        style: const TextStyle(
                          color: Color(0xFFCECAFF),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? const Color(0xFFFFD93D)
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isAdmin ? '👑 Administrador' : '🎓 Estudiante',
                          style: TextStyle(
                            color: isAdmin
                                ? const Color(0xFF333333)
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información de la cuenta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333366),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        icon: Icons.person_rounded,
                        label: 'Nombre',
                        value: usuario.nombre,
                        color: const Color(0xFF6C63FF),
                      ),
                      const SizedBox(height: 10),
                      _InfoCard(
                        icon: Icons.email_rounded,
                        label: 'Correo',
                        value: usuario.email,
                        color: const Color(0xFF2196F3),
                      ),
                      const SizedBox(height: 10),
                      _InfoCard(
                        icon: Icons.badge_rounded,
                        label: 'Rol',
                        value: isAdmin ? 'Administrador' : 'Estudiante',
                        color: isAdmin
                            ? const Color(0xFFFF9800)
                            : const Color(0xFF4CAF50),
                      ),
                      const SizedBox(height: 10),
                      _InfoCard(
                        icon: Icons.calendar_today_rounded,
                        label: 'Miembro desde',
                        value: usuario.fechaRegistro
                            .toString()
                            .split(' ')[0],
                        color: const Color(0xFFE91E63),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            auth.logout();
                            Navigator.of(context)
                                .pushReplacementNamed('/login');
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text(
                            'Cerrar sesión',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333366),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
