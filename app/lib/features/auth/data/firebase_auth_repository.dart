import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:vantia/core/result/failure.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/features/auth/domain/auth_failure.dart';
import 'package:vantia/features/auth/domain/auth_repository.dart';
import 'package:vantia/features/auth/domain/auth_user.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final fb.FirebaseAuth _auth;

  static AuthUser? _map(fb.User? u) => u == null
      ? null
      : AuthUser(
          uid: u.uid,
          email: u.email ?? '',
          emailVerified: u.emailVerified,
          displayName: u.displayName,
        );

  @override
  Stream<AuthUser?> userChanges() => _auth.userChanges().map(_map);

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<Result<void>> signUp({
    required String displayName,
    required String email,
    required String password,
  }) => _guard(() async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(displayName.trim());
    await _auth.setLanguageCode('es');
    await user.sendEmailVerification();
    await user.reload();
  });

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) => _guard(() async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  });

  @override
  Future<Result<void>> sendEmailVerification() => _guard(() async {
    await _auth.setLanguageCode('es');
    await _auth.currentUser?.sendEmailVerification();
  });

  @override
  Future<Result<AuthUser?>> reload() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return const Ok(null);
      await user.reload();
      final fresh = _auth.currentUser;
      if (fresh != null && fresh.emailVerified) {
        await fresh.getIdToken(true);
      }
      return Ok(_map(fresh));
    } on fb.FirebaseAuthException catch (e) {
      return Err(mapAuthException(e));
    }
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await _auth.setLanguageCode('es');
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const Ok(null);
    } on fb.FirebaseAuthException catch (e) {
      final failure = mapAuthException(e);
      // No revelar si el correo existe.
      return switch (failure.code) {
        AuthErrorCode.network ||
        AuthErrorCode.tooManyRequests ||
        AuthErrorCode.invalidEmail => Err(failure),
        _ => const Ok(null),
      };
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<Result<void>> reauthenticate(String password) => _guard(() async {
    final u = _auth.currentUser!;
    await u.reauthenticateWithCredential(
      fb.EmailAuthProvider.credential(email: u.email!, password: password),
    );
  });

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final r = await reauthenticate(currentPassword);
    if (r case Err()) return r;
    return await _guard(() => _auth.currentUser!.updatePassword(newPassword));
  }

  @override
  Future<Result<void>> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final r = await reauthenticate(currentPassword);
    if (r case Err()) return r;
    return await _guard(() async {
      await _auth.setLanguageCode('es');
      await _auth.currentUser!.verifyBeforeUpdateEmail(newEmail.trim());
    });
  }

  @override
  Future<Result<void>> updateDisplayName(String name) => _guard(() async {
    await _auth.currentUser?.updateDisplayName(name.trim());
    await _auth.currentUser?.reload();
  });

  Future<Result<void>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return const Ok(null);
    } on fb.FirebaseAuthException catch (e) {
      return Err(mapAuthException(e));
    } on Object catch (e) {
      return Err(UnexpectedFailure('$e', e));
    }
  }
}

/// Traduce los códigos de Firebase Auth a errores de dominio.
AuthFailure mapAuthException(fb.FirebaseAuthException e) {
  final code = switch (e.code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'INVALID_LOGIN_CREDENTIALS' => AuthErrorCode.invalidCredentials,
    'email-already-in-use' => AuthErrorCode.emailAlreadyInUse,
    'weak-password' => AuthErrorCode.weakPassword,
    'invalid-email' => AuthErrorCode.invalidEmail,
    'user-disabled' => AuthErrorCode.userDisabled,
    'too-many-requests' => AuthErrorCode.tooManyRequests,
    'network-request-failed' => AuthErrorCode.network,
    'requires-recent-login' => AuthErrorCode.requiresRecentLogin,
    _ => AuthErrorCode.unknown,
  };
  return AuthFailure(code, e.code);
}
