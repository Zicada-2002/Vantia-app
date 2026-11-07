import 'package:flutter_test/flutter_test.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/features/payments/application/payment_providers.dart';
import 'package:vantia/features/payments/domain/payment.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';
import 'package:vantia/features/payments/presentation/payments_screen.dart';

import '../helpers/fakes.dart';

void main() {
  group('PaymentDraft', () {
    PaymentDraft draft({
      PaymentMethod method = PaymentMethod.cash,
      int received = 5000,
      int change = 0,
      DateTime? at,
    }) => PaymentDraft(
      method: method,
      received: Money(received),
      change: Money(change),
      occurredAt: at ?? fixedNow,
    );

    test('efectivo: venta = recibido − cambio', () {
      expect(draft(change: 1250).net, const Money(3750));
    });

    test('digital: venta = monto', () {
      expect(draft(method: PaymentMethod.yape).net, const Money(5000));
    });

    test('validaciones', () {
      expect(
        draft(received: 0).validate(now: fixedNow),
        PaymentDraftError.amountRequired,
      );
      expect(
        draft(change: 5000).validate(now: fixedNow),
        PaymentDraftError.changeTooBig,
      );
      expect(
        draft(change: -1).validate(now: fixedNow),
        PaymentDraftError.changeInvalid,
      );
      expect(
        draft(method: PaymentMethod.plin, change: 100).validate(now: fixedNow),
        PaymentDraftError.changeInvalid,
      );
      expect(
        draft(
          at: fixedNow.add(const Duration(hours: 1)),
        ).validate(now: fixedNow),
        PaymentDraftError.futureDate,
      );
      expect(draft(change: 1000).validate(now: fixedNow), isNull);
    });
  });

  test('PaymentSummary separa efectivo y digital e ignora anulados', () {
    final s = PaymentSummary.of([
      fakePayment(id: 'a', cents: 1000),
      fakePayment(
        id: 'b',
        cents: 3750,
        method: PaymentMethod.cash,
        receivedCents: 5000,
        changeCents: 1250,
      ),
      Payment(
        id: 'c',
        method: PaymentMethod.bcp,
        amount: const Money(99999),
        occurredAt: fixedNow,
        createdBy: 'x',
        createdByName: 'x',
        status: PaymentStatus.voided,
      ),
    ]);
    expect(s.total, const Money(4750));
    expect(s.count, 2);
    expect(s.cash, const Money(3750));
    expect(s.digital, const Money(1000));
    expect(s.cashCount, 1);
    expect(s.digitalCount, 1);
    expect(s.cashReceived, const Money(5000));
    expect(s.changeGiven, const Money(1250));
    expect(s.byMethod[PaymentMethod.yape], const Money(1000));
    expect(s.byMethod.containsKey(PaymentMethod.bcp), isFalse);
  });

  group('canVoid', () {
    const owner = SessionReady(
      uid: 'o',
      businessId: 'b',
      role: MemberRole.owner,
    );
    const collab = SessionReady(
      uid: 'c',
      businessId: 'b',
      role: MemberRole.collaborator,
    );
    final mine = fakePayment(id: '1', cents: 100, createdBy: 'c');

    test('el dueño puede anular cualquiera', () {
      expect(
        canVoid(
          payment: mine,
          session: owner,
          now: fixedNow.add(const Duration(days: 3)),
        ),
        VoidPermission.allowed,
      );
    });

    test('el colaborador solo los suyos y dentro de 15 min', () {
      expect(
        canVoid(
          payment: mine,
          session: collab,
          now: fixedNow.add(const Duration(minutes: 14)),
        ),
        VoidPermission.allowed,
      );
      expect(
        canVoid(
          payment: mine,
          session: collab,
          now: fixedNow.add(const Duration(minutes: 16)),
        ),
        VoidPermission.windowExpired,
      );
      expect(
        canVoid(
          payment: fakePayment(id: '2', cents: 1),
          session: collab,
          now: fixedNow,
        ),
        VoidPermission.notOwnPayment,
      );
    });
  });

  test('groupByDay agrupa por día de Lima', () {
    final groups = groupByDay([
      fakePayment(
        id: '1',
        cents: 100,
        at: DateTime.utc(2026, 11, 3, 4, 59),
      ), // 2 nov 23:59
      fakePayment(
        id: '2',
        cents: 100,
        at: DateTime.utc(2026, 11, 2, 15),
      ), // 2 nov 10:00
      fakePayment(
        id: '3',
        cents: 100,
        at: DateTime.utc(2026, 11, 2, 4),
      ), // 1 nov 23:00
    ]);
    expect(groups.map((g) => g.dayKey), ['2026-11-02', '2026-11-01']);
    expect(groups.first.payments.length, 2);
  });
}
