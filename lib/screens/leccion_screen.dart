import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

const _kBg     = Color(0xFFFFF9F2);
const _kDark   = Color(0xFF1C1140);
const _kMuted  = Color(0xFF8E8EA9);
const _kPurple = Color(0xFF6B46F6);

// One color/emoji per "page feel" cycling
const _accentColors = [
  Color(0xFF6B46F6),
  Color(0xFF0EA5E9),
  Color(0xFF059669),
  Color(0xFFF97316),
  Color(0xFFEF4444),
  Color(0xFFD946EF),
];
const _accentBgs = [
  Color(0xFFEFEBFF),
  Color(0xFFE0F2FE),
  Color(0xFFECFDF5),
  Color(0xFFFFF7ED),
  Color(0xFFFFF1F1),
  Color(0xFFFDF4FF),
];
const _headerEmojis = ['📖', '🔐', '🛡️', '🌐', '⚡', '🎯'];

class LeccionScreen extends StatefulWidget {
  final Leccion leccion;
  const LeccionScreen({super.key, required this.leccion});

  @override
  State<LeccionScreen> createState() => _LeccionScreenState();
}

class _LeccionScreenState extends State<LeccionScreen>
    with SingleTickerProviderStateMixin {
  late Future<Leccion> _leccionF;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  // Use lesson id hash to pick a consistent accent
  int get _accentIdx => widget.leccion.id.codeUnits.fold(0, (a, b) => a + b) % _accentColors.length;

  @override
  void initState() {
    super.initState();
    _leccionF = ApiService.getLeccion(widget.leccion.id);
    _bounceCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  Color get _accent => _accentColors[_accentIdx];
  Color get _accentBg => _accentBgs[_accentIdx];
  String get _emoji => _headerEmojis[_accentIdx];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: FutureBuilder<Leccion>(
        future: _leccionF,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _LoadingView(accent: _accent);
          }
          if (snap.hasError) {
            return _ErrorView(onBack: () => Navigator.of(context).pop());
          }
          final leccion = snap.data!;
          return _Body(
            leccion: leccion,
            accent: _accent,
            accentBg: _accentBg,
            emoji: _emoji,
            bounceAnim: _bounceAnim,
          );
        },
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatefulWidget {
  final Leccion leccion;
  final Color accent;
  final Color accentBg;
  final String emoji;
  final Animation<double> bounceAnim;

  const _Body({
    required this.leccion,
    required this.accent,
    required this.accentBg,
    required this.emoji,
    required this.bounceAnim,
  });

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> with SingleTickerProviderStateMixin {
  late AnimationController _btnCtrl;

  @override
  void initState() {
    super.initState();
    _btnCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 120),
      lowerBound: 0.96, upperBound: 1.0, value: 1.0,
    );
  }

  @override
  void dispose() { _btnCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // ── Header ─────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Stack(
            children: [
              // Background blobs
              Positioned(top: -30, right: -30,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.08),
                    shape: BoxShape.circle),
                )),
              Positioned(bottom: 0, left: -20,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.06),
                    shape: BoxShape.circle),
                )),

              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Back button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(children: [
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
                        const Spacer(),
                        // Tema pill
                        if (widget.leccion.tema.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.accentBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(widget.leccion.tema,
                              style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: widget.accent)),
                          ),
                      ]),
                    ),

                    const SizedBox(height: 20),

                    // Floating emoji
                    AnimatedBuilder(
                      animation: widget.bounceAnim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, widget.bounceAnim.value), child: child),
                      child: Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          color: widget.accentBg,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                            color: widget.accent.withValues(alpha: 0.25),
                            blurRadius: 22, offset: const Offset(0, 10))],
                        ),
                        child: Center(
                          child: Text(widget.emoji,
                              style: const TextStyle(fontSize: 44))),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.leccion.titulo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900,
                          color: _kDark, height: 1.3),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Stats row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatChip('📚', 'Lección', widget.accent, widget.accentBg),
                          const SizedBox(width: 8),
                          _StatChip('⚡', 'Interactivo', widget.accent, widget.accentBg),
                        ]),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Content ────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(
                    color: _kDark.withValues(alpha: 0.05),
                    blurRadius: 20, offset: const Offset(0, 6))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 4, height: 22,
                        decoration: BoxDecoration(
                          color: widget.accent,
                          borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 10),
                      const Text('Contenido', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, color: _kDark)),
                    ]),
                    const SizedBox(height: 16),
                    SelectableText(
                      widget.leccion.contenido,
                      style: const TextStyle(
                        fontSize: 15.5, color: _kDark,
                        height: 1.75, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Practice button ──────────────────────────────────────
              GestureDetector(
                onTapDown: (_) => _btnCtrl.reverse(),
                onTapUp: (_) {
                  _btnCtrl.forward();
                  Navigator.of(context).pushNamed(
                    '/ejercicios', arguments: widget.leccion.id);
                },
                onTapCancel: () => _btnCtrl.forward(),
                child: ScaleTransition(
                  scale: _btnCtrl,
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: widget.accent,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(
                        color: widget.accent.withValues(alpha: 0.4),
                        blurRadius: 18, offset: const Offset(0, 8))],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('⚡', style: TextStyle(fontSize: 26)),
                        SizedBox(width: 10),
                        Text('¡Practicar ahora!',
                          style: TextStyle(
                            color: Colors.white, fontSize: 18,
                            fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Back link
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: widget.accent.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Center(
                    child: Text('← Volver al caminito',
                      style: TextStyle(
                        color: widget.accent, fontSize: 14,
                        fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Small helpers ─────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color accent;
  final Color bg;
  const _StatChip(this.emoji, this.label, this.accent, this.bg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w700, color: accent)),
    ]),
  );
}

class _LoadingView extends StatelessWidget {
  final Color accent;
  const _LoadingView({required this.accent});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _kBg,
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('📖', style: TextStyle(fontSize: 60)),
      const SizedBox(height: 20),
      CircularProgressIndicator(color: accent, strokeWidth: 3),
      const SizedBox(height: 14),
      const Text('Cargando lección...', style: TextStyle(
        color: _kMuted, fontSize: 15, fontWeight: FontWeight.w600)),
    ])),
  );
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onBack;
  const _ErrorView({required this.onBack});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _kBg,
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('😥', style: TextStyle(fontSize: 60)),
      const SizedBox(height: 16),
      const Text('No pudimos cargar la lección',
        style: TextStyle(color: _kMuted, fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 20),
      GestureDetector(
        onTap: onBack,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _kPurple,
            borderRadius: BorderRadius.circular(16)),
          child: const Text('← Volver',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    ])),
  );
}
