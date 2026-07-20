import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Notificaciones locales de Android:
///   1. "Tu racha está en riesgo" — programada para mañana; si el estudiante
///      hace un ejercicio antes, se reprograma y nunca la ve.
///   2. Re-enganche a los 3 y 7 días sin actividad.
///
/// Cada actividad del usuario reprograma todo, así que las notificaciones
/// solo llegan si de verdad dejó de usar la app.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _inicializado = false;

  static const _idRacha = 1;
  static const _idReenganche3 = 2;
  static const _idReenganche7 = 3;

  static Future<void> init() async {
    if (_inicializado || kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;

    tzdata.initializeTimeZones();

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: settings);

    // Android 13+ requiere pedir el permiso de notificaciones en runtime
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _inicializado = true;
  }

  static NotificationDetails get _detalles => const NotificationDetails(
        android: AndroidNotificationDetails(
          'recordatorios',
          'Recordatorios',
          channelDescription:
              'Recordatorios de racha y para volver a aprender',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

  // La hora objetivo (mañana/pasado a las N) convertida a un instante tz.
  // Se calcula como diferencia desde ahora para no depender de la zona
  // horaria configurada en la base de datos de tz.
  static tz.TZDateTime _instante(int diasDespues, int hora) {
    final ahora = DateTime.now();
    var objetivo = DateTime(ahora.year, ahora.month, ahora.day, hora)
        .add(Duration(days: diasDespues));
    if (!objetivo.isAfter(ahora)) {
      objetivo = objetivo.add(const Duration(days: 1));
    }
    return tz.TZDateTime.now(tz.local).add(objetivo.difference(ahora));
  }

  /// Reprograma los recordatorios. Llamar después de cada actividad
  /// (login, ejercicio respondido, racha actualizada).
  static Future<void> programarRecordatorios({required int racha}) async {
    if (!_inicializado) return;
    try {
      await _plugin.cancelAll();

      // 1. Racha en riesgo: mañana a las 19:00 (si hoy ya hubo actividad,
      //    la racha se pierde si mañana no hay ninguna)
      if (racha > 0) {
        await _plugin.zonedSchedule(
          id: _idRacha,
          title: '🔥 ¡Tu racha de $racha días está en riesgo!',
          body:
              'Haz un ejercicio hoy para no perderla. ¡Solo te toma un minuto!',
          scheduledDate: _instante(1, 19),
          notificationDetails: _detalles,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }

      // 2. Re-enganche: 3 días sin actividad
      await _plugin.zonedSchedule(
        id: _idReenganche3,
        title: '👋 ¡Te extrañamos en CyLearn!',
        body:
            'Tus lecciones de ciberseguridad te esperan. ¡Vuelve a la aventura!',
        scheduledDate: _instante(3, 18),
        notificationDetails: _detalles,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

      // 3. Re-enganche: 7 días sin actividad
      await _plugin.zonedSchedule(
        id: _idReenganche7,
        title: '🚀 ¡Una semana sin verte!',
        body:
            'Los héroes digitales entrenan seguido. ¿Retomamos donde quedaste?',
        scheduledDate: _instante(7, 18),
        notificationDetails: _detalles,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // Las notificaciones nunca deben romper el flujo de la app
    }
  }

  static Future<void> cancelarTodo() async {
    if (!_inicializado) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
