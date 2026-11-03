import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';
import 'package:vantia/features/reports/domain/report.dart';

abstract interface class ReportsRepository {
  /// `dailyStats` con `dayKey` en `[fromKey, toKey)`.
  Stream<List<DailyStat>> watchDailyStats(
    String businessId, {
    required String fromKey,
    required String toKey,
  });
}

class FirestoreReportsRepository implements ReportsRepository {
  FirestoreReportsRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Stream<List<DailyStat>> watchDailyStats(
    String businessId, {
    required String fromKey,
    required String toKey,
  }) => _db
      .collection('businesses/$businessId/dailyStats')
      .where('dayKey', isGreaterThanOrEqualTo: fromKey)
      .where('dayKey', isLessThan: toKey)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            DailyStat(
              dayKey: d.id,
              total: Money((d.data()['totalCents'] as num? ?? 0).toInt()),
              count: (d.data()['count'] as num? ?? 0).toInt(),
              cashCount: (d.data()['cashCount'] as num? ?? 0).toInt(),
              digitalCount: (d.data()['digitalCount'] as num? ?? 0).toInt(),
              byMethod: {
                for (final e
                    in ((d.data()['byMethod'] as Map<String, dynamic>?) ??
                            const {})
                        .entries)
                  ?PaymentMethod.fromId(e.key): Money(
                    ((e.value as Map<String, dynamic>)['cents'] as num? ?? 0)
                        .toInt(),
                  ),
              },
            ),
        ],
      );
}
