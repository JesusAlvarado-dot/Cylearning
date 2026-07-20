import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';

const _kBg     = Color(0xFFFFF9F2);
const _kDark   = Color(0xFF1C1140);
const _kMuted  = Color(0xFF8E8EA9);
const _kPurple = Color(0xFF6B46F6);
const _kYellow = Color(0xFFFFCC00);

const _nodeColors = [
  Color(0xFF6B46F6),
  Color(0xFF0EA5E9),
  Color(0xFF059669),
  Color(0xFFF97316),
  Color(0xFFEF4444),
  Color(0xFFD946EF),
  Color(0xFF8B5CF6),
];

const _nodeEmojis = ['🔐', '🌐', '🛡️', '⚡', '💡', '🔍', '🚀'];

class NivelDetailScreen extends StatefulWidget {
  final Nivel nivel;
  const NivelDetailScreen({super.key, required this.nivel});
  @override
  State<NivelDetailScreen> createState() => _NivelDetailScreenState();
}

class _NivelDetailScreenState extends State<NivelDetailScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Leccion>> _leccionesF;
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _leccionesF = ApiService.getLecciones(widget.nivel.id);
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>(); // rebuild when progress changes
    return Scaffold(
      backgroundColor: _kBg,
      body: FutureBuilder<List<Leccion>>(
        future: _leccionesF,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _loading();
          }
          if (snap.hasError) {
            return _error();
          }
          final lecciones = snap.data ?? [];
          if (lecciones.isEmpty) {
            return _empty();
          }
          return _buildPath(lecciones);
        },
      ),
    );
  }

  Widget _buildPath(List<Leccion> lecciones) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              _buildPathItems(lecciones),
            ),
          ),
        ),
      ],
    );
  }

  // Los 5 muñequillos disponibles (el organizador elige uno por tema)
  static const _moods = ['start', 'progress', 'proud', 'excited', 'challenge'];

  List<Widget> _buildPathItems(List<Leccion> lecciones) {
    final auth = context.read<AuthProvider>();
    final items = <Widget>[];

    // La organización puede apagar las burbujas de los personajes
    final mostrarMascotas =
        auth.usuario?.organizacion?.mostrarMensajesMascota ?? true;

    // Opening character bubble
    if (mostrarMascotas) {
      items.add(_CharacterBubble(
        message:
            '¡Hola! Bienvenido a "${widget.nivel.nombre}". ¡Prepárate para una aventura épica! 🚀',
        mood: 'start',
        fromLeft: true,
      ));
      items.add(const _PathConnector(height: 32));
    }

    for (int i = 0; i < lecciones.length; i++) {
      final color = _nodeColors[i % _nodeColors.length];
      final emoji = _nodeEmojis[i % _nodeEmojis.length];
      final isLeft = i % 2 == 0;
      final isLocked = i > 0 && !auth.isLeccionCompletada(lecciones[i - 1].id);

      items.add(_LessonNode(
        leccion: lecciones[i],
        index: i,
        color: color,
        emoji: emoji,
        isLeft: isLeft,
        isLocked: isLocked,
        onTap: isLocked
            ? () {}
            : () => Navigator.of(context)
                .pushNamed('/leccion', arguments: lecciones[i]),
      ));

      if (i < lecciones.length - 1) {
        if (mostrarMascotas) {
          items.add(const _PathConnector(height: 32));
          final temaLabel = lecciones[i].tema.isNotEmpty
              ? lecciones[i].tema
              : lecciones[i].titulo;
          // Mensaje y muñequillo personalizados del tema (si el organizador
          // los configuró); si no, la rotación automática de siempre
          final mensaje = lecciones[i].temaMensaje.isNotEmpty
              ? lecciones[i].temaMensaje
              : _midMessage(temaLabel, i);
          final mascota = lecciones[i].temaMascota;
          final mood = (mascota != null && mascota >= 0 && mascota < _moods.length)
              ? _moods[mascota]
              : ['progress', 'proud', 'excited'][i % 3];
          items.add(_CharacterBubble(
            message: mensaje,
            mood: mood,
            fromLeft: (i + 1) % 2 == 0,
          ));
        }
        items.add(const _PathConnector(height: 32));
      }
    }

    // Before final test
    items.add(const _PathConnector(height: 32));
    if (mostrarMascotas) {
      items.add(const _CharacterBubble(
        message:
            '¡Increíble! Completaste todas las lecciones. ¡Ahora demuestra todo lo que aprendiste... si te atreves! 😤',
        mood: 'challenge',
        fromLeft: true,
      ));
      items.add(const _PathConnector(height: 32));
    }

    // Final test node — locked until ALL lessons are done
    final allDone = lecciones.every((l) => auth.isLeccionCompletada(l.id));
    items.add(AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: _FinalTestNode(
          leccionCount: lecciones.length,
          isLocked: !allDone,
          onTap: allDone
              ? () => Navigator.of(context).pushNamed(
                    '/prueba-final',
                    arguments: {
                      'nivel': widget.nivel,
                      'lecciones': lecciones,
                    },
                  )
              : () {},
        ),
      ),
    ));

    return items;
  }

  String _midMessage(String tema, int i) {
    const msgs = [
      '¡Vaya! Aprendiste sobre {tema}. ¡No te confíes y acepta el siguiente desafío! 💪',
      '¡Genial! Ya sabes sobre {tema}. Sigue avanzando, ¡tú puedes! 🌟',
      '¡{tema} ya no tiene secretos para ti! A por la siguiente lección ⚡',
      '¡Lo estás haciendo de maravilla! Cada lección te hace más fuerte 🛡️',
      '¡Eres imparable! Solo un poco más y llegas a la cima 🏆',
    ];
    return msgs[i % msgs.length].replaceAll('{tema}', tema);
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Positioned(
          top: -30, right: -30,
          child: Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              color: _kPurple.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 60, left: -20,
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _kYellow.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 42, height: 42,
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nivel.nombre,
                        style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900,
                          color: _kDark,
                        ),
                      ),
                      if (widget.nivel.descripcion.isNotEmpty)
                        Text(
                          widget.nivel.descripcion,
                          style: const TextStyle(fontSize: 13, color: _kMuted),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _loading() => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('📚', style: TextStyle(fontSize: 52)),
      SizedBox(height: 12),
      CircularProgressIndicator(color: _kPurple),
      SizedBox(height: 12),
      Text('Cargando tu camino...', style: TextStyle(color: _kMuted)),
    ]),
  );

  Widget _error() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('😥', style: TextStyle(fontSize: 52)),
      const SizedBox(height: 12),
      const Text('No pudimos cargar las lecciones',
          style: TextStyle(color: _kMuted)),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: () => setState(
            () => _leccionesF = ApiService.getLecciones(widget.nivel.id)),
        icon: const Icon(Icons.refresh),
        label: const Text('Reintentar'),
        style: ElevatedButton.styleFrom(
            backgroundColor: _kPurple, foregroundColor: Colors.white),
      ),
    ]),
  );

  Widget _empty() => const Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('📖', style: TextStyle(fontSize: 52)),
      SizedBox(height: 12),
      Text('Aún no hay lecciones en este nivel',
          style: TextStyle(color: _kMuted, fontSize: 15)),
    ]),
  );
}

// ─── Character Bubble ─────────────────────────────────────────────────────────

class _CharacterBubble extends StatelessWidget {
  final String message;
  final String mood;
  final bool fromLeft;

  const _CharacterBubble({
    required this.message,
    required this.mood,
    required this.fromLeft,
  });

  @override
  Widget build(BuildContext context) {
    final kid = _KidCharacter(mood: mood);
    final bubble = _SpeechBubble(message: message, fromLeft: fromLeft);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: fromLeft
            ? [kid, const SizedBox(width: 10), Expanded(child: bubble)]
            : [Expanded(child: bubble), const SizedBox(width: 10), kid],
      ),
    );
  }
}

// ─── Kid Illustration ─────────────────────────────────────────────────────────

class _KidCharacter extends StatelessWidget {
  final String mood;
  const _KidCharacter({required this.mood});

  static const _skinColor = Color(0xFFFFCBA4);
  static const _hairColor = Color(0xFF5C3D1E);
  static const _eyeColor  = Color(0xFF2D2D2D);

  Color get _shirtColor {
    switch (mood) {
      case 'start':     return const Color(0xFF6B46F6);
      case 'progress':  return const Color(0xFF0EA5E9);
      case 'proud':     return const Color(0xFF059669);
      case 'excited':   return const Color(0xFFF97316);
      case 'challenge': return const Color(0xFFEF4444);
      default:          return const Color(0xFF6B46F6);
    }
  }

  String get _badge {
    switch (mood) {
      case 'start':     return '🎒';
      case 'progress':  return '⭐';
      case 'proud':     return '😎';
      case 'excited':   return '🔥';
      case 'challenge': return '💪';
      default:          return '✨';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70, height: 96,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Body shadow
          Positioned(
            bottom: -3, left: 14, right: 14,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: _shirtColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          // Left arm
          Positioned(
            bottom: 18, left: 3,
            child: Transform.rotate(
              angle: -0.3,
              child: Container(
                width: 12, height: 28,
                decoration: BoxDecoration(
                  color: _shirtColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          // Right arm
          Positioned(
            bottom: 18, right: 3,
            child: Transform.rotate(
              angle: 0.3,
              child: Container(
                width: 12, height: 28,
                decoration: BoxDecoration(
                  color: _shirtColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          // Shirt body
          Positioned(
            bottom: 0, left: 14, right: 14,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _shirtColor,
                borderRadius: const BorderRadius.only(
                  topLeft:     Radius.circular(6),
                  topRight:    Radius.circular(6),
                  bottomLeft:  Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
            ),
          ),
          // Neck
          Positioned(
            bottom: 40, left: 26, right: 26,
            child: Container(height: 10, color: _skinColor),
          ),
          // Head circle
          Positioned(
            top: 0, left: 5, right: 5,
            child: Container(
              height: 58,
              decoration: const BoxDecoration(
                color: _skinColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Hair
          Positioned(
            top: 0, left: 5, right: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft:  Radius.circular(29),
                topRight: Radius.circular(29),
              ),
              child: Container(height: 22, color: _hairColor),
            ),
          ),
          // Left eye
          Positioned(
            top: 27, left: 16,
            child: Container(
              width: 9, height: 9,
              decoration: const BoxDecoration(
                  color: _eyeColor, shape: BoxShape.circle),
            ),
          ),
          // Right eye
          Positioned(
            top: 27, right: 16,
            child: Container(
              width: 9, height: 9,
              decoration: const BoxDecoration(
                  color: _eyeColor, shape: BoxShape.circle),
            ),
          ),
          // Left blush
          Positioned(
            top: 34, left: 10,
            child: Container(
              width: 11, height: 7,
              decoration: BoxDecoration(
                color: Colors.pink.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          // Right blush
          Positioned(
            top: 34, right: 10,
            child: Container(
              width: 11, height: 7,
              decoration: BoxDecoration(
                color: Colors.pink.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          // Smile
          Positioned(
            top: 41, left: 19, right: 19,
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                border: const Border(
                  bottom: BorderSide(color: _eyeColor, width: 2.5),
                  left:   BorderSide(color: _eyeColor, width: 2.5),
                  right:  BorderSide(color: _eyeColor, width: 2.5),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Mood badge
          Positioned(
            top: -4, right: 0,
            child: Text(_badge, style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}

// ─── Speech Bubble ────────────────────────────────────────────────────────────

class _SpeechBubble extends StatelessWidget {
  final String message;
  final bool fromLeft;
  const _SpeechBubble({required this.message, required this.fromLeft});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(18),
            topRight:    const Radius.circular(18),
            bottomLeft:  Radius.circular(fromLeft ? 4 : 18),
            bottomRight: Radius.circular(fromLeft ? 18 : 4),
          ),
          boxShadow: [
            BoxShadow(
              color: _kDark.withValues(alpha: 0.07),
              blurRadius: 10, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: _kDark, height: 1.5,
          ),
        ),
      );
}

// ─── Path Connector (dashed line) ────────────────────────────────────────────

class _PathConnector extends StatelessWidget {
  final double height;
  const _PathConnector({this.height = 40});

  @override
  Widget build(BuildContext context) => Center(
        child: CustomPaint(
          size: Size(4, height),
          painter: _DashedLinePainter(),
        ),
      );
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E0)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    const dash = 7.0;
    const gap = 5.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, math.min(y + dash, size.height)),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Lesson Node ─────────────────────────────────────────────────────────────

class _LessonNode extends StatefulWidget {
  final Leccion leccion;
  final int index;
  final Color color;
  final String emoji;
  final bool isLeft;
  final bool isLocked;
  final VoidCallback onTap;

  const _LessonNode({
    required this.leccion,
    required this.index,
    required this.color,
    required this.emoji,
    required this.isLeft,
    required this.isLocked,
    required this.onTap,
  });

  @override
  State<_LessonNode> createState() => _LessonNodeState();
}

class _LessonNodeState extends State<_LessonNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.92,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offset = widget.isLeft ? -50.0 : 50.0;
    final locked = widget.isLocked;
    final nodeColor = locked ? const Color(0xFFD1D5DB) : widget.color;

    return Center(
      child: Transform.translate(
        offset: Offset(offset, 0),
        child: GestureDetector(
          onTapDown: locked ? null : (_) => _tapCtrl.reverse(),
          onTapUp: locked ? null : (_) { _tapCtrl.forward(); widget.onTap(); },
          onTapCancel: locked ? null : () => _tapCtrl.forward(),
          child: ScaleTransition(
            scale: _tapCtrl,
            child: Column(
              children: [
                // Node circle
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    color: nodeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: nodeColor.withValues(alpha: locked ? 0.2 : 0.4),
                        blurRadius: 18, offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(locked ? '🔒' : widget.emoji,
                          style: const TextStyle(fontSize: 32)),
                      Text(
                        '${widget.index + 1}',
                        style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Label
                Container(
                  constraints: const BoxConstraints(maxWidth: 130),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: nodeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: nodeColor.withValues(alpha: 0.3),
                        width: 1),
                  ),
                  child: Text(
                    locked ? 'Bloqueado' : widget.leccion.titulo,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: nodeColor,
                      height: 1.3,
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

// ─── Final Test Node ─────────────────────────────────────────────────────────

class _FinalTestNode extends StatelessWidget {
  final int leccionCount;
  final bool isLocked;
  final VoidCallback onTap;
  const _FinalTestNode(
      {required this.leccionCount, required this.isLocked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg     = isLocked ? const Color(0xFFE5E7EB) : _kYellow;
    final textClr = isLocked ? const Color(0xFF9CA3AF) : const Color(0xFF7A5800);

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: bg.withValues(alpha: isLocked ? 0.3 : 0.5),
              blurRadius: 24, offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(isLocked ? '🔒' : '🏆',
                style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 10),
            Text(
              isLocked ? 'BLOQUEADO' : 'PRUEBA FINAL',
              style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900,
                color: textClr, letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isLocked
                  ? 'Completa todas las lecciones para desbloquear'
                  : '$leccionCount temas · ¡Demuestra todo lo que aprendiste!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: textClr,
              ),
            ),
            if (!isLocked) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7A5800),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '¡Aceptar desafío! →',
                  style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800,
                    color: _kYellow,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
