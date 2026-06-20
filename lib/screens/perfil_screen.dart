import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

const _kBg     = Color(0xFFFFF9F2);
const _kDark   = Color(0xFF1C1140);
const _kMuted  = Color(0xFF8E8EA9);
const _kPurple = Color(0xFF6B46F6);
const _kYellow = Color(0xFFFFCC00);

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _floatCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Consumer<AuthProvider>(
        builder: (_, auth, __) {
          if (auth.usuario == null) {
            return const Center(
              child: Text('No autenticado',
                  style: TextStyle(color: _kMuted, fontSize: 16)));
          }

          final usuario  = auth.usuario!;
          final inicial  = usuario.nombre.isNotEmpty
              ? usuario.nombre[0].toUpperCase() : '?';
          final isAdmin  = usuario.rol == 'admin';
          final accent   = isAdmin ? _kYellow : _kPurple;
          final accentBg = isAdmin
              ? const Color(0xFFFFF8E1) : const Color(0xFFEFEBFF);
          final roleEmoji  = isAdmin ? '👑' : '🎓';
          final roleLabel  = isAdmin ? 'Administrador' : 'Estudiante';

          return Stack(
            children: [
              // Background blobs
              Positioned(top: -40, right: -40,
                child: Container(width: 200, height: 200,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.07),
                    shape: BoxShape.circle))),
              Positioned(bottom: -30, left: -30,
                child: Container(width: 140, height: 140,
                  decoration: BoxDecoration(
                    color: _kYellow.withValues(alpha: 0.12),
                    shape: BoxShape.circle))),

              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Back button ─────────────────────────────────────
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

                      const SizedBox(height: 20),

                      // ── Avatar ──────────────────────────────────────────
                      Center(
                        child: AnimatedBuilder(
                          animation: _floatAnim,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, _floatAnim.value), child: child),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 110, height: 110,
                                decoration: BoxDecoration(
                                  color: accentBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: accent, width: 3),
                                  boxShadow: [BoxShadow(
                                    color: accent.withValues(alpha: 0.25),
                                    blurRadius: 24, offset: const Offset(0, 12))],
                                ),
                                child: Center(
                                  child: Text(inicial, style: TextStyle(
                                    fontSize: 46, fontWeight: FontWeight.w900,
                                    color: accent)),
                                ),
                              ),
                              Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: accent.withValues(alpha: 0.3), width: 2)),
                                child: Center(
                                  child: Text(roleEmoji,
                                      style: const TextStyle(fontSize: 16))),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Name + role ─────────────────────────────────────
                      Text(usuario.nombre, textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w900,
                          color: _kDark)),
                      const SizedBox(height: 6),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: accentBg,
                            borderRadius: BorderRadius.circular(20)),
                          child: Text('$roleEmoji $roleLabel',
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: accent)),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Stats bar ───────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [BoxShadow(
                            color: _kDark.withValues(alpha: 0.05),
                            blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatCell('⭐', '${usuario.puntosTotales}',
                                'Puntos', _kYellow),
                            Container(width: 1, height: 40,
                                color: const Color(0xFFE5E7EB)),
                            _StatCell(roleEmoji, roleLabel, 'Rol', accent),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Info card ───────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [BoxShadow(
                            color: _kDark.withValues(alpha: 0.05),
                            blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(width: 4, height: 18,
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 8),
                              const Text('Información', style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800,
                                color: _kDark)),
                            ]),
                            const SizedBox(height: 16),
                            _InfoRow('👤', 'Nombre', usuario.nombre, accent),
                            const SizedBox(height: 12),
                            _InfoRow('📧', 'Correo', usuario.email, accent),
                            const SizedBox(height: 12),
                            _InfoRow('📅', 'Miembro desde',
                              usuario.fechaRegistro.toString().split('T')[0],
                              accent),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Logout button ───────────────────────────────────
                      GestureDetector(
                        onTap: () {
                          auth.logout();
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                              blurRadius: 14, offset: const Offset(0, 6))],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('🚪', style: TextStyle(fontSize: 22)),
                              SizedBox(width: 10),
                              Text('Cerrar sesión', style: TextStyle(
                                color: Colors.white, fontSize: 17,
                                fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;
  const _StatCell(this.emoji, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 22)),
    const SizedBox(height: 4),
    Text(value, style: TextStyle(
      fontSize: 17, fontWeight: FontWeight.w900, color: color)),
    Text(label, style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600, color: _kMuted)),
  ]);
}

class _InfoRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color accent;
  const _InfoRow(this.emoji, this.label, this.value, this.accent);

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12)),
      child: Center(child: Text(emoji,
          style: const TextStyle(fontSize: 18))),
    ),
    const SizedBox(width: 12),
    Expanded(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          fontSize: 11, color: _kMuted, fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: _kDark)),
      ],
    )),
  ]);
}
