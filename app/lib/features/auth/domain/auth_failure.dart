import 'package:vantia/core/result/failure.dart';

enum AuthErrorCode {
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,
  invalidEmail,
  userDisabled,
  tooManyRequests,
  network,
  requiresRecentLogin,
  unknown,
}

class AuthFailure extends Failure {
  const AuthFailure(this.code, [String message = '']) : super(message);

  final AuthErrorCode code;
}
