import 'package:flutter_test/flutter_test.dart';
import 'package:vantia/core/validation/validators.dart';
import 'package:vantia/features/business/domain/business.dart';

void main() {
  test('email', () {
    expect(Validators.email(''), FieldError.required);
    expect(Validators.email('a@b'), FieldError.invalidEmail);
    expect(Validators.email(' carlos@gmail.com '), isNull);
  });

  test('password: 8+ caracteres y un número', () {
    expect(Validators.password(''), FieldError.required);
    expect(Validators.password('abc1'), FieldError.passwordTooShort);
    expect(Validators.password('abcdefgh'), FieldError.passwordNeedsNumber);
    expect(Validators.password('abcdefg1'), isNull);
  });

  test('confirmPassword', () {
    expect(Validators.confirmPassword('x', 'y'), FieldError.passwordsDontMatch);
    expect(Validators.confirmPassword('abc', 'abc'), isNull);
  });

  test('phone peruano', () {
    expect(Validators.phone('987 654 321'), isNull);
    expect(Validators.phone('+51 987654321'), isNull);
    expect(Validators.phone('887654321'), FieldError.invalidPhone);
    expect(Validators.phone('98765432'), FieldError.invalidPhone);
    expect(Validators.normalizePhone('+51 987-654-321'), '987654321');
  });

  test('inviteCode sin caracteres ambiguos', () {
    expect(Validators.inviteCode('abc234'), isNull);
    expect(Validators.inviteCode('ABC10O'), FieldError.invalidInviteCode);
    expect(Validators.inviteCode('ABC23'), FieldError.invalidInviteCode);
  });

  test('maskEmail', () {
    expect(Validators.maskEmail('carlos@gmail.com'), 'c****s@gmail.com');
    expect(Validators.maskEmail('ab@x.pe'), 'a*@x.pe');
  });

  test('initialsOf', () {
    expect(initialsOf('Vantia Perú'), 'VP');
    expect(initialsOf('bodega'), 'BO');
    expect(initialsOf('  '), '?');
  });
}
