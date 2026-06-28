import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/celebration_overlay.dart';

const _kBg     = Color(0xFFFFF9F2);
const _kDark   = Color(0xFF1C1140);
const _kMuted  = Color(0xFF8E8EA9);
const _kGreen  = Color(0xFF059669);
const _kRed    = Color(0xFFEF4444);
const _kYellow = Color(0xFFFFCC00);
const _kPurple = Color(0xFF6B46F6);

class PruebaFinalScreen extends StatefulWidget {
  final Nivel nivel;
  final List<Leccion> lecciones;

  const PruebaFinalScreen({
    super.key,
    required this.nivel,
    required this.lecciones,
  });

  @override
  State<PruebaFinalScreen> createState() => _PruebaFinalScreenState();
}

class _PruebaFinalScreenState extends State<PruebaFinalScreen>
    with TickerProviderStateMixin {
  late Future<List<Ejercicio>> _ejerciciosF;

  List<Ejercicio> _ejercicios = [];
  int _currentIndex = 0;
  int? _selectedOption;
  bool _answered = false;
  bool _isCorrect = false;
  int _score = 0;
  bool _finished = false;
  bool _progressSaved = false;

  late AnimationController _feedbackCtrl;
  late Animation<double> _feedbackAnim;
  late AnimationController _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _ejerciciosF = _fetchAll();

    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _feedbackAnim = CurvedAnimation(
        parent: _feedbackCtrl, curve: Curves.elasticOut);

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  Future<List<Ejercicio>> _fetchAll() async {
    final futures =
        widget.lecciones.map((l) => ApiService.getEjercicios(l.id)).toList();
    final results = await Future.wait(futures);
    final all = results.expand((e) => e).toList();
    all.shuffle();
    return all;
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _onOptionTap(int idx) {
    if (_answered) return;
    HapticFeedback.lightImpact();
    final correct = idx == _ejercicios[_currentIndex].respuestaCorrecta;
    setState(() {
      _selectedOption = idx;
      _answered = true;
      _isCorrect = correct;
      if (correct) _score++;
    });
    _feedbackCtrl.forward(from: 0);
    _bounceCtrl.reverse().then((_) => _bounceCtrl.forward());
  }

  void _onNext() {
    if (_currentIndex < _ejercicios.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
      _feedbackCtrl.reset();
    } else {
      setState(() => _finished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: FutureBuilder<List<Ejercicio>>(
        future: _ejerciciosF,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _LoadingView();
          }
          if (snap.hasError) {
            return _ErrorView(
              error: snap.error.toString(),
              onBack: () => Navigator.of(context).pop(),
            );
          }

          if (_ejercicios.isEmpty && (snap.data?.isNotEmpty ?? false)) {
            WidgetsBinding.instance.addPostFrameCallback(
                (_) => setState(() => _ejercicios = snap.data!));
          }
          final ejercicios =
              _ejercicios.isNotEmpty ? _ejercicios : (snap.data ?? []);

          if (ejercicios.isEmpty) {
            return _EmptyView(onBack: () => Navigator.of(context).pop());
          }

          if (_finished) {
            final total = ejercicios.length;
            final pct = total > 0 ? _score / total : 0.0;
            if (!_progressSaved) {
              _progressSaved = true;
              final pctInt = (pct * 100).round();
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted) return;
                await context.read<AuthProvider>()
                    .marcarNivelCompleto(widget.nivel.id, pctInt);
              });
            }
            return Stack(
              children: [
                _CompletionView(
                  nivel: widget.nivel,
                  score: _score,
                  total: total,
                  onReplay: () => setState(() {
                    _currentIndex = 0;
                    _selectedOption = null;
                    _answered = false;
                    _isCorrect = false;
                    _score = 0;
                    _finished = false;
                    _progressSaved = false;
                    _feedbackCtrl.reset();
                    _ejerciciosF = _fetchAll();
                  }),
                  onBack: () => Navigator.of(context).pop(),
                  onNextNivel: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/niveles', (_) => false),
                ),
                CelebrationOverlay(show: pct >= 0.7),
              ],
            );
          }

          final ejercicio = ejercicios[_currentIndex];
          return SafeArea(
            child: Column(
              children: [
                _TopBar(
                  nivel: widget.nivel,
                  current: _currentIndex,
                  total: ejercicios.length,
                  score: _score,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question card — gold theme
                        ScaleTransition(
                          scale: _bounceCtrl,
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF8E1),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: _kYellow.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _questionEmoji(_currentIndex),
                                  style: const TextStyle(fontSize: 44),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  ejercicio.pregunta,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: _kDark,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...List.generate(
                          ejercicio.opciones.length,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _OptionTile(
                              label: _optionLabel(i),
                              text: ejercicio.opciones[i],
                              state: _optionState(i, ejercicio),
                              onTap: () => _onOptionTap(i),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_answered)
                          ScaleTransition(
                            scale: _feedbackAnim,
                            child: _FeedbackBanner(correct: _isCorrect),
                          ),
                        const SizedBox(height: 16),
                        if (_answered)
                          _NextButton(
                            isLast: _currentIndex == ejercicios.length - 1,
                            onTap: _onNext,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  _OptionState _optionState(int i, Ejercicio e) {
    if (!_answered) {
      return i == _selectedOption ? _OptionState.selected : _OptionState.normal;
    }
    if (i == e.respuestaCorrecta) return _OptionState.correct;
    if (i == _selectedOption) return _OptionState.wrong;
    return _OptionState.normal;
  }

  String _questionEmoji(int i) {
    const emojis = ['🏆', '🎯', '🔐', '🛡️', '⚡', '💡', '🌐', '🚀'];
    return emojis[i % emojis.length];
  }

  String _optionLabel(int i) {
    const labels = ['A', 'B', 'C', 'D'];
    return labels[i % labels.length];
  }
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final Nivel nivel;
  final int current;
  final int total;
  final int score;
  final VoidCallback onBack;

  const _TopBar({
    required this.nivel,
    required this.current,
    required this.total,
    required this.score,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(
          bottom: BorderSide(color: _kYellow.withValues(alpha: 0.3), width: 2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _kDark.withValues(alpha: 0.07),
                        blurRadius: 8, offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: _kDark),
                ),
              ),
              const SizedBox(width: 12),
              const Text('🏆', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PRUEBA FINAL',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w900,
                        color: Color(0xFF7A5800), letterSpacing: 1,
                      ),
                    ),
                    Text(
                      nivel.nombre,
                      style: const TextStyle(
                        fontSize: 11, color: _kMuted, fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '⭐ $score',
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800,
                    color: Color(0xFF7A5800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Gold progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total > 0 ? (current + 1) / total : 0,
              minHeight: 7,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(_kYellow),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${current + 1} / $total',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Option Tile ─────────────────────────────────────────────────────────────

enum _OptionState { normal, selected, correct, wrong }

class _OptionTile extends StatefulWidget {
  final String label;
  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.text,
    required this.state,
    required this.onTap,
  });
  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.state) {
      case _OptionState.correct:  return const Color(0xFFECFDF5);
      case _OptionState.wrong:    return const Color(0xFFFFF1F1);
      case _OptionState.selected: return const Color(0xFFFFF8E1);
      case _OptionState.normal:   return Colors.white;
    }
  }

  Color get _borderColor {
    switch (widget.state) {
      case _OptionState.correct:  return _kGreen;
      case _OptionState.wrong:    return _kRed;
      case _OptionState.selected: return _kYellow;
      case _OptionState.normal:   return const Color(0xFFE5E7EB);
    }
  }

  Color get _labelBg {
    switch (widget.state) {
      case _OptionState.correct:  return _kGreen;
      case _OptionState.wrong:    return _kRed;
      case _OptionState.selected: return _kYellow;
      case _OptionState.normal:   return const Color(0xFFF3F4F6);
    }
  }

  Color get _labelFg {
    switch (widget.state) {
      case _OptionState.normal: return _kMuted;
      case _OptionState.selected: return const Color(0xFF7A5800);
      default: return Colors.white;
    }
  }

  String get _icon {
    switch (widget.state) {
      case _OptionState.correct: return '✅';
      case _OptionState.wrong:   return '❌';
      default:                   return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tapCtrl.reverse(),
      onTapUp: (_) { _tapCtrl.forward(); widget.onTap(); },
      onTapCancel: () => _tapCtrl.forward(),
      child: ScaleTransition(
        scale: _tapCtrl,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: _kDark.withValues(alpha: 0.04),
                blurRadius: 6, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _labelBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w900,
                      color: _labelFg,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: _kDark,
                  ),
                ),
              ),
              if (_icon.isNotEmpty)
                Text(_icon, style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Feedback Banner ─────────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  final bool correct;
  const _FeedbackBanner({required this.correct});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: correct ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: correct ? _kGreen : _kRed, width: 1.5),
        ),
        child: Row(
          children: [
            Text(correct ? '🎉' : '💪',
                style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    correct ? '¡Correcto!' : '¡Casi!',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w900,
                      color: correct ? _kGreen : _kRed,
                    ),
                  ),
                  Text(
                    correct
                        ? '¡Excelente! Sigues sumando puntos 🌟'
                        : 'Sigue intentando, esto es la prueba final 💪',
                    style: const TextStyle(
                        fontSize: 12, color: _kMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─── Next Button ─────────────────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  final bool isLast;
  final VoidCallback onTap;
  const _NextButton({required this.isLast, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: _kYellow,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _kYellow.withValues(alpha: 0.4),
                blurRadius: 14, offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              isLast ? '¡Ver mis resultados! 🏆' : 'Siguiente pregunta  →',
              style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: Color(0xFF7A5800),
              ),
            ),
          ),
        ),
      );
}

// ─── Completion View ─────────────────────────────────────────────────────────

class _CompletionView extends StatefulWidget {
  final Nivel nivel;
  final int score;
  final int total;
  final VoidCallback onReplay;
  final VoidCallback onBack;
  final VoidCallback onNextNivel;

  const _CompletionView({
    required this.nivel,
    required this.score,
    required this.total,
    required this.onReplay,
    required this.onBack,
    required this.onNextNivel,
  });

  @override
  State<_CompletionView> createState() => _CompletionViewState();
}

class _CompletionViewState extends State<_CompletionView>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim =
        CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _scaleCtrl.forward();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.total > 0 ? widget.score / widget.total : 0.0;
    final stars = pct >= 0.9 ? 3 : pct >= 0.6 ? 2 : 1;
    final Color accent;
    final String emoji;
    final String title;
    final String subtitle;
    if (pct >= 0.9) {
      accent = _kGreen;
      emoji = '🏆';
      title = '¡NIVEL COMPLETADO!';
      subtitle = 'Eres un experto en ${widget.nivel.nombre}';
    } else if (pct >= 0.6) {
      accent = _kPurple;
      emoji = '🌟';
      title = '¡Muy bien!';
      subtitle = 'Sigue practicando para dominar ${widget.nivel.nombre}';
    } else {
      accent = _kRed;
      emoji = '💪';
      title = '¡Buen intento!';
      subtitle = 'Repasa las lecciones e inténtalo de nuevo';
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          children: [
            // Trophy badge
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent, width: 4),
                ),
                child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 72)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900, color: accent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: _kMuted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(i < stars ? '⭐' : '☆',
                      style: const TextStyle(fontSize: 40)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Stats card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _kDark.withValues(alpha: 0.06),
                    blurRadius: 16, offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Stat(
                    label: 'Correctas',
                    value: '${widget.score}',
                    color: _kGreen,
                  ),
                  Container(width: 1, height: 40,
                      color: const Color(0xFFE5E7EB)),
                  _Stat(
                    label: 'Total',
                    value: '${widget.total}',
                    color: _kDark,
                  ),
                  Container(width: 1, height: 40,
                      color: const Color(0xFFE5E7EB)),
                  _Stat(
                    label: 'Resultado',
                    value: '${(pct * 100).round()}%',
                    color: accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Mensaje si score < 70%
            if (pct < 0.7) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kYellow, width: 1.5),
                ),
                child: const Row(children: [
                  Text('😅', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 10),
                  Expanded(child: Text(
                    '¡Vaya! Necesitas una nota mayor a 70 para pasar al siguiente nivel.',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Color(0xFF7A5800)),
                  )),
                ]),
              ),
            ],
            // Botón "Siguiente nivel" cuando score >= 70%
            if (pct >= 0.7) ...[
              GestureDetector(
                onTap: widget.onNextNivel,
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: _kGreen,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _kGreen.withValues(alpha: 0.4),
                        blurRadius: 16, offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '¡Siguiente nivel!  →',
                      style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            // Botón reintentar
            GestureDetector(
              onTap: widget.onReplay,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: _kYellow,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _kYellow.withValues(alpha: 0.4),
                      blurRadius: 14, offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '🔁  Intentar de nuevo',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      color: Color(0xFF7A5800),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: widget.onBack,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFE5E7EB), width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    '← Volver al nivel',
                    style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: _kDark,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted)),
        ],
      );
}

// ─── Loading / Error / Empty ─────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🏆', style: TextStyle(fontSize: 60)),
            SizedBox(height: 16),
            CircularProgressIndicator(color: _kYellow),
            SizedBox(height: 14),
            Text('Preparando la prueba final...',
                style: TextStyle(
                    color: _kMuted, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onBack;
  const _ErrorView({required this.error, required this.onBack});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('😕', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            const Text('No pudimos cargar los ejercicios',
                style: TextStyle(color: _kDark, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kMuted, fontSize: 12)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Volver'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kPurple, foregroundColor: Colors.white),
            ),
          ]),
        ),
      );
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onBack;
  const _EmptyView({required this.onBack});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('📭', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            const Text(
              'Las lecciones de este nivel aún no tienen ejercicios',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _kDark, fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Volver'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kPurple, foregroundColor: Colors.white),
            ),
          ]),
        ),
      );
}
