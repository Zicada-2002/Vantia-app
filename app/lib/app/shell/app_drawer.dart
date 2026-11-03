import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vantia/app/router/routes.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/l10n/l10n.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(sessionProvider);
    final isOwner = session is SessionReady && session.role == MemberRole.owner;

    void go(String route) {
      Navigator.of(context).pop();
      if (route == Routes.home) {
        context.go(route);
      } else {
        unawaited(context.push(route));
      }
    }

    return NavigationDrawer(
      onDestinationSelected: (i) {
        final routes = [
          Routes.home,
          if (isOwner) Routes.collaborators,
          Routes.cashRegister,
          Routes.settings,
        ];
        go(routes[i]);
      },
      children: [
        // TODO(F-18): datos reales del negocio.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: context.colors.primaryContainer,
                child: Text(
                  'VP',
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
                    Text('Vantia Perú', style: context.text.titleMedium),
                    const SizedBox(height: 4),
                    const _InfoRow(
                      icon: Icons.phone_outlined,
                      text: '917 926 826',
                    ),
                    const _InfoRow(
                      icon: Icons.place_outlined,
                      text: 'Lima - Lima',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            // TODO(F-18): confirmación + signOut real.
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}

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
