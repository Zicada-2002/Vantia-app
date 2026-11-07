import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vantia/app/theme/theme_mode_controller.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('arranca en Inicio y navega entre pestañas', (tester) async {
    await tester.pumpVantiaApp();

    expect(find.widgetWithText(AppBar, 'Inicio'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Pagos'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Todos mis pagos'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Productos'));
    await tester.pumpAndSettle();
    expect(find.text('Aún no has registrado productos'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Reportes'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Mis reportes'), findsOneWidget);
  });

  testWidgets('FAB abre el selector de medio de pago', (tester) async {
    await tester.pumpVantiaApp();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('¿Cómo pagó el cliente?'), findsOneWidget);
    expect(find.bySemanticsLabel('Yape'), findsOneWidget);
    expect(find.bySemanticsLabel('Efectivo'), findsOneWidget);
  });

  testWidgets('menú lateral lleva a Ajustes y el tema se persiste', (
    tester,
  ) async {
    final container = await tester.pumpVantiaApp();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('Cuadre de caja'), findsOneWidget);

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Ajustes'), findsOneWidget);

    await tester.tap(find.byTooltip('Claro'));
    await tester.pumpAndSettle();
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(
      container.read(sharedPreferencesProvider).getString('pref.themeMode'),
      'light',
    );
  });
}
