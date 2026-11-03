import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/routes.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/shell/app_drawer.dart' show formatPhone;
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/core/time/lima_time.dart';
import 'package:vantia/core/validation/validators.dart';
import 'package:vantia/core/widgets/error_messages.dart';
import 'package:vantia/core/widgets/v_button.dart';
import 'package:vantia/core/widgets/v_card.dart';
import 'package:vantia/core/widgets/v_text_field.dart';
import 'package:vantia/features/auth/presentation/widgets/password_field.dart';
import 'package:vantia/features/business/domain/business.dart';
import 'package:vantia/features/subscription/application/plan_providers.dart';
import 'package:vantia/features/subscription/domain/plan.dart';
import 'package:vantia/features/user/application/app_info.dart';
import 'package:vantia/l10n/l10n.dart';

/// F-80: pestaña Usuario → Info.
class UserScreen extends ConsumerWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.watch(authUserProvider).value;
    final profile = ref.watch(userProfileProvider).value;
    final business = ref.watch(currentBusinessProvider).value;
    final session = ref.watch(sessionProvider);
    final plan = ref.watch(planProvider);
    final info = ref.watch(appInfoProvider).value;
    final name = profile?.displayName ?? auth?.displayName ?? '';

    Widget section(String title, List<Widget> rows) => Padding(
      padding: const EdgeInsets.only(bottom: VantiaSpacing.md),
      child: VCard(
        padding: const EdgeInsets.symmetric(
          horizontal: VantiaSpacing.md,
          vertical: VantiaSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: VantiaSpacing.sm),
              child: Text(
                title,
                style: context.text.titleSmall?.copyWith(
                  color: context.colors.primary,
                ),
              ),
            ),
            ...rows,
          ],
        ),
      ),
    );

    Widget row(String label, String value, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: context.vColors.muted)),
          ),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
          if (trailing != null) ...[const SizedBox(width: 6), trailing],
        ],
      ),
    );

    final roleLabel = session is SessionReady
        ? (session.isOwner ? l10n.roleOwner : l10n.roleCollaborator)
        : '—';
    final planLabel = switch (plan.tier) {
      PlanTier.free => l10n.planFree,
      PlanTier.trial => l10n.planTrial,
      PlanTier.pro => l10n.planPro,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleUser)),
      body: ListView(
        padding: const EdgeInsets.all(VantiaSpacing.page),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: context.colors.primaryContainer,
              child: Text(
                initialsOf(name),
                style: context.text.headlineSmall?.copyWith(
                  color: context.colors.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: VantiaSpacing.sm),
          Center(child: Text(name, style: context.text.titleLarge)),
          const SizedBox(height: VantiaSpacing.lg),
          section(l10n.userInfoPersonal, [
            row(l10n.userName, name),
            row(
              l10n.userEmail,
              auth?.email ?? '',
              trailing: (auth?.emailVerified ?? false)
                  ? Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: context.vColors.success,
                      semanticLabel: l10n.userEmailVerified,
                    )
                  : null,
            ),
            row(
              l10n.userPhone,
              profile?.phone == null
                  ? l10n.userNoPhone
                  : formatPhone(profile!.phone!),
            ),
          ]),
          if (business != null)
            section(l10n.userInfoBusiness, [
              row(l10n.userBusinessName, business.name),
              row(l10n.userLocation, business.location),
              row(l10n.userRole, roleLabel),
            ]),
          section(l10n.userInfoAccount, [
            row(l10n.userPlan, planLabel),
            if (profile?.createdAt != null)
              row(
                l10n.userMemberSince,
                LimaTime.formatDate(profile!.createdAt!),
              ),
          ]),
          section(l10n.userInfoSupport, [
            if (supportWhatsapp.isNotEmpty)
              _Action(
                icon: Icons.chat_outlined,
                label: l10n.userWhatsapp,
                onTap: () => launchUrl(
                  Uri.parse('https://wa.me/$supportWhatsapp'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            _Action(
              icon: Icons.bug_report_outlined,
              label: l10n.userReport,
              onTap: () => launchUrl(
                Uri.parse(
                  'mailto:?subject=${Uri.encodeComponent('Vantia: problema')}',
                ),
              ),
            ),
            if (info != null)
              row('', l10n.userVersion(info.version, info.build)),
          ]),
          _Action(
            icon: Icons.edit_outlined,
            label: l10n.userEdit,
            onTap: () => context.push(Routes.editProfile),
          ),
          _Action(
            icon: Icons.lock_outline_rounded,
            label: l10n.userChangePassword,
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => const _ChangePasswordDialog(),
            ),
          ),
          _Action(
            icon: Icons.alternate_email_rounded,
            label: l10n.userChangeEmail,
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => const _ChangeEmailDialog(),
            ),
          ),
          const SizedBox(height: VantiaSpacing.md),
          _Action(
            icon: Icons.delete_forever_outlined,
            label: l10n.userDeleteAccount,
            danger: true,
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => _DeleteAccountDialog(
                isOwner: session is SessionReady && session.isOwner,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.vColors.danger : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

/// F-81: editar nombre y celular.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;

  @override
  void initState() {
    super.initState();
    final p = ref.read(userProfileProvider).value;
    _name = TextEditingController(text: p?.displayName ?? '');
    _phone = TextEditingController(text: p?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final uid = ref.read(authUserProvider).value?.uid;
    if (uid == null) return;
    final l10n = context.l10n;
    final phone = _phone.text.trim().isEmpty
        ? null
        : Validators.normalizePhone(_phone.text);
    await ref.read(authRepositoryProvider).updateDisplayName(_name.text);
    final r = await ref
        .read(businessRepositoryProvider)
        .updateProfile(uid, displayName: _name.text, phone: phone);
    if (!mounted) return;
    r.fold((_) {
      showSnack(context, l10n.editSaved);
      context.pop();
    }, (f) => showSnack(context, failureMessage(l10n, f)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfileTitle)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(VantiaSpacing.page),
          children: [
            VTextField(
              label: l10n.fieldName,
              controller: _name,
              validator: validatorFor(context, Validators.name),
            ),
            const SizedBox(height: VantiaSpacing.md),
            VTextField(
              label: l10n.fieldPhone,
              prefixText: '+51 ',
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
                LengthLimitingTextInputFormatter(11),
              ],
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? null
                  : Validators.phone(v)?.message(l10n),
            ),
            const SizedBox(height: VantiaSpacing.xl),
            VButton(label: l10n.productSave, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final r = await ref
        .read(authRepositoryProvider)
        .changePassword(
          currentPassword: _current.text,
          newPassword: _next.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    final l10n = context.l10n;
    switch (r) {
      case Ok():
        Navigator.pop(context);
        showSnack(context, l10n.passwordChanged);
      case Err(:final failure):
        showSnack(context, failureMessage(l10n, failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.userChangePassword),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PasswordField(
              label: l10n.fieldCurrentPassword,
              controller: _current,
              validator: validatorFor(context, Validators.required),
            ),
            const SizedBox(height: VantiaSpacing.md),
            PasswordField(
              label: l10n.fieldNewPassword,
              controller: _next,
              autofillHints: const [AutofillHints.newPassword],
              validator: validatorFor(context, Validators.password),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: Text(l10n.productSave),
        ),
      ],
    );
  }
}

class _ChangeEmailDialog extends ConsumerStatefulWidget {
  const _ChangeEmailDialog();

  @override
  ConsumerState<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends ConsumerState<_ChangeEmailDialog> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final r = await ref
        .read(authRepositoryProvider)
        .changeEmail(currentPassword: _password.text, newEmail: _email.text);
    if (!mounted) return;
    final l10n = context.l10n;
    switch (r) {
      case Ok():
        Navigator.pop(context);
        showSnack(context, l10n.emailChangeSent(_email.text.trim()));
      case Err(:final failure):
        showSnack(context, failureMessage(l10n, failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.userChangeEmail),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VTextField(
              label: l10n.fieldNewEmail,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: validatorFor(context, Validators.email),
            ),
            const SizedBox(height: VantiaSpacing.md),
            PasswordField(
              label: l10n.fieldCurrentPassword,
              controller: _password,
              validator: validatorFor(context, Validators.required),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.productSave)),
      ],
    );
  }
}

/// F-82: eliminar cuenta (re-autenticación + escribir ELIMINAR).
class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog({required this.isOwner});

  final bool isOwner;

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() => _loading = true);
    final l10n = context.l10n;
    final auth = ref.read(authRepositoryProvider);
    final re = await auth.reauthenticate(_password.text);
    if (!mounted) return;
    if (re case Err(:final failure)) {
      setState(() => _loading = false);
      showSnack(context, failureMessage(l10n, failure));
      return;
    }
    final r = await ref.read(businessRepositoryProvider).deleteAccount();
    if (!mounted) return;
    switch (r) {
      case Ok():
        Navigator.pop(context);
        unawaited(auth.signOut());
      case Err(:final failure):
        setState(() => _loading = false);
        showSnack(context, failureMessage(l10n, failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canDelete =
        _confirm.text.trim() == 'ELIMINAR' && _password.text.isNotEmpty;
    return AlertDialog(
      title: Text(l10n.deleteTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteBody),
            if (widget.isOwner) ...[
              const SizedBox(height: VantiaSpacing.sm),
              Text(
                l10n.deleteOwnerWarning,
                style: TextStyle(color: context.vColors.danger),
              ),
            ],
            const SizedBox(height: VantiaSpacing.md),
            PasswordField(
              label: l10n.fieldCurrentPassword,
              controller: _password,
            ),
            const SizedBox(height: VantiaSpacing.md),
            TextField(
              controller: _confirm,
              decoration: InputDecoration(labelText: l10n.deleteTypeConfirm),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: context.vColors.danger,
            minimumSize: const Size(0, 44),
          ),
          onPressed: canDelete && !_loading ? _delete : null,
          child: Text(l10n.deleteConfirm),
        ),
      ],
    );
  }
}
