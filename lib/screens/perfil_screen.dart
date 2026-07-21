import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/plataforma_stub.dart' if (dart.library.io) '../config/plataforma_io.dart';
import '../providers/auth_provider.dart';
import '../widgets/avatar.dart';

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

  // Cambiar o quitar la foto de perfil (galería o cámara). Se comprime en
  // el cliente para que el avatar quede pequeño (<300KB).
  Future<void> _cambiarFoto(AuthProvider auth) async {
    final tieneFoto = (auth.usuario?.foto ?? '').isNotEmpty;
    final opcion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _kBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Text('Foto de perfil',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w900, color: _kDark)),
            ListTile(
              leading: const Text('🖼️', style: TextStyle(fontSize: 22)),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(ctx, 'galeria'),
            ),
            // La cámara solo tiene implementación nativa en Android; en
            // Windows/Web el plugin no la soporta y el botón no haría nada.
            if (!kIsWeb && esAndroidNativo)
              ListTile(
                leading: const Text('📷', style: TextStyle(fontSize: 22)),
                title: const Text('Tomar una foto'),
                onTap: () => Navigator.pop(ctx, 'camara'),
              ),
            if (tieneFoto)
              ListTile(
                leading: const Text('🗑️', style: TextStyle(fontSize: 22)),
                title: const Text('Quitar la foto'),
                onTap: () => Navigator.pop(ctx, 'quitar'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (opcion == null || !mounted) return;

    try {
      String? nuevaFoto;
      if (opcion == 'quitar') {
        nuevaFoto = '';
      } else {
        final picker = ImagePicker();
        final archivo = await picker.pickImage(
          source: opcion == 'camara'
              ? ImageSource.camera
              : ImageSource.gallery,
          maxWidth: 400,
          maxHeight: 400,
          imageQuality: 70,
        );
        if (archivo == null) return;
        final bytes = await archivo.readAsBytes();
        if (bytes.lengthInBytes > 300 * 1024) {
          throw Exception('La imagen es demasiado grande. Elige otra.');
        }
        nuevaFoto = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      await auth.actualizarPerfil(foto: nuevaFoto);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(opcion == 'quitar'
            ? 'Foto eliminada'
            : '📸 ¡Foto de perfil actualizada!'),
        backgroundColor: const Color(0xFF059669),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red.shade600,
      ));
    }
  }

  // Editar nombre y/o contraseña (contraseña vacía = no cambiarla)
  Future<void> _dlgEditarPerfil(AuthProvider auth) async {
    final nombreCtrl = TextEditingController(text: auth.usuario?.nombre ?? '');
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String error = '';
    bool guardando = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: _kBg,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(children: [
                  Text('✏️', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 10),
                  Text('Editar perfil',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _kDark)),
                ]),
                const SizedBox(height: 18),
                _campoPerfil(nombreCtrl, 'Nombre', false),
                const SizedBox(height: 10),
                _campoPerfil(passCtrl, 'Nueva contraseña (opcional)', true),
                const SizedBox(height: 10),
                _campoPerfil(confirmCtrl, 'Confirmar contraseña', true),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(error,
                      style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFE5E7EB), width: 1.5),
                        ),
                        child: const Center(
                            child: Text('Cancelar',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _kMuted))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: guardando
                          ? null
                          : () async {
                              final nombre = nombreCtrl.text.trim();
                              final pass = passCtrl.text;
                              if (nombre.length < 3) {
                                setS(() => error =
                                    'El nombre debe tener al menos 3 caracteres');
                                return;
                              }
                              if (pass.isNotEmpty && pass.length < 6) {
                                setS(() => error =
                                    'La contraseña debe tener al menos 6 caracteres');
                                return;
                              }
                              if (pass != confirmCtrl.text) {
                                setS(() =>
                                    error = 'Las contraseñas no coinciden');
                                return;
                              }
                              setS(() {
                                error = '';
                                guardando = true;
                              });
                              try {
                                await auth.actualizarPerfil(
                                    nombre: nombre, contrasena: pass);
                                if (ctx.mounted) Navigator.of(ctx).pop();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('✅ Perfil actualizado')),
                                  );
                                }
                              } catch (e) {
                                setS(() {
                                  guardando = false;
                                  error = e
                                      .toString()
                                      .replaceFirst('Exception: ', '');
                                });
                              }
                            },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: _kPurple
                              .withValues(alpha: guardando ? 0.6 : 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: guardando
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Guardar',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoPerfil(
          TextEditingController ctrl, String hint, bool obscure) =>
      TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: _kDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: _kMuted, fontWeight: FontWeight.w500, fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kPurple, width: 2),
          ),
        ),
      );

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

                      // ── Avatar (tócalo para cambiar la foto) ────────────
                      Center(
                        child: AnimatedBuilder(
                          animation: _floatAnim,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, _floatAnim.value), child: child),
                          child: GestureDetector(
                            onTap: () => _cambiarFoto(auth),
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
                                  child: usuario.foto.isEmpty
                                      ? Center(
                                          child: Text(inicial, style: TextStyle(
                                            fontSize: 46, fontWeight: FontWeight.w900,
                                            color: accent)),
                                        )
                                      : ClipOval(
                                          child: Avatar(
                                            foto: usuario.foto,
                                            nombre: usuario.nombre,
                                            radio: 52,
                                            color: accent,
                                          ),
                                        ),
                                ),
                                Container(
                                  width: 34, height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: accent.withValues(alpha: 0.3), width: 2)),
                                  child: const Center(
                                    child: Icon(Icons.photo_camera_rounded,
                                        size: 17, color: _kPurple)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ── Name + role + edit ──────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(usuario.nombre,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w900,
                                color: _kDark)),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _dlgEditarPerfil(auth),
                            child: Container(
                              width: 34, height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: accent.withValues(alpha: 0.3),
                                    width: 1.5),
                              ),
                              child: const Center(
                                child: Text('✏️',
                                    style: TextStyle(fontSize: 15))),
                            ),
                          ),
                        ],
                      ),
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
                            _StatCell('🔥', '${auth.racha}d',
                                'Racha', const Color(0xFFE65100)),
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
                              usuario.fechaRegistro.toIso8601String().split('T')[0],
                              accent),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Medallas ────────────────────────────────────────
                      if (usuario.medallas.isNotEmpty) ...[
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
                                    color: _kYellow,
                                    borderRadius: BorderRadius.circular(2))),
                                const SizedBox(width: 8),
                                Text(
                                  '🏅 Mis medallas (${usuario.medallas.length})',
                                  style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w800,
                                    color: _kDark)),
                              ]),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: usuario.medallas.map((m) =>
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF9F2),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: _kYellow.withValues(alpha: 0.5),
                                          width: 1.5),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(m.emoji,
                                            style: const TextStyle(fontSize: 22)),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          width: 80,
                                          child: Text(
                                            m.descripcion,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: _kMuted),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      const SizedBox(height: 4),

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
