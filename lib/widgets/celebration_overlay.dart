import 'dart:math' as math;
import 'package:flutter/material.dart';

class CelebrationOverlay extends StatefulWidget {
  final bool show;
  const CelebrationOverlay({super.key, required this.show});

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _particles = _buildParticles();
    if (widget.show) _ctrl.forward();
  }

  @override
  void didUpdateWidget(CelebrationOverlay old) {
    super.didUpdateWidget(old);
    if (widget.show && !old.show) {
      _particles = _buildParticles();
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<_Particle> _buildParticles() =>
      List.generate(28, (_) => _Particle(_rng));

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value;
          return Stack(
            children: _particles.map((p) {
              final opacity =
                  (t < 0.65 ? 1.0 : 1.0 - (t - 0.65) / 0.35).clamp(0.0, 1.0);
              final dy = -(size.height * 0.75) * t * p.speed;
              final dx = p.dxBase +
                  math.sin(t * math.pi * p.wobble) * 28;
              return Positioned(
                left: p.startX * size.width,
                bottom: 80,
                child: Transform.translate(
                  offset: Offset(dx, dy),
                  child: Opacity(
                    opacity: opacity,
                    child: Text(
                      p.emoji,
                      style: TextStyle(fontSize: p.size),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double startX;
  final double dxBase;
  final double speed;
  final double wobble;
  final double size;
  final String emoji;

  static const _emojis = [
    '⭐', '🌟', '✨', '🎉', '🎊', '🏆', '💫', '🥳',
    '🎈', '🎆', '💥', '🔥', '🌈', '🎇',
  ];

  _Particle(math.Random rng)
      : startX = rng.nextDouble(),
        dxBase = (rng.nextDouble() - 0.5) * 55,
        speed = 0.35 + rng.nextDouble() * 0.65,
        wobble = 1.0 + rng.nextDouble() * 3.0,
        size = 16 + rng.nextDouble() * 24,
        emoji = _emojis[rng.nextInt(_emojis.length)];
}
