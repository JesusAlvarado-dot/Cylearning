import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/models.dart';

// Gradients per question index (cycles)
const _questionGradients = [
  [Color(0xFF7C4DFF), Color(0xFF448AFF)],
  [Color(0xFFFF6D00), Color(0xFFFFAB00)],
  [Color(0xFF00897B), Color(0xFF26C6DA)],
  [Color(0xFFE91E63), Color(0xFFFF5722)],
  [Color(0xFF1565C0), Color(0xFF7B1FA2)],
];

const _questionEmojis = ['🧠', '🔐', '🛡️', '⚡', '🎯', '💡', '🔍', '🌐'];

const _optionColors = [
  Color(0xFF7C4DFF),
  Color(0xFF2196F3),
  Color(0xFFFF6D00),
  Color(0xFFE91E63),
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
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _confirmed = false;
  int _correctCount = 0;
  bool _finished = false;

  late AnimationController _feedbackCtrl;
  late Animation<double> _feedbackAnim;
  late AnimationController _optionPulseCtrl;
  late Animation<double> _optionPulseAnim;

  @override
  void initState() {
    super.initState();
    _ejerciciosF = ApiService.getEjercicios(widget.leccionId ?? '');
    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _feedbackAnim = CurvedAnimation(
      parent: _feedbackCtrl,
      curve: Curves.elasticOut,
    );
    _optionPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _optionPulseAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _optionPulseCtrl, curve: Curves.easeInOut),
    );
  }

  void _seleccionar(int index) {
    HapticFeedback.lightImpact();
    setState(() => _selectedAnswer = index);
    _optionPulseCtrl.forward().then((_) => _optionPulseCtrl.reverse());
  }

  void _confirmar(Ejercicio ejercicio) {
    HapticFeedback.mediumImpact();
    final isCorrect = _selectedAnswer == ejercicio.respuestaCorrecta;
    setState(() {
      _confirmed = true;
      if (isCorrect) _correctCount++;
    });
    _feedbackCtrl.forward(from: 0);
  }

  void _siguiente(List<Ejercicio> ejercicios) {
    if (_currentIndex < ejercicios.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _confirmed = false;
      });
      _feedbackCtrl.reset();
    } else {
      setState(() => _finished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      body: FutureBuilder<List<Ejercicio>>(
        future: _ejerciciosF,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _LoadingView();
          }
          if (snapshot.hasError) {
            return _ErrorView(
              onRetry: () => setState(() {
                _ejerciciosF =
                    ApiService.getEjercicios(widget.leccionId ?? '');
              }),
            );
          }

          final ejercicios = snapshot.data ?? [];

          if (ejercicios.isEmpty) {
            return _EmptyView();
          }

          if (_finished) {
            return _ResultadosView(
              correctas: _correctCount,
              total: ejercicios.length,
              onRepeat: () => setState(() {
                _currentIndex = 0;
                _selectedAnswer = null;
                _confirmed = false;
                _correctCount = 0;
                _finished = false;
              }),
              onExit: () => Navigator.of(context).pop(),
            );
          }

          final ejercicio = ejercicios[_currentIndex];
          final isCorrect =
              _confirmed && _selectedAnswer == ejercicio.respuestaCorrecta;
          final gradColors =
              _questionGradients[_currentIndex % _questionGradients.length];
          final qEmoji =
              _questionEmojis[_currentIndex % _questionEmojis.length];

          return SafeArea(
            child: Column(
              children: [
                _GameTopBar(
                  current: _currentIndex + 1,
                  total: ejercicios.length,
                  correctas: _correctCount,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question card
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradColors,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: gradColors[0].withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '✏️ Pregunta ${_currentIndex + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(qEmoji,
                                      style: const TextStyle(fontSize: 32)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                ejercicio.pregunta,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        // Options
                        ...List.generate(ejercicio.opciones.length, (i) {
                          return _OptionButton(
                            index: i,
                            text: ejercicio.opciones[i],
                            isSelected: _selectedAnswer == i,
                            isConfirmed: _confirmed,
                            isCorrect: i == ejercicio.respuestaCorrecta,
                            pulseAnim: _optionPulseAnim,
                            onTap: _confirmed ? null : () => _seleccionar(i),
                          );
                        }),
                        // Feedback
                        if (_confirmed) ...[
                          const SizedBox(height: 16),
                          ScaleTransition(
                            scale: _feedbackAnim,
                            child: _FeedbackBanner(
                              isCorrect: isCorrect,
                              explicacion: ejercicio.explicacion,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        // Action button
                        if (!_confirmed)
                          _ActionButton(
                            label: '✅  Confirmar respuesta',
                            enabled: _selectedAnswer != null,
                            color: gradColors[0],
                            onTap: () => _confirmar(ejercicio),
                          )
                        else
                          _ActionButton(
                            label: _currentIndex < ejercicios.length - 1
                                ? '➡️  Siguiente pregunta'
                                : '🏆  Ver resultados',
                            enabled: true,
                            color: isCorrect
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF7C4DFF),
                            onTap: () => _siguiente(ejercicios),
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

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    _optionPulseCtrl.dispose();
    super.dispose();
  }
}

// ─── Game Top Bar ────────────────────────────────────────────────────────────

class _GameTopBar extends StatelessWidget {
  final int current;
  final int total;
  final int correctas;
  final VoidCallback onBack;

  const _GameTopBar({
    required this.current,
    required this.total,
    required this.correctas,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF5C35CC)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white),
                onPressed: onBack,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(total, (i) {
                    final done = i < current;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: done ? 24 : 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: i < current - 1
                            ? const Color(0xFFFFD600)
                            : i == current - 1
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    );
                  }),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '⭐ $correctas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: current / total,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFFD600)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Option Button ───────────────────────────────────────────────────────────

const _optionLetters = ['A', 'B', 'C', 'D'];

class _OptionButton extends StatelessWidget {
  final int index;
  final String text;
  final bool isSelected;
  final bool isConfirmed;
  final bool isCorrect;
  final Animation<double> pulseAnim;
  final VoidCallback? onTap;

  const _OptionButton({
    required this.index,
    required this.text,
    required this.isSelected,
    required this.isConfirmed,
    required this.isCorrect,
    required this.pulseAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = index < _optionColors.length
        ? _optionColors[index]
        : const Color(0xFF7C4DFF);

    Color bg = Colors.white;
    Color border = Colors.grey.shade200;
    Color textColor = const Color(0xFF2D2D44);
    Color badgeBg = Colors.grey.shade100;
    Color badgeText = Colors.grey;
    Widget? trailingIcon;

    if (isConfirmed) {
      if (isCorrect) {
        bg = const Color(0xFFE8F5E9);
        border = const Color(0xFF4CAF50);
        textColor = const Color(0xFF1B5E20);
        badgeBg = const Color(0xFF4CAF50);
        badgeText = Colors.white;
        trailingIcon = const Icon(Icons.check_circle_rounded,
            color: Color(0xFF4CAF50), size: 26);
      } else if (isSelected) {
        bg = const Color(0xFFFFEBEE);
        border = const Color(0xFFEF5350);
        textColor = const Color(0xFFB71C1C);
        badgeBg = const Color(0xFFEF5350);
        badgeText = Colors.white;
        trailingIcon = const Icon(Icons.cancel_rounded,
            color: Color(0xFFEF5350), size: 26);
      }
    } else if (isSelected) {
      bg = baseColor.withValues(alpha: 0.08);
      border = baseColor;
      textColor = baseColor;
      badgeBg = baseColor;
      badgeText = Colors.white;
    }

    final letter = index < _optionLetters.length ? _optionLetters[index] : '?';

    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: isSelected && !isConfirmed ? pulseAnim.value : 1.0,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: (isSelected && !isConfirmed)
                    ? baseColor.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      color: badgeText,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                trailingIcon,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 60,
        decoration: BoxDecoration(
          color: enabled ? color : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: enabled ? Colors.white : Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Feedback Banner ─────────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  final bool isCorrect;
  final String explicacion;

  const _FeedbackBanner({required this.isCorrect, required this.explicacion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCorrect
              ? [const Color(0xFF43A047), const Color(0xFF00C853)]
              : [const Color(0xFFE53935), const Color(0xFFFF6F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (isCorrect
                    ? const Color(0xFF43A047)
                    : const Color(0xFFE53935))
                .withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? '🎉' : '💡',
            style: const TextStyle(fontSize: 36),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? '¡Correcto! ¡Lo lograste!' : '¡Casi! Así es:',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                if (explicacion.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    explicacion,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Results View ─────────────────────────────────────────────────────────────

class _ResultadosView extends StatelessWidget {
  final int correctas;
  final int total;
  final VoidCallback onRepeat;
  final VoidCallback onExit;

  const _ResultadosView({
    required this.correctas,
    required this.total,
    required this.onRepeat,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (correctas / total * 100).round() : 0;
    final stars = pct >= 90 ? 3 : pct >= 70 ? 2 : pct >= 50 ? 1 : 0;

    final String emoji;
    final String titulo;
    final List<Color> gradColors;

    if (pct >= 90) {
      emoji = '🏆';
      titulo = '¡Eres una estrella!';
      gradColors = [const Color(0xFFFF6F00), const Color(0xFFFFD600)];
    } else if (pct >= 70) {
      emoji = '🎉';
      titulo = '¡Muy bien hecho!';
      gradColors = [const Color(0xFF2E7D32), const Color(0xFF00C853)];
    } else if (pct >= 50) {
      emoji = '👍';
      titulo = '¡Buen intento!';
      gradColors = [const Color(0xFF1565C0), const Color(0xFF448AFF)];
    } else {
      emoji = '💪';
      titulo = '¡Sigue practicando!';
      gradColors = [const Color(0xFF6A1B9A), const Color(0xFF7C4DFF)];
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [gradColors[0].withValues(alpha: 0.1), const Color(0xFFF3F0FF)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 90)),
                const SizedBox(height: 8),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: gradColors[0],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Text(
                      i < stars ? '⭐' : '☆',
                      style: TextStyle(
                        fontSize: 36,
                        color: i < stars
                            ? const Color(0xFFFFD600)
                            : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                // Score card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: gradColors[0].withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$correctas / $total',
                        style: TextStyle(
                          fontSize: 58,
                          fontWeight: FontWeight.w900,
                          color: gradColors[0],
                        ),
                      ),
                      const Text(
                        'respuestas correctas',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 17),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: LinearProgressIndicator(
                          value: total > 0 ? correctas / total : 0,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(gradColors[0]),
                          minHeight: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: gradColors[0],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _StatBadge(
                              emoji: '✅',
                              value: '$correctas',
                              label: 'Correctas',
                              color: const Color(0xFF43A047),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatBadge(
                              emoji: '❌',
                              value: '${total - correctas}',
                              label: 'Incorrectas',
                              color: const Color(0xFFE53935),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _BigButton(
                  label: '🔄  Intentar de nuevo',
                  color: gradColors[0],
                  onTap: onRepeat,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onExit,
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: gradColors[0], width: 2.5),
                    ),
                    child: Center(
                      child: Text(
                        '🏠  Volver al inicio',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: gradColors[0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _StatBadge({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BigButton(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helper Views ─────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🧠', style: TextStyle(fontSize: 72)),
          SizedBox(height: 20),
          CircularProgressIndicator(color: Color(0xFF7C4DFF)),
          SizedBox(height: 16),
          Text('Cargando preguntas...',
              style: TextStyle(
                  color: Color(0xFF7C4DFF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😥', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            const Text(
              'No pudimos cargar los ejercicios',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🎉', style: TextStyle(fontSize: 72)),
          SizedBox(height: 16),
          Text(
            '¡Esta lección no tiene ejercicios aún!',
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
