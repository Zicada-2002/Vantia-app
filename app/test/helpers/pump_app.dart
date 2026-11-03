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
import 'package:vantia/features/automation/application/automation_providers.dart';
import 'package:vantia/features/automation/application/receipt_providers.dart';
import 'package:vantia/features/automation/data/automation_channel.dart';
import 'package:vantia/features/automation/data/receipt_scanner.dart';
import 'package:vantia/features/business/domain/business_repository.dart';
import 'package:vantia/features/cash_register/application/cash_providers.dart';
import 'package:vantia/features/cash_register/domain/cash_session.dart';
import 'package:vantia/features/collaborators/application/collaborator_providers.dart';
import 'package:vantia/features/collaborators/domain/collaborators.dart';
import 'package:vantia/features/notifications/push_service.dart';
import 'package:vantia/features/payments/application/payment_providers.dart';
import 'package:vantia/features/payments/domain/payment_repository.dart';
import 'package:vantia/features/products/application/product_providers.dart';
import 'package:vantia/features/products/domain/product.dart';
import 'package:vantia/features/reports/application/report_providers.dart';
import 'package:vantia/features/reports/data/reports_repository.dart';
import 'package:vantia/features/settings/presentation/settings_screen.dart';
import 'package:vantia/features/subscription/application/plan_providers.dart';
import 'package:vantia/features/subscription/data/subscription_service.dart';
import 'package:vantia/features/user/application/app_info.dart';

import 'fakes.dart';

extension PumpApp on WidgetTester {
  /// Monta la app completa con repositorios falsos. Por defecto, un dueño
  /// logueado con negocio.
  Future<ProviderContainer> pumpVantiaApp({
    AuthRepository? auth,
    BusinessRepository? business,
    PaymentRepository? payments,
    CollaboratorRepository? collaborators,
    CashRepository? cash,
    ReportsRepository? reports,
    ProductRepository? products,
    Future<String?> Function()? scan,
    AutomationChannel? automation,
    ReceiptStorage? receipts,
    SubscriptionService? subscriptions,
    DateTime? now,
    Map<String, Object> prefs = const {},
    List<Override> extraOverrides = const [],
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    await initializeDateFormatting('es');
    final defaults = readyOwnerRepos();
    final paymentRepo =
        payments ?? FakePaymentRepository(clock: () => now ?? fixedNow);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        authRepositoryProvider.overrideWithValue(auth ?? defaults.auth),
        businessRepositoryProvider.overrideWithValue(
          business ?? defaults.business,
        ),
        paymentRepositoryProvider.overrideWithValue(paymentRepo),
        cashRepositoryProvider.overrideWithValue(
          cash ??
              FakeCashRepository(
                paymentRepo is FakePaymentRepository
                    ? paymentRepo
                    : FakePaymentRepository(),
              ),
        ),
        clockProvider.overrideWithValue(() => now ?? fixedNow),
        offlineProvider.overrideWith((ref) => Stream.value(false)),
        pushServiceProvider.overrideWithValue(const NoopPushService()),
        collaboratorRepositoryProvider.overrideWithValue(
          collaborators ?? FakeCollaboratorRepository(),
        ),
        reportsRepositoryProvider.overrideWithValue(
          reports ?? FakeReportsRepository(),
        ),
        productRepositoryProvider.overrideWithValue(
          products ?? FakeProductRepository(),
        ),
        barcodeScannerProvider.overrideWithValue(
          (_) async => scan == null ? null : await scan(),
        ),
        automationChannelProvider.overrideWithValue(
          automation ?? FakeAutomationChannel(supported: false),
        ),
        receiptStorageProvider.overrideWithValue(
          receipts ?? FakeReceiptStorage(),
        ),
        subscriptionServiceProvider.overrideWithValue(
          subscriptions ?? FakeSubscriptionService(),
        ),
        appInfoProvider.overrideWith(
          (ref) async => (version: '1.0.0', build: '1'),
        ),
        rateAppProvider.overrideWithValue(() async {}),
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
