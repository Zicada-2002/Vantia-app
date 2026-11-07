// Los providers `.family` de Riverpod 3 no exportan un tipo público.
// ignore_for_file: specify_nonobvious_property_types

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/core/time/clock.dart';
import 'package:vantia/core/time/lima_time.dart';
import 'package:vantia/features/reports/data/reports_repository.dart';
import 'package:vantia/features/reports/domain/report.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => FirestoreReportsRepository(FirebaseFirestore.instance),
);

final reportProvider = StreamProvider.family<Report, ReportPeriod>((
  ref,
  period,
) {
  final s = ref.watch(sessionProvider);
  final today = LimaTime.toLima(ref.watch(clockProvider)());
  if (s is! SessionReady || !s.isOwner) {
    return Stream.value(Report.build(period, today, const []));
  }
  final range = DayRange.current(period, today);
  final prev = range.previous(period);
  return ref
      .watch(reportsRepositoryProvider)
      .watchDailyStats(
        s.businessId,
        fromKey: prev.startKey,
        toKey: range.endKey,
      )
      .map((stats) => Report.build(period, today, stats));
});
