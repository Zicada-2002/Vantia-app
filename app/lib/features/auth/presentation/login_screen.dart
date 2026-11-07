import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/routes.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/core/validation/validators.dart';
import 'package:vantia/core/widgets/error_messages.dart';
import 'package:vantia/core/widgets/v_button.dart';
import 'package:vantia/core/widgets/v_card.dart';
import 'package:vantia/core/widgets/v_text_field.dart';
import 'package:vantia/demo/demo_backend.dart';
import 'package:vantia/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:vantia/features/auth/presentation/widgets/password_field.dart';
import 'package:vantia/l10n/l10n.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await ref
        .read(authRepositoryProvider)
        .signIn(email: _email.text, password: _password.text);
    if (!mounted) return;
    setState(() => _loading = false);
    // En éxito, el router redirige solo según la sesión.
    if (result case Err(:final failure)) {
      showSnack(context, failureMessage(context.l10n, failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final demo = ref.watch(demoModeProvider);
    return AuthScaffold(
      title: l10n.loginTitle,
      subtitle: l10n.loginSubtitle,
      children: [
        if (demo) ...[
          VCard(
            highlight: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.demoBanner),
                const SizedBox(height: VantiaSpacing.sm),
                Text(
                  l10n.demoCredentials(demoEmail, demoPassword),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: VantiaSpacing.md),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.vColors.onHighlight,
                    foregroundColor: context.vColors.highlight,
                  ),
                  onPressed: _loading
                      ? null
                      : () {
                          _email.text = demoEmail;
                          _password.text = demoPassword;
                          unawaited(_submit());
                        },
                  child: Text(l10n.demoEnter),
                ),
              ],
            ),
          ),
          const SizedBox(height: VantiaSpacing.lg),
        ],
        AutofillGroup(
          child: Form(
            key: _form,
            child: Column(
              children: [
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
                  controller: _password,
                  textInputAction: TextInputAction.done,
                  validator: validatorFor(context, Validators.required),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push(Routes.forgotPassword),
            child: Text(l10n.loginForgot),
          ),
        ),
        const SizedBox(height: VantiaSpacing.md),
        VButton(label: l10n.loginButton, loading: _loading, onPressed: _submit),
        const SizedBox(height: VantiaSpacing.lg),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.loginNoAccount),
            TextButton(
              onPressed: () => context.go(Routes.register),
              child: Text(l10n.loginCreateAccount),
            ),
          ],
        ),
      ],
    );
  }
}
