import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class LeccionScreen extends StatefulWidget {
  final Leccion leccion;

  const LeccionScreen({super.key, required this.leccion});

  @override
  State<LeccionScreen> createState() => _LeccionScreenState();
}

class _LeccionScreenState extends State<LeccionScreen> {
  late Future<Leccion> _leccionF;

  @override
  void initState() {
    super.initState();
    _leccionF = ApiService.getLeccion(widget.leccion.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Lección'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<Leccion>(
        future: _leccionF,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📖', style: TextStyle(fontSize: 56)),
                  SizedBox(height: 16),
                  CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  SizedBox(height: 12),
                  Text('Cargando lección...',
                      style: TextStyle(color: Color(0xFF6C63FF))),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('😥', style: TextStyle(fontSize: 56)),
                  SizedBox(height: 16),
                  Text(
                    'No pudimos cargar la lección',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final leccion = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF3E3799)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📖', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 10),
                      Text(
                        leccion.titulo,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _Chip(
                            icon: Icons.timer_outlined,
                            label: '${leccion.duracion} min',
                          ),
                          const SizedBox(width: 8),
                          _Chip(
                            icon: Icons.label_outline,
                            label: leccion.tema,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    leccion.contenido,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF333366),
                      height: 1.7,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed(
                      '/ejercicios',
                      arguments: leccion.id,
                    ),
                    icon: const Icon(Icons.quiz_rounded, size: 24),
                    label: const Text(
                      '¡Practicar ejercicios!',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
