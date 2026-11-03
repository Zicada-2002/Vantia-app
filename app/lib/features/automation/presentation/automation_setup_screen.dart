import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/widgets/error_messages.dart';
import 'package:vantia/core/widgets/v_card.dart';
import 'package:vantia/features/automation/application/automation_providers.dart';
import 'package:vantia/features/subscription/presentation/plan_card.dart';
import 'package:vantia/l10n/l10n.dart';

/// F-71 / F-73: permisos guiados para leer notificaciones.
class AutomationSetupScreen extends ConsumerStatefulWidget {
  const AutomationSetupScreen({super.key});

  @override
  ConsumerState<AutomationSetupScreen> createState() =>
      _AutomationSetupScreenState();
}

class _AutomationSetupScreenState extends ConsumerState<AutomationSetupScreen>
    with WidgetsBindingObserver {
  bool _permission = false;
  bool _battery = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final ch = ref.read(automationChannelProvider);
    final p = await ch.isPermissionGranted();
    final b = await ch.isIgnoringBatteryOptimizations();
    if (!mounted) return;
    setState(() {
      _permission = p;
      _battery = b;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final channel = ref.watch(automationChannelProvider);
    final settings = ref.watch(automationSettingsProvider);
    final controller = ref.read(automationSettingsProvider.notifier);

    Widget step(
      String title, {
      required bool ok,
      required VoidCallback onOpen,
    }) => VCard(
      padding: const EdgeInsets.all(VantiaSpacing.md),
      radius: VantiaRadius.md,
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: ok ? context.vColors.success : context.vColors.muted,
          ),
          const SizedBox(width: VantiaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall),
                Text(
                  ok ? l10n.autoGranted : l10n.autoPending,
                  style: TextStyle(color: context.vColors.muted),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onOpen, child: Text(l10n.autoOpenSettings)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.autoTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(VantiaSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.autoIntro, style: context.text.bodyLarge),
            const SizedBox(height: VantiaSpacing.sm),
            Text(
              l10n.autoPrivacy,
              style: TextStyle(color: context.vColors.muted),
            ),
            const SizedBox(height: VantiaSpacing.lg),
            if (!channel.isSupported)
              Text(
                l10n.autoUnsupported,
                style: TextStyle(color: context.vColors.warning),
              )
            else ...[
              step(
                l10n.autoStepPermission,
                ok: _permission,
                onOpen: channel.openPermissionSettings,
              ),
              const SizedBox(height: VantiaSpacing.sm),
              step(
                l10n.autoStepBattery,
                ok: _battery,
                onOpen: channel.openBatterySettings,
              ),
              const SizedBox(height: VantiaSpacing.sm),
              Text(
                l10n.autoBatteryHelp,
                style: TextStyle(color: context.vColors.muted),
              ),
              const SizedBox(height: VantiaSpacing.lg),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.autoEnable),
                value: settings.autoVerify,
                onChanged: (v) {
                  if (v && !_permission) {
                    showSnack(context, l10n.autoNeedsPermission);
                    return;
                  }
                  unawaited(controller.setAutoVerify(value: v));
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.autoVoice),
                value: settings.voice,
                onChanged: (v) {
                  if (v && !requirePro(context, ref)) return;
                  unawaited(controller.setVoice(value: v));
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
