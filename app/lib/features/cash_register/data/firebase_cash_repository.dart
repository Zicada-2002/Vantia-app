import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:vantia/core/money/money.dart';
import 'package:vantia/core/result/failure.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/features/business/data/firestore_business_repository.dart';
import 'package:vantia/features/cash_register/domain/cash_session.dart';

class FirebaseCashRepository implements CashRepository {
  FirebaseCashRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> _col(String bid) =>
      _db.collection('businesses/$bid/cashSessions');

  static CashSession _map(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    Money? money(String k) => m[k] is num ? Money((m[k] as num).toInt()) : null;
    return CashSession(
      dayKey: m['dayKey'] as String? ?? '',
      uid: m['uid'] as String? ?? '',
      displayName: m['displayName'] as String? ?? '',
      status: CashStatus.values.asNameMap()[m['status']] ?? CashStatus.open,
      opening: money('openingCents') ?? const Money.zero(),
      counted: money('countedCents'),
      total: money('totalCents'),
      expected: money('expectedCents'),
      difference: money('differenceCents'),
      closedAt: (m['closedAt'] as Timestamp?)?.toDate(),
      reopenReason: m['reopenReason'] as String?,
    );
  }

  @override
  Stream<CashSession?> watchSession(
    String businessId,
    String dayKey,
    String uid,
  ) => _col(businessId)
      .doc(CashSession.idFor(dayKey, uid))
      .snapshots()
      .map((d) => d.exists ? _map(d) : null);

  @override
  Stream<List<CashSession>> watchDay(String businessId, String dayKey) =>
      _col(businessId)
          .where('dayKey', isEqualTo: dayKey)
          .snapshots()
          .map((s) => s.docs.map(_map).toList());

  @override
  Future<Result<void>> saveDraft({
    required String businessId,
    required String dayKey,
    required String uid,
    required String displayName,
    required bool exists,
    Money? opening,
    Money? counted,
  }) async {
    final ref = _col(businessId).doc(CashSession.idFor(dayKey, uid));
    try {
      final draft = <String, Object>{
        if (opening != null) 'openingCents': opening.cents,
        if (counted != null) 'countedCents': counted.cents,
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (exists) {
        ref.update(draft).ignore();
      } else {
        ref.set({
          ...draft,
          'dayKey': dayKey,
          'uid': uid,
          'status': 'open',
        }).ignore();
      }
      return const Ok(null);
    } on FirebaseException catch (e) {
      return Err(UnexpectedFailure(e.code, e));
    }
  }

  @override
  Future<Result<void>> close({
    required String dayKey,
    required Money opening,
    required Money counted,
  }) => _call('closeCashSession', {
    'dayKey': dayKey,
    'openingCents': opening.cents,
    'countedCents': counted.cents,
  });

  @override
  Future<Result<void>> reopen({
    required String dayKey,
    required String uid,
    required String reason,
  }) => _call('reopenCashSession', {
    'dayKey': dayKey,
    'uid': uid,
    'reason': reason,
  });

  Future<Result<void>> _call(String name, Map<String, Object> data) async {
    try {
      await _functions.httpsCallable(name).call<Map<String, dynamic>>(data);
      return const Ok(null);
    } on FirebaseFunctionsException catch (e) {
      return Err(mapFunctionsException(e));
    }
  }
}
