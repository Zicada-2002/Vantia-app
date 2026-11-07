import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/core/widgets/money_text.dart';
import 'package:vantia/core/widgets/v_card.dart';
import 'package:vantia/features/payments/application/payment_providers.dart';
import 'package:vantia/features/payments/domain/payment.dart';
import 'package:vantia/features/payments/presentation/widgets/payment_tile.dart';
import 'package:vantia/l10n/l10n.dart';

/// F-23 / F-24: resumen del día y últimos pagos.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(sessionProvider);
    final isOwner = session is SessionReady && session.isOwner;
    final summary = ref.watch(todaySummaryProvider);
    final recent = ref.watch(recentPaymentsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        VantiaSpacing.page,
        VantiaSpacing.sm,
        VantiaSpacing.page,
        VantiaSpacing.bottomSafe,
      ),
      children: [
        _SectionTitle(l10n.homeSummary),
        const SizedBox(height: VantiaSpacing.sm),
        _SummaryCard(
          summary: summary.value ?? PaymentSummary.empty,
          loading: summary.isLoading,
          title: isOwner ? l10n.homeIncomeToday : l10n.homeMyIncomeToday,
        ),
        const SizedBox(height: VantiaSpacing.lg),
        _SectionTitle(l10n.homeLatest),
        const SizedBox(height: VantiaSpacing.sm),
        switch (recent) {
          AsyncData(:final value) when value.isEmpty => Padding(
            padding: const EdgeInsets.symmetric(vertical: VantiaSpacing.xl),
            child: Text(
              l10n.homeNoPayments,
              textAlign: TextAlign.center,
              style: context.text.bodyLarge?.copyWith(
                color: context.vColors.muted,
              ),
            ),
          ),
          AsyncData(:final value) => Column(
            children: [for (final p in value) PaymentTile(payment: p)],
          ),
          AsyncError() => Text(l10n.errUnknown),
          _ => const Padding(
            padding: EdgeInsets.all(VantiaSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
        },
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.text.titleMedium?.copyWith(color: context.colors.primary),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.summary,
    required this.loading,
    required this.title,
  });

  final PaymentSummary summary;
  final bool loading;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final on = context.vColors.onHighlight;
    final label = context.text.labelMedium?.copyWith(
      color: on.withValues(alpha: 0.7),
      letterSpacing: 0.5,
    );
    final value = context.text.titleMedium?.copyWith(color: on);

    Widget stat(String l, Widget v) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l, style: label),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, child: v),
        ],
      ),
    );

    return VCard(
      highlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: label),
          const SizedBox(height: VantiaSpacing.xs),
          if (loading)
            const SizedBox(height: 48)
          else
            MoneyText(
              summary.total,
              semanticsPrefix: title,
              style: context.text.headlineLarge?.copyWith(color: on),
            ),
          const SizedBox(height: VantiaSpacing.md),
          Divider(color: on.withValues(alpha: 0.2)),
          const SizedBox(height: VantiaSpacing.md),
          Row(
            children: [
              stat(
                l10n.homePaymentsCount,
                Text('${summary.count}', style: value),
              ),
              stat(l10n.homeCash, _money(summary.cash, value)),
              stat(l10n.homeDigital, _money(summary.digital, value)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _money(Money m, TextStyle? style) => MoneyText(m, style: style);
}
