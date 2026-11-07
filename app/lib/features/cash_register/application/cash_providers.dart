import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/firebase/firebase_env.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/core/time/clock.dart';
import 'package:vantia/core/time/lima_time.dart';
import 'package:vantia/features/cash_register/data/firebase_cash_repository.dart';
import 'package:vantia/features/cash_register/domain/cash_session.dart';

final cashRepositoryProvider = Provider<CashRepository>(
  (ref) => FirebaseCashRepository(
    FirebaseFirestore.instance,
    FirebaseFunctions.instanceFor(region: FirebaseEnv.functionsRegion),
  ),
);

/// Día seleccionado en el cuadre (inicio del día en Lima).
final cashDayProvider = NotifierProvider<CashDay, DateTime>(CashDay.new);

class CashDay extends Notifier<DateTime> {
  @override
  DateTime build() => LimaTime.startOfDay(ref.watch(clockProvider)());

  void select(DateTime limaDate) => state = LimaTime.fromLima(
    DateTime.utc(limaDate.year, limaDate.month, limaDate.day),
  );
}

final mySessionProvider = StreamProvider<CashSession?>((ref) {
  final s = ref.watch(sessionProvider);
  if (s is! SessionReady) return Stream.value(null);
  final dayKey = LimaTime.dayKey(ref.watch(cashDayProvider));
  return ref
      .watch(cashRepositoryProvider)
      .watchSession(s.businessId, dayKey, s.uid);
});

final daySessionsProvider = StreamProvider<List<CashSession>>((ref) {
  final s = ref.watch(sessionProvider);
  if (s is! SessionReady || !s.isOwner) return Stream.value(const []);
  final dayKey = LimaTime.dayKey(ref.watch(cashDayProvider));
  return ref.watch(cashRepositoryProvider).watchDay(s.businessId, dayKey);
});
