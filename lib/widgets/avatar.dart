import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Avatar circular reutilizable: muestra la foto de perfil si existe
/// (data URI base64 subida desde la app, o URL https de Google/Facebook)
/// y si no, la inicial del nombre sobre un fondo de color.
class Avatar extends StatelessWidget {
  final String foto;
  final String nombre;
  final double radio;
  final Color color;
  final Color? fondo;
  final double? bordeAncho;

  const Avatar({
    super.key,
    required this.foto,
    required this.nombre,
    this.radio = 22,
    this.color = const Color(0xFF6B46F6),
    this.fondo,
    this.bordeAncho,
  });

  static Uint8List? _bytesDeDataUri(String dataUri) {
    try {
      final coma = dataUri.indexOf(',');
      if (coma == -1) return null;
      return base64Decode(dataUri.substring(coma + 1));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imagen;
    if (foto.startsWith('data:image/')) {
      final bytes = _bytesDeDataUri(foto);
      if (bytes != null) imagen = MemoryImage(bytes);
    } else if (foto.startsWith('https://')) {
      imagen = NetworkImage(foto);
    }

    final avatar = CircleAvatar(
      radius: radio,
      backgroundColor: fondo ?? color.withValues(alpha: 0.12),
      foregroundImage: imagen,
      child: imagen == null
          ? Text(
              nombre.trim().isNotEmpty ? nombre.trim()[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: radio * 0.82,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            )
          : null,
    );

    if (bordeAncho == null) return avatar;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: bordeAncho!),
      ),
      child: avatar,
    );
  }
}
