import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/routes.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/theme/theme_mode_controller.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/features/automation/application/automation_providers.dart';
import 'package:vantia/features/business/domain/business.dart';
import 'package:vantia/features/settings/presentation/legal_screen.dart';
import 'package:vantia/features/subscription/presentation/plan_card.dart';
import 'package:vantia/features/user/application/app_info.dart';
import 'package:vantia/l10n/l10n.dart';

/// Abre la ficha para valorar la app (inyectable en tests).
final rateAppProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    } else {
      await review.openStoreListing();
    }
  },
);

/// F-83: Ajustes (perfil, plan, tema, sonido, información).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(themeModeProvider);
    final automation = ref.watch(automationSettingsProvider);
    final auth = ref.watch(authUserProvider).value;
    final profile = ref.watch(userProfileProvider).value;
    final session = ref.watch(sessionProvider);
    final isOwner = session is SessionReady && session.isOwner;
    final info = ref.watch(appInfoProvider).value;
    final name = profile?.displayName ?? auth?.displayName ?? '';

    Widget header(String text) => Padding(
      padding: const EdgeInsets.only(
        top: VantiaSpacing.lg,
        bottom: VantiaSpacing.sm,
      ),
      child: Text(
        text,
        style: context.text.labelLarge?.copyWith(color: context.vColors.muted),
      ),
    );

    Widget iconBox(IconData icon, {Color? bg, Color? fg}) => Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg ?? context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(VantiaRadius.sm),
      ),
      child: Icon(icon, color: fg ?? context.vColors.muted),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VantiaSpacing.page,
          0,
          VantiaSpacing.page,
          VantiaSpacing.xl,
        ),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: context.colors.primaryContainer,
              child: Text(
                initialsOf(name),
                style: context.text.titleLarge?.copyWith(
                  color: context.colors.onPrimaryContainer,
                ),
              ),
            ),
            title: Text(name, style: context.text.titleMedium),
            subtitle: Text(auth?.email ?? ''),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(Routes.user),
          ),
          const SizedBox(height: VantiaSpacing.md),
          const PlanCard(),
          header(l10n.settingsAppearance),
          Row(
            children: [
              iconBox(Icons.contrast_rounded),
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
          header(l10n.settingsSound),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: iconBox(
              Icons.notifications_active_outlined,
              bg: context.colors.primaryContainer,
              fg: context.colors.onPrimaryContainer,
            ),
            title: Text(l10n.settingsPayNotifications),
            subtitle: Text(l10n.settingsPayNotificationsSub),
            value: automation.voice,
            onChanged: (v) {
              if (v && !requirePro(context, ref)) return;
              unawaited(
                ref
                    .read(automationSettingsProvider.notifier)
                    .setVoice(value: v),
              );
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: iconBox(
              Icons.verified_user_outlined,
              bg: context.colors.primaryContainer,
              fg: context.colors.onPrimaryContainer,
            ),
            title: Text(l10n.settingsAutoVerify),
            subtitle: Text(l10n.settingsAutoVerifySub),
            trailing: Switch(
              value: automation.autoVerify,
              onChanged: (_) => context.push(Routes.automation),
            ),
            onTap: () => context.push(Routes.automation),
          ),
          if (isOwner && profile != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: iconBox(Icons.groups_outlined),
              title: Text(l10n.settingsCollabPush),
              value: profile.notifyCollaboratorPayments,
              onChanged: (v) => ref
                  .read(businessRepositoryProvider)
                  .updatePrefs(profile.uid, {'notifyCollaboratorPayments': v}),
            ),
          header(l10n.settingsInfo),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: iconBox(Icons.description_outlined),
            title: Text(l10n.settingsTerms),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LegalScreen(
                  title: l10n.settingsTerms,
                  asset: 'assets/legal/terminos.txt',
                ),
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: iconBox(Icons.lock_outline_rounded),
            title: Text(l10n.settingsPrivacy),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LegalScreen(
                  title: l10n.settingsPrivacy,
                  asset: 'assets/legal/privacidad.txt',
                ),
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: iconBox(
              Icons.star_outline_rounded,
              bg: const Color(0xFFFFF4E0),
              fg: const Color(0xFFB7791F),
            ),
            title: Text(l10n.settingsRate),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => ref.read(rateAppProvider)(),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: iconBox(Icons.info_outline_rounded),
            title: Text(l10n.settingsVersion),
            trailing: Chip(label: Text(info?.version ?? '—')),
          ),
        ],
      ),
    );
  }
}
