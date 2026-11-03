import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/features/automation/domain/parsers.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';

RawNotification fixture(String name) {
  final lines = File('test/fixtures/notifications/$name').readAsLinesSync();
  return RawNotification(
    packageName: lines[0],
    title: lines[1],
    text: lines.skip(2).join('\n'),
    postedAt: DateTime.utc(2026, 11, 3, 2, 46),
  );
}

void main() {
  group('NotificationParser', () {
    test('Yape básico', () {
      final p = NotificationParser.parse(fixture('yape_basic.txt'))!;
      expect(p.method, PaymentMethod.yape);
      expect(p.amount, const Money(1000));
      expect(p.payerName, 'Juan Pérez');
      expect(p.occurredAt, DateTime.utc(2026, 11, 3, 2, 46));
    });

    test('Yape con miles y decimales', () {
      final p = NotificationParser.parse(fixture('yape_thousands.txt'))!;
      expect(p.amount, const Money(125050));
      expect(p.payerName, 'MARIA L. ROJAS');
    });

    test('Plin desde Interbank y BBVA', () {
      final a = NotificationParser.parse(fixture('plin_interbank.txt'))!;
      expect(
        (a.method, a.amount, a.payerName),
        (PaymentMethod.plin, const Money(2000), 'CARLOS QUISPE'),
      );
      final b = NotificationParser.parse(fixture('plin_bbva.txt'))!;
      expect((b.amount, b.payerName), (const Money(3590), 'Ana Torres'));
    });

    test('ignora promociones y apps desconocidas', () {
      expect(NotificationParser.parse(fixture('yape_promo.txt')), isNull);
      expect(
        NotificationParser.parse(
          RawNotification(
            packageName: 'com.whatsapp',
            title: 'x',
            text: 'Juan te envió un pago por S/ 10',
            postedAt: DateTime(2026),
          ),
        ),
        isNull,
      );
    });
  });

  group('ReceiptParser', () {
    test('comprobante de Yape', () {
      final r = ReceiptParser.parse(
        File('test/fixtures/receipts/yape_receipt.txt').readAsStringSync(),
        limaYear: 2026,
      );
      expect(r.method, PaymentMethod.yape);
      expect(r.amount, const Money(2500));
      expect(r.operationNumber, '03456789');
      expect(r.payerName, 'Vantia Peru');
      expect(r.limaDateTime, DateTime.utc(2026, 11, 2, 21, 45));
    });

    test('comprobante de Plin con fecha numérica', () {
      final r = ReceiptParser.parse(
        File('test/fixtures/receipts/plin_receipt.txt').readAsStringSync(),
        limaYear: 2026,
      );
      expect(r.method, PaymentMethod.plin);
      expect(r.amount, const Money(12000));
      expect(r.operationNumber, '12345678');
      expect(r.payerName, 'Bodega Don Carlos');
      expect(r.limaDateTime, DateTime.utc(2026, 11, 2, 14, 30));
    });

    test('texto sin datos', () {
      final r = ReceiptParser.parse('hola', limaYear: 2026);
      expect((r.amount, r.operationNumber, r.limaDateTime), (null, null, null));
    });
  });
}
