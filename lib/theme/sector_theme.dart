import 'package:flutter/material.dart';
import '../models/models.dart';

/// Tema visual según el sector de la organización del usuario.
///
/// Cada sector tiene una paleta acorde a su finalidad:
///   escuela     → cálido y juguetón (el look original de CyLearn)
///   colegio     → azul/cian, fresco
///   universidad → índigo profundo, serio pero vivo
///   empresa     → verde azulado profesional
class SectorTheme {
  final String sector;
  final Color fondo;
  final Color primario;
  final Color acento;
  final Color oscuro;
  final String emoji;

  const SectorTheme({
    required this.sector,
    required this.fondo,
    required this.primario,
    required this.acento,
    required this.oscuro,
    required this.emoji,
  });

  static const escuela = SectorTheme(
    sector: 'escuela',
    fondo: Color(0xFFFFF9F2),
    primario: Color(0xFF6B46F6),
    acento: Color(0xFFFFCC00),
    oscuro: Color(0xFF1C1140),
    emoji: '🎒',
  );

  static const colegio = SectorTheme(
    sector: 'colegio',
    fondo: Color(0xFFF2FAFF),
    primario: Color(0xFF0EA5E9),
    acento: Color(0xFF38BDF8),
    oscuro: Color(0xFF0C2D48),
    emoji: '📘',
  );

  static const universidad = SectorTheme(
    sector: 'universidad',
    fondo: Color(0xFFF4F4FB),
    primario: Color(0xFF4338CA),
    acento: Color(0xFFF59E0B),
    oscuro: Color(0xFF1E1B4B),
    emoji: '🎓',
  );

  static const empresa = SectorTheme(
    sector: 'empresa',
    fondo: Color(0xFFF3FAF8),
    primario: Color(0xFF0F766E),
    acento: Color(0xFF14B8A6),
    oscuro: Color(0xFF134E4A),
    emoji: '🏢',
  );

  static SectorTheme porSector(String? sector) {
    switch (sector) {
      case 'colegio':
        return colegio;
      case 'universidad':
        return universidad;
      case 'empresa':
        return empresa;
      default:
        return escuela; // usuarios sin organización o sector escuela
    }
  }

  /// Tema del usuario autenticado (usa el sector de su organización).
  static SectorTheme deUsuario(Usuario? usuario) =>
      porSector(usuario?.organizacion?.sector);
}
