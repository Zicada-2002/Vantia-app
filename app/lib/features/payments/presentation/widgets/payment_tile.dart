import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/routes.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/time/lima_time.dart';
import 'package:vantia/core/widgets/money_text.dart';
import 'package:vantia/core/widgets/payment_method_icon.dart';
import 'package:vantia/features/payments/domain/payment.dart';
import 'package:vantia/l10n/l10n.dart';

/// Fila de un pago: ícono, "Pago por Yape", fecha/hora, quién lo registró
/// y el monto.
class PaymentTile extends ConsumerWidget {
  const PaymentTile({required this.payment, super.key, this.showDate = true});

  final Payment payment;
  final bool showDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(sessionProvider);
    final mine = session is SessionReady && session.uid == payment.createdBy;
    final voided = !payment.isActive;
    final when = showDate
        ? '${LimaTime.formatDate(payment.occurredAt)} · ${LimaTime.formatTime(payment.occurredAt)}'
        : LimaTime.formatTime(payment.occurredAt);

    return InkWell(
      onTap: () => context.push(Routes.paymentDetail(payment.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VantiaSpacing.md,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(VantiaRadius.sm),
              ),
              child: PaymentMethodIcon(payment.method, size: 40),
            ),
            const SizedBox(width: VantiaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.paymentBy(payment.method.label),
                    style: context.text.titleSmall?.copyWith(
                      decoration: voided ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          payment.description?.isNotEmpty ?? false
                              ? '$when · ${payment.description}'
                              : when,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall?.copyWith(
                            color: context.vColors.muted,
                          ),
                        ),
                      ),
                      if (payment.pendingSync) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 14,
                          color: context.vColors.warning,
                          semanticLabel: l10n.paymentPending,
                        ),
                      ],
                      if (payment.verified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: context.vColors.success,
                          semanticLabel: l10n.paymentVerified,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: VantiaSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Badge(
                  text: voided
                      ? l10n.paymentVoided
                      : (mine ? l10n.paymentByMe : payment.createdByName),
                  danger: voided,
                ),
                const SizedBox(height: 4),
                MoneyText(
                  payment.amount,
                  style: context.text.titleMedium?.copyWith(
                    color: voided ? context.vColors.muted : null,
                    decoration: voided ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.danger = false});

  final String text;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final bg = danger
        ? context.vColors.danger.withValues(alpha: 0.18)
        : context.vColors.highlight;
    final fg = danger ? context.vColors.danger : context.vColors.onHighlight;
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.text.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}
