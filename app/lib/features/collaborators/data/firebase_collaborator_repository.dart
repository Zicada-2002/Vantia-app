import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:vantia/app/router/session.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/features/business/data/firestore_business_repository.dart';
import 'package:vantia/features/collaborators/domain/collaborators.dart';

class FirebaseCollaboratorRepository implements CollaboratorRepository {
  FirebaseCollaboratorRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  @override
  Stream<List<Invite>> watchInvites(String businessId) => _db
      .collection('businesses/$businessId/invites')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            Invite(
              code: d.id,
              status:
                  InviteStatus.values.asNameMap()[d.data()['status']] ??
                  InviteStatus.active,
              expiresAt:
                  (d.data()['expiresAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
              createdAt: (d.data()['createdAt'] as Timestamp?)?.toDate(),
              usedBy: d.data()['usedBy'] as String?,
            ),
        ],
      );

  @override
  Stream<List<Member>> watchMembers(String businessId) => _db
      .collection('businesses/$businessId/members')
      .snapshots()
      .map(
        (s) => [
          for (final d in s.docs)
            Member(
              uid: d.id,
              displayName: d.data()['displayName'] as String? ?? '',
              role: d.data()['role'] == 'owner'
                  ? MemberRole.owner
                  : MemberRole.collaborator,
              active: d.data()['active'] as bool? ?? true,
              joinedAt: (d.data()['joinedAt'] as Timestamp?)?.toDate(),
            ),
        ]..sort((a, b) => a.role.index.compareTo(b.role.index)),
      );

  @override
  Future<Result<({String code, DateTime expiresAt})>> generateInvite() async {
    final r = await _call('generateInvite', const {});
    return r.map(
      (d) => (
        code: d['code'] as String,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(
          (d['expiresAt'] as num).toInt(),
        ),
      ),
    );
  }

  @override
  Future<Result<void>> revokeInvite(String code) async =>
      (await _call('revokeInvite', {'code': code})).map((_) {});

  @override
  Future<Result<void>> setMemberActive(
    String uid, {
    required bool active,
  }) async => (await _call('setMemberActive', {
    'uid': uid,
    'active': active,
  })).map((_) {});

  Future<Result<Map<String, dynamic>>> _call(
    String name,
    Map<String, Object> data,
  ) async {
    try {
      final res = await _functions
          .httpsCallable(name)
          .call<Map<String, dynamic>>(data);
      return Ok(res.data);
    } on FirebaseFunctionsException catch (e) {
      return Err(mapFunctionsException(e));
    }
  }
}
