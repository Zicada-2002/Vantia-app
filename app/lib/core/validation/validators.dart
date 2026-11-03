/// Validadores de formularios. Devuelven una clave de error (o `null` si es
/// válido); la UI la traduce con l10n. Puros y testeables.
enum FieldError {
  required,
  invalidEmail,
  passwordTooShort,
  passwordNeedsNumber,
  passwordsDontMatch,
  invalidPhone,
  invalidInviteCode,
  tooShort,
}

abstract final class Validators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final _phone = RegExp(r'^9\d{8}$');

  /// Alfabeto de códigos de invitación: sin 0/O/1/I/L para evitar confusión.
  static const inviteAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static final _invite = RegExp('^[$inviteAlphabet]{6}\$');

  static FieldError? required(String? v) =>
      (v == null || v.trim().isEmpty) ? FieldError.required : null;

  static FieldError? name(String? v) {
    if (required(v) != null) return FieldError.required;
    return v!.trim().length < 2 ? FieldError.tooShort : null;
  }

  static FieldError? email(String? v) {
    if (required(v) != null) return FieldError.required;
    return _email.hasMatch(v!.trim()) ? null : FieldError.invalidEmail;
  }

  /// Mínimo 8 caracteres y al menos un número.
  static FieldError? password(String? v) {
    if (v == null || v.isEmpty) return FieldError.required;
    if (v.length < 8) return FieldError.passwordTooShort;
    if (!v.contains(RegExp(r'\d'))) return FieldError.passwordNeedsNumber;
    return null;
  }

  static FieldError? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return FieldError.required;
    return v == original ? null : FieldError.passwordsDontMatch;
  }

  /// Celular peruano: 9 dígitos que empiezan con 9 (espacios permitidos).
  static FieldError? phone(String? v) {
    if (required(v) != null) return FieldError.required;
    return _phone.hasMatch(normalizePhone(v!)) ? null : FieldError.invalidPhone;
  }

  static String normalizePhone(String v) =>
      v.replaceAll(RegExp(r'[\s-]'), '').replaceFirst(RegExp(r'^\+?51'), '');

  static FieldError? inviteCode(String? v) {
    if (required(v) != null) return FieldError.required;
    return _invite.hasMatch(v!.trim().toUpperCase())
        ? null
        : FieldError.invalidInviteCode;
  }

  /// `carlos@gmail.com` → `c****s@gmail.com`
  static String maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 1) return email;
    final user = email.substring(0, at);
    final masked = user.length <= 2
        ? '${user[0]}*'
        : '${user[0]}${'*' * (user.length - 2)}${user[user.length - 1]}';
    return '$masked${email.substring(at)}';
  }
}
