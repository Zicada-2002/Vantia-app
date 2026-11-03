import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

/// F-91: guías de accesibilidad en las pantallas principales.
void main() {
  FakePaymentRepository seeded() => FakePaymentRepository(clock: () => fixedNow)
    ..seed(fakePayment(id: 'a', cents: 1000))
    ..seed(
      fakePayment(
        id: 'b',
        cents: 3750,
        method: PaymentMethod.cash,
        receivedCents: 5000,
        changeCents: 1250,
      ),
    );

  Future<void> checkGuidelines(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  for (final theme in ['dark', 'light']) {
    testWidgets('Inicio cumple tap targets, etiquetas y contraste ($theme)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpVantiaApp(
        payments: seeded(),
        prefs: {'pref.themeMode': theme},
      );
      await checkGuidelines(tester);
      handle.dispose();
    });
  }

  testWidgets('selector de medio de pago y formulario', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpVantiaApp();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await checkGuidelines(tester);
    await tester.tap(find.bySemanticsLabel('Efectivo'));
    await tester.pumpAndSettle();
    await checkGuidelines(tester);
    handle.dispose();
  });

  testWidgets('login cumple guías', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpVantiaApp(auth: FakeAuthRepository());
    await checkGuidelines(tester);
    handle.dispose();
  });

  testWidgets('letra al 130 % no desborda en las pestañas principales', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpVantiaApp(payments: seeded());
    for (final tab in ['Pagos', 'Productos', 'Reportes', 'Inicio']) {
      await tester.tap(find.bySemanticsLabel(tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Efectivo'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
