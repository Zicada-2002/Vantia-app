import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/time/clock.dart';
import 'package:vantia/core/time/lima_time.dart';
import 'package:vantia/core/widgets/money_text.dart';
import 'package:vantia/core/widgets/v_card.dart';
import 'package:vantia/features/export/export_flow.dart';
import 'package:vantia/features/payments/application/payment_providers.dart';
import 'package:vantia/features/payments/domain/payment.dart';
import 'package:vantia/features/payments/presentation/widgets/payment_tile.dart';
import 'package:vantia/l10n/l10n.dart';

/// Semana seleccionada en la pestaña Pagos (lunes 00:00 Lima).
final selectedWeekProvider = NotifierProvider<SelectedWeek, DateTime>(
  SelectedWeek.new,
);

class SelectedWeek extends Notifier<DateTime> {
  @override
  DateTime build() => LimaTime.startOfWeek(ref.watch(clockProvider)());

  DateTime get _current => LimaTime.startOfWeek(ref.read(clockProvider)());

  bool get canGoNext => state.isBefore(_current);

  void previous() =>
      state = LimaTime.startOfWeek(state.subtract(const Duration(days: 3)));

  void next() {
    if (!canGoNext) return;
    state = LimaTime.startOfWeek(state.add(const Duration(days: 10)));
  }
}

/// F-25: pagos de la semana agrupados por día.
class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key, this.onExport});

  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final week = ref.watch(selectedWeekProvider);
    final controller = ref.read(selectedWeekProvider.notifier);
    final payments = ref.watch(weekPaymentsProvider(week));
    final now = ref.watch(clockProvider)();
    final summary = PaymentSummary.of(payments.value ?? const []);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            VantiaSpacing.page,
            VantiaSpacing.sm,
            VantiaSpacing.page,
            VantiaSpacing.md,
          ),
          sliver: SliverToBoxAdapter(
            child: VCard(
              highlight: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: l10n.paymentsPrevWeek,
                        onPressed: controller.previous,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Text(
                          LimaTime.formatWeekRange(week),
                          textAlign: TextAlign.center,
                          style: context.text.titleSmall,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.paymentsNextWeek,
                        onPressed: controller.canGoNext
                            ? controller.next
                            : null,
                        icon: const Icon(Icons.arrow_forward_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: VantiaSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.paymentsWeekIncome),
                            MoneyText(
                              summary.total,
                              style: context.text.headlineSmall,
                            ),
                          ],
                        ),
                      ),
                      if (onExport != null)
                        IconButton(
                          tooltip: l10n.paymentsExport,
                          onPressed: onExport,
                          icon: const Icon(
                            Icons.calendar_month_rounded,
                            size: 32,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        ...switch (payments) {
          AsyncData(:final value) when value.isEmpty => [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  l10n.paymentsEmptyWeek,
                  style: context.text.bodyLarge?.copyWith(
                    color: context.vColors.muted,
                  ),
                ),
              ),
            ),
          ],
          AsyncData(:final value) => [
            for (final group in groupByDay(value)) ...[
              SliverToBoxAdapter(
                child: _DayHeader(group: group, now: now),
              ),
              SliverList.list(
                children: [
                  for (final p in group.payments)
                    PaymentTile(payment: p, showDate: false),
                ],
              ),
            ],
            const SliverToBoxAdapter(
              child: SizedBox(height: VantiaSpacing.bottomSafe),
            ),
          ],
          _ => [
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        },
      ],
    );
  }
}

class DayGroup {
  const DayGroup(this.dayKey, this.date, this.payments);

  final String dayKey;
  final DateTime date;
  final List<Payment> payments;

  PaymentSummary get summary => PaymentSummary.of(payments);
}

/// Agrupa por `dayKey` (hora de Lima) manteniendo el orden recibido.
List<DayGroup> groupByDay(List<Payment> payments) {
  final groups = <String, List<Payment>>{};
  for (final p in payments) {
    groups.putIfAbsent(p.dayKey, () => []).add(p);
  }
  return [
    for (final e in groups.entries)
      DayGroup(e.key, e.value.first.occurredAt, e.value),
  ];
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.group, required this.now});

  final DayGroup group;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final date = LimaTime.formatShortDate(group.date).toUpperCase();
    final yesterday = now.subtract(const Duration(days: 1));
    final label = LimaTime.isSameDay(group.date, now)
        ? l10n.paymentsToday(date)
        : LimaTime.isSameDay(group.date, yesterday)
        ? l10n.paymentsYesterday(date)
        : '${LimaTime.formatWeekday(group.date).toUpperCase()}, $date';
    return Container(
      color: context.colors.surfaceContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: VantiaSpacing.page,
        vertical: VantiaSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.text.titleSmall?.copyWith(
                color: context.vColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          MoneyText(group.summary.total, style: context.text.titleSmall),
        ],
      ),
    );
  }
}

/// Pestaña Pagos con exportación para el dueño (F-54).
class PaymentsScreenWithExport extends ConsumerWidget {
  const PaymentsScreenWithExport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final isOwner = session is SessionReady && session.isOwner;
    return PaymentsScreen(
      onExport: isOwner ? () => runExportFlow(context, ref) : null,
    );
  }
}
