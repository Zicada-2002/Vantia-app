// F-90: flujo completo en un dispositivo/emulador con repositorios falsos
// (no requiere Firebase). Ejecutar:
//   flutter test integration_test --flavor dev
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/core/money/money.dart';

import '../test/helpers/fakes.dart';
import '../test/helpers/pump_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('registro → verificación → negocio → cobro → cierre de caja', (
    tester,
  ) async {
    final auth = FakeAuthRepository()..verifyOnNextReload = true;
    final business = FakeBusinessRepository();
    final payments = FakePaymentRepository(clock: () => fixedNow);
    final cash = FakeCashRepository(payments);
    final container = await tester.pumpVantiaApp(
      auth: auth,
      business: business,
      payments: payments,
      cash: cash,
    );

    Future<void> enter(String label, String text) async {
      final column = find.ancestor(
        of: find.text(label),
        matching: find.byType(Column),
      );
      await tester.enterText(
        find
            .descendant(of: column.first, matching: find.byType(TextFormField))
            .first,
        text,
      );
      await tester.pump();
    }

    Future<void> tapButton(String label) async {
      final b = find.widgetWithText(FilledButton, label).last;
      await tester.ensureVisible(b);
      await tester.pumpAndSettle();
      await tester.tap(b);
      await tester.pumpAndSettle();
    }

    // Registro.
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
    await enter('Nombre completo', 'Carlos Vásquez');
    await enter('Correo electrónico', 'carlos@vantia.pe');
    await enter('Contraseña', 'clave1234');
    await enter('Confirmar contraseña', 'clave1234');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tapButton('Crear cuenta');

    // Verificación.
    business.currentUid = 'uid-carlos@vantia.pe';
    await tester.tap(find.text('Ya verifiqué mi correo'));
    await tester.pumpAndSettle();

    // Negocio.
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dueño de negocio'));
    await tester.pumpAndSettle();
    await tapButton('Continuar');
    await enter('Nombre del negocio', 'Bodega Don Carlos');
    await enter('Celular', '987654321');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arequipa').last);
    await tester.pumpAndSettle();
    await tapButton('Crear negocio');
    expect(container.read(sessionProvider), isA<SessionReady>());

    // Cobro en efectivo.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Efectivo'));
    await tester.pumpAndSettle();
    await enter('Monto recibido', '50');
    await enter('Cambio', '10');
    await tapButton('Registrar pago');
    expect(payments.payments.values.single.amount, const Money(4000));

    // Cierre de caja.
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cuadre de caja'));
    await tester.pumpAndSettle();
    await enter('Fondo inicial', '0');
    await enter('Total contado', '40');
    await tapButton('Cerrar caja');
    await tapButton('Cerrar caja');
    expect(cash.sessions.values.single.difference, const Money.zero());
  });
}
