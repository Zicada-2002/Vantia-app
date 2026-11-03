import 'package:flutter/material.dart';
import 'package:vantia/app/theme/tokens.dart';

/// Layout común de las pantallas de auth y onboarding: logo, título,
/// subtítulo y contenido desplazable con ancho máximo.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.children,
    super.key,
    this.subtitle,
    this.showLogo = true,
    this.showBack = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool showLogo;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showBack ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                VantiaSpacing.page,
                VantiaSpacing.xl,
                VantiaSpacing.page,
                VantiaSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showLogo) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: VantiaLogo(),
                    ),
                    const SizedBox(height: VantiaSpacing.lg),
                  ],
                  Text(
                    title,
                    style: context.text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: VantiaSpacing.sm),
                    Text(
                      subtitle!,
                      style: context.text.bodyLarge?.copyWith(
                        color: context.vColors.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: VantiaSpacing.xl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VantiaLogo extends StatelessWidget {
  const VantiaLogo({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.account_balance_wallet_rounded,
        color: context.colors.onPrimary,
        size: size * 0.55,
        semanticLabel: 'Vantia',
      ),
    );
  }
}
