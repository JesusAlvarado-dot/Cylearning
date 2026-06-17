import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class NivelDetailScreen extends StatefulWidget {
  final Nivel nivel;

  const NivelDetailScreen({super.key, required this.nivel});

  @override
  State<NivelDetailScreen> createState() => _NivelDetailScreenState();
}

class _NivelDetailScreenState extends State<NivelDetailScreen> {
  late Future<List<Leccion>> _leccionesF;

  @override
  void initState() {
    super.initState();
    _leccionesF = ApiService.getLecciones(widget.nivel.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Text(widget.nivel.nombre),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<Leccion>>(
        future: _leccionesF,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📚', style: TextStyle(fontSize: 56)),
                  SizedBox(height: 16),
                  CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  SizedBox(height: 12),
                  Text('Cargando lecciones...',
                      style: TextStyle(color: Color(0xFF6C63FF))),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('😥', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  const Text(
                    'No pudimos cargar las lecciones',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {
                      _leccionesF = ApiService.getLecciones(widget.nivel.id);
                    }),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final lecciones = snapshot.data ?? [];

          if (lecciones.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📖', style: TextStyle(fontSize: 56)),
                  SizedBox(height: 16),
                  Text(
                    'No hay lecciones disponibles aún',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3E3799)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Text('📚', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${lecciones.length} lecciones disponibles',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.nivel.descripcion,
                          style: const TextStyle(
                            color: Color(0xFFCECAFF),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: lecciones.length,
                  itemBuilder: (context, index) {
                    final leccion = lecciones[index];
                    return _LeccionCard(
                      leccion: leccion,
                      index: index,
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

class _LeccionCard extends StatelessWidget {
  final Leccion leccion;
  final int index;

  const _LeccionCard({required this.leccion, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        shadowColor: const Color(0xFF6C63FF).withValues(alpha: 0.15),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () =>
              Navigator.of(context).pushNamed('/leccion', arguments: leccion),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leccion.titulo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333366),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          _Tag(
                            icon: Icons.timer_outlined,
                            label: '${leccion.duracion} min',
                          ),
                          _Tag(
                            icon: Icons.label_outline,
                            label: leccion.tema,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Color(0xFF6C63FF),
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Tag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
