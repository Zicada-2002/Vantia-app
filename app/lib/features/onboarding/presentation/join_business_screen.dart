import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/observability/analytics.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/core/validation/validators.dart';
import 'package:vantia/core/widgets/error_messages.dart';
import 'package:vantia/core/widgets/v_button.dart';
import 'package:vantia/core/widgets/v_text_field.dart';
import 'package:vantia/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:vantia/l10n/l10n.dart';

/// F-17: el colaborador se une con un código de invitación.
class JoinBusinessScreen extends ConsumerStatefulWidget {
  const JoinBusinessScreen({super.key});

  @override
  ConsumerState<JoinBusinessScreen> createState() => _JoinBusinessScreenState();
}

class _JoinBusinessScreenState extends ConsumerState<JoinBusinessScreen> {
  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await ref
        .read(businessRepositoryProvider)
        .redeemInvite(_code.text);
    if (!mounted) return;
    setState(() => _loading = false);
    switch (result) {
      case Ok():
        await ref.read(analyticsProvider).log(AnalyticsEvent.inviteRedeemed);
      case Err(:final failure):
        if (mounted) showSnack(context, failureMessage(context.l10n, failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      showBack: true,
      showLogo: false,
      title: l10n.joinTitle,
      subtitle: l10n.joinSubtitle,
      children: [
        Form(
          key: _form,
          child: VTextField(
            label: l10n.fieldInviteCode,
            hint: 'ABC234',
            controller: _code,
            textAlign: TextAlign.center,
            inputFormatters: [
              _UpperCaseFormatter(),
              FilteringTextInputFormatter.allow(
                RegExp('[${Validators.inviteAlphabet}]'),
              ),
              LengthLimitingTextInputFormatter(6),
            ],
            validator: validatorFor(context, Validators.inviteCode),
          ),
        ),
        const SizedBox(height: VantiaSpacing.xl),
        VButton(label: l10n.joinButton, loading: _loading, onPressed: _submit),
      ],
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
