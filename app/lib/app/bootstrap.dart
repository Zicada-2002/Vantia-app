import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vantia/app/app.dart';
import 'package:vantia/app/flavor.dart';
import 'package:vantia/app/theme/theme_mode_controller.dart';
import 'package:vantia/core/observability/analytics.dart';

final flavorProvider = Provider<Flavor>((ref) => Flavor.dev);

/// Punto de arranque común a todos los flavors.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  Intl.defaultLocale = 'es';
  await initializeDateFormatting('es');
  final prefs = await SharedPreferences.getInstance();

  // TODO(F-06): inicializar Firebase (por flavor) y usar la implementación
  // de Analytics/Crashlytics en lugar de DebugAnalytics.
  const Analytics analytics = DebugAnalytics();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(analytics.recordError(details.exception, details.stack));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(analytics.recordError(error, stack, fatal: true));
    return true;
  };

  runApp(
    ProviderScope(
      overrides: [
        flavorProvider.overrideWithValue(flavor),
        sharedPreferencesProvider.overrideWithValue(prefs),
        analyticsProvider.overrideWithValue(analytics),
      ],
      child: const VantiaApp(),
    ),
  );
}
