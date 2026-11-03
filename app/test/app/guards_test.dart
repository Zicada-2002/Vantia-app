import 'package:flutter_test/flutter_test.dart';
import 'package:vantia/app/router/guards.dart';
import 'package:vantia/app/router/routes.dart';
import 'package:vantia/app/router/session.dart';

void main() {
  const owner = SessionReady(role: MemberRole.owner);
  const collaborator = SessionReady(role: MemberRole.collaborator);

  test('cargando → splash', () {
    expect(resolveRedirect(const SessionLoading(), Routes.home), Routes.splash);
    expect(resolveRedirect(const SessionLoading(), Routes.splash), isNull);
  });

  test('sin sesión → login, salvo rutas de auth', () {
    expect(resolveRedirect(const SignedOut(), Routes.home), Routes.login);
    expect(resolveRedirect(const SignedOut(), Routes.register), isNull);
    expect(resolveRedirect(const SignedOut(), Routes.forgotPassword), isNull);
  });

  test('correo sin verificar → verify-email en cualquier ruta', () {
    for (final r in [Routes.home, Routes.login, Routes.onboardingRole]) {
      expect(resolveRedirect(const EmailUnverified(), r), Routes.verifyEmail);
    }
    expect(
      resolveRedirect(const EmailUnverified(), Routes.verifyEmail),
      isNull,
    );
  });

  test('sin negocio → onboarding', () {
    expect(
      resolveRedirect(const NoBusiness(), Routes.home),
      Routes.onboardingRole,
    );
    expect(resolveRedirect(const NoBusiness(), Routes.onboardingJoin), isNull);
  });

  test('lista: sale de auth/onboarding hacia home', () {
    expect(resolveRedirect(owner, Routes.login), Routes.home);
    expect(resolveRedirect(owner, Routes.verifyEmail), Routes.home);
    expect(resolveRedirect(owner, Routes.onboardingRole), Routes.home);
    expect(resolveRedirect(owner, Routes.payments), isNull);
  });

  test('colaborador no accede a rutas solo de dueño', () {
    expect(resolveRedirect(collaborator, Routes.collaborators), Routes.home);
    expect(resolveRedirect(collaborator, Routes.reports), Routes.home);
    expect(resolveRedirect(collaborator, Routes.cashRegister), isNull);
    expect(resolveRedirect(owner, Routes.collaborators), isNull);
  });

  test('ignora query params al evaluar', () {
    expect(
      resolveRedirect(const SignedOut(), '${Routes.login}?from=x'),
      isNull,
    );
  });
}
