import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/bootstrap.dart';
import 'package:vantia/app/router/app_router.dart';
import 'package:vantia/app/theme/app_theme.dart';
import 'package:vantia/app/theme/theme_mode_controller.dart';
import 'package:vantia/features/automation/application/automation_providers.dart';
import 'package:vantia/features/notifications/push_service.dart';
import 'package:vantia/l10n/gen/app_localizations.dart';

class VantiaApp extends ConsumerWidget {
  const VantiaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flavor = ref.watch(flavorProvider);
    ref
      ..watch(pushRegistrationProvider)
      ..watch(automationRunnerProvider);
    return MaterialApp.router(
      title: flavor.appTitle,
      debugShowCheckedModeBanner: flavor.isDev,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      locale: const Locale('es', 'PE'),
      supportedLocales: const [Locale('es', 'PE'), Locale('es')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
