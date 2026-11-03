import 'package:intl/intl.dart';

/// Utilidades de fecha en la zona horaria del negocio: **America/Lima**.
///
/// Perú usa UTC−5 todo el año (sin horario de verano desde 1994), por lo que
/// un desfase fijo es exacto y evita depender de la base de datos de zonas.
/// Cualquier agrupamiento por día/semana/mes (cierres de caja, reportes) usa esta
/// clase, nunca la zona del dispositivo.
abstract final class LimaTime {
  static const Duration offset = Duration(hours: -5);

  /// Instante → "hora de pared" de Lima, representada como `DateTime` UTC
  /// cuyos campos (año, mes, día, hora) son los de Lima.
  static DateTime toLima(DateTime instant) => instant.toUtc().add(offset);

  /// "Hora de pared" de Lima → instante real (UTC).
  static DateTime fromLima(DateTime limaWall) => DateTime.utc(
    limaWall.year,
    limaWall.month,
    limaWall.day,
    limaWall.hour,
    limaWall.minute,
    limaWall.second,
    limaWall.millisecond,
  ).subtract(offset);

  /// Clave de día `yyyy-MM-dd` usada en Firestore (`dayKey`).
  static String dayKey(DateTime instant) {
    final l = toLima(instant);
    return '${l.year.toString().padLeft(4, '0')}-'
        '${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')}';
  }

  /// Inicio del día en Lima (como instante UTC).
  static DateTime startOfDay(DateTime instant) {
    final l = toLima(instant);
    return fromLima(DateTime.utc(l.year, l.month, l.day));
  }

  /// Inicio de la semana (lunes 00:00 en Lima).
  static DateTime startOfWeek(DateTime instant) {
    final l = toLima(instant);
    final monday = DateTime.utc(l.year, l.month, l.day - (l.weekday - 1));
    return fromLima(monday);
  }

  /// Inicio del mes en Lima.
  static DateTime startOfMonth(DateTime instant) {
    final l = toLima(instant);
    return fromLima(DateTime.utc(l.year, l.month));
  }

  static bool isSameDay(DateTime a, DateTime b) => dayKey(a) == dayKey(b);

  /// `2 nov. 2026`
  static String formatDate(DateTime instant) => DateFormat(
    'd MMM. y',
    'es',
  ).format(toLima(instant)).replaceAll('..', '.');

  /// `2 nov`
  static String formatShortDate(DateTime instant) =>
      DateFormat('d MMM', 'es').format(toLima(instant)).replaceAll('.', '');

  /// `21:46`
  static String formatTime(DateTime instant) =>
      DateFormat('HH:mm').format(toLima(instant));

  /// Rango de semana: `2 nov - 8 nov`
  static String formatWeekRange(DateTime instant) {
    final start = startOfWeek(instant);
    final end = start.add(const Duration(days: 6));
    return '${formatShortDate(start)} - ${formatShortDate(end)}';
  }
}
