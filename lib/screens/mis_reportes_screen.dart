import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

const _kBg = Color(0xFFFFF9F2);
const _kDark = Color(0xFF1C1140);
const _kMuted = Color(0xFF8E8EA9);
const _kPurple = Color(0xFF6B46F6);
const _kGreen = Color(0xFF059669);
const _kYellow = Color(0xFFFFCC00);

class MisReportesScreen extends StatefulWidget {
  const MisReportesScreen({super.key});
  @override
  State<MisReportesScreen> createState() => _MisReportesScreenState();
}

class _MisReportesScreenState extends State<MisReportesScreen> {
  late Future<List<Reporte>> _reportesF;

  @override
  void initState() {
    super.initState();
    _reportesF = ApiService.getMisReportes();
  }

  Future<void> _refresh() async {
    setState(() => _reportesF = ApiService.getMisReportes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                    child: Text('🚩 Mis reportes',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900,
                            color: _kDark)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Reporte>>(
                future: _reportesF,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: _kPurple));
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('😕', style: TextStyle(fontSize: 44)),
                          const SizedBox(height: 10),
                          const Text('No se pudieron cargar tus reportes',
                              style: TextStyle(color: _kMuted)),
                          const SizedBox(height: 12),
                          TextButton(
                              onPressed: _refresh,
                              child: const Text('Reintentar')),
                        ],
                      ),
                    );
                  }
                  final reportes = snap.data ?? [];
                  if (reportes.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          '🚩\nAún no has enviado reportes.\n\nSi ves una foto de perfil inapropiada '
                          'en el ranking o un ejercicio problemático, puedes reportarlo '
                          'con el ícono 🚩.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _kMuted, fontSize: 14, height: 1.6),
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: _kPurple,
                    onRefresh: _refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: reportes.length,
                      itemBuilder: (_, i) => _tarjeta(reportes[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjeta(Reporte r) {
    final pendiente = r.estado == 'pendiente';
    final fundado = r.estado == 'fundado';
    final color = pendiente ? _kYellow : (fundado ? _kGreen : _kMuted);
    final chipBg = pendiente
        ? const Color(0xFFFEF3C7)
        : (fundado ? const Color(0xFFD1FAE5) : const Color(0xFFF3F4F6));
    final chipFg = pendiente
        ? const Color(0xFF92400E)
        : (fundado ? const Color(0xFF065F46) : _kMuted);
    final chipTexto = pendiente
        ? '⏳ En revisión'
        : (fundado ? '✅ Fundado' : '➖ No fundado');
    final tipoTexto = r.tipo == 'usuario_foto'
        ? '👤 Foto de perfil'
        : '📝 Ejercicio';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(tipoTexto,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800, color: _kDark)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(chipTexto,
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: chipFg)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('💬 ${r.motivo}',
              style: const TextStyle(
                  fontSize: 13, color: _kDark, fontWeight: FontWeight.w600)),
          Text(
            '${r.fecha.day}/${r.fecha.month}/${r.fecha.year}',
            style: const TextStyle(fontSize: 11, color: _kMuted),
          ),
          if (!pendiente && r.respuestaAdmin.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: chipBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📩', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(r.respuestaAdmin,
                        style: const TextStyle(
                            fontSize: 12, color: _kDark, height: 1.4)),
                  ),
                ],
              ),
            ),
            if (fundado) ...[
              const SizedBox(height: 8),
              const Row(children: [
                Text('🦸', style: TextStyle(fontSize: 14)),
                SizedBox(width: 6),
                Text('¡Ganaste la medalla Justiciero!',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _kGreen)),
              ]),
            ],
          ],
        ],
      ),
    );
  }
}
