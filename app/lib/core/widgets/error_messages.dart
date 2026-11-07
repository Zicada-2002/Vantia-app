import 'package:flutter/material.dart';
import 'package:vantia/core/result/failure.dart';
import 'package:vantia/core/validation/validators.dart';
import 'package:vantia/features/auth/domain/auth_failure.dart';
import 'package:vantia/features/business/domain/business_failure.dart';
import 'package:vantia/l10n/l10n.dart';

extension FieldErrorL10n on FieldError {
  String message(AppLocalizations l10n) => switch (this) {
    FieldError.required => l10n.errRequired,
    FieldError.invalidEmail => l10n.errInvalidEmail,
    FieldError.passwordTooShort => l10n.errPasswordTooShort,
    FieldError.passwordNeedsNumber => l10n.errPasswordNeedsNumber,
    FieldError.passwordsDontMatch => l10n.errPasswordsDontMatch,
    FieldError.invalidPhone => l10n.errInvalidPhone,
    FieldError.invalidInviteCode => l10n.errInvalidInviteCode,
    FieldError.tooShort => l10n.errTooShort,
  };
}

/// Adapta un validador de [Validators] a `FormFieldValidator`.
FormFieldValidator<String> validatorFor(
  BuildContext context,
  FieldError? Function(String?) validate,
) =>
    (v) => validate(v)?.message(context.l10n);

String failureMessage(AppLocalizations l10n, Failure failure) {
  return switch (failure) {
    AuthFailure(:final code) => switch (code) {
      AuthErrorCode.invalidCredentials => l10n.errAuthInvalidCredentials,
      AuthErrorCode.emailAlreadyInUse => l10n.errAuthEmailInUse,
      AuthErrorCode.weakPassword => l10n.errAuthWeakPassword,
      AuthErrorCode.invalidEmail => l10n.errAuthInvalidEmail,
      AuthErrorCode.userDisabled => l10n.errAuthUserDisabled,
      AuthErrorCode.tooManyRequests => l10n.errAuthTooManyRequests,
      AuthErrorCode.network => l10n.errNetwork,
      AuthErrorCode.requiresRecentLogin => l10n.errAuthRecentLogin,
      AuthErrorCode.unknown => l10n.errUnknown,
    },
    BusinessFailure(:final code) => switch (code) {
      BusinessErrorCode.inviteInvalid => l10n.errInviteInvalid,
      BusinessErrorCode.inviteExpired => l10n.errInviteExpired,
      BusinessErrorCode.inviteUsed => l10n.errInviteUsed,
      BusinessErrorCode.alreadyMember => l10n.errAlreadyMember,
      BusinessErrorCode.emailNotVerified => l10n.errEmailNotVerified,
      BusinessErrorCode.invalidData => l10n.errInvalidData,
      BusinessErrorCode.network => l10n.errNetwork,
      BusinessErrorCode.unknown => l10n.errUnknown,
    },
    NetworkFailure() => l10n.errNetwork,
    _ => l10n.errUnknown,
  };
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
