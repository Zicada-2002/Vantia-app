import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/routes.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/widgets/v_card.dart';
import 'package:vantia/features/subscription/application/plan_providers.dart';
import 'package:vantia/features/subscription/domain/plan.dart';
import 'package:vantia/l10n/l10n.dart';

/// F-84: "Plan: Free · Tu prueba gratis termina en N días · Mejorar ahora".
class PlanCard extends ConsumerWidget {
  const PlanCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final plan = ref.watch(planProvider);
    final session = ref.watch(sessionProvider);
    final isOwner = session is SessionReady && session.isOwner;
    final on = context.vColors.onHighlight;
    return VCard(
      highlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(VantiaRadius.pill),
            ),
            child: Text(
              switch (plan.tier) {
                PlanTier.free => l10n.planFree,
                PlanTier.trial => l10n.planTrial,
                PlanTier.pro => l10n.planPro,
              },
              style: context.text.labelLarge?.copyWith(
                color: VantiaPalette.navy900,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: VantiaSpacing.md),
          Text(switch (plan.tier) {
            PlanTier.trial => l10n.planTrialDays(plan.trialDaysLeft),
            PlanTier.free => l10n.planFreeBody,
            PlanTier.pro => l10n.planProBody,
          }, style: TextStyle(color: on)),
          if (plan.tier != PlanTier.pro)
            for (final b in [
              l10n.planBenefit1,
              l10n.planBenefit2,
              l10n.planBenefit3,
              l10n.planBenefit4,
            ])
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('✓  $b', style: TextStyle(color: on)),
              ),
          if (plan.tier != PlanTier.pro && isOwner) ...[
            const SizedBox(height: VantiaSpacing.md),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                foregroundColor: on,
                side: BorderSide(color: on),
              ),
              onPressed: () => context.push(Routes.paywall),
              child: Text(l10n.planUpgrade),
            ),
          ],
        ],
      ),
    );
  }
}

/// Muestra el paywall si la función requiere Pro. Devuelve true si puede seguir.
bool requirePro(BuildContext context, WidgetRef ref) {
  if (ref.read(planProvider).isPro) return true;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.l10n.proRequired),
      action: SnackBarAction(
        label: context.l10n.planUpgrade,
        onPressed: () => context.push(Routes.paywall),
      ),
    ),
  );
  return false;
}
