part of 'admin_screen.dart';

// Abre la galería y devuelve la imagen elegida como data URI base64
// comprimido (para logos de organización). null = canceló.
Future<String?> _elegirLogo() async {
  final archivo = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 400,
    maxHeight: 400,
    imageQuality: 70,
  );
  if (archivo == null) return null;
  final bytes = await archivo.readAsBytes();
  if (bytes.lengthInBytes > 300 * 1024) {
    throw Exception('La imagen es demasiado grande. Elige otra.');
  }
  return 'data:image/jpeg;base64,${base64Encode(bytes)}';
}

// Abre la hoja de compartir del sistema con el link de invitación.
// Los links (URL web pública con /#/unirse?codigo=X) abren el registro con
// el código ya puesto: estudiantes entran como alumnos y el link docente
// registra al profesor como organizador de la misma organización. Al ser
// una URL normal, funciona en cualquier navegador/dispositivo, no solo
// para quien ya tenga la app Android instalada.
void _compartirInvitacion(Organizacion org, {required bool docente}) {
  final codigo = docente ? org.codigoDocente : org.codigo;
  final link = docente ? org.linkDocentes : org.linkEstudiantes;
  final texto = docente
      ? '🧑‍🏫 Te invito a ser profesor de "${org.nombre}" en CyLearn.\n\n'
          'Abre este link: $link\n\n'
          'O regístrate con el código docente: $codigo'
      : '🛡️ ¡Únete a "${org.nombre}" en CyLearn y aprende ciberseguridad '
          'jugando!\n\n'
          'Abre este link: $link\n\n'
          'O regístrate con el código: $codigo';
  SharePlus.instance.share(ShareParams(text: texto));
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 (admin): ORGANIZACIONES
// ─────────────────────────────────────────────────────────────────────────────

class _OrganizacionesTab extends StatefulWidget {
  const _OrganizacionesTab();
  @override
  State<_OrganizacionesTab> createState() => _OrganizacionesTabState();
}

class _OrganizacionesTabState extends State<_OrganizacionesTab> {
  List<Organizacion> _orgs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _snack(String msg, {Color color = _green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orgs = await ApiService.getOrganizaciones();
      if (!mounted) return;
      setState(() {
        _orgs = orgs;
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

  Future<void> _dlgCrear() async {
    final nombreCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String sector = 'escuela';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: _bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Nueva organización',
              style: TextStyle(fontWeight: FontWeight.w900, color: _dark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campo(nombreCtrl, 'Nombre', Icons.business_rounded),
              const SizedBox(height: 10),
              _campo(emailCtrl, 'Correo de contacto', Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _selectorSector(sector, (v) => setLocal(() => sector = v)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child:
                    const Text('Cancelar', style: TextStyle(color: _muted))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _purple),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final org = await ApiService.crearOrganizacion(
          nombreCtrl.text.trim(), sector, emailCtrl.text.trim());
      _snack('Organización creada. Código: ${org.codigo}');
      _cargar();
    } catch (e) {
      _snack(_extractMsg(e), color: _red);
    }
  }

  Future<void> _dlgEditar(Organizacion org) async {
    final nombreCtrl = TextEditingController(text: org.nombre);
    final emailCtrl = TextEditingController(text: org.email);
    String sector = org.sector;
    bool activo = org.activo;
    bool mascotas = org.mostrarMensajesMascota;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: _bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Editar organización',
              style: TextStyle(fontWeight: FontWeight.w900, color: _dark)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campo(nombreCtrl, 'Nombre', Icons.business_rounded),
                const SizedBox(height: 10),
                _campo(emailCtrl, 'Correo de contacto', Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 10),
                _selectorSector(sector, (v) => setLocal(() => sector = v)),
                SwitchListTile(
                  value: activo,
                  activeThumbColor: _green,
                  title: const Text('Activa',
                      style: TextStyle(fontSize: 14, color: _dark)),
                  onChanged: (v) => setLocal(() => activo = v),
                ),
                SwitchListTile(
                  value: mascotas,
                  activeThumbColor: _green,
                  title: const Text('Mensajes de los personajes',
                      style: TextStyle(fontSize: 14, color: _dark)),
                  subtitle: const Text('Burbujas motivacionales en el caminito',
                      style: TextStyle(fontSize: 11, color: _muted)),
                  onChanged: (v) => setLocal(() => mascotas = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child:
                    const Text('Cancelar', style: TextStyle(color: _muted))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _purple),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.actualizarOrganizacion(org.id, {
        'nombre': nombreCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'sector': sector,
        'activo': activo,
        'mostrar_mensajes_mascota': mascotas,
      });
      _snack('Organización actualizada');
      _cargar();
    } catch (e) {
      _snack(_extractMsg(e), color: _red);
    }
  }

  Future<void> _regenerarCodigo(Organizacion org) async {
    try {
      final actualizada = await ApiService.regenerarCodigoOrganizacion(org.id);
      _snack('Nuevo código: ${actualizada.codigo}');
      _cargar();
    } catch (e) {
      _snack(_extractMsg(e), color: _red);
    }
  }

  Future<void> _cambiarLogoOrg(Organizacion org) async {
    try {
      final foto = await _elegirLogo();
      if (foto == null) return;
      await ApiService.actualizarOrganizacion(org.id, {'foto': foto});
      _snack('Logo actualizado');
      _cargar();
    } catch (e) {
      _snack(_extractMsg(e), color: _red);
    }
  }

  Future<void> _eliminar(Organizacion org) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar organización?',
            style: TextStyle(fontWeight: FontWeight.w900, color: _dark)),
        content: Text(
          'Se desvincularán sus ${org.totalUsuarios} usuarios (podrán seguir '
          'usando la app con el contenido público) y sus ${org.totalNiveles} '
          'niveles quedarán desactivados.',
          style: const TextStyle(fontSize: 13, color: _muted, height: 1.4),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: _muted))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.eliminarOrganizacion(org.id);
      _snack('Organización eliminada');
      _cargar();
    } catch (e) {
      _snack(_extractMsg(e), color: _red);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _purple));
    }
    if (_error != null) {
      return _ErrorView(onRetry: _cargar, msg: _error);
    }
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        onPressed: _dlgCrear,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Organización',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _orgs.isEmpty
          ? const _EmptyView(
              emoji: '🏫', msg: 'Sin organizaciones. Crea la primera.')
          : RefreshIndicator(
              color: _purple,
              onRefresh: _cargar,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: _orgs.length,
                itemBuilder: (_, i) => _tarjetaOrg(_orgs[i]),
              ),
            ),
    );
  }

  Widget _tarjetaOrg(Organizacion org) {
    final sectorInfo = sectoresDisponibles[org.sector] ?? ('🏫', org.sector);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: org.activo
                ? const Color(0xFFEDE9FE)
                : const Color(0xFFFECACA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                org.foto.isNotEmpty
                    ? Avatar(
                        foto: org.foto,
                        nombre: org.nombre,
                        radio: 18,
                        color: _purple)
                    : Text(sectorInfo.$1, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(org.nombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: _dark)),
                      Text(
                          '${sectorInfo.$2} · ${org.email}'
                          '${org.activo ? '' : ' · INACTIVA'}',
                          style:
                              const TextStyle(fontSize: 11, color: _muted)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: _muted),
                  onSelected: (v) {
                    if (v == 'editar') _dlgEditar(org);
                    if (v == 'logo') _cambiarLogoOrg(org);
                    if (v == 'inv_est') {
                      _compartirInvitacion(org, docente: false);
                    }
                    if (v == 'inv_doc') {
                      _compartirInvitacion(org, docente: true);
                    }
                    if (v == 'codigo') _regenerarCodigo(org);
                    if (v == 'eliminar') _eliminar(org);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'editar', child: Text('✏️ Editar')),
                    PopupMenuItem(value: 'logo', child: Text('🖼️ Cambiar logo')),
                    PopupMenuItem(
                        value: 'inv_est',
                        child: Text('📤 Invitar estudiantes')),
                    PopupMenuItem(
                        value: 'inv_doc',
                        child: Text('📤 Invitar profesores')),
                    PopupMenuItem(
                        value: 'codigo', child: Text('🔄 Regenerar código')),
                    PopupMenuItem(
                        value: 'eliminar', child: Text('🗑️ Eliminar')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _ChipDato('🔑 ${org.codigo}', const Color(0xFFEFEBFF)),
                const SizedBox(width: 8),
                _ChipDato('🧑‍🏫 ${org.codigoDocente}', const Color(0xFFE0F2FE)),
                const SizedBox(width: 8),
                _ChipDato('👤 ${org.totalUsuarios}', const Color(0xFFECFDF5)),
                const SizedBox(width: 8),
                _ChipDato('📚 ${org.totalNiveles}', const Color(0xFFFFF7ED)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Dropdown de sector reutilizado en crear/editar organización
Widget _selectorSector(String valor, ValueChanged<String> onChanged) {
  return DropdownButtonFormField<String>(
    initialValue: valor,
    decoration: InputDecoration(
      labelText: 'Sector',
      prefixIcon: const Icon(Icons.category_rounded, color: _purple),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: const Color(0xFFF5F4FF),
    ),
    items: [
      for (final e in sectoresDisponibles.entries)
        DropdownMenuItem(
            value: e.key, child: Text('${e.value.$1} ${e.value.$2}')),
    ],
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}

class _ChipDato extends StatelessWidget {
  final String texto;
  final Color color;
  const _ChipDato(this.texto, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(texto,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: _dark)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 4 (admin): SOLICITUDES DE ORGANIZACIONES
// ─────────────────────────────────────────────────────────────────────────────

class _SolicitudesTab extends StatefulWidget {
  const _SolicitudesTab();
  @override
  State<_SolicitudesTab> createState() => _SolicitudesTabState();
}

class _SolicitudesTabState extends State<_SolicitudesTab> {
  List<SolicitudOrganizacion> _solicitudes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _snack(String msg, {Color color = _green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final solicitudes = await ApiService.getSolicitudesOrganizacion();
      if (!mounted) return;
      setState(() {
        _solicitudes = solicitudes;
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

  Future<void> _responder(SolicitudOrganizacion s) async {
    // Muestra los datos y permite aceptar o rechazar. En ambos casos se le
    // envía el correo con el resultado desde la cuenta oficial de CyLearn.
    final decision = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.nombreOrganizacion,
            style: const TextStyle(fontWeight: FontWeight.w900, color: _dark)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText('📧 ${s.email}',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _purple)),
            const SizedBox(height: 6),
            Text('🎯 ${(sectoresDisponibles[s.sector] ?? ('', s.sector)).$2}',
                style: const TextStyle(fontSize: 13, color: _dark)),
            if (s.mensaje.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('💬 ${s.mensaje}',
                  style: const TextStyle(
                      fontSize: 13, color: _muted, height: 1.4)),
            ],
            const SizedBox(height: 12),
            const Text(
              'Al aceptar o rechazar se le envía automáticamente el correo '
              'con la decisión. Si la aceptas, créale también su organización '
              'en la pestaña 🏫 y compártele el código.',
              style: TextStyle(fontSize: 12, color: _muted, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar', style: TextStyle(color: _muted))),
          if (s.estado == 'pendiente') ...[
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _red),
              onPressed: () => Navigator.pop(ctx, 'rechazada'),
              child: const Text('Rechazar ✕'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _green),
              onPressed: () => Navigator.pop(ctx, 'aceptada'),
              child: const Text('Aceptar ✓'),
            ),
          ],
        ],
      ),
    );
    if (decision == null) return;
    try {
      final r = await ApiService.actualizarSolicitudOrganizacion(s.id, decision);
      final correoOk = r['correo_enviado'] == true;
      _snack(
        decision == 'aceptada'
            ? (correoOk
                ? '✅ Aceptada y correo enviado a ${s.email}'
                : '✅ Aceptada — ⚠️ correo NO enviado: ${r['correo_motivo'] ?? ''}')
            : (correoOk
                ? 'Rechazada y correo enviado a ${s.email}'
                : 'Rechazada — ⚠️ correo NO enviado: ${r['correo_motivo'] ?? ''}'),
        color: correoOk ? _green : const Color(0xFFF97316),
      );
      _cargar();
    } catch (e) {
      _snack(_extractMsg(e), color: _red);
    }
  }

  Future<void> _eliminar(SolicitudOrganizacion s) async {
    try {
      await ApiService.eliminarSolicitudOrganizacion(s.id);
      _snack('Solicitud eliminada');
      _cargar();
    } catch (e) {
      _snack(_extractMsg(e), color: _red);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _purple));
    }
    if (_error != null) {
      return _ErrorView(onRetry: _cargar, msg: _error);
    }
    if (_solicitudes.isEmpty) {
      return const _EmptyView(
          emoji: '📭', msg: 'No hay solicitudes de organizaciones');
    }
    return RefreshIndicator(
      color: _purple,
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _solicitudes.length,
        itemBuilder: (_, i) => _tarjetaSolicitud(_solicitudes[i]),
      ),
    );
  }

  Widget _tarjetaSolicitud(SolicitudOrganizacion s) {
    final pendiente = s.estado == 'pendiente';
    final rechazada = s.estado == 'rechazada';
    final sectorInfo = sectoresDisponibles[s.sector] ?? ('🏫', s.sector);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: pendiente
                ? const Color(0xFFFDE68A)
                : rechazada
                    ? const Color(0xFFFECACA)
                    : const Color(0xFFD1FAE5),
            width: 1.5),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Text(sectorInfo.$1, style: const TextStyle(fontSize: 26)),
        title: Text(s.nombreOrganizacion,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14, color: _dark)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${s.email}\n${sectorInfo.$2} · '
                '${s.fecha.day}/${s.fecha.month}/${s.fecha.year}',
                style: const TextStyle(fontSize: 11, color: _muted)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: pendiente
                    ? const Color(0xFFFEF3C7)
                    : rechazada
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                  pendiente
                      ? '⏳ Pendiente'
                      : rechazada
                          ? '❌ Rechazada'
                          : '✅ Aceptada',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: pendiente
                          ? const Color(0xFF92400E)
                          : rechazada
                              ? const Color(0xFF991B1B)
                              : const Color(0xFF065F46))),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: _muted),
          onSelected: (v) {
            if (v == 'responder') _responder(s);
            if (v == 'eliminar') _eliminar(s);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'responder', child: Text('📧 Ver y responder')),
            PopupMenuItem(value: 'eliminar', child: Text('🗑️ Eliminar')),
          ],
        ),
        onTap: () => _responder(s),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB (organizador): MI ORGANIZACIÓN
// ─────────────────────────────────────────────────────────────────────────────

class _MiOrganizacionTab extends StatefulWidget {
  const _MiOrganizacionTab();
  @override
  State<_MiOrganizacionTab> createState() => _MiOrganizacionTabState();
}

class _MiOrganizacionTabState extends State<_MiOrganizacionTab> {
  Organizacion? _org;
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
      final org = await ApiService.getMiOrganizacion();
      if (!mounted) return;
      setState(() {
        _org = org;
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

  Future<void> _toggleMascotas(bool valor) async {
    try {
      await ApiService.actualizarMiOrganizacion(mostrarMensajesMascota: valor);
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extractMsg(e)), backgroundColor: _red),
      );
    }
  }

  Future<void> _cambiarMiLogo() async {
    try {
      final foto = await _elegirLogo();
      if (foto == null) return;
      await ApiService.actualizarMiOrganizacion(foto: foto);
      _cargar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🖼️ Logo actualizado'),
        backgroundColor: _green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_extractMsg(e)), backgroundColor: _red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _purple));
    }
    if (_error != null || _org == null) {
      return _ErrorView(onRetry: _cargar, msg: _error);
    }
    final org = _org!;
    final sectorInfo = sectoresDisponibles[org.sector] ?? ('🏫', org.sector);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Logo de la organización (tócalo para cambiarlo)
              GestureDetector(
                onTap: _cambiarMiLogo,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    org.foto.isNotEmpty
                        ? Avatar(
                            foto: org.foto,
                            nombre: org.nombre,
                            radio: 40,
                            color: _purple)
                        : Text(sectorInfo.$1,
                            style: const TextStyle(fontSize: 52)),
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.photo_camera_rounded,
                          size: 14, color: _purple),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(org.nombre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _dark)),
              Text(sectorInfo.$2,
                  style: const TextStyle(fontSize: 13, color: _muted)),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEBFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _purple.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Text('Código para tus estudiantes',
                        style: TextStyle(fontSize: 11, color: _muted)),
                    SelectableText(org.codigo,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: _purple)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Compárteles este código: al registrarse con él, verán '
                'únicamente los niveles de tu organización',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: _muted),
              ),
              const SizedBox(height: 16),
              // Links de invitación: estudiantes y otros profesores
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _purple,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () =>
                          _compartirInvitacion(org, docente: false),
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text('Invitar\nestudiantes',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () =>
                          _compartirInvitacion(org, docente: true),
                      icon: const Icon(Icons.school_rounded, size: 16),
                      label: const Text('Invitar\nprofesores',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Código docente: ${org.codigoDocente} — quien se registre '
                'con él será organizador de tu organización, igual que tú',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SwitchListTile(
            value: org.mostrarMensajesMascota,
            activeThumbColor: _green,
            title: const Text('Mensajes de los personajes 🧑‍🚀',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
            subtitle: const Text(
              'Muestra u oculta las burbujas motivacionales de los '
              'muñequitos en el caminito de lecciones. El personaje y su '
              'mensaje se personalizan editando cada tema en 📚 Contenido.',
              style: TextStyle(fontSize: 11, color: _muted, height: 1.4),
            ),
            onChanged: _toggleMascotas,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB (admin): REPORTES
// ─────────────────────────────────────────────────────────────────────────────

bool _esReporteUsuario(String tipo) =>
    tipo == 'usuario_foto' || tipo == 'usuario_nombre';

class _ReportesTab extends StatefulWidget {
  const _ReportesTab();
  @override
  State<_ReportesTab> createState() => _ReportesTabState();
}

class _ReportesTabState extends State<_ReportesTab> {
  List<Reporte> _reportes = [];
  bool _loading = true;
  String? _error;
  // 'pendiente' (default) o null para ver todos
  String? _filtro = 'pendiente';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _snack(String msg, {Color color = _green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reportes = await ApiService.getReportesAdmin(estado: _filtro);
      if (!mounted) return;
      setState(() {
        _reportes = reportes;
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

  void _cambiarFiltro(String? filtro) {
    if (filtro == _filtro) return;
    setState(() => _filtro = filtro);
    _cargar();
  }

  Future<void> _revisar(Reporte r) async {
    final respuestaCtrl = TextEditingController();
    final decision = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          switch (r.tipo) {
            'usuario_foto' => '📷 Foto de perfil reportada',
            'usuario_nombre' => '✏️ Nombre de usuario reportado',
            _ => '📝 Ejercicio reportado',
          },
          style: const TextStyle(fontWeight: FontWeight.w900, color: _dark, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_esReporteUsuario(r.tipo)) ...[
                Row(children: [
                  Avatar(
                    foto: (r.entidad?['foto'] ?? '').toString(),
                    nombre: (r.entidad?['nombre'] ?? '?').toString(),
                    radio: 22,
                    color: _purple,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((r.entidad?['nombre'] ?? 'Usuario eliminado').toString(),
                            style: const TextStyle(fontWeight: FontWeight.w800, color: _dark)),
                        Text((r.entidad?['email'] ?? '').toString(),
                            style: const TextStyle(fontSize: 11, color: _muted)),
                      ],
                    ),
                  ),
                ]),
              ] else ...[
                Text((r.entidad?['pregunta'] ?? 'Ejercicio eliminado').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w800, color: _dark)),
              ],
              const SizedBox(height: 12),
              Text('Reportado por: ${r.reportadoPorNombre}',
                  style: const TextStyle(fontSize: 12, color: _muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('💬 ${r.motivo}',
                  style: const TextStyle(fontSize: 13, color: _dark, height: 1.4)),
              if (r.estado == 'pendiente') ...[
                const SizedBox(height: 16),
                const Text(
                  'Mensaje para quien reportó (opcional, si lo dejas vacío se usa uno por defecto):',
                  style: TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: respuestaCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13, color: _dark),
                  decoration: InputDecoration(
                    hintText: 'Recibimos tu reporte, consideramos que...',
                    hintStyle: const TextStyle(fontSize: 12, color: _muted),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  switch (r.tipo) {
                    'usuario_foto' => 'Si marcas Fundado, se borra la foto de perfil de este usuario.',
                    'usuario_nombre' => 'Si marcas Fundado, se cambia el nombre de este usuario a uno neutro.',
                    _ => 'Si marcas Fundado, el ejercicio se desactiva.',
                  },
                  style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Text('Respuesta enviada: ${r.respuestaAdmin}',
                    style: const TextStyle(fontSize: 12, color: _muted, fontStyle: FontStyle.italic)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar', style: TextStyle(color: _muted))),
          if (r.estado == 'pendiente') ...[
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _muted),
              onPressed: () => Navigator.pop(ctx, 'infundado|${respuestaCtrl.text}'),
              child: const Text('Infundado ✕'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _green),
              onPressed: () => Navigator.pop(ctx, 'fundado|${respuestaCtrl.text}'),
              child: const Text('Fundado ✓'),
            ),
          ],
        ],
      ),
    );
    if (decision == null) return;
    final partes = decision.split('|');
    final estado = partes.first;
    final respuesta = partes.length > 1 ? partes.sublist(1).join('|') : '';
    try {
      await ApiService.resolverReporte(r.id, estado: estado, respuestaAdmin: respuesta);
      _snack(estado == 'fundado'
          ? '✅ Marcado como fundado — se notificó a quien reportó'
          : 'Marcado como no fundado — se notificó a quien reportó');
      _cargar();
    } catch (e) {
      _snack(_extractMsg(e), color: _red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            _chipFiltro('Pendientes', 'pendiente'),
            const SizedBox(width: 8),
            _chipFiltro('Todos', null),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _purple))
              : _error != null
                  ? _ErrorView(onRetry: _cargar, msg: _error)
                  : _reportes.isEmpty
                      ? const _EmptyView(emoji: '✅', msg: 'No hay reportes por revisar')
                      : RefreshIndicator(
                          color: _purple,
                          onRefresh: _cargar,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _reportes.length,
                            itemBuilder: (_, i) => _tarjetaReporte(_reportes[i]),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _chipFiltro(String label, String? valor) {
    final activo = _filtro == valor;
    return GestureDetector(
      onTap: () => _cambiarFiltro(valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: activo ? _purple : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activo ? _purple : const Color(0xFFE5E7EB)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: activo ? Colors.white : _muted)),
      ),
    );
  }

  Widget _tarjetaReporte(Reporte r) {
    final pendiente = r.estado == 'pendiente';
    final fundado = r.estado == 'fundado';
    final color = pendiente
        ? _yellow
        : (fundado ? _green : _muted);
    final titulo = _esReporteUsuario(r.tipo)
        ? (r.entidad?['nombre'] ?? 'Usuario eliminado').toString()
        : (r.entidad?['pregunta'] ?? 'Ejercicio eliminado').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Text(
            switch (r.tipo) {
              'usuario_foto' => '📷',
              'usuario_nombre' => '✏️',
              _ => '📝',
            },
            style: const TextStyle(fontSize: 24)),
        title: Text(titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _dark)),
        subtitle: Text(
          'Por ${r.reportadoPorNombre} · ${r.fecha.day}/${r.fecha.month}/${r.fecha.year}\n💬 ${r.motivo}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: _muted),
        ),
        isThreeLine: true,
        trailing: pendiente
            ? const Icon(Icons.chevron_right_rounded, color: _muted)
            : Icon(fundado ? Icons.check_circle : Icons.remove_circle_outline,
                color: fundado ? _green : _muted, size: 20),
        onTap: () => _revisar(r),
      ),
    );
  }
}
