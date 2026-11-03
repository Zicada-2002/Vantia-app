import 'package:vantia/core/result/result.dart';
import 'package:vantia/features/auth/domain/auth_user.dart';

abstract interface class AuthRepository {
  /// Emite en login/logout y también al recargar el usuario (p. ej. cuando
  /// el correo pasa a verificado).
  Stream<AuthUser?> userChanges();

  AuthUser? get currentUser;

  /// Crea la cuenta y envía el correo de verificación.
  Future<Result<void>> signUp({
    required String displayName,
    required String email,
    required String password,
  });

  Future<Result<void>> signIn({
    required String email,
    required String password,
  });

  Future<Result<void>> sendEmailVerification();

  /// Recarga el usuario desde el servidor y refresca el token (para que las
  /// reglas vean `email_verified`). Devuelve el usuario actualizado.
  Future<Result<AuthUser?>> reload();

  /// Siempre termina "bien" para el usuario: no revela si la cuenta existe.
  Future<Result<void>> sendPasswordReset(String email);

  Future<void> signOut();
}
