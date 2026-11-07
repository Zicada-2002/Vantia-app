// Genera las capturas de docs/screenshots/ con los datos del modo demo.
// No corre en la suite normal. Uso:
//   flutter test test/screenshots --update-goldens --dart-define=SCREENSHOTS=true
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vantia/app/app.dart';
import 'package:vantia/app/bootstrap.dart';
import 'package:vantia/app/flavor.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/app_router.dart';
import 'package:vantia/app/router/routes.dart';
import 'package:vantia/app/theme/theme_mode_controller.dart';
import 'package:vantia/demo/demo_backend.dart';
import 'package:vantia/features/automation/application/automation_providers.dart';
import 'package:vantia/features/automation/data/automation_channel.dart';
import 'package:vantia/features/payments/application/payment_providers.dart';
import 'package:vantia/features/user/application/app_info.dart';

const _enabled = bool.fromEnvironment('SCREENSHOTS');

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    loader.addFont(File(p).readAsBytes().then((b) => ByteData.view(b.buffer)));
  }
  await loader.load();
}

Future<void> _shot(
  WidgetTester tester,
  String name, {
  String theme = 'dark',
  bool signIn = true,
  Future<void> Function(WidgetTester, ProviderContainer)? go,
}) async {
  SharedPreferences.setMockInitialValues({'pref.themeMode': theme});
  await initializeDateFormatting('es');
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(
        await SharedPreferences.getInstance(),
      ),
      flavorProvider.overrideWithValue(Flavor.demo),
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
  if (signIn) {
    await container
        .read(authRepositoryProvider)
        .signIn(email: demoEmail, password: demoPassword);
    await tester.pumpAndSettle();
  }
  if (go != null) {
    await go(tester, container);
    await tester.pumpAndSettle();
  }
  await expectLater(
    find.byType(VantiaApp),
    matchesGoldenFile('../../../docs/screenshots/$name.png'),
  );
}

Future<void> Function(WidgetTester, ProviderContainer) _push(String route) =>
    (tester, c) async {
      // Sin await: push devuelve un Future que termina al volver atrás.
      c.read(routerProvider).push<void>(route).ignore();
    };

Future<void> Function(WidgetTester, ProviderContainer) _tab(String label) =>
    (tester, c) async {
      await tester.tap(find.bySemanticsLabel(label));
    };

void main() {
  setUpAll(() async {
    final sdk = Platform.environment['FLUTTER_ROOT'] ?? '';
    await _loadFont('Poppins', [
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        'assets/fonts/Poppins-$w.ttf',
    ]);
    await _loadFont('MaterialIcons', [
      '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);
  });

  final cases = <String, Future<void> Function(WidgetTester)>{
    '01_login': (t) => _shot(t, '01_login', signIn: false),
    '02_inicio': (t) => _shot(t, '02_inicio'),
    '03_pagos': (t) => _shot(t, '03_pagos', go: _tab('Pagos')),
    '04_reportes': (t) => _shot(t, '04_reportes', go: _tab('Reportes')),
    '05_productos': (t) => _shot(t, '05_productos', go: _tab('Productos')),
    '06_medio_de_pago': (t) =>
        _shot(t, '06_medio_de_pago', go: _push(Routes.newPayment)),
    '07_pago_efectivo': (t) =>
        _shot(t, '07_pago_efectivo', go: _push(Routes.paymentForm('cash'))),
    '08_cuadre_caja': (t) =>
        _shot(t, '08_cuadre_caja', go: _push(Routes.cashRegister)),
    '09_colaboradores': (t) =>
        _shot(t, '09_colaboradores', go: _push(Routes.collaborators)),
    '10_ajustes': (t) => _shot(t, '10_ajustes', go: _push(Routes.settings)),
    '11_mi_cuenta': (t) => _shot(t, '11_mi_cuenta', go: _push(Routes.user)),
    '12_verificacion_automatica': (t) =>
        _shot(t, '12_verificacion_automatica', go: _push(Routes.automation)),
    '13_menu': (t) => _shot(
      t,
      '13_menu',
      go: (tester, _) => tester.tap(find.byIcon(Icons.menu)),
    ),
    '21_inicio_claro': (t) => _shot(t, '21_inicio_claro', theme: 'light'),
    '22_reportes_claro': (t) =>
        _shot(t, '22_reportes_claro', theme: 'light', go: _tab('Reportes')),
    '23_pagos_claro': (t) =>
        _shot(t, '23_pagos_claro', theme: 'light', go: _tab('Pagos')),
  };

  for (final e in cases.entries) {
    testWidgets(e.key, (t) => e.value(t), skip: !_enabled);
  }
}
