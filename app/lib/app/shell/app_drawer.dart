import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/routes.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/features/business/domain/business.dart';
import 'package:vantia/l10n/l10n.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(sessionProvider);
    final isOwner = session is SessionReady && session.isOwner;
    final business = ref.watch(currentBusinessProvider).value;

    final routes = [
      Routes.home,
      if (isOwner) Routes.collaborators,
      Routes.cashRegister,
      Routes.settings,
    ];

    return NavigationDrawer(
      onDestinationSelected: (i) {
        Navigator.of(context).pop();
        final route = routes[i];
        if (route == Routes.home) {
          context.go(route);
        } else {
          unawaited(context.push(route));
        }
      },
      children: [
        _DrawerHeader(business: business),
        const Divider(indent: 16, endIndent: 16),
        const SizedBox(height: VantiaSpacing.sm),
        NavigationDrawerDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: Text(l10n.drawerHome),
        ),
        if (isOwner)
          NavigationDrawerDestination(
            icon: const Icon(Icons.groups_outlined),
            label: Text(l10n.drawerCollaborators),
          ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.account_balance_wallet_outlined),
          label: Text(l10n.drawerCashRegister),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.settings_outlined),
          label: Text(l10n.drawerSettings),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Divider(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListTile(
            shape: const StadiumBorder(),
            leading: const Icon(Icons.logout_rounded),
            title: Text(l10n.drawerSignOut),
            onTap: () async {
              final confirmed = await confirmSignOut(context);
              if (confirmed && context.mounted) {
                Navigator.of(context).pop();
                await ref.read(authRepositoryProvider).signOut();
              }
            },
          ),
        ),
      ],
    );
  }
}

/// F-18: confirmación antes de cerrar sesión.
Future<bool> confirmSignOut(BuildContext context) async {
  final l10n = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.signOutTitle),
      content: Text(l10n.signOutBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.drawerSignOut),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.business});

  final Business? business;

  @override
  Widget build(BuildContext context) {
    final b = business;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: context.colors.primaryContainer,
            child: Text(
              b?.initials ?? '',
              style: context.text.titleLarge?.copyWith(
                color: context.colors.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: VantiaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b?.name ?? '',
                  style: context.text.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (b != null) ...[
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    text: formatPhone(b.phone),
                  ),
                  _InfoRow(icon: Icons.place_outlined, text: b.location),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `917926826` → `917 926 826`
String formatPhone(String digits) => digits.length == 9
    ? '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}'
    : digits;

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = context.vColors.muted;
    return Row(
      children: [
        Icon(icon, size: 16, color: muted),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(color: muted),
          ),
        ),
      ],
    );
  }
}
