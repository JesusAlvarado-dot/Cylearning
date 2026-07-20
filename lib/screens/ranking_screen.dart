import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/avatar.dart';

const _kBg     = Color(0xFFFFF9F2);
const _kDark   = Color(0xFF1C1140);
const _kMuted  = Color(0xFF8E8EA9);
const _kPurple = Color(0xFF6B46F6);
const _kYellow = Color(0xFFFFCC00);

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});
  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late Future<List<EstudianteRanking>> _rankingF;
  // 'global' = toda la app; 'organizacion' = solo mi clase/organización
  String _alcance = 'global';

  @override
  void initState() {
    super.initState();
    // Los estudiantes de una organización arrancan viendo SU clase
    final usuario = context.read<AuthProvider>().usuario;
    if (usuario?.organizacion != null) _alcance = 'organizacion';
    _rankingF = ApiService.getRanking(alcance: _alcance);
  }

  Future<void> _refresh() async {
    setState(() => _rankingF = ApiService.getRanking(alcance: _alcance));
  }

  void _cambiarAlcance(String alcance) {
    if (alcance == _alcance) return;
    setState(() {
      _alcance = alcance;
      _rankingF = ApiService.getRanking(alcance: alcance);
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.read<AuthProvider>().usuario;
    final myId = usuario?.id ?? '';
    final tieneOrg = usuario?.organizacion != null;
    return Scaffold(
      backgroundColor: _kBg,
      body: FutureBuilder<List<EstudianteRanking>>(
        future: _rankingF,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _kPurple));
          }
          if (snap.hasError) {
            return _ErrorView(onRetry: _refresh);
          }
          final ranking = snap.data ?? [];
          return RefreshIndicator(
            onRefresh: _refresh,
            color: _kPurple,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                // Selector Global / Mi clase (solo si pertenece a una org)
                if (tieneOrg)
                  SliverToBoxAdapter(
                    child: _SelectorAlcance(
                      alcance: _alcance,
                      nombreOrg: usuario!.organizacion!.nombre,
                      onCambiar: _cambiarAlcance,
                    ),
                  ),
                if (ranking.isNotEmpty)
                  SliverToBoxAdapter(
                      child: _buildPodium(ranking.take(3).toList(), myId)),
                if (ranking.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          '🏆\nAún no hay nadie en este ranking.\n¡Sé el primero!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 15,
                              color: _kMuted,
                              fontWeight: FontWeight.w600,
                              height: 1.6),
                        ),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildRow(ranking[i], i + 1, ranking[i].id == myId),
                      childCount: ranking.length,
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

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Stack(
      children: [
        Positioned(
          top: -30, right: -30,
          child: Container(
            width: 130, height: 130,
            decoration: BoxDecoration(
              color: _kPurple.withValues(alpha: 0.07),
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🏆 Ranking',
                          style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900,
                            color: _kDark,
                          )),
                      Text('Los mejores defensores digitales',
                          style: TextStyle(fontSize: 13, color: _kMuted)),
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

  // ─── Podium top 3 ──────────────────────────────────────────────────────────

  Widget _buildPodium(List<EstudianteRanking> top, String myId) {
    final podiumOrder = <int>[]; // indices into top[]
    if (top.length == 1) {
      podiumOrder.addAll([0]);
    } else if (top.length == 2) {
      podiumOrder.addAll([0, 1]);
    } else {
      podiumOrder.addAll([1, 0, 2]); // 2nd, 1st, 3rd
    }

    const podiumColors  = [Color(0xFFFFD700), Color(0xFFC0C0C0), Color(0xFFCD7F32)];
    const podiumHeights = [110.0, 80.0, 65.0];
    const podiumLabels  = ['🥇', '🥈', '🥉'];
    final positions     = [1, 0, 2]; // maps podiumOrder index → rank label index

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kPurple.withValues(alpha: 0.08),
            blurRadius: 20, offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(podiumOrder.length, (slot) {
          final idx  = podiumOrder[slot];
          final entry = top[idx];
          final rankIdx = positions[slot];
          final color = podiumColors[rankIdx];
          final height = podiumHeights[rankIdx];
          final isMe  = entry.id == myId;

          return Expanded(
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isMe ? _kPurple : color,
                      width: isMe ? 3 : 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      entry.nombre.isNotEmpty
                          ? entry.nombre[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  podiumLabels[rankIdx],
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.nombre.split(' ').first,
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: isMe ? _kPurple : _kDark,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.puntosTotales} pts',
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                // Podio
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8)),
                    border: Border.all(
                        color: color.withValues(alpha: 0.4), width: 1.5),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── List rows ─────────────────────────────────────────────────────────────

  Widget _buildRow(EstudianteRanking entry, int rank, bool isMe) {
    final topMedalla = entry.medallas.isNotEmpty ? entry.medallas.last : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFEFEBFF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? _kPurple : const Color(0xFFF0F0F0),
          width: isMe ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _kDark.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900,
                color: rank <= 3 ? _kYellow : _kMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          // Avatar (con foto de perfil si la hay)
          Avatar(
            foto: entry.foto,
            nombre: entry.nombre,
            radio: 20,
            color: isMe ? _kPurple : _kDark,
            fondo: isMe ? const Color(0xFFEFEBFF) : const Color(0xFFF3F4F6),
          ),
          const SizedBox(width: 12),
          // Name + streak
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.nombre + (isMe ? ' (tú)' : ''),
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: isMe ? _kPurple : _kDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (entry.racha > 0) ...[
                      Text('🔥 ${entry.racha}d',
                          style: const TextStyle(
                              fontSize: 11, color: _kMuted,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                    ],
                    if (topMedalla != null)
                      Text(topMedalla.emoji,
                          style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          // Points
          Text(
            '${entry.puntosTotales} pts',
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w900,
              color: isMe ? _kPurple : _kDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            const Text('No se pudo cargar el ranking',
                style: TextStyle(color: _kMuted, fontSize: 15)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kPurple, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
}

// Selector entre el ranking global y el de la organizacion del usuario
class _SelectorAlcance extends StatelessWidget {
  final String alcance;
  final String nombreOrg;
  final ValueChanged<String> onCambiar;

  const _SelectorAlcance({
    required this.alcance,
    required this.nombreOrg,
    required this.onCambiar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDE9FE)),
        ),
        child: Row(
          children: [
            _opcion('🏫 Mi clase', 'organizacion'),
            _opcion('🌍 Global', 'global'),
          ],
        ),
      ),
    );
  }

  Widget _opcion(String label, String valor) {
    final activo = alcance == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () => onCambiar(valor),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: activo ? _kPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: activo ? Colors.white : _kMuted,
            ),
          ),
        ),
      ),
    );
  }
}
