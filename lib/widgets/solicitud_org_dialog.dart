import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

const _kBg    = Color(0xFFFFF9F2);
const _kDark  = Color(0xFF1C1140);
const _kMuted = Color(0xFF8E8EA9);
const _kPurple = Color(0xFF6B46F6);

/// Formulario "¿Eres una organización? Comunícate con nosotros" del login.
/// Envía una solicitud que el admin revisa desde su panel.
Future<void> mostrarSolicitudOrganizacion(BuildContext context) async {
  final nombreCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final mensajeCtrl = TextEditingController();
  String sector = 'escuela';
  bool enviando = false;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        backgroundColor: _kBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🏫 ¿Eres una organización?',
            style: TextStyle(
                fontWeight: FontWeight.w900, color: _kDark, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cuéntanos de tu escuela, colegio, universidad o empresa y '
                'te contactaremos por correo para darte acceso.',
                style: TextStyle(fontSize: 13, color: _kMuted, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nombreCtrl,
                decoration: _deco('Nombre de la organización', '🏢'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _deco('Correo de contacto', '📧'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: sector,
                decoration: _deco('Sector', '🎯'),
                items: [
                  for (final e in sectoresDisponibles.entries)
                    DropdownMenuItem(
                      value: e.key,
                      child: Text('${e.value.$1} ${e.value.$2}',
                          style: const TextStyle(fontSize: 14)),
                    ),
                ],
                onChanged: (v) => setLocal(() => sector = v ?? 'escuela'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: mensajeCtrl,
                maxLines: 3,
                maxLength: 1000,
                decoration: _deco('Cuéntanos qué necesitas (opcional)', '💬'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: enviando ? null : () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: _kMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kPurple),
            onPressed: enviando
                ? null
                : () async {
                    if (nombreCtrl.text.trim().length < 3 ||
                        !emailCtrl.text.contains('@')) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text(
                              'Escribe el nombre de la organización y un correo válido')));
                      return;
                    }
                    setLocal(() => enviando = true);
                    try {
                      final msg = await ApiService.enviarSolicitudOrganizacion(
                        nombreOrganizacion: nombreCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        sector: sector,
                        mensaje: mensajeCtrl.text.trim(),
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('✅ $msg'),
                        backgroundColor: const Color(0xFF059669),
                      ));
                    } catch (e) {
                      setLocal(() => enviando = false);
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                        content: Text(
                            e.toString().replaceFirst('Exception: ', '')),
                        backgroundColor: const Color(0xFFEF4444),
                      ));
                    }
                  },
            child: enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Enviar solicitud 🚀'),
          ),
        ],
      ),
    ),
  );
}

InputDecoration _deco(String label, String emoji) => InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(
          color: _kMuted, fontWeight: FontWeight.w500, fontSize: 13),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: Text(emoji, style: const TextStyle(fontSize: 18)),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kPurple, width: 2),
      ),
    );
