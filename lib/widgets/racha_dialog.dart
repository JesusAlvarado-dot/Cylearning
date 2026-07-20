import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

const _kBg    = Color(0xFFFFF9F2);
const _kDark  = Color(0xFF1C1140);
const _kMuted = Color(0xFF8E8EA9);
const _kFire  = Color(0xFFE65100);

/// Color de la flama según los días de racha (sube de "temperatura"):
/// naranja → azul (7+) → morada (30+) → dorada (100+)
Color colorDeRacha(int dias) {
  if (dias >= 100) return const Color(0xFFFFB800); // dorada
  if (dias >= 30) return const Color(0xFF6B46F6);  // morada
  if (dias >= 7) return const Color(0xFF0EA5E9);   // azul
  return _kFire;                                   // naranja
}

String nombreDeFlama(int dias) {
  if (dias >= 100) return '¡Flama dorada! 👑';
  if (dias >= 30) return '¡Flama morada! 💜';
  if (dias >= 7) return '¡Flama azul! 💙';
  return '¡Sigue así!';
}

/// Celebración grande estilo TikTok cuando la racha sube (a partir del día 3):
/// flama gigante del color del hito con el número de días encima.
Future<void> mostrarCelebracionRacha(BuildContext context, int dias) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (_) => _RachaCelebracion(dias: dias),
  );
}

class _RachaCelebracion extends StatefulWidget {
  final int dias;
  const _RachaCelebracion({required this.dias});

  @override
  State<_RachaCelebracion> createState() => _RachaCelebracionState();
}

class _RachaCelebracionState extends State<_RachaCelebracion>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
    // Se despide sola, como el momento de racha de TikTok
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = colorDeRacha(widget.dias);
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ScaleTransition(
          scale: _scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Flama gigante con el número de días encima
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 220,
                    color: color,
                    shadows: [
                      Shadow(
                        color: color.withValues(alpha: 0.8),
                        blurRadius: 60,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Text(
                      '${widget.dias}',
                      style: TextStyle(
                        fontSize: widget.dias >= 100 ? 56 : 72,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black38, blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '¡${widget.dias} días de racha!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                nombreDeFlama(widget.dias),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color == _kFire ? Colors.white70 : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Si la respuesta del servidor indica que hay una racha recuperable
/// (se perdió exactamente UN día), ofrece reanudarla (máx. 3 veces al mes).
/// `datos` es la respuesta de responder un ejercicio.
Future<void> ofrecerReanudarRacha(
    BuildContext context, Map<String, dynamic> datos) async {
  final recuperable = datos['racha_recuperable'] as int? ?? 0;
  final restantes = datos['reanudaciones_restantes'] as int? ?? 0;
  if (recuperable <= 0) return;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RachaDialog(
      rachaPerdida: recuperable,
      reanudacionesRestantes: restantes,
    ),
  );
}

class _RachaDialog extends StatefulWidget {
  final int rachaPerdida;
  final int reanudacionesRestantes;
  const _RachaDialog({
    required this.rachaPerdida,
    required this.reanudacionesRestantes,
  });

  @override
  State<_RachaDialog> createState() => _RachaDialogState();
}

class _RachaDialogState extends State<_RachaDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _enviando = false;

  bool get _sinOportunidades => widget.reanudacionesRestantes <= 0;

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

  Future<void> _reanudar() async {
    if (_enviando) return;
    setState(() => _enviando = true);
    try {
      final restantes =
          await context.read<AuthProvider>().reanudarRacha();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '¡Racha reanudada! 🔥 Te quedan $restantes reanudaciones este mes'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                color: _kFire.withValues(alpha: 0.25),
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
                  color: _kFire.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: _kFire, width: 3),
                ),
                child: const Center(
                  child: Text('🔥', style: TextStyle(fontSize: 56)),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '¡TU RACHA SE ROMPIÓ!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _kFire,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _sinOportunidades
                    ? 'Perdiste tu racha de ${widget.rachaPerdida} días y ya usaste tus 3 reanudaciones de este mes 😢'
                    : 'Faltaste un día y tu racha de ${widget.rachaPerdida} días está en pausa. ¿La reanudamos?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              if (!_sinOportunidades) ...[
                GestureDetector(
                  onTap: _reanudar,
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _kFire,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _kFire.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _enviando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              '¡Reanudar mi racha! 🔥',
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
                Text(
                  'Te quedan ${widget.reanudacionesRestantes} de 3 reanudaciones este mes',
                  style: const TextStyle(fontSize: 11, color: _kMuted),
                ),
                const SizedBox(height: 10),
              ],
              GestureDetector(
                onTap:
                    _enviando ? null : () => Navigator.of(context).pop(),
                child: Text(
                  _sinOportunidades
                      ? 'Empezar de nuevo desde hoy 💪'
                      : 'Dejarla ir y empezar de 0',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kMuted,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
