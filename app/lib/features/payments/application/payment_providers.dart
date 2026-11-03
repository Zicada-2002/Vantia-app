// Los providers `.family` de Riverpod 3 no exportan un tipo público
// nombrable; se infiere desde el constructor.
// ignore_for_file: specify_nonobvious_property_types

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/core/time/clock.dart';
import 'package:vantia/core/time/lima_time.dart';
import 'package:vantia/features/payments/data/firestore_payment_repository.dart';
import 'package:vantia/features/payments/domain/payment.dart';
import 'package:vantia/features/payments/domain/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => FirestorePaymentRepository(FirebaseFirestore.instance),
);

/// Alcance de lectura según el rol (null si no hay sesión lista).
final paymentScopeProvider = Provider<PaymentScope?>((ref) {
  final session = ref.watch(sessionProvider);
  if (session is! SessionReady) return null;
  return PaymentScope(
    businessId: session.businessId,
    onlyCreatedBy: session.isOwner ? null : session.uid,
  );
});

/// Nombre a mostrar del usuario actual (para `createdByName`).
final currentUserNameProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  final auth = ref.watch(authUserProvider).value;
  final name = profile?.displayName ?? auth?.displayName ?? '';
  return name.isNotEmpty ? name : (auth?.email ?? '');
});

final todayPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  final scope = ref.watch(paymentScopeProvider);
  if (scope == null) return Stream.value(const []);
  final start = LimaTime.startOfDay(ref.watch(clockProvider)());
  return ref
      .watch(paymentRepositoryProvider)
      .watchRange(scope, from: start, to: start.add(const Duration(days: 1)));
});

final todaySummaryProvider = Provider<AsyncValue<PaymentSummary>>(
  (ref) => ref.watch(todayPaymentsProvider).whenData(PaymentSummary.of),
);

final recentPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  final scope = ref.watch(paymentScopeProvider);
  if (scope == null) return Stream.value(const []);
  return ref.watch(paymentRepositoryProvider).watchRecent(scope);
});

/// Pagos de la semana que empieza en `weekStart` (lunes 00:00 Lima).
final weekPaymentsProvider = StreamProvider.family<List<Payment>, DateTime>((
  ref,
  weekStart,
) {
  final scope = ref.watch(paymentScopeProvider);
  if (scope == null) return Stream.value(const []);
  return ref
      .watch(paymentRepositoryProvider)
      .watchRange(
        scope,
        from: weekStart,
        to: weekStart.add(const Duration(days: 7)),
      );
});

/// Pagos en un rango arbitrario `[from, to)` (cuadre, reportes, exportación).
final rangePaymentsProvider =
    StreamProvider.family<List<Payment>, ({DateTime from, DateTime to})>((
      ref,
      range,
    ) {
      final scope = ref.watch(paymentScopeProvider);
      if (scope == null) return Stream.value(const []);
      return ref
          .watch(paymentRepositoryProvider)
          .watchRange(scope, from: range.from, to: range.to);
    });

final paymentProvider = StreamProvider.family<Payment?, String>((ref, id) {
  final scope = ref.watch(paymentScopeProvider);
  if (scope == null) return Stream.value(null);
  return ref.watch(paymentRepositoryProvider).watch(scope.businessId, id);
});

/// `true` si el dispositivo no tiene red (F-27).
final offlineProvider = StreamProvider<bool>(
  (ref) => Connectivity().onConnectivityChanged.map(
    (r) => r.every((c) => c == ConnectivityResult.none),
  ),
);

/// Ventana en la que un colaborador puede anular sus propios pagos.
const collaboratorVoidWindow = Duration(minutes: 15);

enum VoidPermission { allowed, notOwnPayment, windowExpired, alreadyVoided }

VoidPermission canVoid({
  required Payment payment,
  required SessionReady session,
  required DateTime now,
}) {
  if (!payment.isActive) return VoidPermission.alreadyVoided;
  if (session.isOwner) return VoidPermission.allowed;
  if (payment.createdBy != session.uid) return VoidPermission.notOwnPayment;
  final created = payment.createdAt ?? payment.occurredAt;
  return now.difference(created) <= collaboratorVoidWindow
      ? VoidPermission.allowed
      : VoidPermission.windowExpired;
}
