import 'package:flutter/foundation.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';

/// Documento `dailyStats/{dayKey}` (lo mantiene la Function onPaymentWrite).
@immutable
class DailyStat {
  const DailyStat({
    required this.dayKey,
    required this.total,
    required this.count,
    required this.cashCount,
    required this.digitalCount,
    this.byMethod = const {},
  });

  final String dayKey;
  final Money total;
  final int count;
  final int cashCount;
  final int digitalCount;
  final Map<PaymentMethod, Money> byMethod;

  /// Fecha (hora de pared de Lima) del `dayKey`.
  DateTime get date => DateTime.utc(
    int.parse(dayKey.substring(0, 4)),
    int.parse(dayKey.substring(5, 7)),
    int.parse(dayKey.substring(8, 10)),
  );
}

enum ReportPeriod { week, month, year }

String dayKeyOf(DateTime limaWall) =>
    '${limaWall.year.toString().padLeft(4, '0')}-'
    '${limaWall.month.toString().padLeft(2, '0')}-'
    '${limaWall.day.toString().padLeft(2, '0')}';

/// Rango `[start, end)` en fechas de pared de Lima (UTC sin hora).
@immutable
class DayRange {
  const DayRange(this.start, this.end);

  /// Periodo que contiene [limaToday].
  factory DayRange.current(ReportPeriod p, DateTime limaToday) {
    final d = DateTime.utc(limaToday.year, limaToday.month, limaToday.day);
    return switch (p) {
      ReportPeriod.week => DayRange(
        d.subtract(Duration(days: d.weekday - 1)),
        d.subtract(Duration(days: d.weekday - 1)).add(const Duration(days: 7)),
      ),
      ReportPeriod.month => DayRange(
        DateTime.utc(d.year, d.month),
        DateTime.utc(d.year, d.month + 1),
      ),
      ReportPeriod.year => DayRange(
        DateTime.utc(d.year),
        DateTime.utc(d.year + 1),
      ),
    };
  }

  final DateTime start;
  final DateTime end;

  DayRange previous(ReportPeriod p) => switch (p) {
    ReportPeriod.week => DayRange(
      start.subtract(const Duration(days: 7)),
      start,
    ),
    ReportPeriod.month => DayRange(
      DateTime.utc(start.year, start.month - 1),
      start,
    ),
    ReportPeriod.year => DayRange(DateTime.utc(start.year - 1), start),
  };

  String get startKey => dayKeyOf(start);
  String get endKey => dayKeyOf(end);

  bool contains(String dayKey) =>
      dayKey.compareTo(startKey) >= 0 && dayKey.compareTo(endKey) < 0;
}

@immutable
class ReportBucket {
  const ReportBucket(this.label, this.total);

  final String label;
  final Money total;
}

/// Resultado de un reporte (F-51 … F-53).
@immutable
class Report {
  const Report({
    required this.period,
    required this.total,
    required this.previousTotal,
    required this.count,
    required this.cashCount,
    required this.digitalCount,
    required this.buckets,
    required this.byMethod,
    this.best,
  });

  factory Report.build(
    ReportPeriod period,
    DateTime limaToday,
    List<DailyStat> stats,
  ) {
    final range = DayRange.current(period, limaToday);
    final prev = range.previous(period);
    final current = stats.where((s) => range.contains(s.dayKey)).toList();
    final previousTotal = Money.sum(
      stats.where((s) => prev.contains(s.dayKey)).map((s) => s.total),
    );

    final labels = switch (period) {
      ReportPeriod.week => _weekdays,
      ReportPeriod.month => [
        for (var w = 1; w <= _weeksInMonth(range.start); w++) 'Sem $w',
      ],
      ReportPeriod.year => _months,
    };
    final totals = List.filled(labels.length, const Money.zero());
    final byMethod = <PaymentMethod, Money>{};
    var count = 0;
    var cash = 0;
    var digital = 0;
    for (final s in current) {
      final i = switch (period) {
        ReportPeriod.week => s.date.weekday - 1,
        ReportPeriod.month => (s.date.day - 1) ~/ 7,
        ReportPeriod.year => s.date.month - 1,
      };
      totals[i] += s.total;
      count += s.count;
      cash += s.cashCount;
      digital += s.digitalCount;
      s.byMethod.forEach(
        (m, v) => byMethod[m] = (byMethod[m] ?? const Money.zero()) + v,
      );
    }
    final buckets = [
      for (var i = 0; i < labels.length; i++)
        ReportBucket(labels[i], totals[i]),
    ];
    ReportBucket? best;
    for (final b in buckets) {
      if (b.total.isPositive && (best == null || b.total > best.total)) {
        best = b;
      }
    }
    return Report(
      period: period,
      total: Money.sum(totals),
      previousTotal: previousTotal,
      count: count,
      cashCount: cash,
      digitalCount: digital,
      buckets: buckets,
      byMethod: byMethod,
      best: best,
    );
  }

  final ReportPeriod period;
  final Money total;
  final Money previousTotal;
  final int count;
  final int cashCount;
  final int digitalCount;
  final List<ReportBucket> buckets;
  final Map<PaymentMethod, Money> byMethod;
  final ReportBucket? best;

  /// Variación % vs. el periodo anterior (null si el anterior fue 0).
  double? get changePercent => previousTotal.isZero
      ? null
      : (total.cents - previousTotal.cents) * 100 / previousTotal.cents;

  /// Ticket promedio.
  Money get averageTicket =>
      count == 0 ? const Money.zero() : Money((total.cents / count).round());

  /// Participación de cada método, de mayor a menor.
  List<(PaymentMethod, Money, double)> get methodShares {
    final entries = byMethod.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final e in entries)
        (e.key, e.value, total.isZero ? 0 : e.value.cents * 100 / total.cents),
    ];
  }

  static int _weeksInMonth(DateTime monthStart) {
    final days = DateTime.utc(
      monthStart.year,
      monthStart.month + 1,
    ).difference(monthStart).inDays;
    return ((days - 1) ~/ 7) + 1;
  }

  static const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
}
