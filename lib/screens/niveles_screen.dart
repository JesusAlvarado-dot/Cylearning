import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';

const _levelGradients = [
  [Color(0xFF7C4DFF), Color(0xFF448AFF)],
  [Color(0xFFFF6D00), Color(0xFFFFAB00)],
  [Color(0xFF00897B), Color(0xFF26C6DA)],
  [Color(0xFFE91E63), Color(0xFFFF5722)],
  [Color(0xFF1565C0), Color(0xFF7B1FA2)],
  [Color(0xFF2E7D32), Color(0xFF43A047)],
  [Color(0xFF4527A0), Color(0xFF0288D1)],
];

const _levelEmojis = ['🔰', '⚡', '🛡️', '🚀', '🏆', '🌟', '🎯'];

class NivelesScreen extends StatefulWidget {
  const NivelesScreen({super.key});

  @override
  State<NivelesScreen> createState() => _NivelesScreenState();
}

class _NivelesScreenState extends State<NivelesScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Nivel>> _nivelesF;
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _nivelesF = ApiService.getNiveles();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  auth: auth,
                  waveAnim: _waveCtrl,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: FutureBuilder<List<Nivel>>(
                  future: _nivelesF,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('⏳', style: TextStyle(fontSize: 56)),
                              SizedBox(height: 16),
                              CircularProgressIndicator(
                                  color: Color(0xFF7C4DFF)),
                              SizedBox(height: 12),
                              Text('Cargando niveles...',
                                  style: TextStyle(
                                      color: Color(0xFF7C4DFF),
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('😥',
                                  style: TextStyle(fontSize: 56)),
                              const SizedBox(height: 16),
                              const Text(
                                'No pudimos cargar los niveles',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () => setState(
                                    () => _nivelesF = ApiService.getNiveles()),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Reintentar'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C4DFF)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final niveles = snapshot.data ?? [];
                    if (niveles.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('📚', style: TextStyle(fontSize: 56)),
                              SizedBox(height: 16),
                              Text('Aún no hay niveles disponibles',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.82,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _NivelCard(
                            nivel: niveles[index],
                            gradColors: _levelGradients[
                                index % _levelGradients.length],
                            emoji:
                                _levelEmojis[index % _levelEmojis.length],
                            position: index + 1,
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

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AuthProvider auth;
  final Animation<double> waveAnim;

  const _Header({required this.auth, required this.waveAnim});

  @override
  Widget build(BuildContext context) {
    final nombre =
        auth.usuario?.nombre.split(' ').first ?? 'Explorador';
    final puntos = auth.usuario?.puntosTotales ?? 0;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C4DFF), Color(0xFF5C35CC)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedBuilder(
                          animation: waveAnim,
                          builder: (ctx, child) => Transform.translate(
                            offset: Offset(0, -4 * waveAnim.value),
                            child: child,
                          ),
                          child: const Text('👋',
                              style: TextStyle(fontSize: 36)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '¡Hola, $nombre!',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          '¿Listo para aprender hoy?',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFFD1C4E9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    offset: const Offset(0, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    icon: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2),
                      ),
                      child: Center(
                        child: Text(
                          (auth.usuario?.nombre ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Text(
                          auth.usuario?.nombre ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'perfil',
                        child: Row(
                          children: [
                            Icon(Icons.person_rounded,
                                color: Color(0xFF7C4DFF)),
                            SizedBox(width: 10),
                            Text('Mi perfil'),
                          ],
                        ),
                      ),
                      if (auth.usuario?.rol == 'admin')
                        const PopupMenuItem(
                          value: 'admin',
                          child: Row(
                            children: [
                              Icon(Icons.admin_panel_settings_rounded,
                                  color: Color(0xFF7C4DFF)),
                              SizedBox(width: 10),
                              Text('Panel admin'),
                            ],
                          ),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Cerrar sesión',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'perfil':
                          Navigator.of(context).pushNamed('/perfil');
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
              const SizedBox(height: 20),
              // Stats row
              Row(
                children: [
                  _StatChip(
                    emoji: '⭐',
                    value: '$puntos pts',
                    color: const Color(0xFFFFD600),
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    emoji: '🏅',
                    value: '${auth.usuario?.medallas.length ?? 0} medallas',
                    color: const Color(0xFFFF9100),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String emoji;
  final String value;
  final Color color;

  const _StatChip(
      {required this.emoji, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nivel Card ───────────────────────────────────────────────────────────────

class _NivelCard extends StatefulWidget {
  final Nivel nivel;
  final List<Color> gradColors;
  final String emoji;
  final int position;

  const _NivelCard({
    required this.nivel,
    required this.gradColors,
    required this.emoji,
    required this.position,
  });

  @override
  State<_NivelCard> createState() => _NivelCardState();
}

class _NivelCardState extends State<_NivelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tapCtrl.forward(),
      onTapUp: (_) {
        _tapCtrl.reverse();
        Navigator.of(context)
            .pushNamed('/nivel', arguments: widget.nivel);
      },
      onTapCancel: () => _tapCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.gradColors[0].withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top gradient area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.gradColors,
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Level number badge
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.nivel.orden}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.emoji,
                        style: const TextStyle(fontSize: 38)),
                  ],
                ),
              ),
              // Bottom info area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.nivel.nombre,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: widget.gradColors[0],
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              widget.gradColors[0].withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${widget.nivel.temas.length} temas',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.gradColors[0],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Decorative stars
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (i) => Text(
                            i < (widget.position % 4) ? '⭐' : '☆',
                            style: TextStyle(
                              fontSize: 14,
                              color: i < (widget.position % 4)
                                  ? const Color(0xFFFFD600)
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),
                    ],
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
