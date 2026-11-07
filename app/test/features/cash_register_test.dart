import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/features/cash_register/domain/cash_session.dart';
import 'package:vantia/features/payments/domain/payment.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Cuadre de caja'));
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester t, String label, String text) async {
  final column = find.ancestor(
    of: find.text(label),
    matching: find.byType(Column),
  );
  await t.enterText(
    find
        .descendant(of: column.first, matching: find.byType(TextFormField))
        .first,
    text,
  );
  await t.pump();
}

FakePaymentRepository _seeded() => FakePaymentRepository(clock: () => fixedNow)
  ..seed(
    fakePayment(
      id: 'c1',
      cents: 3750,
      method: PaymentMethod.cash,
      receivedCents: 5000,
      changeCents: 1250,
    ),
  )
  ..seed(fakePayment(id: 'y1', cents: 1000))
  ..seed(
    fakePayment(
      id: 'ana',
      cents: 2000,
      method: PaymentMethod.cash,
      receivedCents: 2000,
      changeCents: 0,
      createdBy: 'uid-ana',
      createdByName: 'Ana',
    ),
  );

void main() {
  test('CashCount: esperado y diferencia', () {
    final c = CashCount.from(
      PaymentSummary.of([
        fakePayment(
          id: 'a',
          cents: 3750,
          method: PaymentMethod.cash,
          receivedCents: 5000,
          changeCents: 1250,
        ),
      ]),
      opening: const Money(10000),
      counted: const Money(13500),
    );
    expect(c.expected, const Money(13750));
    expect(c.difference, const Money(-250));
  });

  testWidgets('mi caja: totales por método, diferencia y cierre (F-41…F-43)', (
    tester,
  ) async {
    final payments = _seeded();
    final cash = FakeCashRepository(payments);
    await tester.pumpVantiaApp(payments: payments, cash: cash);
    await _open(tester);

    expect(find.text('Viendo: 2 nov. 2026'), findsOneWidget);
    expect(find.text('Total de tu turno'), findsOneWidget);
    expect(find.text('S/ 47.50'), findsOneWidget); // solo lo mío
    expect(find.text('S/ 50.00'), findsOneWidget); // efectivo recibido
    expect(find.text('S/ 12.50'), findsOneWidget); // cambios

    final close = find.widgetWithText(FilledButton, 'Cerrar caja');
    expect(tester.widget<FilledButton>(close).onPressed, isNull);

    await _enter(tester, 'Fondo inicial', '100');
    await _enter(tester, 'Total contado', '135');
    expect(find.text('S/ 137.50'), findsOneWidget); // esperado
    expect(find.text('-S/ 2.50'), findsOneWidget);
    expect(find.text('Falta'), findsOneWidget);

    await tester.ensureVisible(close);
    await tester.pumpAndSettle();
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(find.text('¿Cerrar la caja?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar caja').last);
    await tester.pumpAndSettle();

    final s = cash.sessions.values.single;
    expect(s.status, CashStatus.closed);
    expect(s.difference, const Money(-250));
    expect(find.widgetWithText(FilledButton, 'Cerrar caja'), findsNothing);
    expect(find.textContaining('Caja cerrada el'), findsOneWidget);
    // El borrador se guardó automáticamente al escribir.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('resumen general y reabrir (F-44, F-45)', (tester) async {
    final payments = _seeded();
    final cash = FakeCashRepository(payments)
      ..seed(
        const CashSession(
          dayKey: '2026-11-02',
          uid: 'uid-ana',
          displayName: 'Ana',
          status: CashStatus.closed,
          difference: Money(500),
        ),
      );
    await tester.pumpVantiaApp(payments: payments, cash: cash);
    await _open(tester);

    await tester.tap(find.text('Mi caja (hoy)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resumen general (hoy)').last);
    await tester.pumpAndSettle();

    expect(find.text('Total del negocio'), findsOneWidget);
    expect(find.text('S/ 67.50'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(
      find.textContaining('Cerrada · Diferencia: S/ 5.00'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Reabrir caja'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Error de conteo');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reabrir caja'));
    await tester.pumpAndSettle();
    expect(cash.reopened, [('2026-11-02', 'uid-ana', 'Error de conteo')]);
    expect(find.text('Caja reabierta'), findsOneWidget);
  });
}
