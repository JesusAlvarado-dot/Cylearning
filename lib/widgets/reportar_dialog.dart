import 'package:flutter/material.dart';
import '../services/api_service.dart';

const _kBg = Color(0xFFFFF9F2);
const _kDark = Color(0xFF1C1140);
const _kMuted = Color(0xFF8E8EA9);
const _kRed = Color(0xFFEF4444);

const _tipoInfo = {
  'usuario_foto': ('📷', 'Foto de perfil'),
  'usuario_nombre': ('✏️', 'Nombre de usuario'),
  'ejercicio': ('📝', 'Ejercicio'),
};

const _tipoDescripcion = {
  'usuario_foto': 'Cuéntanos por qué esta foto de perfil te parece inapropiada.',
  'usuario_nombre': 'Cuéntanos por qué este nombre de usuario te parece inapropiado.',
  'ejercicio': 'Cuéntanos qué tiene de problemático este ejercicio.',
};

// Abre un diálogo para reportar contenido. `tipos` define qué se puede
// reportar: si trae más de una opción (p. ej. foto y nombre de un usuario)
// se muestra un selector; si trae una sola, va directo al motivo. Muestra
// un snackbar de éxito/error al terminar. `tituloEntidad` es opcional, solo
// para dar contexto (p. ej. el nombre del usuario o la pregunta reportada).
Future<void> mostrarReportarDialog(
  BuildContext context, {
  required List<String> tipos,
  required String entidadId,
  String? tituloEntidad,
}) async {
  assert(tipos.isNotEmpty);
  String tipoSeleccionado = tipos.first;
  final motivoCtrl = TextEditingController();
  String error = '';
  bool enviando = false;

  final enviado = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Dialog(
        backgroundColor: _kBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(children: [
                Text('🚩', style: TextStyle(fontSize: 24)),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Reportar contenido',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _kDark)),
                ),
              ]),
              if (tituloEntidad != null && tituloEntidad.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(tituloEntidad,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        color: _kMuted,
                        fontWeight: FontWeight.w600)),
              ],
              if (tipos.length > 1) ...[
                const SizedBox(height: 14),
                const Text('¿Qué quieres reportar?',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: _kDark)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: tipos.map((t) {
                    final info = _tipoInfo[t] ?? ('🚩', t);
                    final activo = t == tipoSeleccionado;
                    return GestureDetector(
                      onTap: () => setS(() => tipoSeleccionado = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: activo ? _kRed.withValues(alpha: 0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: activo ? _kRed : const Color(0xFFE5E7EB),
                              width: 1.5),
                        ),
                        child: Text('${info.$1} ${info.$2}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: activo ? _kRed : _kMuted)),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                _tipoDescripcion[tipoSeleccionado] ?? 'Cuéntanos qué está mal.',
                style: const TextStyle(fontSize: 13, color: _kMuted, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: motivoCtrl,
                maxLines: 4,
                maxLength: 500,
                style: const TextStyle(fontSize: 14, color: _kDark),
                decoration: InputDecoration(
                  hintText: 'Escribe el motivo del reporte...',
                  hintStyle: const TextStyle(color: _kMuted, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(error,
                    style: const TextStyle(
                        color: _kRed, fontSize: 12, fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 18),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(false),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFE5E7EB), width: 1.5),
                      ),
                      child: const Center(
                          child: Text('Cancelar',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, color: _kMuted))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: enviando
                        ? null
                        : () async {
                            final motivo = motivoCtrl.text.trim();
                            if (motivo.length < 5) {
                              setS(() => error =
                                  'Cuéntanos un poco más (mínimo 5 caracteres)');
                              return;
                            }
                            setS(() {
                              error = '';
                              enviando = true;
                            });
                            try {
                              await ApiService.crearReporte(
                                tipo: tipoSeleccionado,
                                entidadId: entidadId,
                                motivo: motivo,
                              );
                              if (ctx.mounted) Navigator.of(ctx).pop(true);
                            } catch (e) {
                              setS(() {
                                enviando = false;
                                error = e.toString().replaceFirst('Exception: ', '');
                              });
                            }
                          },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _kRed.withValues(alpha: enviando ? 0.6 : 1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: enviando
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Reportar 🚩',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    ),
  );

  if (enviado == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('🚩 Reporte enviado. Te avisaremos qué decidimos.'),
      backgroundColor: Color(0xFF059669),
    ));
  }
}
