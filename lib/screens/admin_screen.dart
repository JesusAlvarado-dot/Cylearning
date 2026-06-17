import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          // Header gradiente
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF3E3799)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Panel Admin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'CyLearn',
                                style: TextStyle(
                                    color: Color(0xFFCECAFF), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Consumer<AuthProvider>(
                          builder: (context, auth, _) => IconButton(
                            icon: const Icon(Icons.logout_rounded,
                                color: Colors.white),
                            onPressed: () {
                              auth.logout();
                              Navigator.of(context)
                                  .pushReplacementNamed('/login');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFFFFD93D),
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFFCECAFF),
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: const [
                      Tab(icon: Icon(Icons.people_rounded), text: 'Estudiantes'),
                      Tab(icon: Icon(Icons.menu_book_rounded), text: 'Contenido'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _EstudiantesTab(),
                _ContenidoTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB 1: ESTUDIANTES
// ─────────────────────────────────────────────

class _EstudiantesTab extends StatefulWidget {
  const _EstudiantesTab();

  @override
  State<_EstudiantesTab> createState() => _EstudiantesTabState();
}

class _EstudiantesTabState extends State<_EstudiantesTab> {
  String _orden = 'desc';
  late Future<List<EstudianteRanking>> _rankingF;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _rankingF = ApiService.getEstudiantes(orden: _orden);
  }

  void _recargar() => setState(() => _cargar());

  Future<void> _mostrarDialogoMedalla(EstudianteRanking est) async {
    String? seleccion;
    final tecCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('🏅 Dar medalla a\n${est.nombre}',
              style: const TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 10,
                children: [
                  for (final m in [
                    ('oro', '🥇 Oro'),
                    ('plata', '🥈 Plata'),
                    ('bronce', '🥉 Bronce'),
                    ('estrella', '⭐ Estrella'),
                  ])
                    ChoiceChip(
                      label: Text(m.$2),
                      selected: seleccion == m.$1,
                      selectedColor: const Color(0xFF6C63FF),
                      labelStyle: TextStyle(
                        color: seleccion == m.$1
                            ? Colors.white
                            : const Color(0xFF333366),
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => setS(() => seleccion = m.$1),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tecCtrl,
                decoration: InputDecoration(
                  labelText: 'Motivo (opcional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFFF5F4FF),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: seleccion == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      try {
                        await ApiService.darMedalla(
                            est.id, seleccion!, tecCtrl.text.trim());
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              '🏅 Medalla otorgada a ${est.nombre}'),
                          backgroundColor: const Color(0xFF4CAF50),
                        ));
                        _recargar();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(e.toString().replaceFirst('Exception: ', '')),
                          backgroundColor: Colors.red,
                        ));
                      }
                    },
              child: const Text('Dar medalla'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtro
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Text('Ordenar:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFF333366))),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text('🏆 Mejor puntaje'),
                selected: _orden == 'desc',
                selectedColor: const Color(0xFF6C63FF),
                labelStyle: TextStyle(
                    color: _orden == 'desc' ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold),
                onSelected: (_) {
                  if (_orden != 'desc') setState(() { _orden = 'desc'; _cargar(); });
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('📉 Menor puntaje'),
                selected: _orden == 'asc',
                selectedColor: const Color(0xFFE91E63),
                labelStyle: TextStyle(
                    color: _orden == 'asc' ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold),
                onSelected: (_) {
                  if (_orden != 'asc') setState(() { _orden = 'asc'; _cargar(); });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<EstudianteRanking>>(
            future: _rankingF,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('👥', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      CircularProgressIndicator(color: Color(0xFF6C63FF)),
                    ],
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('😥', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      const Text('Error al cargar estudiantes',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _recargar,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }
              final lista = snapshot.data ?? [];
              if (lista.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🎓', style: TextStyle(fontSize: 56)),
                      SizedBox(height: 12),
                      Text('No hay estudiantes registrados',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: lista.length,
                itemBuilder: (ctx, i) =>
                    _EstudianteCard(
                      est: lista[i],
                      posicion: i + 1,
                      onMedalla: () => _mostrarDialogoMedalla(lista[i]),
                    ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EstudianteCard extends StatelessWidget {
  final EstudianteRanking est;
  final int posicion;
  final VoidCallback onMedalla;

  const _EstudianteCard({
    required this.est,
    required this.posicion,
    required this.onMedalla,
  });

  Color get _posColor {
    if (posicion == 1) return const Color(0xFFFFD93D);
    if (posicion == 2) return const Color(0xFFB0BEC5);
    if (posicion == 3) return const Color(0xFFFF9800);
    return const Color(0xFF6C63FF);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _posColor.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Posición
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _posColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  posicion <= 3
                      ? ['🥇', '🥈', '🥉'][posicion - 1]
                      : '#$posicion',
                  style: TextStyle(
                    fontSize: posicion <= 3 ? 20 : 13,
                    fontWeight: FontWeight.bold,
                    color: _posColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Avatar inicial
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              child: Text(
                est.nombre.isNotEmpty ? est.nombre[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C63FF),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    est.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF333366),
                    ),
                  ),
                  Text(
                    '⭐ ${est.puntosTotales} puntos',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13),
                  ),
                  if (est.medallas.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        children: est.medallas
                            .map((m) => Text(m.emoji,
                                style: const TextStyle(fontSize: 16)))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            // Botón medalla
            IconButton(
              icon: const Text('🏅', style: TextStyle(fontSize: 22)),
              tooltip: 'Dar medalla',
              onPressed: onMedalla,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB 2: CONTENIDO
// ─────────────────────────────────────────────

class _ContenidoTab extends StatefulWidget {
  const _ContenidoTab();

  @override
  State<_ContenidoTab> createState() => _ContenidoTabState();
}

class _ContenidoTabState extends State<_ContenidoTab> {
  Future<void> _abrirFormLeccion() async {
    List<Map<String, dynamic>> temas = [];
    try {
      temas = await ApiService.getTemasAdmin();
    } catch (_) {}

    if (!mounted) return;

    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final contenidoCtrl = TextEditingController();
    String? temaId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FormSheet(
        titulo: '📖 Nueva Lección',
        child: StatefulBuilder(
          builder: (ctx, setS) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _campo(nombreCtrl, 'Título de la lección', Icons.title_rounded),
              const SizedBox(height: 12),
              _campo(descCtrl, 'Descripción breve', Icons.notes_rounded),
              const SizedBox(height: 12),
              _campo(contenidoCtrl, 'Contenido (texto completo)',
                  Icons.article_rounded,
                  maxLines: 5),
              const SizedBox(height: 12),
              if (temas.isEmpty)
                const Text('⚠️ No hay temas disponibles',
                    style: TextStyle(color: Colors.orange))
              else
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tema',
                    prefixIcon: const Icon(Icons.folder_rounded,
                        color: Color(0xFF6C63FF)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade400)),
                    filled: true,
                    fillColor: const Color(0xFFF5F4FF),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: temaId,
                      isExpanded: true,
                      hint: const Text('Selecciona un tema'),
                      items: temas
                          .map((t) => DropdownMenuItem<String>(
                                value: t['_id'] as String,
                                child:
                                    Text(t['nombre'] as String? ?? ''),
                              ))
                          .toList(),
                      onChanged: (v) => setS(() => temaId = v),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final nombre = nombreCtrl.text.trim();
                  if (nombre.length < 3) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('El título debe tener al menos 3 caracteres'),
                    ));
                    return;
                  }
                  if (contenidoCtrl.text.trim().isEmpty || temaId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Completa todos los campos'),
                    ));
                    return;
                  }
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(ctx);
                  try {
                    await ApiService.crearLeccion(
                      nombre: nombre,
                      descripcion: descCtrl.text.trim(),
                      contenido: contenidoCtrl.text.trim(),
                      temaId: temaId!,
                    );
                    if (!mounted) return;
                    nav.pop();
                    messenger.showSnackBar(const SnackBar(
                      content: Text('📖 Lección publicada'),
                      backgroundColor: Color(0xFF4CAF50),
                    ));
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(SnackBar(
                      content: Text(
                          e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ));
                  }
                },
                icon: const Icon(Icons.publish_rounded),
                label: const Text('Publicar lección',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirFormEjercicio() async {
    List<Map<String, dynamic>> lecciones = [];
    try {
      lecciones = await ApiService.getLeccionesAdmin();
    } catch (_) {}

    if (!mounted) return;

    final preguntaCtrl = TextEditingController();
    final opcion1Ctrl = TextEditingController();
    final opcion2Ctrl = TextEditingController();
    final opcion3Ctrl = TextEditingController();
    final opcion4Ctrl = TextEditingController();
    final explicCtrl = TextEditingController();
    final puntosCtrl = TextEditingController(text: '10');
    String? leccionId;
    String tipo = 'seleccion_unica';
    int respuestaIdx = 0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FormSheet(
        titulo: '❓ Nuevo Ejercicio',
        child: StatefulBuilder(
          builder: (ctx, setS) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _campo(preguntaCtrl, 'Pregunta', Icons.quiz_rounded, maxLines: 2),
              const SizedBox(height: 12),
              // Tipo
              Row(
                children: [
                  const Text('Tipo: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  for (final t in [
                    ('seleccion_unica', 'Opción múltiple'),
                    ('verdadero_falso', 'V/F'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(t.$2,
                            style: const TextStyle(fontSize: 12)),
                        selected: tipo == t.$1,
                        selectedColor: const Color(0xFF6C63FF),
                        labelStyle: TextStyle(
                          color: tipo == t.$1 ? Colors.white : Colors.black87,
                        ),
                        onSelected: (_) => setS(() {
                          tipo = t.$1;
                          if (tipo == 'verdadero_falso') {
                            opcion1Ctrl.text = 'Verdadero';
                            opcion2Ctrl.text = 'Falso';
                          }
                        }),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (tipo == 'seleccion_unica') ...[
                const Text('Opciones:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                for (int i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setS(() => respuestaIdx = i),
                          child: Icon(
                            respuestaIdx == i
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: respuestaIdx == i
                                ? const Color(0xFF4CAF50)
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: [
                              opcion1Ctrl,
                              opcion2Ctrl,
                              opcion3Ctrl,
                              opcion4Ctrl
                            ][i],
                            decoration: InputDecoration(
                              labelText: 'Opción ${['A', 'B', 'C', 'D'][i]}',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: respuestaIdx == i
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFF5F4FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Text('(Toca el círculo de la respuesta correcta)',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ] else ...[
                Row(
                  children: [
                    for (int i = 0; i < 2; i++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: i == 0 ? 8 : 0),
                          child: GestureDetector(
                            onTap: () => setS(() => respuestaIdx = i),
                            child: Row(
                              children: [
                                Icon(
                                  respuestaIdx == i
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: respuestaIdx == i
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(['Verdadero', 'Falso'][i],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              _campo(explicCtrl, 'Explicación', Icons.lightbulb_rounded,
                  maxLines: 2),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _campo(puntosCtrl, 'Puntos', Icons.star_rounded,
                        keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: lecciones.isEmpty
                        ? const Text('⚠️ Sin lecciones',
                            style: TextStyle(color: Colors.orange))
                        : InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Lección',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade400)),
                              filled: true,
                              fillColor: const Color(0xFFF5F4FF),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: leccionId,
                                isExpanded: true,
                                hint: const Text('Selecciona',
                                    overflow: TextOverflow.ellipsis),
                                items: lecciones
                                    .map((l) => DropdownMenuItem<String>(
                                          value: l['_id'] as String,
                                          child: Text(
                                            l['nombre'] as String? ?? '',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (v) => setS(() => leccionId = v),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final opciones = tipo == 'verdadero_falso'
                      ? ['Verdadero', 'Falso']
                      : [
                          opcion1Ctrl.text.trim(),
                          opcion2Ctrl.text.trim(),
                          opcion3Ctrl.text.trim(),
                          opcion4Ctrl.text.trim(),
                        ].where((o) => o.isNotEmpty).toList();

                  final pregunta = preguntaCtrl.text.trim();
                  if (pregunta.length < 5) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'La pregunta debe tener al menos 5 caracteres'),
                    ));
                    return;
                  }
                  if (opciones.isEmpty || leccionId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Completa todos los campos'),
                    ));
                    return;
                  }

                  final respuestaCorrecta = opciones.length > respuestaIdx
                      ? opciones[respuestaIdx]
                      : opciones.first;

                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(ctx);
                  try {
                    await ApiService.crearEjercicio(
                      pregunta: pregunta,
                      tipo: tipo,
                      opciones: opciones,
                      respuestaCorrecta: respuestaCorrecta,
                      explicacion: explicCtrl.text.trim(),
                      puntos: int.tryParse(puntosCtrl.text) ?? 10,
                      leccionId: leccionId!,
                    );
                    if (!mounted) return;
                    nav.pop();
                    messenger.showSnackBar(const SnackBar(
                      content: Text('❓ Ejercicio publicado'),
                      backgroundColor: Color(0xFF4CAF50),
                    ));
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(SnackBar(
                      content: Text(
                          e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: Colors.red,
                    ));
                  }
                },
                icon: const Icon(Icons.publish_rounded),
                label: const Text('Publicar ejercicio',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Publicar contenido',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333366),
            ),
          ),
          const SizedBox(height: 16),
          _ContentActionCard(
            emoji: '📖',
            titulo: 'Nueva Lección',
            descripcion:
                'Crea una nueva lección con texto educativo para los estudiantes',
            color: const Color(0xFF6C63FF),
            onTap: _abrirFormLeccion,
          ),
          const SizedBox(height: 14),
          _ContentActionCard(
            emoji: '❓',
            titulo: 'Nuevo Ejercicio',
            descripcion:
                'Añade una pregunta de opción múltiple o verdadero/falso',
            color: const Color(0xFF4CAF50),
            onTap: _abrirFormEjercicio,
          ),
          const SizedBox(height: 24),
          const _InfoCard(
            emoji: '💡',
            texto:
                'Los ejercicios de tipo "completar" requieren que el estudiante '
                'escriba la respuesta exacta. Usa opción múltiple o V/F para preguntas más amigables.',
          ),
        ],
      ),
    );
  }
}

class _ContentActionCard extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String descripcion;
  final Color color;
  final VoidCallback onTap;

  const _ContentActionCard({
    required this.emoji,
    required this.titulo,
    required this.descripcion,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: color)),
                    const SizedBox(height: 4),
                    Text(descripcion,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.add_circle_rounded, color: color, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String emoji;
  final String texto;

  const _InfoCard({required this.emoji, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD93D), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto,
                style: const TextStyle(
                    color: Color(0xFF795548), fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────

class _FormSheet extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _FormSheet({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(titulo,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333366))),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

Widget _campo(
  TextEditingController ctrl,
  String label,
  IconData icon, {
  int maxLines = 1,
  TextInputType keyboardType = TextInputType.text,
}) {
  return TextField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFF5F4FF),
    ),
  );
}
