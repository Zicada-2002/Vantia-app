import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vantia/app/app.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/theme/theme_mode_controller.dart';
import 'package:vantia/demo/demo_backend.dart';
import 'package:vantia/features/automation/application/automation_providers.dart';
import 'package:vantia/features/automation/data/automation_channel.dart';
import 'package:vantia/features/payments/application/payment_providers.dart';
import 'package:vantia/features/user/application/app_info.dart';

/// El APK demo debe funcionar sin Firebase: login con la cuenta demo y datos.
void main() {
  testWidgets('modo demo: entrar, ver datos en Inicio, Pagos y Reportes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('es');
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        ...demoOverrides(),
        offlineProvider.overrideWith((ref) => Stream.value(false)),
        automationChannelProvider.overrideWithValue(
          const NoopAutomationChannel(),
        ),
        appInfoProvider.overrideWith(
          (ref) async => (version: '1.0.0', build: '1'),
        ),
      ],
    );
    addTearDown(container.dispose);
    tester.view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const VantiaApp()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Modo demo'), findsOneWidget);
    await tester.tap(find.text('Entrar a la demo'));
    await tester.pumpAndSettle();

    final session = container.read(sessionProvider);
    expect(session, isA<SessionReady>());
    expect((session as SessionReady).isOwner, isTrue);
    expect(find.text('INGRESOS DE HOY'), findsOneWidget);
    expect(find.text('Pago por Yape'), findsWidgets);

    await tester.tap(find.bySemanticsLabel('Reportes'));
    await tester.pumpAndSettle();
    expect(find.text('Esta semana'), findsOneWidget);
    expect(find.text('S/ 0.00'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Productos'));
    await tester.pumpAndSettle();
    expect(find.text('Gaseosa 500 ml'), findsOneWidget);
  });
}
