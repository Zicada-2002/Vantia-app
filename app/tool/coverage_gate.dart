// Falla si los módulos críticos bajan del umbral de cobertura (F-90).
// Uso: flutter test --coverage && dart run tool/coverage_gate.dart
import 'dart:io';

const threshold = 90.0;
const critical = [
  'lib/features/automation/domain/parsers.dart',
  'lib/features/cash_register/domain/cash_session.dart',
  'lib/features/reports/domain/report.dart',
  'lib/core/time/lima_time.dart',
  'lib/core/validation/validators.dart',
  'lib/app/router/guards.dart',
];

void main() {
  final lcov = File('coverage/lcov.info');
  if (!lcov.existsSync()) {
    stderr.writeln(
      'No existe coverage/lcov.info. Ejecuta flutter test --coverage.',
    );
    exit(2);
  }
  final records = lcov.readAsStringSync().split('end_of_record');
  var failed = false;
  var hitAll = 0;
  var foundAll = 0;
  for (final rec in records) {
    final sf = RegExp('SF:(.*)').firstMatch(rec)?.group(1)?.trim();
    if (sf == null) continue;
    final lf = int.parse(RegExp(r'LF:(\d+)').firstMatch(rec)!.group(1)!);
    final lh = int.parse(RegExp(r'LH:(\d+)').firstMatch(rec)!.group(1)!);
    hitAll += lh;
    foundAll += lf;
    final match = critical.where(sf.endsWith);
    if (match.isEmpty || lf == 0) continue;
    final pct = 100 * lh / lf;
    final ok = pct >= threshold;
    failed |= !ok;
    stdout.writeln(
      '${ok ? 'OK ' : 'BAJO'} ${pct.toStringAsFixed(1)}%  ${match.first}',
    );
  }
  stdout.writeln('Total: ${(100 * hitAll / foundAll).toStringAsFixed(1)}%');
  if (failed) {
    stderr.writeln('Cobertura de módulos críticos por debajo de $threshold%.');
    exit(1);
  }
}
