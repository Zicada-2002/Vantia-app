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

  /// F-81: requieren re-autenticación con la contraseña actual.
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Envía un enlace al nuevo correo; el cambio aplica al confirmarlo.
  Future<Result<void>> changeEmail({
    required String currentPassword,
    required String newEmail,
  });

  Future<Result<void>> updateDisplayName(String name);

  /// Re-autentica (requerido antes de eliminar la cuenta).
  Future<Result<void>> reauthenticate(String password);
}
