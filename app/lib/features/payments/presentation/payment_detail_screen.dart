import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/core/observability/analytics.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/core/time/clock.dart';
import 'package:vantia/core/time/lima_time.dart';
import 'package:vantia/core/widgets/empty_state.dart';
import 'package:vantia/core/widgets/error_messages.dart';
import 'package:vantia/core/widgets/money_text.dart';
import 'package:vantia/core/widgets/payment_method_icon.dart';
import 'package:vantia/core/widgets/v_button.dart';
import 'package:vantia/core/widgets/v_card.dart';
import 'package:vantia/features/payments/application/payment_providers.dart';
import 'package:vantia/features/payments/domain/payment.dart';
import 'package:vantia/l10n/l10n.dart';

/// F-26: detalle y anulación lógica.
class PaymentDetailScreen extends ConsumerWidget {
  const PaymentDetailScreen({required this.paymentId, super.key});

  final String paymentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final payment = ref.watch(paymentProvider(paymentId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentDetail)),
      body: switch (payment) {
        AsyncData(value: final p?) => _Detail(payment: p),
        AsyncData() || AsyncError() => EmptyState(
          icon: Icons.search_off_rounded,
          message: l10n.notFound,
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(sessionProvider);
    final now = ref.watch(clockProvider)();
    final permission = session is SessionReady
        ? canVoid(payment: payment, session: session, now: now)
        : VoidPermission.notOwnPayment;
    final p = payment;

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: context.text.bodyMedium?.copyWith(
                color: context.vColors.muted,
              ),
            ),
          ),
          const SizedBox(width: VantiaSpacing.md),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(VantiaSpacing.page),
      children: [
        VCard(
          child: Column(
            children: [
              PaymentMethodIcon(p.method, size: 56),
              const SizedBox(height: VantiaSpacing.md),
              MoneyText(
                p.amount,
                style: context.text.headlineMedium?.copyWith(
                  decoration: p.isActive ? null : TextDecoration.lineThrough,
                ),
              ),
              if (!p.isActive)
                Text(
                  l10n.paymentVoided,
                  style: TextStyle(color: context.vColors.danger),
                ),
              if (p.pendingSync)
                Text(
                  l10n.paymentPending,
                  style: TextStyle(color: context.vColors.warning),
                ),
              const SizedBox(height: VantiaSpacing.md),
              const Divider(),
              row(l10n.detailMethod, p.method.label),
              row(
                l10n.detailDate,
                '${LimaTime.formatDate(p.occurredAt)} ${LimaTime.formatTime(p.occurredAt)}',
              ),
              row(l10n.detailRegisteredBy, p.createdByName),
              if (p.isCash && p.received != null) ...[
                row(l10n.detailReceived, p.received!.format()),
                row(
                  l10n.detailChange,
                  (p.change ?? const Money.zero()).format(),
                ),
              ],
              if (p.operationNumber != null)
                row(l10n.fieldOperation, p.operationNumber!),
              if (p.payerName != null) row(l10n.fieldPayer, p.payerName!),
              if (p.description != null)
                row(l10n.fieldDescription, p.description!),
              row(l10n.detailSource, switch (p.source) {
                PaymentSource.manual => l10n.sourceManual,
                PaymentSource.ocr => l10n.sourceOcr,
                PaymentSource.notification => l10n.sourceNotification,
              }),
              if (p.voidReason != null)
                row(l10n.detailVoidReason, p.voidReason!),
            ],
          ),
        ),
        if (p.items.isNotEmpty) ...[
          const SizedBox(height: VantiaSpacing.md),
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.detailProducts, style: context.text.titleSmall),
                for (final i in p.items)
                  row('${i.quantity} × ${i.name}', i.subtotal.format()),
              ],
            ),
          ),
        ],
        const SizedBox(height: VantiaSpacing.lg),
        if (p.isActive)
          VButton(
            variant: VButtonVariant.outlined,
            icon: Icons.block_rounded,
            label: l10n.voidPayment,
            onPressed: switch (permission) {
              VoidPermission.allowed => () => _void(context, ref),
              VoidPermission.windowExpired => () => showSnack(
                context,
                l10n.voidWindowExpired,
              ),
              _ => () => showSnack(context, l10n.voidNotAllowed),
            },
          ),
      ],
    );
  }

  Future<void> _void(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _VoidDialog(),
    );
    if (reason == null || !context.mounted) return;
    final session = ref.read(sessionProvider) as SessionReady;
    final result = await ref
        .read(paymentRepositoryProvider)
        .voidPayment(
          businessId: session.businessId,
          paymentId: payment.id,
          userId: session.uid,
          reason: reason,
        );
    if (!context.mounted) return;
    switch (result) {
      case Ok():
        ref.read(analyticsProvider).log(AnalyticsEvent.paymentVoided).ignore();
        showSnack(context, l10n.voidDone);
      case Err(:final failure):
        showSnack(context, failureMessage(l10n, failure));
    }
  }
}

class _VoidDialog extends StatefulWidget {
  const _VoidDialog();

  @override
  State<_VoidDialog> createState() => _VoidDialogState();
}

class _VoidDialogState extends State<_VoidDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final valid = _reason.text.trim().length >= 3;
    return AlertDialog(
      title: Text(l10n.voidTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.voidBody),
          const SizedBox(height: VantiaSpacing.md),
          TextField(
            controller: _reason,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.voidReasonLabel,
              hintText: l10n.voidReasonHint,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: valid ? () => Navigator.pop(context, _reason.text) : null,
          child: Text(l10n.voidConfirm),
        ),
      ],
    );
  }
}
