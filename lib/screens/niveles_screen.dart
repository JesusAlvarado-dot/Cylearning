import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';

const _kBg     = Color(0xFFFFF9F2);
const _kDark   = Color(0xFF1C1140);
const _kMuted  = Color(0xFF8E8EA9);
const _kYellow = Color(0xFFFFCC00);

// Solid accent colors — one per level (no gradients)
const _levelColors = [
  Color(0xFF6B46F6), // purple
  Color(0xFFEF4444), // red
  Color(0xFF059669), // green
  Color(0xFFF97316), // orange
  Color(0xFF0EA5E9), // sky blue
  Color(0xFFD946EF), // fuchsia
  Color(0xFF8B5CF6), // violet
];

const _levelEmojis = ['🔰', '⚡', '🛡️', '🚀', '🏆', '🌟', '🎯'];
const _levelBgs    = [
  Color(0xFFEFEBFF),
  Color(0xFFFFF1F1),
  Color(0xFFECFDF5),
  Color(0xFFFFF7ED),
  Color(0xFFE0F2FE),
  Color(0xFFFDF4FF),
  Color(0xFFF5F3FF),
];

class NivelesScreen extends StatefulWidget {
  const NivelesScreen({super.key});
  @override
  State<NivelesScreen> createState() => _NivelesScreenState();
}

class _NivelesScreenState extends State<NivelesScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Nivel>> _nivelesF;
  late AnimationController _waveCtrl;
  late Animation<double> _waveAnim;

  @override
  void initState() {
    super.initState();
    _nivelesF = ApiService.getNiveles();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _waveAnim = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _waveCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final nombre = (auth.usuario?.nombre.trim().isNotEmpty ?? false)
              ? auth.usuario!.nombre.trim().split(' ').first
              : 'Explorador';
          final puntos = auth.usuario?.puntosTotales ?? 0;
          final medallas = auth.usuario?.medallas.length ?? 0;
          final racha = auth.racha;

          return CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _Header(
                  nombre: nombre,
                  puntos: puntos,
                  medallas: medallas,
                  racha: racha,
                  auth: auth,
                  waveAnim: _waveAnim,
                ),
              ),
              // ── Section title ─────────────────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 4),
                  child: Text(
                    '🗺️  Elige tu misión',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _kDark,
                    ),
                  ),
                ),
              ),
              // ── Grid ─────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                sliver: FutureBuilder<List<Nivel>>(
                  future: _nivelesF,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF6B46F6))));
                    }
                    if (snap.hasError) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('😕',
                                  style: TextStyle(fontSize: 52)),
                              const SizedBox(height: 12),
                              const Text('No pudimos cargar los niveles',
                                  style: TextStyle(
                                      color: _kMuted, fontSize: 15)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => setState(
                                    () => _nivelesF =
                                        ApiService.getNiveles()),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Reintentar'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF6B46F6)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final niveles = snap.data ?? [];
                    if (niveles.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('📚', style: TextStyle(fontSize: 52)),
                              SizedBox(height: 12),
                              Text('Aún no hay niveles',
                                  style: TextStyle(
                                      color: _kMuted, fontSize: 15)),
                            ],
                          ),
                        ),
                      );
                    }
                    return SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final isCompleted = auth.isNivelCompletado(niveles[i].id);
                          final isLocked = i > 0 &&
                              !auth.isNivelCompletado(niveles[i - 1].id);
                          final leccionesCompletadas = niveles[i]
                              .leccionesIds
                              .where(auth.isLeccionCompletada)
                              .length;
                          return _NivelCard(
                            nivel: niveles[i],
                            color: _levelColors[i % _levelColors.length],
                            bgColor: _levelBgs[i % _levelBgs.length],
                            emoji: _levelEmojis[i % _levelEmojis.length],
                            index: i,
                            isLocked: isLocked,
                            isCompleted: isCompleted,
                            leccionesCompletadas: leccionesCompletadas,
                          );
                        },
                        childCount: niveles.length,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String nombre;
  final int puntos;
  final int medallas;
  final int racha;
  final AuthProvider auth;
  final Animation<double> waveAnim;

  const _Header({
    required this.nombre,
    required this.puntos,
    required this.medallas,
    required this.racha,
    required this.auth,
    required this.waveAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
      child: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF6B46F6).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: -20,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: _kYellow.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFEBFF),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF6B46F6), width: 2.5),
                    ),
                    child: Center(
                      child: Text(
                        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF6B46F6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedBuilder(
                          animation: waveAnim,
                          builder: (_, child) => Row(
                            children: [
                              Transform.translate(
                                offset: Offset(0, waveAnim.value * 0.5),
                                child: const Text('👋 ',
                                    style: TextStyle(fontSize: 18)),
                              ),
                              Flexible(
                                child: Text(
                                  '¡Hola, $nombre!',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: _kDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _StatPill(
                                emoji: '⭐', label: '$puntos pts',
                                color: const Color(0xFFFFF3CD),
                                textColor: const Color(0xFF7A5800)),
                            const SizedBox(width: 8),
                            _StatPill(
                                emoji: '🏅', label: '$medallas',
                                color: const Color(0xFFEFEBFF),
                                textColor: const Color(0xFF5B21B6)),
                            if (racha > 0) ...[
                              const SizedBox(width: 8),
                              _StatPill(
                                  emoji: '🔥', label: '${racha}d',
                                  color: const Color(0xFFFFF3E0),
                                  textColor: const Color(0xFFE65100)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Menu
                  PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    icon: Container(
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
                      child: const Icon(Icons.more_vert_rounded,
                          color: _kDark),
                    ),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Text(auth.usuario?.nombre ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'perfil',
                        child: Row(children: [
                          Icon(Icons.person_rounded,
                              color: Color(0xFF6B46F6)),
                          SizedBox(width: 10),
                          Text('Mi perfil'),
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'ranking',
                        child: Row(children: [
                          Icon(Icons.leaderboard_rounded,
                              color: Color(0xFFFFB800)),
                          SizedBox(width: 10),
                          Text('🏆 Ranking'),
                        ]),
                      ),
                      if (auth.usuario?.rol == 'admin')
                        const PopupMenuItem(
                          value: 'admin',
                          child: Row(children: [
                            Icon(Icons.admin_panel_settings_rounded,
                                color: Color(0xFF6B46F6)),
                            SizedBox(width: 10),
                            Text('Panel admin'),
                          ]),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(children: [
                          Icon(Icons.logout_rounded, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Cerrar sesión',
                              style: TextStyle(color: Colors.red)),
                        ]),
                      ),
                    ],
                    onSelected: (v) {
                      switch (v) {
                        case 'perfil':
                          Navigator.of(context).pushNamed('/perfil');
                        case 'ranking':
                          Navigator.of(context).pushNamed('/ranking');
                        case 'admin':
                          Navigator.of(context).pushNamed('/admin');
                        case 'logout':
                          auth.logout();
                          Navigator.of(context)
                              .pushReplacementNamed('/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final Color textColor;
  const _StatPill({
    required this.emoji,
    required this.label,
    required this.color,
    required this.textColor,
  });
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$emoji $label',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      );
}

// ─── Nivel Card ───────────────────────────────────────────────────────────────

class _NivelCard extends StatefulWidget {
  final Nivel nivel;
  final Color color;
  final Color bgColor;
  final String emoji;
  final int index;
  final bool isLocked;
  final bool isCompleted;
  final int leccionesCompletadas;
  const _NivelCard({
    required this.nivel,
    required this.color,
    required this.bgColor,
    required this.emoji,
    required this.index,
    required this.isLocked,
    required this.isCompleted,
    required this.leccionesCompletadas,
  });
  @override
  State<_NivelCard> createState() => _NivelCardState();
}

class _NivelCardState extends State<_NivelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
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
    final locked = widget.isLocked;
    final completed = widget.isCompleted;
    final cardColor = locked ? const Color(0xFFE5E7EB) : widget.color;
    final cardBg    = locked ? const Color(0xFFF3F4F6) : widget.bgColor;

    return GestureDetector(
      onTapDown: locked ? null : (_) => _tapCtrl.reverse(),
      onTapUp: locked ? null : (_) {
        _tapCtrl.forward();
        Navigator.of(context).pushNamed('/nivel', arguments: widget.nivel);
      },
      onTapCancel: locked ? null : () => _tapCtrl.forward(),
      child: ScaleTransition(
        scale: _tapCtrl,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: cardColor.withValues(alpha: locked ? 0.06 : 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Colored top strip
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(22)),
                    ),
                    child: Column(
                      children: [
                        // Level badge
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: cardColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              locked ? '🔒' : '${widget.nivel.orden}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: locked ? 14 : 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          locked ? '🔒' : widget.emoji,
                          style: TextStyle(
                            fontSize: 40,
                            color: locked
                                ? const Color(0xFF9CA3AF)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Info section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            locked ? 'Bloqueado' : widget.nivel.nombre,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: locked
                                  ? const Color(0xFF9CA3AF)
                                  : cardColor,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              locked
                                  ? 'Completa el anterior'
                                  : '${widget.nivel.temas.length} temas',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: locked
                                    ? const Color(0xFF9CA3AF)
                                    : cardColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Progreso real de lecciones del nivel
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Column(
                              children: [
                                Text(
                                  locked
                                      ? '0/${widget.nivel.totalLecciones} lecciones'
                                      : '${widget.leccionesCompletadas}/${widget.nivel.totalLecciones} lecciones',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _kMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: locked || widget.nivel.totalLecciones == 0
                                        ? 0
                                        : widget.leccionesCompletadas /
                                            widget.nivel.totalLecciones,
                                    minHeight: 6,
                                    backgroundColor: const Color(0xFFE5E7EB),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        locked
                                            ? const Color(0xFF9CA3AF)
                                            : cardColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Completed badge ──────────────────────────────────────────
            if (completed)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF059669),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('✓',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
