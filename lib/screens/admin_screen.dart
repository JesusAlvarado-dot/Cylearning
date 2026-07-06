import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/models.dart';

const _bg = Color(0xFFFFF9F2);
const _purple = Color(0xFF6B46F6);
const _yellow = Color(0xFFFFCC00);
const _green = Color(0xFF059669);
const _red = Color(0xFFEF4444);
const _dark = Color(0xFF1C1140);
const _muted = Color(0xFF8E8EA9);

String _id(dynamic v) => v is Map ? (v['_id'] ?? '').toString() : v?.toString() ?? '';
String _extractMsg(Object e) => e.toString().replaceFirst('Exception: ', '');

// ─────────────────────────────────────────────────────────────────────────────
// ROOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────

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
    final auth = context.watch<AuthProvider>();
    final adminNombre = auth.usuario?.nombre ?? 'Admin';

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          Container(
            color: _purple,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('⚙️', style: TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Panel Admin ⚙️',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                adminNombre,
                                style: const TextStyle(
                                    color: Color(0xFFD4C8FF), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded,
                              color: Colors.white),
                          tooltip: 'Cerrar sesión',
                          onPressed: () {
                            auth.logout();
                            Navigator.of(context).pushReplacementNamed('/login');
                          },
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: _yellow,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFFD4C8FF),
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(text: '👤 Usuarios'),
                      Tab(text: '📚 Contenido'),
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
                _UsuariosTab(),
                _ContenidoTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: USUARIOS
// ─────────────────────────────────────────────────────────────────────────────

class _UsuariosTab extends StatefulWidget {
  const _UsuariosTab();

  @override
  State<_UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<_UsuariosTab> {
  List<EstudianteRanking> _usuarios = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lista = await ApiService.getEstudiantes(orden: 'desc');
      if (!mounted) return;
      setState(() {
        _usuarios = lista;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _extractMsg(e);
        _loading = false;
      });
    }
  }

  void _snack(String msg, {Color color = _green}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _dlgCrearUsuario() async {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String rol = 'student';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _AdminDialog(
          titulo: 'Nuevo Usuario',
          icon: Icons.person_add_rounded,
          color: _purple,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campo(nombreCtrl, 'Nombre', Icons.person_rounded),
              const SizedBox(height: 10),
              _campo(emailCtrl, 'Email', Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _campo(passCtrl, 'Contraseña', Icons.lock_rounded),
              const SizedBox(height: 10),
              _dropdownField<String>(
                label: 'Rol',
                icon: Icons.badge_rounded,
                value: rol,
                items: const [
                  ('student', 'Estudiante'),
                  ('admin', 'Administrador'),
                ],
                onChanged: (v) => setS(() => rol = v ?? 'student'),
              ),
            ],
          ),
          onGuardar: () async {
            if (nombreCtrl.text.trim().length < 2) {
              throw Exception('El nombre debe tener al menos 2 caracteres');
            }
            if (!emailCtrl.text.contains('@')) {
              throw Exception('Email inválido');
            }
            if (passCtrl.text.length < 6) {
              throw Exception('La contraseña debe tener al menos 6 caracteres');
            }
            await ApiService.crearUsuarioAdmin(
              nombre: nombreCtrl.text.trim(),
              email: emailCtrl.text.trim(),
              contrasena: passCtrl.text,
              rol: rol,
            );
          },
          onExito: () {
            _snack('Usuario creado');
            _cargar();
          },
        ),
      ),
    );
  }

  Future<void> _dlgEditarUsuario(EstudianteRanking est) async {
    final nombreCtrl = TextEditingController(text: est.nombre);

    await showDialog(
      context: context,
      builder: (ctx) => _AdminDialog(
        titulo: 'Editar Usuario',
        icon: Icons.edit_rounded,
        color: _purple,
        content: _campo(nombreCtrl, 'Nombre', Icons.person_rounded),
        onGuardar: () async {
          if (nombreCtrl.text.trim().length < 2) {
            throw Exception('El nombre debe tener al menos 2 caracteres');
          }
          await ApiService.actualizarUsuarioAdmin(
              est.id, {'nombre': nombreCtrl.text.trim()});
        },
        onExito: () {
          _snack('Usuario actualizado');
          _cargar();
        },
      ),
    );
  }

  Future<void> _confirmarEliminarUsuario(EstudianteRanking est) async {
    final ok = await _dlgConfirmar(
      context,
      'Eliminar "${est.nombre}"',
      '¿Eliminar ${est.nombre}? Esta acción no se puede deshacer.',
    );
    if (!ok || !mounted) return;
    try {
      await ApiService.eliminarUsuario(est.id);
      _snack('Usuario eliminado');
      _cargar();
    } catch (e) {
      _snack(_extractMsg(e), color: _red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        onPressed: _dlgCrearUsuario,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Nuevo usuario',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Builder(
        builder: (_) {
          if (_loading) {
            return const Center(
                child: CircularProgressIndicator(color: _purple));
          }
          if (_error != null) {
            return _ErrorView(onRetry: _cargar, msg: _error);
          }
          if (_usuarios.isEmpty) {
            return const _EmptyView(
                emoji: '👤', msg: 'No hay usuarios registrados');
          }
          return RefreshIndicator(
            color: _purple,
            onRefresh: _cargar,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: _usuarios.length,
              itemBuilder: (_, i) => _UsuarioCard(
                est: _usuarios[i],
                posicion: i + 1,
                onEdit: () => _dlgEditarUsuario(_usuarios[i]),
                onDelete: () => _confirmarEliminarUsuario(_usuarios[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  final EstudianteRanking est;
  final int posicion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UsuarioCard({
    required this.est,
    required this.posicion,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _purple.withValues(alpha: 0.12),
              child: Text(
                est.nombre.isNotEmpty ? est.nombre[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _purple),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(est.nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _dark)),
                  Text(est.email,
                      style: const TextStyle(color: _muted, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _yellow.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('⭐ ${est.puntosTotales} pts',
                            style: const TextStyle(
                                fontSize: 11,
                                color: _dark,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('student',
                            style: TextStyle(
                                fontSize: 11,
                                color: _purple,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _IconActionBtn(
                icon: Icons.edit_rounded,
                color: _muted,
                tooltip: 'Editar',
                onTap: onEdit),
            _IconActionBtn(
                icon: Icons.delete_rounded,
                color: _red,
                tooltip: 'Eliminar',
                onTap: onDelete),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: CONTENIDO — drill-down navigator
// ─────────────────────────────────────────────────────────────────────────────

class _ContenidoTab extends StatefulWidget {
  const _ContenidoTab();

  @override
  State<_ContenidoTab> createState() => _ContenidoTabState();
}

class _ContenidoTabState extends State<_ContenidoTab> {
  // drill-down state
  int _view = 0;
  Nivel? _nivelSel;
  Map<String, dynamic>? _temaSel;
  Map<String, dynamic>? _leccionSel;

  // data
  List<Nivel> _niveles = [];
  List<Map<String, dynamic>> _temas = [];
  List<Map<String, dynamic>> _lecciones = [];
  List<Map<String, dynamic>> _ejercicios = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarNiveles();
  }

  // ── loaders ──────────────────────────────────────────────────────────────

  Future<void> _cargarNiveles() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final niveles = await ApiService.getNiveles();
      if (!mounted) return;
      setState(() {
        _niveles = niveles;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _extractMsg(e);
        _loading = false;
      });
    }
  }

  Future<void> _cargarTemasDelNivel(String nivelId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final todos = await ApiService.getTemasAdmin();
      if (!mounted) return;
      setState(() {
        _temas = todos.where((t) => _id(t['nivel_id']) == nivelId).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _extractMsg(e);
        _loading = false;
      });
    }
  }

  Future<void> _cargarLeccionesDelTema(String temaId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final todas = await ApiService.getLeccionesAdmin();
      if (!mounted) return;
      setState(() {
        _lecciones = todas.where((l) => _id(l['tema_id']) == temaId).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _extractMsg(e);
        _loading = false;
      });
    }
  }

  Future<void> _cargarEjerciciosDeLeccion(String leccionId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lista =
          await ApiService.getEjerciciosAdmin(leccionId: leccionId);
      if (!mounted) return;
      setState(() {
        _ejercicios = lista;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _extractMsg(e);
        _loading = false;
      });
    }
  }

  Future<void> _recargarVista() async {
    switch (_view) {
      case 0:
        await _cargarNiveles();
      case 1:
        if (_nivelSel != null) { await _cargarTemasDelNivel(_nivelSel!.id); }
      case 2:
        if (_temaSel != null) {
          await _cargarLeccionesDelTema(_temaSel!['_id'] as String);
        }
      case 3:
        if (_leccionSel != null) {
          await _cargarEjerciciosDeLeccion(_leccionSel!['_id'] as String);
        }
    }
  }

  // ── navigation ────────────────────────────────────────────────────────────

  void _drillNivel(Nivel nv) {
    _nivelSel = nv;
    _view = 1;
    _cargarTemasDelNivel(nv.id);
  }

  void _drillTema(Map<String, dynamic> tema) {
    _temaSel = tema;
    _view = 2;
    _cargarLeccionesDelTema(tema['_id'] as String);
  }

  void _drillLeccion(Map<String, dynamic> lec) {
    _leccionSel = lec;
    _view = 3;
    _cargarEjerciciosDeLeccion(lec['_id'] as String);
  }

  void _back() {
    setState(() {
      if (_view == 1) {
        _view = 0;
        _nivelSel = null;
        _cargarNiveles();
      } else if (_view == 2) {
        _view = 1;
        _temaSel = null;
        _cargarTemasDelNivel(_nivelSel!.id);
      } else if (_view == 3) {
        _view = 2;
        _leccionSel = null;
        _cargarLeccionesDelTema(_temaSel!['_id'] as String);
      }
    });
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  void _snack(String msg, {Color color = _green}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── NIVEL dialogs ─────────────────────────────────────────────────────────

  Future<void> _dlgCrearNivel() async {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String dificultad = 'principiante';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _AdminDialog(
          titulo: 'Nuevo Nivel',
          icon: Icons.layers_rounded,
          color: _purple,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campo(nombreCtrl, 'Nombre del nivel', Icons.title_rounded),
              const SizedBox(height: 10),
              _campo(descCtrl, 'Descripción', Icons.notes_rounded),
              const SizedBox(height: 10),
              _dropdownField<String>(
                label: 'Dificultad',
                icon: Icons.bolt_rounded,
                value: dificultad,
                items: const [
                  ('principiante', 'Principiante'),
                  ('intermedio', 'Intermedio'),
                  ('avanzado', 'Avanzado'),
                ],
                onChanged: (v) => setS(() => dificultad = v ?? 'principiante'),
              ),
            ],
          ),
          onGuardar: () async {
            if (nombreCtrl.text.trim().length < 2) {
              throw Exception('El nombre debe tener al menos 2 caracteres');
            }
            final orden = _niveles.length + 1;
            await ApiService.crearNivel(
              nombreCtrl.text.trim(),
              descCtrl.text.trim(),
              orden,
              dificultad,
            );
          },
          onExito: () {
            _snack('Nivel creado');
            _cargarNiveles();
          },
        ),
      ),
    );
  }

  Future<void> _dlgEditarNivel(Nivel nv) async {
    final nombreCtrl = TextEditingController(text: nv.nombre);
    final descCtrl = TextEditingController(text: nv.descripcion);
    String dificultad = 'principiante';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _AdminDialog(
          titulo: 'Editar Nivel',
          icon: Icons.edit_rounded,
          color: _purple,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campo(nombreCtrl, 'Nombre del nivel', Icons.title_rounded),
              const SizedBox(height: 10),
              _campo(descCtrl, 'Descripción', Icons.notes_rounded),
              const SizedBox(height: 10),
              _dropdownField<String>(
                label: 'Dificultad',
                icon: Icons.bolt_rounded,
                value: dificultad,
                items: const [
                  ('principiante', 'Principiante'),
                  ('intermedio', 'Intermedio'),
                  ('avanzado', 'Avanzado'),
                ],
                onChanged: (v) => setS(() => dificultad = v ?? 'principiante'),
              ),
            ],
          ),
          onGuardar: () async {
            if (nombreCtrl.text.trim().length < 2) {
              throw Exception('El nombre debe tener al menos 2 caracteres');
            }
            await ApiService.actualizarNivel(nv.id, {
              'nombre': nombreCtrl.text.trim(),
              'descripcion': descCtrl.text.trim(),
              'dificultad': dificultad,
            });
          },
          onExito: () {
            _snack('Nivel actualizado');
            _cargarNiveles();
          },
        ),
      ),
    );
  }

  Future<void> _confirmarEliminarNivel(Nivel nv) async {
    final ok = await _dlgConfirmar(
      context,
      'Eliminar "${nv.nombre}"',
      '⚠️ Se borrará el nivel COMPLETO: todos sus temas, lecciones y '
      'ejercicios, junto con el progreso de los estudiantes en este nivel. '
      'Esta acción no se puede deshacer.',
    );
    if (!ok || !mounted) return;
    try {
      final d = await ApiService.eliminarNivel(nv.id);
      _snack('Nivel eliminado: ${d['temas_eliminados'] ?? 0} temas, '
          '${d['lecciones_eliminadas'] ?? 0} lecciones, '
          '${d['ejercicios_eliminados'] ?? 0} ejercicios');
      _cargarNiveles();
    } catch (e) {
      _snack(_extractMsg(e), color: _red);
    }
  }

  // ── TEMA dialogs ──────────────────────────────────────────────────────────

  Future<void> _dlgCrearTema() async {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => _AdminDialog(
        titulo: 'Nuevo Tema',
        icon: Icons.folder_rounded,
        color: _yellow,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _campo(nombreCtrl, 'Nombre del tema', Icons.title_rounded),
            const SizedBox(height: 10),
            _campo(descCtrl, 'Descripción', Icons.notes_rounded),
          ],
        ),
        onGuardar: () async {
          if (nombreCtrl.text.trim().length < 2) {
            throw Exception('El nombre debe tener al menos 2 caracteres');
          }
          await ApiService.crearTema(
            nombreCtrl.text.trim(),
            descCtrl.text.trim(),
            _nivelSel!.id,
            _temas.length + 1,
          );
        },
        onExito: () {
          _snack('Tema creado');
          _cargarTemasDelNivel(_nivelSel!.id);
        },
      ),
    );
  }

  Future<void> _dlgEditarTema(Map<String, dynamic> tema) async {
    final nombreCtrl =
        TextEditingController(text: tema['nombre'] as String? ?? '');
    final descCtrl =
        TextEditingController(text: tema['descripcion'] as String? ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => _AdminDialog(
        titulo: 'Editar Tema',
        icon: Icons.edit_rounded,
        color: _yellow,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _campo(nombreCtrl, 'Nombre del tema', Icons.title_rounded),
            const SizedBox(height: 10),
            _campo(descCtrl, 'Descripción', Icons.notes_rounded),
          ],
        ),
        onGuardar: () async {
          if (nombreCtrl.text.trim().length < 2) {
            throw Exception('El nombre debe tener al menos 2 caracteres');
          }
          await ApiService.actualizarTema(tema['_id'] as String, {
            'nombre': nombreCtrl.text.trim(),
            'descripcion': descCtrl.text.trim(),
          });
        },
        onExito: () {
          _snack('Tema actualizado');
          _cargarTemasDelNivel(_nivelSel!.id);
        },
      ),
    );
  }

  Future<void> _confirmarEliminarTema(Map<String, dynamic> tema) async {
    final nombre = tema['nombre'] as String? ?? 'este tema';
    final ok = await _dlgConfirmar(
      context,
      'Eliminar "$nombre"',
      '⚠️ Se borrará el tema COMPLETO: todas sus lecciones y ejercicios, '
      'junto con el progreso de los estudiantes en ellas. '
      'Esta acción no se puede deshacer.',
    );
    if (!ok || !mounted) return;
    try {
      final d = await ApiService.eliminarTema(tema['_id'] as String);
      _snack('Tema eliminado: ${d['lecciones_eliminadas'] ?? 0} lecciones, '
          '${d['ejercicios_eliminados'] ?? 0} ejercicios');
      _cargarTemasDelNivel(_nivelSel!.id);
    } catch (e) {
      _snack(_extractMsg(e), color: _red);
    }
  }

  // ── LECCION dialogs ───────────────────────────────────────────────────────

  Future<void> _dlgCrearLeccion() async {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final contenidoCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => _AdminDialog(
        titulo: 'Nueva Lección',
        icon: Icons.menu_book_rounded,
        color: _green,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _campo(nombreCtrl, 'Título', Icons.title_rounded),
            const SizedBox(height: 10),
            _campo(descCtrl, 'Descripción breve', Icons.notes_rounded),
            const SizedBox(height: 10),
            _campo(contenidoCtrl, 'Contenido', Icons.article_rounded,
                maxLines: 4),
          ],
        ),
        onGuardar: () async {
          if (nombreCtrl.text.trim().length < 3) {
            throw Exception('El título debe tener al menos 3 caracteres');
          }
          if (contenidoCtrl.text.trim().isEmpty) {
            throw Exception('El contenido no puede estar vacío');
          }
          await ApiService.crearLeccion(
            nombre: nombreCtrl.text.trim(),
            descripcion: descCtrl.text.trim(),
            contenido: contenidoCtrl.text.trim(),
            temaId: _temaSel!['_id'] as String,
          );
        },
        onExito: () {
          _snack('Lección creada');
          _cargarLeccionesDelTema(_temaSel!['_id'] as String);
        },
      ),
    );
  }

  Future<void> _dlgEditarLeccion(Map<String, dynamic> lec) async {
    final nombreCtrl =
        TextEditingController(text: lec['nombre'] as String? ?? '');
    final descCtrl =
        TextEditingController(text: lec['descripcion'] as String? ?? '');
    final contenidoCtrl =
        TextEditingController(text: lec['contenido'] as String? ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => _AdminDialog(
        titulo: 'Editar Lección',
        icon: Icons.edit_rounded,
        color: _green,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _campo(nombreCtrl, 'Título', Icons.title_rounded),
            const SizedBox(height: 10),
            _campo(descCtrl, 'Descripción breve', Icons.notes_rounded),
            const SizedBox(height: 10),
            _campo(contenidoCtrl, 'Contenido', Icons.article_rounded,
                maxLines: 4),
          ],
        ),
        onGuardar: () async {
          if (nombreCtrl.text.trim().length < 3) {
            throw Exception('El título debe tener al menos 3 caracteres');
          }
          await ApiService.actualizarLeccion(lec['_id'] as String, {
            'nombre': nombreCtrl.text.trim(),
            'descripcion': descCtrl.text.trim(),
            'contenido': contenidoCtrl.text.trim(),
          });
        },
        onExito: () {
          _snack('Lección actualizada');
          _cargarLeccionesDelTema(_temaSel!['_id'] as String);
        },
      ),
    );
  }

  Future<void> _confirmarEliminarLeccion(Map<String, dynamic> lec) async {
    final nombre = lec['nombre'] as String? ?? 'esta lección';
    final ok = await _dlgConfirmar(
      context,
      'Eliminar "$nombre"',
      '⚠️ Se borrará la lección con TODOS sus ejercicios, junto con el '
      'progreso de los estudiantes en ella. '
      'Esta acción no se puede deshacer.',
    );
    if (!ok || !mounted) return;
    try {
      final d = await ApiService.eliminarLeccion(lec['_id'] as String);
      _snack('Lección eliminada: '
          '${d['ejercicios_eliminados'] ?? 0} ejercicios');
      _cargarLeccionesDelTema(_temaSel!['_id'] as String);
    } catch (e) {
      _snack(_extractMsg(e), color: _red);
    }
  }

  // ── EJERCICIO dialogs ─────────────────────────────────────────────────────

  Future<void> _dlgCrearEjercicio() async {
    await showDialog(
      context: context,
      builder: (ctx) => _EjercicioFormDialog(
        leccionId: _leccionSel!['_id'] as String,
        onExito: () {
          _snack('Ejercicio creado');
          _cargarEjerciciosDeLeccion(_leccionSel!['_id'] as String);
        },
      ),
    );
  }

  Future<void> _dlgEditarEjercicio(Map<String, dynamic> ej) async {
    final preguntaCtrl =
        TextEditingController(text: ej['pregunta'] as String? ?? '');
    final explicCtrl =
        TextEditingController(text: ej['explicacion'] as String? ?? '');
    final puntosCtrl =
        TextEditingController(text: '${ej['puntos'] ?? 10}');
    final opciones = List<String>.from(ej['opciones'] as List? ?? []);
    while (opciones.length < 4) {
      opciones.add('');
    }
    final opCtrls =
        opciones.map((o) => TextEditingController(text: o)).toList();
    final respCorrecta =
        (ej['respuesta_correcta'] as String? ?? '').trim().toLowerCase();
    int respIdx =
        opciones.indexWhere((o) => o.trim().toLowerCase() == respCorrecta);
    if (respIdx < 0) respIdx = 0;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => _AdminDialog(
          titulo: 'Editar Ejercicio',
          icon: Icons.quiz_rounded,
          color: _purple,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campo(preguntaCtrl, 'Pregunta', Icons.quiz_rounded,
                  maxLines: 2),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Opciones:',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _dark,
                        fontSize: 13)),
              ),
              const SizedBox(height: 6),
              for (int i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setS(() => respIdx = i),
                        child: Icon(
                          respIdx == i
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: respIdx == i ? _green : _muted,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: opCtrls[i],
                          decoration: InputDecoration(
                            labelText: 'Opción ${['A', 'B', 'C', 'D'][i]}',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: respIdx == i
                                ? _green.withValues(alpha: 0.08)
                                : const Color(0xFFF5F4FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              _campo(explicCtrl, 'Explicación', Icons.lightbulb_rounded,
                  maxLines: 2),
              const SizedBox(height: 10),
              _campo(puntosCtrl, 'Puntos', Icons.star_rounded,
                  keyboardType: TextInputType.number),
            ],
          ),
          onGuardar: () async {
            final ops = opCtrls.map((c) => c.text.trim()).toList();
            if (preguntaCtrl.text.trim().length < 5) {
              throw Exception(
                  'La pregunta debe tener al menos 5 caracteres');
            }
            await ApiService.actualizarEjercicio(ej['_id'] as String, {
              'pregunta': preguntaCtrl.text.trim(),
              'opciones': ops,
              'respuesta_correcta':
                  ops.length > respIdx ? ops[respIdx] : ops.first,
              'explicacion': explicCtrl.text.trim(),
              'puntos': int.tryParse(puntosCtrl.text) ?? 10,
            });
          },
          onExito: () {
            _snack('Ejercicio actualizado');
            _cargarEjerciciosDeLeccion(_leccionSel!['_id'] as String);
          },
        ),
      ),
    );
  }

  Future<void> _confirmarEliminarEjercicio(Map<String, dynamic> ej) async {
    final pregunta = ej['pregunta'] as String? ?? 'este ejercicio';
    final ok = await _dlgConfirmar(
      context,
      'Eliminar ejercicio',
      '¿Eliminar "${pregunta.length > 60 ? '${pregunta.substring(0, 60)}…' : pregunta}"? Esta acción no se puede deshacer.',
    );
    if (!ok || !mounted) return;
    try {
      await ApiService.eliminarEjercicio(ej['_id'] as String);
      _snack('Ejercicio eliminado');
      _cargarEjerciciosDeLeccion(_leccionSel!['_id'] as String);
    } catch (e) {
      _snack(_extractMsg(e), color: _red);
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: _buildFab(),
      body: Column(
        children: [
          _Breadcrumb(
            view: _view,
            nivelNombre: _nivelSel?.nombre,
            temaNombre: _temaSel?['nombre'] as String?,
            leccionNombre: _leccionSel?['nombre'] as String?,
            onBack: _view > 0 ? _back : null,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget? _buildFab() {
    switch (_view) {
      case 0:
        return FloatingActionButton.extended(
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          onPressed: _dlgCrearNivel,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nivel',
              style: TextStyle(fontWeight: FontWeight.bold)),
        );
      case 1:
        return FloatingActionButton.extended(
          backgroundColor: _yellow,
          foregroundColor: _dark,
          onPressed: _dlgCrearTema,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tema',
              style: TextStyle(fontWeight: FontWeight.bold)),
        );
      case 2:
        return FloatingActionButton.extended(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          onPressed: _dlgCrearLeccion,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Lección',
              style: TextStyle(fontWeight: FontWeight.bold)),
        );
      case 3:
        return FloatingActionButton.extended(
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          onPressed: _dlgCrearEjercicio,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Pregunta',
              style: TextStyle(fontWeight: FontWeight.bold)),
        );
      default:
        return null;
    }
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _purple));
    }
    if (_error != null) {
      return _ErrorView(onRetry: _recargarVista, msg: _error);
    }
    switch (_view) {
      case 0:
        return _buildNiveles();
      case 1:
        return _buildTemas();
      case 2:
        return _buildLecciones();
      case 3:
        return _buildEjercicios();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNiveles() {
    if (_niveles.isEmpty) {
      return const _EmptyView(emoji: '📚', msg: 'Sin niveles. Crea el primero.');
    }
    return RefreshIndicator(
      color: _purple,
      onRefresh: _cargarNiveles,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _niveles.length,
        itemBuilder: (_, i) {
          final nv = _niveles[i];
          final emojis = ['🌱', '🔥', '⚡', '🚀', '💎', '🌟', '🏆'];
          final emoji = emojis[nv.orden % emojis.length];
          return _NivelCard(
            nivel: nv,
            emoji: emoji,
            onTap: () => setState(() => _drillNivel(nv)),
            onEdit: () => _dlgEditarNivel(nv),
            onDelete: () => _confirmarEliminarNivel(nv),
          );
        },
      ),
    );
  }

  Widget _buildTemas() {
    if (_temas.isEmpty) {
      return const _EmptyView(
          emoji: '📁', msg: 'Sin temas. Crea el primero.');
    }
    return RefreshIndicator(
      color: _purple,
      onRefresh: () => _cargarTemasDelNivel(_nivelSel!.id),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _temas.length,
        itemBuilder: (_, i) {
          final tema = _temas[i];
          final emojis = ['📂', '📋', '📌', '🗂️', '📄'];
          final emoji = emojis[i % emojis.length];
          return _TemaCard(
            tema: tema,
            emoji: emoji,
            onTap: () => setState(() => _drillTema(tema)),
            onEdit: () => _dlgEditarTema(tema),
            onDelete: () => _confirmarEliminarTema(tema),
          );
        },
      ),
    );
  }

  Widget _buildLecciones() {
    if (_lecciones.isEmpty) {
      return const _EmptyView(
          emoji: '📖', msg: 'Sin lecciones. Crea la primera.');
    }
    return RefreshIndicator(
      color: _purple,
      onRefresh: () =>
          _cargarLeccionesDelTema(_temaSel!['_id'] as String),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _lecciones.length,
        itemBuilder: (_, i) {
          final lec = _lecciones[i];
          return _LeccionCard(
            leccion: lec,
            onTap: () => setState(() => _drillLeccion(lec)),
            onEdit: () => _dlgEditarLeccion(lec),
            onDelete: () => _confirmarEliminarLeccion(lec),
          );
        },
      ),
    );
  }

  Widget _buildEjercicios() {
    if (_ejercicios.isEmpty) {
      return const _EmptyView(
          emoji: '❓', msg: 'Sin preguntas. Crea la primera.');
    }
    return RefreshIndicator(
      color: _purple,
      onRefresh: () =>
          _cargarEjerciciosDeLeccion(_leccionSel!['_id'] as String),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _ejercicios.length,
        itemBuilder: (_, i) {
          final ej = _ejercicios[i];
          return _EjercicioCard(
            ej: ej,
            onEdit: () => _dlgEditarEjercicio(ej),
            onDelete: () => _confirmarEliminarEjercicio(ej),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BREADCRUMB
// ─────────────────────────────────────────────────────────────────────────────

class _Breadcrumb extends StatelessWidget {
  final int view;
  final String? nivelNombre;
  final String? temaNombre;
  final String? leccionNombre;
  final VoidCallback? onBack;

  const _Breadcrumb({
    required this.view,
    required this.nivelNombre,
    required this.temaNombre,
    required this.leccionNombre,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          if (onBack != null)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: _purple, size: 16),
              ),
            ),
          if (onBack != null) const SizedBox(width: 8),
          Expanded(child: _buildCrumbs()),
        ],
      ),
    );
  }

  Widget _buildCrumbs() {
    final List<String> parts = ['Niveles'];
    if (view >= 1 && nivelNombre != null) parts.add(nivelNombre!);
    if (view >= 2 && temaNombre != null) parts.add(temaNombre!);
    if (view >= 3 && leccionNombre != null) parts.add(leccionNombre!);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < parts.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right_rounded,
                    color: _muted, size: 16),
              ),
            Text(
              parts[i],
              style: TextStyle(
                fontSize: 13,
                fontWeight: i == parts.length - 1
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: i == parts.length - 1 ? _dark : _muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTENT CARDS
// ─────────────────────────────────────────────────────────────────────────────

class _NivelCard extends StatelessWidget {
  final Nivel nivel;
  final String emoji;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NivelCard({
    required this.nivel,
    required this.emoji,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.09),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nivel.nombre,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _dark)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _purple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${nivel.temas.length} tema${nivel.temas.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                                fontSize: 11, color: _purple),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('principiante',
                              style: TextStyle(
                                  fontSize: 11, color: _green)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _IconActionBtn(
                  icon: Icons.edit_rounded,
                  color: _muted,
                  tooltip: 'Editar',
                  onTap: onEdit),
              _IconActionBtn(
                  icon: Icons.delete_rounded,
                  color: _red,
                  tooltip: 'Eliminar',
                  onTap: onDelete),
              const Icon(Icons.chevron_right_rounded, color: _muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemaCard extends StatelessWidget {
  final Map<String, dynamic> tema;
  final String emoji;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemaCard({
    required this.tema,
    required this.emoji,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = tema['nombre'] as String? ?? '';
    final desc = tema['descripcion'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _yellow.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _yellow.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _dark)),
                    if (desc.isNotEmpty)
                      Text(
                        desc.length > 60
                            ? '${desc.substring(0, 60)}…'
                            : desc,
                        style:
                            const TextStyle(color: _muted, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              _IconActionBtn(
                  icon: Icons.edit_rounded,
                  color: _muted,
                  tooltip: 'Editar',
                  onTap: onEdit),
              _IconActionBtn(
                  icon: Icons.delete_rounded,
                  color: _red,
                  tooltip: 'Eliminar',
                  onTap: onDelete),
              const Icon(Icons.chevron_right_rounded, color: _muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeccionCard extends StatelessWidget {
  final Map<String, dynamic> leccion;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LeccionCard({
    required this.leccion,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = leccion['nombre'] as String? ?? '';
    final contenido = leccion['contenido'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                    child: Text('📖', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _dark)),
                    if (contenido.isNotEmpty)
                      Text(
                        contenido.length > 70
                            ? '${contenido.substring(0, 70)}…'
                            : contenido,
                        style:
                            const TextStyle(color: _muted, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              _IconActionBtn(
                  icon: Icons.edit_rounded,
                  color: _muted,
                  tooltip: 'Editar',
                  onTap: onEdit),
              _IconActionBtn(
                  icon: Icons.delete_rounded,
                  color: _red,
                  tooltip: 'Eliminar',
                  onTap: onDelete),
              const Icon(Icons.chevron_right_rounded, color: _muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _EjercicioCard extends StatelessWidget {
  final Map<String, dynamic> ej;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EjercicioCard({
    required this.ej,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final pregunta = ej['pregunta'] as String? ?? '';
    final puntos = ej['puntos'] as int? ?? 10;
    final opciones = List<String>.from(ej['opciones'] as List? ?? []);
    final respCorrecta =
        (ej['respuesta_correcta'] as String? ?? '').trim().toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('❓', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pregunta,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _dark,
                        height: 1.4),
                  ),
                ),
                _IconActionBtn(
                    icon: Icons.edit_rounded,
                    color: _muted,
                    tooltip: 'Editar',
                    onTap: onEdit),
                _IconActionBtn(
                    icon: Icons.delete_rounded,
                    color: _red,
                    tooltip: 'Eliminar',
                    onTap: onDelete),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (int i = 0; i < opciones.length && i < 4; i++)
                  _OpcionChip(
                    letra: ['A', 'B', 'C', 'D'][i],
                    texto: opciones[i],
                    isCorrect: opciones[i].trim().toLowerCase() ==
                        respCorrecta,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 14, color: _yellow),
                const SizedBox(width: 3),
                Text('$puntos pts',
                    style:
                        const TextStyle(color: _muted, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionChip extends StatelessWidget {
  final String letra;
  final String texto;
  final bool isCorrect;

  const _OpcionChip({
    required this.letra,
    required this.texto,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCorrect
            ? _green.withValues(alpha: 0.12)
            : const Color(0xFFF5F4FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCorrect
              ? _green.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$letra. ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isCorrect ? _green : _muted,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                color: isCorrect ? _green : _dark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isCorrect) ...[
            const SizedBox(width: 4),
            const Icon(Icons.check_circle_rounded,
                size: 12, color: _green),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EJERCICIO FORM DIALOG (create)
// ─────────────────────────────────────────────────────────────────────────────

class _EjercicioFormDialog extends StatefulWidget {
  final String leccionId;
  final VoidCallback onExito;

  const _EjercicioFormDialog({
    required this.leccionId,
    required this.onExito,
  });

  @override
  State<_EjercicioFormDialog> createState() => _EjercicioFormDialogState();
}

class _EjercicioFormDialogState extends State<_EjercicioFormDialog> {
  final _preguntaCtrl = TextEditingController();
  final _opCtrls = List.generate(4, (_) => TextEditingController());
  final _explicCtrl = TextEditingController();
  final _puntosCtrl = TextEditingController(text: '10');
  int _respIdx = 0;
  bool _saving = false;

  @override
  void dispose() {
    _preguntaCtrl.dispose();
    for (final c in _opCtrls) {
      c.dispose();
    }
    _explicCtrl.dispose();
    _puntosCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {Color color = _green}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _guardar() async {
    final pregunta = _preguntaCtrl.text.trim();
    final opciones = _opCtrls.map((c) => c.text.trim()).toList();
    if (pregunta.length < 5) {
      _snack('La pregunta debe tener al menos 5 caracteres', color: _red);
      return;
    }
    if (opciones.any((o) => o.isEmpty)) {
      _snack('Completa todas las opciones', color: _red);
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService.crearEjercicio(
        pregunta: pregunta,
        tipo: 'seleccion_unica',
        opciones: opciones,
        respuestaCorrecta: opciones[_respIdx],
        explicacion: _explicCtrl.text.trim(),
        puntos: int.tryParse(_puntosCtrl.text) ?? 10,
        leccionId: widget.leccionId,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onExito();
    } catch (e) {
      if (!mounted) return;
      _snack(_extractMsg(e), color: _red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child:
                const Icon(Icons.quiz_rounded, color: _purple, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Nueva Pregunta',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _dark)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _campo(_preguntaCtrl, 'Pregunta', Icons.quiz_rounded,
                maxLines: 2),
            const SizedBox(height: 12),
            const Text(
                'Opciones (toca el círculo para marcar la correcta):',
                style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            for (int i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _respIdx = i),
                      child: Icon(
                        _respIdx == i
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _respIdx == i ? _green : _muted,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _opCtrls[i],
                        decoration: InputDecoration(
                          labelText:
                              'Opción ${['A', 'B', 'C', 'D'][i]}',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: _respIdx == i
                              ? _green.withValues(alpha: 0.08)
                              : const Color(0xFFF5F4FF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _campo(_explicCtrl, 'Explicación', Icons.lightbulb_rounded,
                maxLines: 2),
            const SizedBox(height: 10),
            _campo(_puntosCtrl, 'Puntos', Icons.star_rounded,
                keyboardType: TextInputType.number),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: _muted)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          onPressed: _saving ? null : _guardar,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.publish_rounded, size: 18),
          label: const Text('Publicar'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE DIALOG WRAPPER
// ─────────────────────────────────────────────────────────────────────────────

class _AdminDialog extends StatefulWidget {
  final String titulo;
  final IconData icon;
  final Color color;
  final Widget content;
  final Future<void> Function() onGuardar;
  final VoidCallback onExito;

  const _AdminDialog({
    required this.titulo,
    required this.icon,
    required this.color,
    required this.content,
    required this.onGuardar,
    required this.onExito,
  });

  @override
  State<_AdminDialog> createState() => _AdminDialogState();
}

class _AdminDialogState extends State<_AdminDialog> {
  bool _saving = false;

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    try {
      await widget.onGuardar();
      if (!mounted) return;
      Navigator.pop(context);
      widget.onExito();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_extractMsg(e),
            style: const TextStyle(color: Colors.white)),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(widget.icon, color: widget.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(widget.titulo,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _dark)),
          ),
        ],
      ),
      content: SingleChildScrollView(child: widget.content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: _muted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          onPressed: _saving ? null : _handleSave,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Guardar',
                  style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _IconActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconActionBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final String? msg;

  const _ErrorView({required this.onRetry, this.msg});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😵', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(msg ?? 'Error al cargar datos',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String emoji;
  final String msg;

  const _EmptyView({required this.emoji, required this.msg});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: _muted, fontSize: 15)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

Future<bool> _dlgConfirmar(
    BuildContext context, String titulo, String cuerpo) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(titulo,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: _dark)),
      content: Text(cuerpo,
          style: const TextStyle(color: _muted, fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar', style: TextStyle(color: _muted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  return result ?? false;
}

Widget _dropdownField<T>({
  required String label,
  required IconData icon,
  required T value,
  required List<(T, String)> items,
  required ValueChanged<T?> onChanged,
}) {
  return InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _purple),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400)),
      filled: true,
      fillColor: const Color(0xFFF5F4FF),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        items: items
            .map((item) => DropdownMenuItem<T>(
                  value: item.$1,
                  child: Text(item.$2),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    ),
  );
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
      prefixIcon: Icon(icon, color: _purple),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _purple, width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFF5F4FF),
    ),
  );
}
