import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vantia/app/router/routes.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/features/automation/application/automation_providers.dart';
import 'package:vantia/features/automation/application/receipt_providers.dart';
import 'package:vantia/features/automation/data/receipt_scanner.dart';
import 'package:vantia/features/payments/domain/payment.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';
import 'package:vantia/features/payments/presentation/payment_form_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

class FakeReceiptScanner implements ReceiptScanner {
  @override
  Future<PaymentPrefill?> scan(BuildContext context) async =>
      const PaymentPrefill(
        amount: Money(2500),
        operationNumber: '03456789',
        payerName: 'Rosa',
        source: PaymentSource.ocr,
        receiptFilePath: '/tmp/receipt.jpg',
        detectedMethod: PaymentMethod.yape,
      );
}

void main() {
  test('el id de una notificación es determinista', () {
    final a = notificationPaymentId(yapeNotification());
    expect(a, startsWith('n_'));
    expect(notificationPaymentId(yapeNotification()), a);
    expect(notificationPaymentId(yapeNotification(soles: 11)), isNot(a));
  });

  testWidgets(
    'con la verificación activa, la cola y los eventos crean pagos verificados (F-71)',
    (tester) async {
      final channel = FakeAutomationChannel(permission: true)
        ..queue.addAll([
          yapeNotification(),
          yapeNotification(), // duplicada
          yapeNotification(
            soles: 5,
            at: fixedNow.add(const Duration(minutes: 2)),
          ),
        ]);
      final payments = FakePaymentRepository(clock: () => fixedNow);
      await tester.pumpVantiaApp(
        automation: channel,
        payments: payments,
        prefs: {'pref.autoVerify': true},
      );
      await tester.pumpAndSettle();

      expect(payments.payments.length, 2);
      final p = payments.payments.values.firstWhere(
        (p) => p.amount == const Money(1000),
      );
      expect(p.method, PaymentMethod.yape);
      expect(p.source, PaymentSource.notification);
      expect(p.verified, isTrue);
      expect(p.id, startsWith('n_'));
      expect(channel.lastConfig, (enabled: true, voice: true));

      channel.emit(
        yapeNotification(
          soles: 7,
          at: fixedNow.add(const Duration(minutes: 5)),
        ),
      );
      await tester.pumpAndSettle();
      expect(payments.payments.length, 3);
      expect(find.text('S/ 22.00'), findsWidgets); // resumen de hoy
    },
  );

  testWidgets('desactivada no registra nada', (tester) async {
    final channel = FakeAutomationChannel(permission: true)
      ..queue.add(yapeNotification());
    final payments = FakePaymentRepository(clock: () => fixedNow);
    await tester.pumpVantiaApp(automation: channel, payments: payments);
    await tester.pumpAndSettle();
    expect(payments.payments, isEmpty);
    expect(channel.lastConfig?.enabled, isFalse);
  });

  testWidgets('pantalla de permisos: exige acceso antes de activar (F-73)', (
    tester,
  ) async {
    final channel = FakeAutomationChannel();
    final container = await tester.pumpVantiaApp(automation: channel);
    unawaited(
      GoRouter.of(
        tester.element(find.byType(Scaffold).first),
      ).push<void>(Routes.automation),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verificación automática'), findsOneWidget);
    expect(find.text('Pendiente'), findsWidgets);
    await tester.ensureVisible(find.text('Registrar cobros automáticamente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar cobros automáticamente'));
    await tester.pumpAndSettle();
    expect(
      find.text('Primero concede el acceso a notificaciones'),
      findsOneWidget,
    );
    expect(container.read(automationSettingsProvider).autoVerify, isFalse);

    await tester.ensureVisible(find.text('Abrir ajustes').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Abrir ajustes').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir ajustes').first);
    expect(channel.permissionOpened, 1);
    channel.permission = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Concedido'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Registrar cobros automáticamente'),
      100,
    );
    await tester.ensureVisible(find.text('Registrar cobros automáticamente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar cobros automáticamente'));
    await tester.pumpAndSettle();
    expect(container.read(automationSettingsProvider).autoVerify, isTrue);
  });

  testWidgets('escanear comprobante prellena y sube la imagen (F-70)', (
    tester,
  ) async {
    final payments = FakePaymentRepository(clock: () => fixedNow);
    final storage = FakeReceiptStorage();
    await tester.pumpVantiaApp(
      payments: payments,
      receipts: storage,
      extraOverrides: [
        receiptScannerProvider.overrideWithValue(FakeReceiptScanner()),
      ],
    );
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Yape'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escanear comprobante'));
    await tester.pumpAndSettle();

    expect(find.text('25.00'), findsOneWidget);
    expect(find.text('03456789'), findsOneWidget);
    final submit = find.widgetWithText(FilledButton, 'Registrar pago');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    final p = payments.payments.values.single;
    expect(
      (p.amount, p.source, p.operationNumber),
      (const Money(2500), PaymentSource.ocr, '03456789'),
    );
    expect(p.receiptPath, 'receipts/biz-demo/test.jpg');
    expect(storage.uploads, ['/tmp/receipt.jpg']);
  });
}
