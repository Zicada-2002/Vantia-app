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
import 'package:vantia/core/widgets/v_text_field.dart';
import 'package:vantia/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:vantia/l10n/l10n.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await ref
        .read(authRepositoryProvider)
        .sendPasswordReset(_email.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _sent = result.isOk;
    });
    if (result case Err(:final failure)) {
      showSnack(context, failureMessage(context.l10n, failure));
    }
  }

  void _back() => context.canPop() ? context.pop() : context.go(Routes.login);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      showBack: true,
      showLogo: false,
      title: l10n.forgotTitle,
      subtitle: l10n.forgotSubtitle,
      children: [
        if (_sent) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline, color: context.vColors.success),
              const SizedBox(width: VantiaSpacing.md),
              Expanded(child: Text(l10n.forgotSent)),
            ],
          ),
          const SizedBox(height: VantiaSpacing.xl),
          VButton(label: l10n.forgotBackToLogin, onPressed: _back),
        ] else ...[
          Form(
            key: _form,
            child: VTextField(
              label: l10n.fieldEmail,
              hint: l10n.hintEmail,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: validatorFor(context, Validators.email),
            ),
          ),
          const SizedBox(height: VantiaSpacing.xl),
          VButton(
            label: l10n.forgotButton,
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ],
    );
  }
}
