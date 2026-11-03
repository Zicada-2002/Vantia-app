import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/core/result/failure.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/core/time/lima_time.dart';
import 'package:vantia/features/payments/domain/payment.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';
import 'package:vantia/features/payments/domain/payment_repository.dart';

class FirestorePaymentRepository implements PaymentRepository {
  FirestorePaymentRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String bid) =>
      _db.collection('businesses/$bid/payments');

  Query<Map<String, dynamic>> _scoped(PaymentScope scope) {
    Query<Map<String, dynamic>> q = _col(scope.businessId);
    if (scope.onlyCreatedBy != null) {
      q = q.where('createdBy', isEqualTo: scope.onlyCreatedBy);
    }
    return q;
  }

  @override
  Stream<List<Payment>> watchRange(
    PaymentScope scope, {
    required DateTime from,
    required DateTime to,
  }) => _scoped(scope)
      .where('occurredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
      .where('occurredAt', isLessThan: Timestamp.fromDate(to))
      .orderBy('occurredAt', descending: true)
      .snapshots(includeMetadataChanges: true)
      .map((s) => s.docs.map(paymentFromDoc).toList());

  @override
  Stream<List<Payment>> watchRecent(PaymentScope scope, {int limit = 10}) =>
      _scoped(scope)
          .orderBy('occurredAt', descending: true)
          .limit(limit)
          .snapshots(includeMetadataChanges: true)
          .map((s) => s.docs.map(paymentFromDoc).toList());

  @override
  Stream<Payment?> watch(String businessId, String paymentId) =>
      _col(businessId)
          .doc(paymentId)
          .snapshots(includeMetadataChanges: true)
          .map((d) => d.exists ? paymentFromDoc(d) : null);

  @override
  Future<Result<String>> create({
    required String businessId,
    required String userId,
    required String userName,
    required PaymentDraft draft,
    String? id,
  }) async {
    final ref = id == null ? _col(businessId).doc() : _col(businessId).doc(id);
    final data = <String, Object?>{
      'method': draft.method.id,
      'amountCents': draft.net.cents,
      if (draft.method == PaymentMethod.cash) ...{
        'receivedCents': draft.received.cents,
        'changeCents': draft.change.cents,
      },
      'description': _clean(draft.description),
      'operationNumber': _clean(draft.operationNumber),
      'payerName': _clean(draft.payerName),
      'occurredAt': Timestamp.fromDate(draft.occurredAt),
      'dayKey': LimaTime.dayKey(draft.occurredAt),
      'createdBy': userId,
      'createdByName': userName,
      'source': draft.source.name,
      'verified': draft.verified,
      'status': PaymentStatus.active.name,
      'items': draft.items.map((i) => i.toJson()).toList(),
      'receiptPath': draft.receiptPath,
      'createdAt': FieldValue.serverTimestamp(),
    }..removeWhere((_, v) => v == null);
    // Sin await al servidor: offline-first. El set queda en la cola local.
    ref.set(data).ignore();
    return Ok(ref.id);
  }

  @override
  Future<Result<void>> voidPayment({
    required String businessId,
    required String paymentId,
    required String userId,
    required String reason,
  }) async {
    try {
      await _col(businessId).doc(paymentId).update({
        'status': PaymentStatus.voided.name,
        'voidReason': reason.trim(),
        'voidedBy': userId,
        'voidedAt': FieldValue.serverTimestamp(),
      });
      return const Ok(null);
    } on FirebaseException catch (e) {
      return Err(
        e.code == 'permission-denied'
            ? const PermissionFailure()
            : UnexpectedFailure(e.code, e),
      );
    }
  }

  @override
  Future<bool> existsOperation(
    PaymentScope scope, {
    required String method,
    required String operationNumber,
  }) async {
    try {
      final q = await _scoped(scope)
          .where('method', isEqualTo: method)
          .where('operationNumber', isEqualTo: operationNumber.trim())
          .limit(1)
          .get();
      return q.docs.isNotEmpty;
    } on FirebaseException {
      return false;
    }
  }

  static String? _clean(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}

Payment paymentFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data() ?? const <String, dynamic>{};
  Money? money(String k) {
    final v = d[k];
    return v is num ? Money(v.toInt()) : null;
  }

  return Payment(
    id: doc.id,
    method:
        PaymentMethod.fromId(d['method'] as String? ?? '') ??
        PaymentMethod.cash,
    amount: money('amountCents') ?? const Money.zero(),
    received: money('receivedCents'),
    change: money('changeCents'),
    description: d['description'] as String?,
    operationNumber: d['operationNumber'] as String?,
    payerName: d['payerName'] as String?,
    occurredAt: (d['occurredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    createdBy: d['createdBy'] as String? ?? '',
    createdByName: d['createdByName'] as String? ?? '',
    source:
        PaymentSource.values.asNameMap()[d['source']] ?? PaymentSource.manual,
    verified: d['verified'] as bool? ?? false,
    status:
        PaymentStatus.values.asNameMap()[d['status']] ?? PaymentStatus.active,
    voidReason: d['voidReason'] as String?,
    items: [
      for (final i in (d['items'] as List<dynamic>? ?? const []))
        PaymentItem.fromJson(Map<String, dynamic>.from(i as Map)),
    ],
    createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    pendingSync: doc.metadata.hasPendingWrites,
    receiptPath: d['receiptPath'] as String?,
  );
}
