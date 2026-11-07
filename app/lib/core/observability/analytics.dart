import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Catálogo de eventos (ver docs/PLAN.md §5). Usar solo estos nombres.
enum AnalyticsEvent {
  signUp('sign_up'),
  emailVerified('email_verified'),
  businessCreated('business_created'),
  inviteGenerated('invite_generated'),
  inviteRedeemed('invite_redeemed'),
  paymentRegistered('payment_registered'),
  paymentVoided('payment_voided'),
  cashClosed('cash_closed'),
  reportViewed('report_viewed'),
  exportGenerated('export_generated'),
  productCreated('product_created'),
  ocrScan('ocr_scan'),
  notificationPaymentCaptured('notification_payment_captured'),
  paywallViewed('paywall_viewed'),
  subscriptionStarted('subscription_started');

  const AnalyticsEvent(this.name);
  final String name;
}

/// Abstracción de analítica y reporte de errores. La implementación con
/// Firebase (Analytics + Crashlytics) se conecta cuando exista el proyecto
/// de Firebase; mientras tanto se usa [DebugAnalytics].
///
/// Regla: **nunca** enviar datos personales (correo, teléfono, nombres,
/// montos individuales con identificadores) en parámetros.
abstract interface class Analytics {
  Future<void> log(AnalyticsEvent event, [Map<String, Object> params]);
  Future<void> recordError(Object error, StackTrace? stack, {bool fatal});
  Future<void> setUser(String? uid);
}

class DebugAnalytics implements Analytics {
  const DebugAnalytics();

  @override
  Future<void> log(AnalyticsEvent event, [Map<String, Object>? params]) async =>
      developer.log('${event.name} ${params ?? {}}', name: 'analytics');

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async => developer.log(
    fatal ? 'FATAL' : 'error',
    name: 'crash',
    error: error,
    stackTrace: stack,
  );

  @override
  Future<void> setUser(String? uid) async {}
}

final analyticsProvider = Provider<Analytics>((ref) => const DebugAnalytics());
