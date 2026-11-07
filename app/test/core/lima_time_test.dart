import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:vantia/core/time/lima_time.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('dayKey', () {
    test('usa la hora de Lima, no UTC', () {
      // 2 nov 2026 23:30 en Lima = 3 nov 04:30 UTC.
      final instant = DateTime.utc(2026, 11, 3, 4, 30);
      expect(LimaTime.dayKey(instant), '2026-11-02');
    });

    test('a partir de las 05:00 UTC ya es el día siguiente en Lima', () {
      expect(LimaTime.dayKey(DateTime.utc(2026, 11, 3, 5)), '2026-11-03');
    });
  });

  test('startOfDay devuelve 00:00 de Lima como instante UTC', () {
    final start = LimaTime.startOfDay(DateTime.utc(2026, 11, 3, 2));
    expect(start, DateTime.utc(2026, 11, 2, 5));
  });

  group('startOfWeek (lunes)', () {
    test('un domingo pertenece a la semana del lunes anterior', () {
      // Domingo 8 nov 2026 20:00 Lima.
      final sunday = DateTime.utc(2026, 11, 9, 1);
      expect(LimaTime.startOfWeek(sunday), DateTime.utc(2026, 11, 2, 5));
    });

    test('cruza el cambio de mes', () {
      // Domingo 1 nov 2026 → lunes 26 oct.
      final instant = DateTime.utc(2026, 11, 1, 17);
      expect(LimaTime.startOfWeek(instant), DateTime.utc(2026, 10, 26, 5));
    });
  });

  test('startOfMonth', () {
    expect(
      LimaTime.startOfMonth(DateTime.utc(2026, 12, 1, 3)), // 30 nov en Lima
      DateTime.utc(2026, 11, 1, 5),
    );
  });

  test('formatos es-PE', () {
    final instant = DateTime.utc(2026, 11, 3, 2, 46); // 2 nov 21:46 Lima
    expect(LimaTime.formatTime(instant), '21:46');
    expect(LimaTime.formatDate(instant), '2 nov. 2026');
    expect(LimaTime.formatWeekRange(instant), '2 nov - 8 nov');
  });
}
