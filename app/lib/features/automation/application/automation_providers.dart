import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/theme/theme_mode_controller.dart';
import 'package:vantia/core/observability/analytics.dart';
import 'package:vantia/features/automation/data/automation_channel.dart';
import 'package:vantia/features/automation/domain/parsers.dart';
import 'package:vantia/features/payments/application/payment_providers.dart';
import 'package:vantia/features/payments/domain/payment.dart';

final automationChannelProvider = Provider<AutomationChannel>(
  (ref) => PlatformAutomationChannel(),
);

@immutable
class AutomationSettings {
  const AutomationSettings({required this.autoVerify, required this.voice});

  /// F-71: registrar automáticamente los pagos de Yape/Plin.
  final bool autoVerify;

  /// F-72: anunciar cada cobro por voz.
  final bool voice;
}

/// Preferencias del dispositivo, sincronizadas con el listener nativo.
class AutomationSettingsController extends Notifier<AutomationSettings> {
  static const _kAuto = 'pref.autoVerify';
  static const _kVoice = 'pref.voiceAnnouncements';

  @override
  AutomationSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AutomationSettings(
      autoVerify: prefs.getBool(_kAuto) ?? false,
      voice: prefs.getBool(_kVoice) ?? true,
    );
  }

  Future<void> setAutoVerify({required bool value}) async {
    state = AutomationSettings(autoVerify: value, voice: state.voice);
    await ref.read(sharedPreferencesProvider).setBool(_kAuto, value);
    await _sync();
  }

  Future<void> setVoice({required bool value}) async {
    state = AutomationSettings(autoVerify: state.autoVerify, voice: value);
    await ref.read(sharedPreferencesProvider).setBool(_kVoice, value);
    await _sync();
  }

  Future<void> _sync() => ref
      .read(automationChannelProvider)
      .setConfig(enabled: state.autoVerify, voice: state.voice);
}

final automationSettingsProvider =
    NotifierProvider<AutomationSettingsController, AutomationSettings>(
      AutomationSettingsController.new,
    );

/// Id determinista: la misma notificación nunca crea dos pagos.
String notificationPaymentId(RawNotification n) {
  final minute = n.postedAt.millisecondsSinceEpoch ~/ 60000;
  final digest = sha1.convert(
    utf8.encode('${n.packageName}|${n.text.trim()}|$minute'),
  );
  return 'n_${digest.toString().substring(0, 24)}';
}

/// Convierte notificaciones en pagos verificados (F-71).
class AutomationProcessor {
  AutomationProcessor(this._ref);

  final Ref _ref;
  final _seen = <String>{};

  Future<int> process(Iterable<RawNotification> notifications) async {
    final session = _ref.read(sessionProvider);
    if (session is! SessionReady) return 0;
    var created = 0;
    for (final n in notifications) {
      final detected = NotificationParser.parse(n);
      if (detected == null) continue;
      final id = notificationPaymentId(n);
      if (!_seen.add(id)) continue;
      final r = await _ref
          .read(paymentRepositoryProvider)
          .create(
            businessId: session.businessId,
            userId: session.uid,
            userName: _ref.read(currentUserNameProvider),
            id: id,
            draft: PaymentDraft(
              method: detected.method,
              received: detected.amount,
              occurredAt: detected.occurredAt ?? n.postedAt,
              payerName: detected.payerName,
              source: PaymentSource.notification,
              verified: true,
            ),
          );
      if (r.isOk) {
        created++;
        _ref.read(analyticsProvider).log(
          AnalyticsEvent.notificationPaymentCaptured,
          {'app': detected.method.id},
        ).ignore();
      }
    }
    return created;
  }
}

final automationProcessorProvider = Provider<AutomationProcessor>(
  AutomationProcessor.new,
);

/// Mantiene el flujo activo: vacía la cola al entrar/volver a la app y
/// escucha eventos en vivo mientras haya sesión y la función esté activa.
final automationRunnerProvider = Provider<void>((ref) {
  final session = ref.watch(sessionProvider);
  final settings = ref.watch(automationSettingsProvider);
  final channel = ref.watch(automationChannelProvider);
  unawaited(
    channel.setConfig(enabled: settings.autoVerify, voice: settings.voice),
  );
  if (session is! SessionReady ||
      !settings.autoVerify ||
      !channel.isSupported) {
    return;
  }
  final processor = ref.watch(automationProcessorProvider);

  Future<void> drain() async {
    await processor.process(await channel.drainQueue());
  }

  unawaited(drain());
  final sub = channel.events.listen((n) => processor.process([n]));
  final lifecycle = AppLifecycleListener(onResume: () => unawaited(drain()));
  ref.onDispose(() {
    unawaited(sub.cancel());
    lifecycle.dispose();
  });
});
