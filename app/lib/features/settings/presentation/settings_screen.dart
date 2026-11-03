import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vantia/app/router/routes.dart';
import 'package:vantia/app/theme/theme_mode_controller.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/features/automation/application/automation_providers.dart';
import 'package:vantia/l10n/l10n.dart';

/// Ajustes. En M0 solo el selector de tema (base de F-83).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(themeModeProvider);
    final automation = ref.watch(automationSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleSettings)),
      body: ListView(
        padding: const EdgeInsets.all(VantiaSpacing.page),
        children: [
          Row(
            children: [
              Icon(Icons.contrast_rounded, color: context.vColors.muted),
              const SizedBox(width: VantiaSpacing.md),
              Expanded(
                child: Text(
                  l10n.settingsTheme,
                  style: context.text.titleMedium,
                ),
              ),
              SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode_outlined),
                    tooltip: l10n.themeLight,
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto_outlined),
                    tooltip: l10n.themeSystem,
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode_outlined),
                    tooltip: l10n.themeDark,
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (s) =>
                    ref.read(themeModeProvider.notifier).set(s.first),
              ),
            ],
          ),
          const SizedBox(height: VantiaSpacing.lg),
          Text(
            l10n.settingsSound,
            style: context.text.labelLarge?.copyWith(
              color: context.vColors.muted,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.notifications_active_outlined),
            title: Text(l10n.settingsPayNotifications),
            subtitle: Text(l10n.settingsPayNotificationsSub),
            value: automation.voice,
            onChanged: (v) => ref
                .read(automationSettingsProvider.notifier)
                .setVoice(value: v),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.verified_user_outlined),
            title: Text(l10n.settingsAutoVerify),
            subtitle: Text(l10n.settingsAutoVerifySub),
            trailing: Switch(
              value: automation.autoVerify,
              onChanged: (_) => context.push(Routes.automation),
            ),
            onTap: () => context.push(Routes.automation),
          ),
        ],
      ),
    );
  }
}
