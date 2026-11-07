import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/features/auth/domain/auth_user.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

/// Escribe en el campo cuyo rótulo superior es [label].
Future<void> _enter(WidgetTester t, String label, String text) async {
  final column = find.ancestor(
    of: find.text(label),
    matching: find.byType(Column),
  );
  final field = find.descendant(
    of: column.first,
    matching: find.byType(TextFormField),
  );
  await t.enterText(field.first, text);
}

void main() {
  testWidgets('sin sesión arranca en login', (tester) async {
    await tester.pumpVantiaApp(auth: FakeAuthRepository());
    expect(find.text('Bienvenido a Vantia'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Ingresar'), findsOneWidget);
  });

  testWidgets('login con credenciales inválidas muestra error en español', (
    tester,
  ) async {
    final auth = FakeAuthRepository()..accounts['a@b.pe'] = 'secreto123';
    await tester.pumpVantiaApp(auth: auth, business: FakeBusinessRepository());

    await _enter(tester, 'Correo electrónico', 'a@b.pe');
    await _enter(tester, 'Contraseña', 'otraclave1');
    await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
  });

  testWidgets('login valida campos antes de llamar al backend', (tester) async {
    await tester.pumpVantiaApp(auth: FakeAuthRepository());
    await _enter(tester, 'Correo electrónico', 'no-es-correo');
    await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa un correo válido'), findsOneWidget);
    expect(find.text('Este campo es obligatorio'), findsOneWidget);
  });

  testWidgets(
    'registro → verificación de correo → rol → crear negocio → Inicio',
    (tester) async {
      final auth = FakeAuthRepository();
      final business = FakeBusinessRepository();
      final container = await tester.pumpVantiaApp(
        auth: auth,
        business: business,
      );

      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Crea tu cuenta'), findsOneWidget);

      await _enter(tester, 'Nombre completo', 'Carlos Vásquez');
      await _enter(tester, 'Correo electrónico', 'carlos@vantia.pe');
      await _enter(tester, 'Contraseña', 'clave1234');
      await _enter(tester, 'Confirmar contraseña', 'clave1234');

      // Sin aceptar términos no avanza.
      final submit = find.widgetWithText(FilledButton, 'Crear cuenta');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        find.text('Debes aceptar los términos para continuar'),
        findsOneWidget,
      );
      expect(auth.accounts, isEmpty);

      await tester.tap(find.byType(Checkbox));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      // Bloqueado en verificación.
      expect(find.text('Revisa tu correo'), findsOneWidget);
      expect(find.textContaining('c****s@vantia.pe'), findsOneWidget);
      expect(auth.verificationEmailsSent, 1);
      expect(container.read(sessionProvider), isA<EmailUnverified>());

      // Reenviar está en cooldown.
      expect(find.textContaining('Reenviar en'), findsOneWidget);

      // "Ya verifiqué" sin haber verificado.
      await tester.tap(find.text('Ya verifiqué mi correo'));
      await tester.pumpAndSettle();
      expect(find.textContaining('aún no está verificado'), findsOneWidget);

      // Verifica y vuelve a revisar.
      auth.verifyOnNextReload = true;
      business.currentUid = 'uid-carlos@vantia.pe';
      await tester.tap(find.text('Ya verifiqué mi correo'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cómo usarás la aplicación?'), findsOneWidget);

      // Continuar deshabilitado hasta elegir.
      final continueBtn = find.widgetWithText(FilledButton, 'Continuar');
      expect(tester.widget<FilledButton>(continueBtn).onPressed, isNull);
      await tester.tap(find.text('Dueño de negocio'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(continueBtn);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();
      expect(find.text('Datos de tu negocio'), findsOneWidget);

      await _enter(tester, 'Nombre del negocio', 'Bodega Don Carlos');
      await _enter(tester, 'Celular', '987 654 321');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arequipa').last);
      await tester.pumpAndSettle();
      final create = find.widgetWithText(FilledButton, 'Crear negocio');
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();

      final session = container.read(sessionProvider);
      expect(session, isA<SessionReady>());
      expect((session as SessionReady).role, MemberRole.owner);
      expect(find.widgetWithText(AppBar, 'Inicio'), findsOneWidget);
      expect(find.text('BD'), findsOneWidget); // iniciales en el avatar
    },
  );

  testWidgets('colaborador se une con código; código inválido da error', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      initial: const AuthUser(
        uid: 'uid-ana',
        email: 'ana@vantia.pe',
        emailVerified: true,
      ),
    );
    final business = FakeBusinessRepository()
      ..currentUid = 'uid-ana'
      ..seedBusiness(demoBusiness)
      ..invites['ABC234'] = 'biz-demo';
    final container = await tester.pumpVantiaApp(
      auth: auth,
      business: business,
    );

    await tester.tap(find.text('Colaborador'));
    await tester.pumpAndSettle();
    final continueBtn = find.widgetWithText(FilledButton, 'Continuar');
    await tester.ensureVisible(continueBtn);
    await tester.tap(continueBtn);
    await tester.pumpAndSettle();
    expect(find.text('Únete a un negocio'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'zzz999');
    await tester.tap(find.widgetWithText(FilledButton, 'Unirme'));
    await tester.pumpAndSettle();
    expect(find.text('El código no existe o fue revocado'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'abc234');
    await tester.tap(find.widgetWithText(FilledButton, 'Unirme'));
    await tester.pumpAndSettle();

    final session = container.read(sessionProvider) as SessionReady;
    expect(session.role, MemberRole.collaborator);
    // El colaborador no ve "Colaboradores" en el menú.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('Colaboradores'), findsNothing);
    expect(find.text('Vantia Peru'), findsOneWidget);
  });

  testWidgets('recuperar contraseña muestra mensaje genérico', (tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpVantiaApp(auth: auth);

    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'quien@sea.pe');
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar enlace'));
    await tester.pumpAndSettle();

    expect(auth.passwordResets, ['quien@sea.pe']);
    expect(find.textContaining('Si existe una cuenta'), findsOneWidget);
  });

  testWidgets('cerrar sesión pide confirmación y vuelve a login', (
    tester,
  ) async {
    final container = await tester.pumpVantiaApp();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('917 926 826'), findsOneWidget);
    expect(find.text('Lima - Lima'), findsOneWidget);

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cerrar sesión?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(container.read(sessionProvider), isA<SignedOut>());
    expect(find.text('Bienvenido a Vantia'), findsOneWidget);
  });
}
