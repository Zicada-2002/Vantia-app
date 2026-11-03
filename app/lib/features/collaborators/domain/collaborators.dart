import 'package:flutter/foundation.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/core/result/result.dart';

enum InviteStatus { active, used, revoked, expired }

@immutable
class Invite {
  const Invite({
    required this.code,
    required this.status,
    required this.expiresAt,
    this.createdAt,
    this.usedBy,
  });

  final String code;
  final InviteStatus status;
  final DateTime expiresAt;
  final DateTime? createdAt;
  final String? usedBy;

  /// Estado considerando el vencimiento (el servidor no lo marca solo).
  InviteStatus effectiveStatus(DateTime now) =>
      status == InviteStatus.active && expiresAt.isBefore(now)
      ? InviteStatus.expired
      : status;
}

@immutable
class Member {
  const Member({
    required this.uid,
    required this.displayName,
    required this.role,
    required this.active,
    this.joinedAt,
  });

  final String uid;
  final String displayName;
  final MemberRole role;
  final bool active;
  final DateTime? joinedAt;
}

abstract interface class CollaboratorRepository {
  Stream<List<Invite>> watchInvites(String businessId);

  Stream<List<Member>> watchMembers(String businessId);

  Future<Result<({String code, DateTime expiresAt})>> generateInvite();

  Future<Result<void>> revokeInvite(String code);

  Future<Result<void>> setMemberActive(String uid, {required bool active});
}
