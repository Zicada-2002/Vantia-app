import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/core/observability/analytics.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/core/time/clock.dart';
import 'package:vantia/core/time/lima_time.dart';
import 'package:vantia/core/widgets/error_messages.dart';
import 'package:vantia/core/widgets/v_button.dart';
import 'package:vantia/core/widgets/v_card.dart';
import 'package:vantia/features/business/domain/business.dart';
import 'package:vantia/features/collaborators/application/collaborator_providers.dart';
import 'package:vantia/features/collaborators/domain/collaborators.dart';
import 'package:vantia/features/payments/application/payment_providers.dart';
import 'package:vantia/features/payments/domain/payment.dart';
import 'package:vantia/l10n/l10n.dart';

/// M3: invitaciones (F-30, F-31) y equipo (F-32).
class CollaboratorsScreen extends ConsumerStatefulWidget {
  const CollaboratorsScreen({super.key});

  @override
  ConsumerState<CollaboratorsScreen> createState() =>
      _CollaboratorsScreenState();
}

class _CollaboratorsScreenState extends ConsumerState<CollaboratorsScreen> {
  bool _generating = false;

  Future<void> _generate() async {
    setState(() => _generating = true);
    final result = await ref
        .read(collaboratorRepositoryProvider)
        .generateInvite();
    if (!mounted) return;
    setState(() => _generating = false);
    switch (result) {
      case Ok(:final value):
        ref
            .read(analyticsProvider)
            .log(AnalyticsEvent.inviteGenerated)
            .ignore();
        await showDialog<void>(
          context: context,
          builder: (_) => _CodeDialog(code: value.code),
        );
      case Err(:final failure):
        showSnack(context, failureMessage(context.l10n, failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final invites = ref.watch(invitesProvider).value ?? const <Invite>[];
    final members = ref.watch(membersProvider).value ?? const <Member>[];
    final today = PaymentSummaryByUser.of(
      ref.watch(todayPaymentsProvider).value ?? const [],
    );
    final now = ref.watch(clockProvider)();
    final names = {for (final m in members) m.uid: m.displayName};

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleCollaborators)),
      body: ListView(
        padding: const EdgeInsets.all(VantiaSpacing.page),
        children: [
          VButton(
            icon: Icons.person_add_alt_1_rounded,
            label: l10n.collabGenerate,
            loading: _generating,
            onPressed: _generate,
          ),
          const SizedBox(height: VantiaSpacing.lg),
          Text(l10n.collabMembers, style: context.text.titleMedium),
          const SizedBox(height: VantiaSpacing.sm),
          if (members.where((m) => m.role != MemberRole.owner).isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: VantiaSpacing.md),
              child: Text(
                l10n.collabNoMembers,
                style: TextStyle(color: context.vColors.muted),
              ),
            ),
          for (final m in members)
            _MemberTile(member: m, todaySales: today[m.uid]),
          const SizedBox(height: VantiaSpacing.lg),
          Text(l10n.collabInvites, style: context.text.titleMedium),
          const SizedBox(height: VantiaSpacing.sm),
          if (invites.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: VantiaSpacing.md),
              child: Text(
                l10n.collabEmptyInvites,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.vColors.muted),
              ),
            ),
          for (final i in invites)
            _InviteTile(invite: i, now: now, usedByName: names[i.usedBy]),
        ],
      ),
    );
  }
}

/// Ventas activas por usuario.
abstract final class PaymentSummaryByUser {
  static Map<String, Money> of(Iterable<Payment> payments) {
    final out = <String, Money>{};
    for (final p in payments.where((p) => p.isActive)) {
      out[p.createdBy] = (out[p.createdBy] ?? const Money.zero()) + p.amount;
    }
    return out;
  }
}

class _CodeDialog extends ConsumerWidget {
  const _CodeDialog({required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final business = ref.watch(currentBusinessProvider).value;
    return AlertDialog(
      title: Text(l10n.collabCodeTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(
            code,
            style: context.text.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: VantiaSpacing.md),
          Text(l10n.collabCodeBody, textAlign: TextAlign.center),
        ],
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.copy_rounded),
          label: Text(l10n.collabCopy),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: code));
            if (!context.mounted) return;
            Navigator.pop(context);
            showSnack(context, l10n.collabCopied);
          },
        ),
        FilledButton.icon(
          icon: const Icon(Icons.share_rounded),
          label: Text(l10n.collabShare),
          onPressed: () => SharePlus.instance.share(
            ShareParams(
              text: l10n.collabShareText(business?.name ?? 'Vantia', code),
            ),
          ),
        ),
      ],
    );
  }
}

class _InviteTile extends ConsumerWidget {
  const _InviteTile({required this.invite, required this.now, this.usedByName});

  final Invite invite;
  final DateTime now;
  final String? usedByName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status = invite.effectiveStatus(now);
    final (label, color) = switch (status) {
      InviteStatus.active => (
        l10n.inviteActive(
          invite.expiresAt.difference(now).inHours.clamp(0, 48),
        ),
        context.vColors.success,
      ),
      InviteStatus.used => (
        usedByName != null ? l10n.inviteUsedBy(usedByName!) : l10n.inviteUsed,
        context.colors.primary,
      ),
      InviteStatus.expired => (l10n.inviteExpired, context.vColors.muted),
      InviteStatus.revoked => (l10n.inviteRevoked, context.vColors.danger),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: VantiaSpacing.sm),
      child: VCard(
        padding: const EdgeInsets.symmetric(
          horizontal: VantiaSpacing.md,
          vertical: VantiaSpacing.sm,
        ),
        radius: VantiaRadius.md,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invite.code,
                    style: context.text.titleMedium?.copyWith(letterSpacing: 2),
                  ),
                  Text(label, style: TextStyle(color: color, fontSize: 13)),
                ],
              ),
            ),
            if (status == InviteStatus.active)
              TextButton(
                onPressed: () => _revoke(context, ref),
                child: Text(l10n.inviteRevoke),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.inviteRevokeTitle(invite.code)),
        content: Text(l10n.inviteRevokeBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.inviteRevoke),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final r = await ref
        .read(collaboratorRepositoryProvider)
        .revokeInvite(invite.code);
    if (!context.mounted) return;
    showSnack(
      context,
      r.fold((_) => l10n.inviteRevoked2, (f) => failureMessage(l10n, f)),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({required this.member, this.todaySales});

  final Member member;
  final Money? todaySales;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isOwner = member.role == MemberRole.owner;
    final subtitle = [
      if (isOwner) l10n.memberOwner,
      if (!member.active) l10n.memberInactive,
      if (member.joinedAt != null)
        l10n.memberSince(LimaTime.formatDate(member.joinedAt!)),
      l10n.memberTodaySales((todaySales ?? const Money.zero()).format()),
    ].join(' · ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: member.active
            ? context.colors.primaryContainer
            : context.colors.surfaceContainerHigh,
        child: Text(initialsOf(member.displayName)),
      ),
      title: Text(member.displayName.isEmpty ? '—' : member.displayName),
      subtitle: Text(subtitle),
      trailing: isOwner
          ? null
          : TextButton(
              onPressed: () => _toggle(context, ref),
              child: Text(
                member.active ? l10n.memberDeactivate : l10n.memberActivate,
              ),
            ),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    if (member.active) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.memberDeactivateTitle(member.displayName)),
          content: Text(l10n.memberDeactivateBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.memberDeactivate),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
    }
    final r = await ref
        .read(collaboratorRepositoryProvider)
        .setMemberActive(member.uid, active: !member.active);
    if (!context.mounted) return;
    showSnack(
      context,
      r.fold((_) => l10n.memberUpdated, (f) => failureMessage(l10n, f)),
    );
  }
}
