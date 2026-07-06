import 'package:flutter/material.dart';

const _kBg    = Color(0xFFFFF9F2);
const _kDark  = Color(0xFF1C1140);
const _kMuted = Color(0xFF8E8EA9);

String _emojiDeMedalla(String tipo) {
  switch (tipo) {
    case 'oro':      return '🥇';
    case 'plata':    return '🥈';
    case 'bronce':   return '🥉';
    case 'estrella': return '⭐';
    default:         return '🏅';
  }
}

Color _colorDeMedalla(String tipo) {
  switch (tipo) {
    case 'oro':      return const Color(0xFFFFB800);
    case 'plata':    return const Color(0xFF9CA3AF);
    case 'bronce':   return const Color(0xFFB45309);
    case 'estrella': return const Color(0xFF6B46F6);
    default:         return const Color(0xFFFFB800);
  }
}

/// Muestra la celebración de una medalla recién ganada.
/// `medalla` es el mapa {tipo, descripcion} que devuelve el backend.
Future<void> showMedallaDialog(
    BuildContext context, Map<String, dynamic> medalla) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _MedallaDialog(
      tipo: (medalla['tipo'] ?? '').toString(),
      descripcion: (medalla['descripcion'] ?? '').toString(),
    ),
  );
}

class _MedallaDialog extends StatefulWidget {
  final String tipo;
  final String descripcion;
  const _MedallaDialog({required this.tipo, required this.descripcion});

  @override
  State<_MedallaDialog> createState() => _MedallaDialogState();
}

class _MedallaDialogState extends State<_MedallaDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _colorDeMedalla(widget.tipo);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 3),
                ),
                child: Center(
                  child: Text(
                    _emojiDeMedalla(widget.tipo),
                    style: const TextStyle(fontSize: 56),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '¡NUEVA MEDALLA!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.descripcion,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '¡Genial! 🎉',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'La encontrarás en tu perfil',
                style: TextStyle(fontSize: 11, color: _kMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
