import 'package:flutter/foundation.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/features/payments/domain/payment.dart';

enum CashStatus { open, closed, reopened }

/// Cálculo del cuadre (F-42). Mismo algoritmo que `computeCashTotals`
/// en Functions; el cierre lo recalcula el servidor.
@immutable
class CashCount {
  const CashCount({
    required this.opening,
    required this.cashReceived,
    required this.changeGiven,
    required this.counted,
  });

  factory CashCount.from(
    PaymentSummary summary, {
    required Money opening,
    required Money counted,
  }) => CashCount(
    opening: opening,
    cashReceived: summary.cashReceived,
    changeGiven: summary.changeGiven,
    counted: counted,
  );

  final Money opening;
  final Money cashReceived;
  final Money changeGiven;
  final Money counted;

  Money get expected => opening + cashReceived - changeGiven;
  Money get difference => counted - expected;
}

@immutable
class CashSession {
  const CashSession({
    required this.dayKey,
    required this.uid,
    required this.status,
    this.displayName = '',
    this.opening = const Money.zero(),
    this.counted,
    this.total,
    this.expected,
    this.difference,
    this.closedAt,
    this.reopenReason,
  });

  final String dayKey;
  final String uid;
  final String displayName;
  final CashStatus status;
  final Money opening;
  final Money? counted;

  /// Snapshot del servidor al cerrar.
  final Money? total;
  final Money? expected;
  final Money? difference;
  final DateTime? closedAt;
  final String? reopenReason;

  bool get isClosed => status == CashStatus.closed;

  static String idFor(String dayKey, String uid) => '${dayKey}_$uid';
}

abstract interface class CashRepository {
  Stream<CashSession?> watchSession(
    String businessId,
    String dayKey,
    String uid,
  );

  /// Todas las cajas del día (solo dueño).
  Stream<List<CashSession>> watchDay(String businessId, String dayKey);

  /// Guarda el borrador (fondo inicial / contado) mientras la caja está abierta.
  Future<Result<void>> saveDraft({
    required String businessId,
    required String dayKey,
    required String uid,
    required String displayName,
    required bool exists,
    Money? opening,
    Money? counted,
  });

  Future<Result<void>> close({
    required String dayKey,
    required Money opening,
    required Money counted,
  });

  Future<Result<void>> reopen({
    required String dayKey,
    required String uid,
    required String reason,
  });
}
