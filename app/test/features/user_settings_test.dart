import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/features/auth/domain/auth_user.dart';
import 'package:vantia/features/business/domain/business.dart';
import 'package:vantia/features/subscription/domain/plan.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

/// Desplaza la pantalla visible (la ruta superior) hasta [finder].
Future<void> scrollTo(WidgetTester t, Finder finder, double delta) =>
    t.scrollUntilVisible(
      finder,
      delta,
      scrollable: find.byType(Scrollable).last,
    );

Future<void> _openUser(WidgetTester t) async {
  // Pantalla alta: la sección de acciones queda visible sin desplazar.
  t.view.physicalSize = const Size(1080, 4200);
  await t.pumpAndSettle();
  await t.tap(find.byTooltip('Mi cuenta'));
  await t.pumpAndSettle();
}

Future<void> _openSettings(WidgetTester t) async {
  await t.tap(find.byIcon(Icons.menu));
  await t.pumpAndSettle();
  await t.tap(find.text('Ajustes'));
  await t.pumpAndSettle();
}

({FakeAuthRepository auth, FakeBusinessRepository business}) _repos({
  Business? biz,
}) {
  final auth = FakeAuthRepository(
    initial: const AuthUser(
      uid: 'uid-owner',
      email: 'owner@vantia.pe',
      emailVerified: true,
      displayName: 'Carlos',
    ),
  )..accounts['owner@vantia.pe'] = 'clave1234';
  final business = FakeBusinessRepository()
    ..currentUid = 'uid-owner'
    ..seedBusiness(biz ?? demoBusiness)
    ..seedProfile(
      UserProfile(
        uid: 'uid-owner',
        displayName: 'Carlos Vásquez',
        email: 'owner@vantia.pe',
        phone: '917926826',
        activeBusinessId: 'biz-demo',
        role: MemberRole.owner,
        createdAt: DateTime.utc(2026, 10, 1, 15),
      ),
    );
  return (auth: auth, business: business);
}

void main() {
  group('PlanStatus', () {
    test('prueba vigente, vencida y pro', () {
      final trial = PlanStatus.of(demoBusiness, fixedNow);
      expect(
        (trial.tier, trial.trialDaysLeft, trial.isPro),
        (PlanTier.trial, 7, true),
      );
      final expired = PlanStatus.of(
        demoBusiness,
        fixedNow.add(const Duration(days: 8)),
      );
      expect((expired.tier, expired.isPro), (PlanTier.free, false));
      expect(PlanStatus.of(freeBusiness, fixedNow).isPro, isFalse);
    });
  });

  testWidgets(
    'Usuario → Info muestra datos personales, negocio y cuenta (F-80)',
    (tester) async {
      final r = _repos();
      await tester.pumpVantiaApp(auth: r.auth, business: r.business);
      await _openUser(tester);

      expect(find.text('Información personal'), findsOneWidget);
      expect(find.text('Carlos Vásquez'), findsWidgets);
      expect(find.text('owner@vantia.pe'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      expect(find.text('917 926 826'), findsOneWidget);
      expect(find.text('Vantia Peru'), findsOneWidget);
      expect(find.text('Lima - Lima'), findsOneWidget);
      expect(find.text('Dueño'), findsOneWidget);
      expect(find.text('Plan: Prueba Pro'), findsOneWidget);
      expect(find.text('1 oct. 2026'), findsOneWidget);
      await scrollTo(tester, find.text('Versión 1.0.0 (1)'), 100);
    },
  );

  testWidgets('editar perfil y cambiar contraseña (F-81)', (tester) async {
    final r = _repos();
    await tester.pumpVantiaApp(auth: r.auth, business: r.business);
    await _openUser(tester);

    await scrollTo(tester, find.text('Editar perfil'), 100);
    await tester.tap(find.text('Editar perfil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Carlos V.');
    await tester.enterText(find.byType(TextFormField).last, '987 654 321');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(r.business.profileUpdates, [('Carlos V.', '987654321')]);
    expect(find.text('Perfil actualizado'), findsOneWidget);

    await scrollTo(tester, find.text('Cambiar contraseña'), 100);
    await tester.tap(find.text('Cambiar contraseña'));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(fields.at(0), 'incorrecta1');
    await tester.enterText(fields.at(1), 'nueva1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
    await tester.enterText(fields.at(0), 'clave1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(r.auth.passwordChanges, ['nueva1234']);
  });

  testWidgets('eliminar cuenta exige contraseña y escribir ELIMINAR (F-82)', (
    tester,
  ) async {
    final r = _repos();
    await tester.pumpVantiaApp(auth: r.auth, business: r.business);
    await _openUser(tester);
    await scrollTo(tester, find.text('Eliminar cuenta'), 100);
    await tester.tap(find.text('Eliminar cuenta'));
    await tester.pumpAndSettle();

    expect(find.textContaining('el negocio se cerrará'), findsOneWidget);
    final confirm = find.widgetWithText(
      FilledButton,
      'Eliminar definitivamente',
    );
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    final fields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(EditableText),
    );
    await tester.enterText(fields.at(0), 'clave1234');
    await tester.enterText(fields.at(1), 'ELIMINAR');
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(r.business.deleted, isTrue);
    expect(find.text('Bienvenido a Vantia'), findsOneWidget);
  });

  testWidgets(
    'Ajustes: perfil, plan con días de prueba, tema y legales (F-83, F-84)',
    (tester) async {
      final r = _repos();
      await tester.pumpVantiaApp(auth: r.auth, business: r.business);
      await _openSettings(tester);

      expect(find.text('Plan: Prueba Pro'), findsOneWidget);
      expect(find.text('Tu prueba gratis termina en 7 días.'), findsOneWidget);
      expect(find.text('Mejorar ahora'), findsOneWidget);
      await scrollTo(tester, find.text('Términos y condiciones'), 200);
      await tester.tap(find.text('Términos y condiciones'));
      await tester.pumpAndSettle();
      expect(find.textContaining('TÉRMINOS Y CONDICIONES'), findsOneWidget);
      await tester.tap(find.byType(BackButton).last);
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Versión de la app'), 200);
      expect(find.text('1.0.0'), findsOneWidget);
    },
  );

  testWidgets(
    'plan Free bloquea funciones Pro y el paywall compra (F-84, F-85)',
    (tester) async {
      final r = _repos(biz: freeBusiness);
      final subs = FakeSubscriptionService();
      await tester.pumpVantiaApp(
        auth: r.auth,
        business: r.business,
        subscriptions: subs,
      );
      await _openSettings(tester);

      expect(find.text('Plan: Free'), findsOneWidget);
      await scrollTo(tester, find.text('Notificaciones de pago'), 200);
      // La voz viene activa por defecto: apagar y volver a encender exige Pro.
      await tester.tap(find.text('Notificaciones de pago'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notificaciones de pago'));
      await tester.pumpAndSettle();
      expect(find.text('Función disponible en Vantia Pro'), findsOneWidget);

      await scrollTo(tester, find.text('Mejorar ahora'), -200);
      await tester.tap(find.text('Mejorar ahora').first);
      await tester.pumpAndSettle();
      expect(find.text('Vantia Pro'), findsOneWidget);
      await tester.tap(find.text('Anual · S/ 199.00'));
      await tester.pumpAndSettle();
      expect(subs.purchased, ['annual']);
      expect(find.text('¡Listo! Ya tienes Vantia Pro'), findsOneWidget);
    },
  );
}
