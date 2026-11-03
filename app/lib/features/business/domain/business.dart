import 'package:flutter/foundation.dart';
import 'package:vantia/app/router/session.dart';

/// Documento `users/{uid}`.
@immutable
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.phone,
    this.activeBusinessId,
    this.role,
    this.createdAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? phone;
  final String? activeBusinessId;
  final MemberRole? role;
  final DateTime? createdAt;

  bool get hasBusiness => activeBusinessId != null && role != null;
}

/// Documento `businesses/{bid}`.
@immutable
class Business {
  const Business({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.phone,
    required this.department,
    required this.province,
    this.planTier = 'free',
    this.trialEndsAt,
  });

  final String id;
  final String name;
  final String ownerUid;
  final String phone;
  final String department;
  final String province;
  final String planTier;
  final DateTime? trialEndsAt;

  String get location => '$department - $province';

  /// Iniciales para el avatar: "Vantia Perú" → "VP".
  String get initials => initialsOf(name);
}

String initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length.clamp(1, 2))
        .toUpperCase();
  }
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

@immutable
class CreateBusinessInput {
  const CreateBusinessInput({
    required this.name,
    required this.phone,
    required this.department,
    required this.province,
  });

  final String name;

  /// 9 dígitos, sin +51.
  final String phone;
  final String department;
  final String province;

  Map<String, Object> toJson() => {
    'name': name.trim(),
    'phone': phone,
    'department': department,
    'province': province.trim(),
  };
}
