import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/routes.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/widgets/v_button.dart';
import 'package:vantia/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:vantia/l10n/l10n.dart';

/// F-15: "¿Cómo usarás la aplicación?"
class RoleScreen extends ConsumerStatefulWidget {
  const RoleScreen({super.key});

  @override
  ConsumerState<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends ConsumerState<RoleScreen> {
  MemberRole? _role;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.roleTitle,
      subtitle: l10n.roleSubtitle,
      children: [
        _RoleCard(
          icon: Icons.storefront_outlined,
          title: l10n.roleOwnerTitle,
          body: l10n.roleOwnerBody,
          selected: _role == MemberRole.owner,
          onTap: () => setState(() => _role = MemberRole.owner),
        ),
        const SizedBox(height: VantiaSpacing.md),
        _RoleCard(
          icon: Icons.group_outlined,
          title: l10n.roleCollaboratorTitle,
          body: l10n.roleCollaboratorBody,
          selected: _role == MemberRole.collaborator,
          onTap: () => setState(() => _role = MemberRole.collaborator),
        ),
        const SizedBox(height: VantiaSpacing.xl),
        VButton(
          label: l10n.continueButton,
          onPressed: _role == null
              ? null
              : () => context.push(
                  _role == MemberRole.owner
                      ? Routes.onboardingBusiness
                      : Routes.onboardingJoin,
                ),
        ),
        const SizedBox(height: VantiaSpacing.md),
        Center(
          child: TextButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: Text(l10n.drawerSignOut),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? context.colors.primary
        : context.colors.outline;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: context.colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VantiaRadius.lg),
          side: BorderSide(color: borderColor, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(VantiaRadius.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(VantiaSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(VantiaRadius.md),
                      ),
                      child: Icon(icon, color: context.vColors.muted),
                    ),
                    const Spacer(),
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected
                          ? context.colors.primary
                          : context.colors.outline,
                    ),
                  ],
                ),
                const SizedBox(height: VantiaSpacing.md),
                Text(title, style: context.text.titleMedium),
                const SizedBox(height: VantiaSpacing.xs),
                Text(
                  body,
                  style: context.text.bodyMedium?.copyWith(
                    color: context.vColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
