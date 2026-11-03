import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vantia/app/app.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/theme/theme_mode_controller.dart';
import 'package:vantia/core/time/clock.dart';
import 'package:vantia/features/auth/domain/auth_repository.dart';
import 'package:vantia/features/business/domain/business_repository.dart';
import 'package:vantia/features/payments/application/payment_providers.dart';
import 'package:vantia/features/payments/domain/payment_repository.dart';

import 'fakes.dart';

extension PumpApp on WidgetTester {
  /// Monta la app completa con repositorios falsos. Por defecto, un dueño
  /// logueado con negocio.
  Future<ProviderContainer> pumpVantiaApp({
    AuthRepository? auth,
    BusinessRepository? business,
    PaymentRepository? payments,
    DateTime? now,
    Map<String, Object> prefs = const {},
    List<Override> extraOverrides = const [],
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    await initializeDateFormatting('es');
    final defaults = readyOwnerRepos();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        authRepositoryProvider.overrideWithValue(auth ?? defaults.auth),
        businessRepositoryProvider.overrideWithValue(
          business ?? defaults.business,
        ),
        paymentRepositoryProvider.overrideWithValue(
          payments ?? FakePaymentRepository(clock: () => now ?? fixedNow),
        ),
        clockProvider.overrideWithValue(() => now ?? fixedNow),
        offlineProvider.overrideWith((ref) => Stream.value(false)),
        ...extraOverrides,
      ],
    );
    addTearDown(container.dispose);
    view
      ..physicalSize = const Size(1080, 2340)
      ..devicePixelRatio = 3;
    addTearDown(view.reset);
    await pumpWidget(
      UncontrolledProviderScope(container: container, child: const VantiaApp()),
    );
    await pumpAndSettle();
    return container;
  }
}
