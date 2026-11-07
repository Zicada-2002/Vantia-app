import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/features/auth/domain/auth_user.dart';
import 'package:vantia/features/business/domain/business.dart';
import 'package:vantia/features/payments/domain/payment.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

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
}

Future<void> _tapButton(WidgetTester t, String label) async {
  final b = find.widgetWithText(FilledButton, label);
  await t.ensureVisible(b);
  await t.tap(b);
  await t.pumpAndSettle();
}

void main() {
  testWidgets('Inicio muestra el resumen del día y los últimos pagos', (
    tester,
  ) async {
    final payments = FakePaymentRepository(clock: () => fixedNow)
      ..seed(fakePayment(id: 'p1', cents: 1000))
      ..seed(
        fakePayment(
          id: 'p2',
          cents: 3750,
          method: PaymentMethod.cash,
          receivedCents: 5000,
          changeCents: 1250,
          at: fixedNow.subtract(const Duration(minutes: 5)),
        ),
      )
      // Ayer: no suma en el resumen de hoy.
      ..seed(
        fakePayment(
          id: 'p0',
          cents: 50000,
          at: fixedNow.subtract(const Duration(days: 1)),
        ),
      );
    await tester.pumpVantiaApp(payments: payments);

    expect(find.text('INGRESOS DE HOY'), findsOneWidget);
    expect(find.text('S/ 47.50'), findsOneWidget); // total
    expect(find.text('S/ 37.50'), findsWidgets); // efectivo
    expect(find.text('2'), findsOneWidget); // nº de pagos
    expect(find.text('Pago por Yape'), findsWidgets);
    expect(find.text('Tú'), findsWidgets);
  });

  testWidgets('registrar pago en efectivo con cambio (F-21)', (tester) async {
    final payments = FakePaymentRepository(clock: () => fixedNow);
    await tester.pumpVantiaApp(payments: payments);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Efectivo'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar pago'), findsOneWidget);

    // Botón deshabilitado sin monto.
    final submit = find.widgetWithText(FilledButton, 'Registrar pago');
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await _enter(tester, 'Monto recibido', '50');
    await _enter(tester, 'Cambio', '12,50');
    await tester.pumpAndSettle();
    expect(find.text('S/ 37.50'), findsOneWidget); // venta registrada

    await _enter(tester, 'Descripción', 'Menú del día');
    await _tapButton(tester, 'Registrar pago');

    final saved = payments.payments.values.single;
    expect(saved.method, PaymentMethod.cash);
    expect(saved.amount, const Money(3750));
    expect(saved.received, const Money(5000));
    expect(saved.change, const Money(1250));
    expect(saved.description, 'Menú del día');
    expect(saved.createdBy, 'uid-owner');
    // Vuelve a Inicio y el resumen se actualiza.
    expect(find.text('INGRESOS DE HOY'), findsOneWidget);
    expect(find.text('S/ 37.50'), findsWidgets);
  });

  testWidgets('cambio mayor al monto muestra error y no registra', (
    tester,
  ) async {
    final payments = FakePaymentRepository(clock: () => fixedNow);
    await tester.pumpVantiaApp(payments: payments);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Efectivo'));
    await tester.pumpAndSettle();

    await _enter(tester, 'Monto recibido', '10');
    await _enter(tester, 'Cambio', '20');
    await tester.pumpAndSettle();
    await _tapButton(tester, 'Registrar pago');

    expect(
      find.text('El cambio debe ser menor al monto recibido'),
      findsOneWidget,
    );
    expect(payments.payments, isEmpty);
  });

  testWidgets('pago digital con nº de operación duplicado pide confirmación', (
    tester,
  ) async {
    final payments = FakePaymentRepository(clock: () => fixedNow)
      ..seed(
        Payment(
          id: 'old',
          method: PaymentMethod.plin,
          amount: const Money(2000),
          operationNumber: '123456',
          occurredAt: fixedNow.subtract(const Duration(hours: 1)),
          createdBy: 'uid-owner',
          createdByName: 'Carlos',
        ),
      );
    await tester.pumpVantiaApp(payments: payments);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Plin'));
    await tester.pumpAndSettle();

    expect(find.text('Cambio'), findsNothing);
    await _enter(tester, 'Monto', '20');
    await _enter(tester, 'Nº de operación', '123456');
    await tester.pumpAndSettle();
    await _tapButton(tester, 'Registrar pago');

    expect(find.text('¿Pago duplicado?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(payments.payments.length, 1);

    await _tapButton(tester, 'Registrar pago');
    await tester.tap(find.text('Registrar igual'));
    await tester.pumpAndSettle();
    expect(payments.payments.length, 2);
  });

  testWidgets('lista semanal agrupa por día y navega entre semanas', (
    tester,
  ) async {
    final payments = FakePaymentRepository(clock: () => fixedNow)
      ..seed(fakePayment(id: 'hoy', cents: 1000))
      ..seed(
        fakePayment(
          id: 'semana-pasada',
          cents: 2500,
          at: fixedNow.subtract(const Duration(days: 3)),
        ),
      );
    await tester.pumpVantiaApp(payments: payments);

    await tester.tap(find.bySemanticsLabel('Pagos'));
    await tester.pumpAndSettle();
    expect(find.text('2 nov - 8 nov'), findsOneWidget);
    expect(find.text('HOY, 2 NOV'), findsOneWidget);
    expect(find.text('S/ 10.00'), findsWidgets);
    // No se puede ir a semanas futuras.
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.arrow_forward_rounded),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byTooltip('Semana anterior'));
    await tester.pumpAndSettle();
    expect(find.text('26 oct - 1 nov'), findsOneWidget);
    expect(find.text('S/ 25.00'), findsWidgets);
  });

  testWidgets('dueño anula un pago con motivo (F-26)', (tester) async {
    final payments = FakePaymentRepository(clock: () => fixedNow)
      ..seed(fakePayment(id: 'p1', cents: 1000));
    await tester.pumpVantiaApp(payments: payments);

    await tester.tap(find.text('Pago por Yape'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle del pago'), findsOneWidget);

    await tester.tap(find.text('Anular pago'));
    await tester.pumpAndSettle();
    final confirm = find.widgetWithText(FilledButton, 'Anular');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await tester.enterText(find.byType(TextField).last, 'Registrado por error');
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(payments.payments['p1']!.status, PaymentStatus.voided);
    expect(find.text('Anulado'), findsOneWidget);
  });

  testWidgets('colaborador solo ve sus pagos y no anula pasados 15 min', (
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
      ..seedBusiness(demoBusiness)
      ..seedProfile(
        const UserProfile(
          uid: 'uid-ana',
          displayName: 'Ana',
          email: 'ana@vantia.pe',
          activeBusinessId: 'biz-demo',
          role: MemberRole.collaborator,
        ),
      );
    final payments = FakePaymentRepository(clock: () => fixedNow)
      ..seed(fakePayment(id: 'del-dueno', cents: 9900))
      ..seed(
        fakePayment(
          id: 'de-ana',
          cents: 1500,
          createdBy: 'uid-ana',
          createdByName: 'Ana',
          at: fixedNow.subtract(const Duration(minutes: 30)),
        ),
      );
    await tester.pumpVantiaApp(
      auth: auth,
      business: business,
      payments: payments,
    );

    expect(find.text('MIS INGRESOS DE HOY'), findsOneWidget);
    expect(find.text('S/ 15.00'), findsWidgets);
    expect(find.text('S/ 99.00'), findsNothing);

    await tester.tap(find.text('Pago por Yape'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anular pago'));
    await tester.pumpAndSettle();
    expect(
      find.text('Solo puedes anular tus pagos durante los primeros 15 minutos'),
      findsOneWidget,
    );
    expect(payments.payments['de-ana']!.isActive, isTrue);
  });
}
