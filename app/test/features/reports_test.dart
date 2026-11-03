import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/features/export/export_flow.dart';
import 'package:vantia/features/export/payment_export.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';
import 'package:vantia/features/reports/domain/report.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

DailyStat stat(String day, int cents, {int cash = 0, int digital = 1}) =>
    DailyStat(
      dayKey: day,
      total: Money(cents),
      count: cash + digital,
      cashCount: cash,
      digitalCount: digital,
      byMethod: {
        if (digital > 0) PaymentMethod.yape: Money(cents ~/ 2),
        PaymentMethod.cash: Money(cents - (digital > 0 ? cents ~/ 2 : 0)),
      },
    );

void main() {
  final today = DateTime.utc(2026, 11, 2); // lunes

  group('DayRange', () {
    test('semana lunes a domingo y la anterior', () {
      final r = DayRange.current(ReportPeriod.week, DateTime.utc(2026, 11, 5));
      expect(r.startKey, '2026-11-02');
      expect(r.endKey, '2026-11-09');
      expect(r.previous(ReportPeriod.week).startKey, '2026-10-26');
    });

    test('mes y año', () {
      final m = DayRange.current(ReportPeriod.month, today);
      expect((m.startKey, m.endKey), ('2026-11-01', '2026-12-01'));
      expect(m.previous(ReportPeriod.month).startKey, '2026-10-01');
      final y = DayRange.current(ReportPeriod.year, today);
      expect((y.startKey, y.endKey), ('2026-01-01', '2027-01-01'));
    });
  });

  test('Report.build: buckets, mejor día, variación y KPIs', () {
    final r = Report.build(ReportPeriod.week, DateTime.utc(2026, 11, 4), [
      stat('2026-11-02', 1000),
      stat('2026-11-04', 3000, cash: 2),
      stat('2026-10-28', 2000), // semana anterior
    ]);
    expect(r.buckets.map((b) => b.label), [
      'Lun',
      'Mar',
      'Mié',
      'Jue',
      'Vie',
      'Sáb',
      'Dom',
    ]);
    expect(r.buckets[0].total, const Money(1000));
    expect(r.buckets[2].total, const Money(3000));
    expect(r.total, const Money(4000));
    expect(r.previousTotal, const Money(2000));
    expect(r.changePercent, 100);
    expect(r.best?.label, 'Mié');
    expect(r.cashCount, 2);
    expect(r.digitalCount, 2);
    expect(r.averageTicket, const Money(1000));
    final shares = r.methodShares;
    expect(shares.map((s) => s.$3).reduce((a, b) => a + b), closeTo(100, 0.01));
    expect(shares.first.$2 >= shares.last.$2, isTrue);
  });

  test('Report.build mes agrupa por semanas y año por meses', () {
    final m = Report.build(ReportPeriod.month, today, [
      stat('2026-11-01', 100),
      stat('2026-11-08', 200),
      stat('2026-11-30', 300),
    ]);
    expect(m.buckets.length, 5);
    expect(m.buckets.map((b) => b.total.cents), [100, 200, 0, 0, 300]);
    final y = Report.build(ReportPeriod.year, today, [stat('2026-03-15', 500)]);
    expect(y.buckets[2].total, const Money(500));
    expect(y.best?.label, 'Mar');
  });

  test('PaymentExport genera xlsx legible y pdf', () async {
    final payments = [
      fakePayment(
        id: 'a',
        cents: 3750,
        method: PaymentMethod.cash,
        receivedCents: 5000,
        changeCents: 1250,
      ),
      fakePayment(id: 'b', cents: 1000),
    ];
    final bytes = PaymentExport.xlsx(payments, title: 'Pagos');
    final sheet = Excel.decodeBytes(bytes)['Pagos'];
    expect(sheet.rows[1].first?.value.toString(), 'Fecha');
    expect(sheet.rows[2][2]?.value.toString(), 'Efectivo');
    expect(sheet.rows.length, 5); // título + cabecera + 2 + total
    final pdf = await PaymentExport.pdf(
      payments,
      title: 'Pagos',
      businessName: 'Bodega',
    );
    expect(String.fromCharCodes(pdf.take(5)), '%PDF-');
  });

  testWidgets('pestaña Reportes muestra total, KPIs y métodos (F-51…F-53)', (
    tester,
  ) async {
    await tester.pumpVantiaApp(
      reports: FakeReportsRepository([stat('2026-11-02', 1000)]),
    );
    await tester.tap(find.bySemanticsLabel('Reportes'));
    await tester.pumpAndSettle();

    expect(find.text('Esta semana'), findsOneWidget);
    expect(find.text('S/ 10.00'), findsWidgets);
    expect(find.text('Lun'), findsWidgets); // mejor día + eje
    await tester.tap(find.text('Año'));
    await tester.pumpAndSettle();
    expect(find.text('Este año'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Métodos de pago'), 200);
    await tester.scrollUntilVisible(find.text('Yape'), 100);
    expect(find.text('50 %'), findsWidgets);
  });

  testWidgets('exportar pagos a Excel (F-54)', (tester) async {
    final shared = <(String, Uint8List)>[];
    final payments = FakePaymentRepository(clock: () => fixedNow)
      ..seed(fakePayment(id: 'a', cents: 1000));
    await tester.pumpVantiaApp(
      payments: payments,
      extraOverrides: [
        fileSharerProvider.overrideWithValue((
          bytes,
          name,
          mime,
          subject,
        ) async {
          shared.add((name, bytes));
        }),
        rangePickerProvider.overrideWithValue(
          (_, today) async => DateTimeRange(start: today, end: today),
        ),
      ],
    );
    await tester.tap(find.bySemanticsLabel('Pagos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Exportar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excel (.xlsx)'));
    await tester.pumpAndSettle();

    expect(shared.single.$1, 'vantia_pagos_2026-11-02_a_2026-11-02.xlsx');
    final sheet = Excel.decodeBytes(shared.single.$2)['Pagos'];
    expect(double.parse(sheet.rows[2][3]!.value.toString()), 10);
  });

  testWidgets('el colaborador no ve reportes', (tester) async {
    await tester.pumpVantiaApp(
      business: collaboratorBusiness(),
      auth: collaboratorAuth(),
    );
    await tester.tap(find.bySemanticsLabel('Reportes'));
    await tester.pumpAndSettle();
    expect(
      find.text('Solo el dueño del negocio puede ver los reportes.'),
      findsOneWidget,
    );
  });
}
