import 'package:audioplayers/audioplayers.dart';

/// Efectos de sonido cortos de la app. Los errores se ignoran a propósito:
/// si el audio falla (p. ej. sin dispositivo de salida), el juego sigue.
class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> _play(String asset) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(asset), volume: 0.6);
    } catch (_) {}
  }

  /// Respuesta correcta
  static Future<void> correct() => _play('sounds/correct.wav');

  /// Respuesta incorrecta
  static Future<void> wrong() => _play('sounds/wrong.wav');

  /// Lección/nivel superado o medalla ganada
  static Future<void> levelUp() => _play('sounds/levelup.wav');
}
