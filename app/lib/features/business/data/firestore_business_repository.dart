import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:vantia/app/router/session.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/features/business/domain/business.dart';
import 'package:vantia/features/business/domain/business_failure.dart';
import 'package:vantia/features/business/domain/business_repository.dart';

class FirestoreBusinessRepository implements BusinessRepository {
  FirestoreBusinessRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  @override
  Stream<UserProfile?> watchProfile(String uid) =>
      _db.doc('users/$uid').snapshots().map((s) {
        final d = s.data();
        if (d == null) return null;
        return UserProfile(
          uid: uid,
          displayName: d['displayName'] as String? ?? '',
          email: d['email'] as String? ?? '',
          phone: d['phone'] as String?,
          activeBusinessId: d['activeBusinessId'] as String?,
          role: switch (d['role']) {
            'owner' => MemberRole.owner,
            'collaborator' => MemberRole.collaborator,
            _ => null,
          },
          createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
        );
      });

  @override
  Stream<Business?> watchBusiness(String businessId) =>
      _db.doc('businesses/$businessId').snapshots().map((s) {
        final d = s.data();
        if (d == null) return null;
        final plan = (d['plan'] as Map<String, dynamic>?) ?? const {};
        return Business(
          id: s.id,
          name: d['name'] as String? ?? '',
          ownerUid: d['ownerUid'] as String? ?? '',
          phone: d['phone'] as String? ?? '',
          department: d['department'] as String? ?? '',
          province: d['province'] as String? ?? '',
          planTier: plan['tier'] as String? ?? 'free',
          trialEndsAt: (plan['trialEndsAt'] as Timestamp?)?.toDate(),
        );
      });

  @override
  Future<Result<String>> createBusiness(CreateBusinessInput input) =>
      _call('createBusiness', input.toJson());

  @override
  Future<Result<String>> redeemInvite(String code) =>
      _call('redeemInvite', {'code': code.trim().toUpperCase()});

  Future<Result<String>> _call(String name, Map<String, Object> data) async {
    try {
      final res = await _functions
          .httpsCallable(name)
          .call<Map<String, dynamic>>(data);
      return Ok(res.data['businessId'] as String);
    } on FirebaseFunctionsException catch (e) {
      return Err(mapFunctionsException(e));
    } on FirebaseException catch (e) {
      return Err(BusinessFailure(BusinessErrorCode.unknown, e.code));
    }
  }
}

/// Las Functions devuelven en `details.reason` un código estable.
BusinessFailure mapFunctionsException(FirebaseFunctionsException e) {
  final reason =
      (e.details is Map ? (e.details as Map)['reason'] : null) as String?;
  final code = switch (reason) {
    'invite-invalid' => BusinessErrorCode.inviteInvalid,
    'invite-expired' => BusinessErrorCode.inviteExpired,
    'invite-used' => BusinessErrorCode.inviteUsed,
    'already-member' => BusinessErrorCode.alreadyMember,
    'email-not-verified' => BusinessErrorCode.emailNotVerified,
    'invalid-data' => BusinessErrorCode.invalidData,
    _ => switch (e.code) {
      'unavailable' || 'deadline-exceeded' => BusinessErrorCode.network,
      'invalid-argument' => BusinessErrorCode.invalidData,
      _ => BusinessErrorCode.unknown,
    },
  };
  return BusinessFailure(code, '${e.code}: ${e.message}');
}
