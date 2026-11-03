import 'package:flutter/foundation.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/features/payments/domain/payment.dart';

/// Alcance de lectura: el dueño ve todo el negocio; un colaborador, solo
/// lo suyo (las reglas de Firestore lo exigen así).
@immutable
class PaymentScope {
  const PaymentScope({required this.businessId, this.onlyCreatedBy});

  final String businessId;
  final String? onlyCreatedBy;

  @override
  bool operator ==(Object other) =>
      other is PaymentScope &&
      other.businessId == businessId &&
      other.onlyCreatedBy == onlyCreatedBy;

  @override
  int get hashCode => Object.hash(businessId, onlyCreatedBy);
}

abstract interface class PaymentRepository {
  /// Pagos con `occurredAt` en `[from, to)`, más recientes primero.
  Stream<List<Payment>> watchRange(
    PaymentScope scope, {
    required DateTime from,
    required DateTime to,
  });

  Stream<List<Payment>> watchRecent(PaymentScope scope, {int limit = 10});

  Stream<Payment?> watch(String businessId, String paymentId);

  /// Registra el pago. Funciona offline: devuelve el id de inmediato.
  Future<Result<String>> create({
    required String businessId,
    required String userId,
    required String userName,
    required PaymentDraft draft,
  });

  Future<Result<void>> voidPayment({
    required String businessId,
    required String paymentId,
    required String userId,
    required String reason,
  });

  /// ¿Ya existe un pago con ese nº de operación y método? (duplicados)
  Future<bool> existsOperation(
    PaymentScope scope, {
    required String method,
    required String operationNumber,
  });
}
