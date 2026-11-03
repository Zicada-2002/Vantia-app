import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/routes.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/observability/analytics.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/core/validation/validators.dart';
import 'package:vantia/core/widgets/error_messages.dart';
import 'package:vantia/core/widgets/v_button.dart';
import 'package:vantia/core/widgets/v_text_field.dart';
import 'package:vantia/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:vantia/features/auth/presentation/widgets/password_field.dart';
import 'package:vantia/l10n/l10n.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _acceptedTerms = false;
  bool _showTermsError = false;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _form.currentState!.validate();
    setState(() => _showTermsError = !_acceptedTerms);
    if (!valid || !_acceptedTerms) return;

    setState(() => _loading = true);
    final result = await ref
        .read(authRepositoryProvider)
        .signUp(
          displayName: _name.text,
          email: _email.text,
          password: _password.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    switch (result) {
      case Ok():
        await ref.read(analyticsProvider).log(AnalyticsEvent.signUp);
      // El router lleva a /auth/verify-email.
      case Err(:final failure):
        if (mounted) showSnack(context, failureMessage(context.l10n, failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.registerTitle,
      subtitle: l10n.registerSubtitle,
      children: [
        AutofillGroup(
          child: Form(
            key: _form,
            child: Column(
              children: [
                VTextField(
                  label: l10n.fieldName,
                  hint: l10n.hintName,
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: validatorFor(context, Validators.name),
                ),
                const SizedBox(height: VantiaSpacing.md),
                VTextField(
                  label: l10n.fieldEmail,
                  hint: l10n.hintEmail,
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: validatorFor(context, Validators.email),
                ),
                const SizedBox(height: VantiaSpacing.md),
                PasswordField(
                  label: l10n.fieldPassword,
                  hint: l10n.hintPassword,
                  controller: _password,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: validatorFor(context, Validators.password),
                ),
                const SizedBox(height: VantiaSpacing.md),
                PasswordField(
                  label: l10n.fieldConfirmPassword,
                  controller: _confirm,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: validatorFor(
                    context,
                    (v) => Validators.confirmPassword(v, _password.text),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: VantiaSpacing.sm),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _acceptedTerms,
          onChanged: (v) => setState(() {
            _acceptedTerms = v ?? false;
            if (_acceptedTerms) _showTermsError = false;
          }),
          // TODO(F-83): enlazar a los documentos de términos y privacidad.
          title: Text(l10n.registerAcceptTerms),
          subtitle: _showTermsError
              ? Text(
                  l10n.registerTermsRequired,
                  style: TextStyle(color: context.colors.error),
                )
              : null,
        ),
        const SizedBox(height: VantiaSpacing.md),
        VButton(
          label: l10n.registerButton,
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: VantiaSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.registerHaveAccount),
            TextButton(
              onPressed: () => context.go(Routes.login),
              child: Text(l10n.registerSignIn),
            ),
          ],
        ),
      ],
    );
  }
}
