import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/sound_service.dart';
import '../models/models.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/medalla_dialog.dart';

const _kBg     = Color(0xFFFFF9F2);
const _kDark   = Color(0xFF1C1140);
const _kMuted  = Color(0xFF8E8EA9);
const _kGreen  = Color(0xFF059669);
const _kRed    = Color(0xFFEF4444);
const _kYellow = Color(0xFFFFCC00);

const _qColors = [
  Color(0xFF6B46F6),
  Color(0xFF0EA5E9),
  Color(0xFF059669),
  Color(0xFFEF4444),
  Color(0xFFF97316),
];
const _qBgColors = [
  Color(0xFFEFEBFF),
  Color(0xFFE0F2FE),
  Color(0xFFECFDF5),
  Color(0xFFFFF1F1),
  Color(0xFFFFF7ED),
];

class EjerciciosScreen extends StatefulWidget {
  final String? leccionId;
  const EjerciciosScreen({super.key, this.leccionId});
  @override
  State<EjerciciosScreen> createState() => _EjerciciosScreenState();
}

class _EjerciciosScreenState extends State<EjerciciosScreen>
    with TickerProviderStateMixin {
  late Future<List<Ejercicio>> _ejerciciosF;

  List<Ejercicio> _ejercicios = [];
  int _currentIndex = 0;
  int? _selectedOption;
  int? _correctIndex;
  bool _answered = false;
  bool _submitting = false;
  bool _isCorrect = false;
  String _explicacion = '';
  int _score = 0;
  bool _finished = false;
  bool _progressSaved = false;

  late AnimationController _feedbackCtrl;
  late Animation<double> _feedbackAnim;
  late AnimationController _bounceCtrl;

  @override
  void initState() {
    super.initState();
    _ejerciciosF = widget.leccionId != null
        ? ApiService.getEjercicios(widget.leccionId!)
        : Future.value([]);

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

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  Color get _accentColor => _qColors[_currentIndex % _qColors.length];
  Color get _accentBg    => _qBgColors[_currentIndex % _qBgColors.length];

  // La calificación se hace en el servidor: la respuesta correcta no viaja
  // al cliente hasta después de responder
  Future<void> _onOptionTap(int idx) async {
    if (_answered || _submitting) return;
    HapticFeedback.lightImpact();
    final ejercicio = _ejercicios[_currentIndex];
    setState(() {
      _submitting = true;
      _selectedOption = idx;
    });
    try {
      final r = await ApiService.submitEjercicio(
          ejercicio.id, ejercicio.opciones[idx]);
      if (!mounted) return;
      final correct = r['esCorrecta'] == true;
      setState(() {
        _answered = true;
        _isCorrect = correct;
        _explicacion = (r['explicacion'] ?? '').toString();
        _correctIndex = ejercicio
            .indexDeRespuesta((r['respuesta_correcta'] ?? '').toString());
        if (correct) _score++;
        _submitting = false;
      });
      correct ? SoundService.correct() : SoundService.wrong();
      _feedbackCtrl.forward(from: 0);
      _bounceCtrl.reverse().then((_) => _bounceCtrl.forward());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _selectedOption = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se pudo enviar tu respuesta. Intenta de nuevo')),
      );
    }
  }

  void _onNext() {
    if (_currentIndex < _ejercicios.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _correctIndex = null;
        _answered = false;
        _explicacion = '';
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
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF6B46F6)));
          }
          if (snap.hasError) {
            return _ErrorView(
                error: snap.error.toString(),
                onBack: () => Navigator.of(context).pop());
          }

          // Sync list once on first load
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
            if (!_progressSaved && widget.leccionId != null) {
              _progressSaved = true;
              final pctInt = (pct * 100).round();
              if (pct >= 0.7) SoundService.levelUp();
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted) return;
                final result = await context.read<AuthProvider>()
                    .marcarLeccionCompleta(widget.leccionId!, pctInt);
                if (!context.mounted) return;
                // Celebrar la medalla apenas se gana
                final medalla = result['medalla'];
                if (medalla is Map) {
                  await showMedallaDialog(
                      context, Map<String, dynamic>.from(medalla));
                }
              });
            }
            return Stack(
              children: [
                _ResultView(
                  score: _score,
                  total: total,
                  onReplay: () => setState(() {
                    _currentIndex = 0;
                    _selectedOption = null;
                    _correctIndex = null;
                    _answered = false;
                    _isCorrect = false;
                    _explicacion = '';
                    _score = 0;
                    _finished = false;
                    _progressSaved = false;
                    _feedbackCtrl.reset();
                  }),
                  onBack: () => Navigator.of(context).pop(),
                  onNext: () => Navigator.of(context)
                      .popUntil(ModalRoute.withName('/nivel')),
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
                  current: _currentIndex,
                  total: ejercicios.length,
                  score: _score,
                  accentColor: _accentColor,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ScaleTransition(
                          scale: _bounceCtrl,
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: _accentBg,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                  color: _accentColor.withValues(alpha: 0.25),
                                  width: 1.5),
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
                              accentColor: _accentColor,
                              onTap: () => _onOptionTap(i),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_answered)
                          ScaleTransition(
                            scale: _feedbackAnim,
                            child: _FeedbackBanner(
                                correct: _isCorrect,
                                explicacion: _explicacion),
                          ),
                        const SizedBox(height: 16),
                        if (_answered)
                          _NextButton(
                            isLast: _currentIndex == ejercicios.length - 1,
                            accentColor: _accentColor,
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

  _OptionState _optionState(int i, Ejercicio ejercicio) {
    if (!_answered) {
      return i == _selectedOption
          ? _OptionState.selected
          : _OptionState.normal;
    }
    if (i == _correctIndex) return _OptionState.correct;
    if (i == _selectedOption) return _OptionState.wrong;
    return _OptionState.normal;
  }

  String _questionEmoji(int i) {
    const emojis = ['🤔', '💡', '🔐', '🌐', '🛡️', '🔍', '⚡'];
    return emojis[i % emojis.length];
  }

  String _optionLabel(int i) {
    const labels = ['A', 'B', 'C', 'D'];
    return labels[i % labels.length];
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int current;
  final int total;
  final int score;
  final Color accentColor;
  final VoidCallback onBack;

  const _TopBar({
    required this.current,
    required this.total,
    required this.score,
    required this.accentColor,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      color: _kBg,
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _kDark.withValues(alpha: 0.07),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: _kDark),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ejercicios',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _kDark,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '⭐ $score',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7A5800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(total, (i) {
              Color color;
              if (i < current) {
                color = accentColor;
              } else if (i == current) {
                color = accentColor.withValues(alpha: 0.4);
              } else {
                color = const Color(0xFFE5E7EB);
              }
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${current + 1} / $total',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Option tile ──────────────────────────────────────────────────────────────

enum _OptionState { normal, selected, correct, wrong }

class _OptionTile extends StatefulWidget {
  final String label;
  final String text;
  final _OptionState state;
  final Color accentColor;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.text,
    required this.state,
    required this.accentColor,
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
      case _OptionState.selected: return widget.accentColor.withValues(alpha: 0.08);
      case _OptionState.normal:   return Colors.white;
    }
  }

  Color get _borderColor {
    switch (widget.state) {
      case _OptionState.correct:  return _kGreen;
      case _OptionState.wrong:    return _kRed;
      case _OptionState.selected: return widget.accentColor;
      case _OptionState.normal:   return const Color(0xFFE5E7EB);
    }
  }

  Color get _labelBg {
    switch (widget.state) {
      case _OptionState.correct:  return _kGreen;
      case _OptionState.wrong:    return _kRed;
      case _OptionState.selected: return widget.accentColor;
      case _OptionState.normal:   return const Color(0xFFF3F4F6);
    }
  }

  Color get _labelFg {
    switch (widget.state) {
      case _OptionState.normal: return _kMuted;
      default:                  return Colors.white;
    }
  }

  String get _trailingIcon {
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
      onTapUp: (_) {
        _tapCtrl.forward();
        widget.onTap();
      },
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
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _labelBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                  ),
                ),
              ),
              if (_trailingIcon.isNotEmpty)
                Text(_trailingIcon, style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Feedback banner ──────────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  final bool correct;
  final String explicacion;
  const _FeedbackBanner({required this.correct, this.explicacion = ''});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: correct
              ? const Color(0xFFECFDF5)
              : const Color(0xFFFFF1F1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: correct ? _kGreen : _kRed,
            width: 1.5,
          ),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: correct ? _kGreen : _kRed,
                    ),
                  ),
                  Text(
                    correct
                        ? 'Excelente respuesta 🌟'
                        : 'Sigue intentando, puedes lograrlo',
                    style: const TextStyle(
                        fontSize: 12,
                        color: _kMuted,
                        fontWeight: FontWeight.w600),
                  ),
                  // Explicación educativa que envía el servidor tras responder
                  if (explicacion.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            explicacion,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _kDark,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

// ─── Next button ──────────────────────────────────────────────────────────────

class _NextButton extends StatelessWidget {
  final bool isLast;
  final Color accentColor;
  final VoidCallback onTap;
  const _NextButton(
      {required this.isLast, required this.accentColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 54,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              isLast ? '¡Ver resultados! 🏆' : 'Siguiente  →',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
}

// ─── Result view ──────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final int score;
  final int total;
  final VoidCallback onReplay;
  final VoidCallback onBack;
  final VoidCallback onNext;
  const _ResultView({
    required this.score,
    required this.total,
    required this.onReplay,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? score / total : 0.0;
    final stars = pct >= 0.9 ? 3 : pct >= 0.6 ? 2 : 1;
    final Color accentColor;
    final String emoji;
    final String title;
    final String subtitle;
    if (pct >= 0.9) {
      accentColor = _kGreen;
      emoji = '🏆';
      title = '¡Perfecto!';
      subtitle = '¡Eres un experto en ciberseguridad!';
    } else if (pct >= 0.6) {
      accentColor = _kYellow;
      emoji = '🌟';
      title = '¡Muy bien!';
      subtitle = 'Sigue así, casi lo dominas';
    } else {
      accentColor = _kRed;
      emoji = '💪';
      title = '¡Buen intento!';
      subtitle = 'Practica un poco más y lo lograrás';
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor, width: 3),
                    ),
                    child: Center(
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 64))),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15,
                        color: _kMuted,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        3,
                        (i) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                i < stars ? '⭐' : '☆',
                                style: const TextStyle(fontSize: 36),
                              ),
                            )),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: _kDark.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ScoreStat(
                            label: 'Correctas',
                            value: '$score',
                            color: _kGreen),
                        _Divider(),
                        _ScoreStat(
                            label: 'Total',
                            value: '$total',
                            color: _kDark),
                        _Divider(),
                        _ScoreStat(
                            label: 'Puntaje',
                            value: '${(pct * 100).round()}%',
                            color: accentColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                        '¡Vaya! Necesitas una nota mayor a 70 para continuar.',
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: Color(0xFF7A5800)),
                      )),
                    ]),
                  ),
                ],
                // Botón "Siguiente" cuando score >= 70%
                if (pct >= 0.7) ...[
                  GestureDetector(
                    onTap: onNext,
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
                          '¡Siguiente lección!  →',
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
                GestureDetector(
                  onTap: onReplay,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B46F6),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF6B46F6).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '🔁  Intentar de nuevo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onBack,
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
                        '← Volver a la lección',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: const Color(0xFFE5E7EB));
}

class _ScoreStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ScoreStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted)),
        ],
      );
}

// ─── Error / Empty views ──────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onBack;
  const _ErrorView({required this.error, required this.onBack});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              const Text('No pudimos cargar los ejercicios',
                  style: TextStyle(
                      color: _kDark, fontWeight: FontWeight.w700)),
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
                    backgroundColor: const Color(0xFF6B46F6),
                    foregroundColor: Colors.white),
              ),
            ],
          ),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📭', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              const Text(
                'Esta lección no tiene ejercicios todavía',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _kDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Volver'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46F6),
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
}
