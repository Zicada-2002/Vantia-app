import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/observability/analytics.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/core/validation/validators.dart';
import 'package:vantia/core/widgets/error_messages.dart';
import 'package:vantia/core/widgets/v_button.dart';
import 'package:vantia/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:vantia/l10n/l10n.dart';

/// F-11: bloquea la app hasta que el correo esté verificado.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.resendCooldown = defaultCooldown});

  static const defaultCooldown = Duration(seconds: 60);

  final Duration resendCooldown;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  int _secondsLeft = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // El correo se acaba de enviar al registrarse: arrancar con cooldown.
    _startCooldown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  /// Al volver a la app (p. ej. tras abrir el enlace en el navegador),
  /// revisar si el correo ya está verificado.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_check(silent: true));
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = widget.resendCooldown.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    final result = await ref
        .read(authRepositoryProvider)
        .sendEmailVerification();
    if (!mounted) return;
    final l10n = context.l10n;
    switch (result) {
      case Ok():
        _startCooldown();
        showSnack(context, l10n.verifyResent);
      case Err(:final failure):
        showSnack(context, failureMessage(l10n, failure));
    }
  }

  Future<void> _check({bool silent = false}) async {
    if (_checking) return;
    setState(() => _checking = true);
    final result = await ref.read(authRepositoryProvider).reload();
    if (!mounted) return;
    setState(() => _checking = false);
    final l10n = context.l10n;
    switch (result) {
      case Ok(:final value) when value?.emailVerified ?? false:
        // El router redirige al onboarding; no arrastrar avisos previos.
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await ref.read(analyticsProvider).log(AnalyticsEvent.emailVerified);
      case Ok():
        if (!silent) showSnack(context, l10n.verifyStillPending);
      case Err(:final failure):
        if (!silent) showSnack(context, failureMessage(l10n, failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final email = ref.watch(authUserProvider).value?.email ?? '';
    return AuthScaffold(
      showLogo: false,
      title: l10n.verifyTitle,
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: context.colors.primaryContainer,
            child: Icon(
              Icons.mark_email_unread_outlined,
              size: 48,
              color: context.colors.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: VantiaSpacing.lg),
        Text(
          l10n.verifyBody(Validators.maskEmail(email)),
          style: context.text.bodyLarge,
        ),
        const SizedBox(height: VantiaSpacing.sm),
        Text(
          l10n.verifyHint,
          style: context.text.bodyMedium?.copyWith(
            color: context.vColors.muted,
          ),
        ),
        const SizedBox(height: VantiaSpacing.xl),
        VButton(label: l10n.verifyCheck, loading: _checking, onPressed: _check),
        const SizedBox(height: VantiaSpacing.md),
        VButton(
          variant: VButtonVariant.outlined,
          label: _secondsLeft > 0
              ? l10n.verifyResendIn(_secondsLeft)
              : l10n.verifyResend,
          onPressed: _secondsLeft > 0 ? null : _resend,
        ),
        const SizedBox(height: VantiaSpacing.md),
        Center(
          child: TextButton(
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            child: Text(l10n.verifyUseOtherEmail),
          ),
        ),
      ],
    );
  }
}
