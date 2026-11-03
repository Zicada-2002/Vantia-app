import 'package:flutter/foundation.dart';

@immutable
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    required this.emailVerified,
    this.displayName,
  });

  final String uid;
  final String email;
  final bool emailVerified;
  final String? displayName;

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.uid == uid &&
      other.email == email &&
      other.emailVerified == emailVerified &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(uid, email, emailVerified, displayName);
}
