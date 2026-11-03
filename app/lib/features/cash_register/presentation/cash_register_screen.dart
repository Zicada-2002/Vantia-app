import 'dart:async';

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
import 'package:vantia/core/widgets/error_messages.dart';
import 'package:vantia/core/widgets/money_field.dart';
import 'package:vantia/core/widgets/money_text.dart';
import 'package:vantia/core/widgets/payment_method_icon.dart';
import 'package:vantia/core/widgets/reason_dialog.dart';
import 'package:vantia/core/widgets/v_button.dart';
import 'package:vantia/core/widgets/v_card.dart';
import 'package:vantia/features/cash_register/application/cash_providers.dart';
import 'package:vantia/features/cash_register/domain/cash_session.dart';
import 'package:vantia/features/payments/application/payment_providers.dart';
import 'package:vantia/features/payments/domain/payment.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';
import 'package:vantia/l10n/l10n.dart';

enum CashView { mine, general }

/// M4: cuadre de caja (F-40 … F-45).
class CashRegisterScreen extends ConsumerStatefulWidget {
  const CashRegisterScreen({super.key});

  @override
  ConsumerState<CashRegisterScreen> createState() => _CashRegisterScreenState();
}

class _CashRegisterScreenState extends ConsumerState<CashRegisterScreen> {
  CashView _view = CashView.mine;

  Future<void> _pickDate() async {
    final now = LimaTime.toLima(ref.read(clockProvider)());
    final current = LimaTime.toLima(ref.read(cashDayProvider));
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(current.year, current.month, current.day),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) ref.read(cashDayProvider.notifier).select(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(sessionProvider);
    final isOwner = session is SessionReady && session.isOwner;
    final day = ref.watch(cashDayProvider);
    final isToday = LimaTime.isSameDay(day, ref.watch(clockProvider)());
    final suffix = isToday ? ' ${l10n.cashToday}' : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleCashRegister),
        actions: [
          IconButton(
            tooltip: l10n.cashPickDate,
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VantiaSpacing.page,
          0,
          VantiaSpacing.page,
          VantiaSpacing.xl,
        ),
        children: [
          Text(
            l10n.cashViewing(LimaTime.formatDate(day)),
            style: TextStyle(color: context.vColors.muted),
          ),
          const SizedBox(height: VantiaSpacing.md),
          if (isOwner)
            Align(
              alignment: Alignment.centerLeft,
              child: DropdownButton<CashView>(
                value: _view,
                isExpanded: true,
                underline: const SizedBox(),
                style: context.text.titleMedium?.copyWith(
                  color: context.colors.primary,
                ),
                items: [
                  DropdownMenuItem(
                    value: CashView.mine,
                    child: Text('${l10n.cashMine}$suffix'),
                  ),
                  DropdownMenuItem(
                    value: CashView.general,
                    child: Text('${l10n.cashGeneral}$suffix'),
                  ),
                ],
                onChanged: (v) => setState(() => _view = v ?? CashView.mine),
              ),
            )
          else
            Text(
              '${l10n.cashMine}$suffix',
              style: context.text.titleMedium?.copyWith(
                color: context.colors.primary,
              ),
            ),
          const SizedBox(height: VantiaSpacing.sm),
          if (_view == CashView.mine || !isOwner)
            const _MyCash()
          else
            const _GeneralSummary(),
        ],
      ),
    );
  }
}

List<Payment> _dayPayments(WidgetRef ref) {
  final day = ref.watch(cashDayProvider);
  return ref
          .watch(
            rangePaymentsProvider((
              from: day,
              to: day.add(const Duration(days: 1)),
            )),
          )
          .value ??
      const [];
}

class _MethodBreakdown extends StatelessWidget {
  const _MethodBreakdown({required this.title, required this.summary});

  final String title;
  final PaymentSummary summary;

  @override
  Widget build(BuildContext context) {
    final methods = [
      for (final m in PaymentMethod.values)
        if (summary.byMethod.containsKey(m) || m == PaymentMethod.cash) m,
    ];
    return VCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: context.text.titleMedium)),
              MoneyText(summary.total, style: context.text.titleMedium),
            ],
          ),
          const Divider(height: VantiaSpacing.lg),
          for (final m in methods)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  PaymentMethodIcon(m, size: 24),
                  const SizedBox(width: VantiaSpacing.sm),
                  Expanded(child: Text(m.label)),
                  MoneyText(
                    summary.byMethod[m] ?? const Money.zero(),
                    style: TextStyle(color: context.vColors.muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MyCash extends ConsumerStatefulWidget {
  const _MyCash();

  @override
  ConsumerState<_MyCash> createState() => _MyCashState();
}

class _MyCashState extends ConsumerState<_MyCash> {
  final _opening = TextEditingController();
  final _counted = TextEditingController();
  String? _loadedFor;
  Timer? _debounce;
  bool _closing = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _opening.dispose();
    _counted.dispose();
    super.dispose();
  }

  void _fill(CashSession? s, String dayKey) {
    if (_loadedFor == dayKey) return;
    _loadedFor = dayKey;
    _opening.text = s == null || s.opening.isZero
        ? ''
        : s.opening.format(withSymbol: false).replaceAll(',', '');
    _counted.text = s?.counted == null
        ? ''
        : s!.counted!.format(withSymbol: false).replaceAll(',', '');
  }

  void _saveDraftLater(SessionReady session, String dayKey, bool exists) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      ref
          .read(cashRepositoryProvider)
          .saveDraft(
            businessId: session.businessId,
            dayKey: dayKey,
            uid: session.uid,
            displayName: ref.read(currentUserNameProvider),
            exists: exists,
            opening: MoneyField.read(_opening),
            counted: MoneyField.read(_counted),
          )
          .ignore();
    });
  }

  Future<void> _close(String dayKey, CashCount count) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cashCloseTitle),
        content: Text(l10n.cashCloseBody(count.difference.format())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.cashClose),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _closing = true);
    _debounce?.cancel();
    final r = await ref
        .read(cashRepositoryProvider)
        .close(dayKey: dayKey, opening: count.opening, counted: count.counted);
    if (!mounted) return;
    setState(() => _closing = false);
    switch (r) {
      case Ok():
        ref.read(analyticsProvider).log(AnalyticsEvent.cashClosed, {
          'difference_sign': count.difference.cents.sign,
        }).ignore();
        showSnack(context, l10n.cashClosed);
      case Err(:final failure):
        showSnack(context, failureMessage(l10n, failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(sessionProvider);
    if (session is! SessionReady) return const SizedBox();
    final dayKey = LimaTime.dayKey(ref.watch(cashDayProvider));
    final mySession = ref.watch(mySessionProvider);
    final cash = mySession.value;
    if (mySession.hasValue) _fill(cash, dayKey);

    final mine = _dayPayments(
      ref,
    ).where((p) => p.createdBy == session.uid).toList();
    final summary = PaymentSummary.of(mine);
    final closed = cash?.isClosed ?? false;
    final count = CashCount.from(
      summary,
      opening: closed
          ? cash!.opening
          : (MoneyField.read(_opening) ?? const Money.zero()),
      counted: closed
          ? (cash!.counted ?? const Money.zero())
          : (MoneyField.read(_counted) ?? const Money.zero()),
    );
    final hasCounted = _counted.text.trim().isNotEmpty;

    void changed(String _) {
      setState(() {});
      _saveDraftLater(session, dayKey, cash != null);
    }

    Widget line(String label, Money value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: context.vColors.muted)),
          ),
          MoneyText(value, style: TextStyle(color: context.vColors.muted)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MethodBreakdown(title: l10n.cashShiftTotal, summary: summary),
        const SizedBox(height: VantiaSpacing.md),
        Text(
          l10n.cashPhysical,
          style: context.text.titleMedium?.copyWith(
            color: context.colors.primary,
          ),
        ),
        const SizedBox(height: VantiaSpacing.sm),
        VCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (closed)
                line(l10n.cashOpening, count.opening)
              else
                MoneyField(
                  label: l10n.cashOpening,
                  hint: '0.00',
                  controller: _opening,
                  onChanged: changed,
                ),
              const SizedBox(height: VantiaSpacing.sm),
              line(l10n.cashReceived, count.cashReceived),
              line(l10n.cashChangeGiven, count.changeGiven),
              line(l10n.cashExpected, count.expected),
              const Divider(height: VantiaSpacing.lg),
              if (closed)
                line(l10n.cashCounted, count.counted)
              else
                MoneyField(
                  label: l10n.cashCounted,
                  hint: '0.00',
                  controller: _counted,
                  onChanged: changed,
                ),
              const Divider(height: VantiaSpacing.lg),
              _DifferenceRow(difference: count.difference),
              const SizedBox(height: VantiaSpacing.lg),
              if (closed) ...[
                Text(
                  l10n.cashClosedAt(
                    cash!.closedAt == null
                        ? LimaTime.formatDate(ref.read(cashDayProvider))
                        : '${LimaTime.formatDate(cash.closedAt!)} ${LimaTime.formatTime(cash.closedAt!)}',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.vColors.success),
                ),
              ] else ...[
                if (cash?.status == CashStatus.reopened &&
                    cash?.reopenReason != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: VantiaSpacing.sm),
                    child: Text(
                      l10n.cashReopened(cash!.reopenReason!),
                      style: TextStyle(color: context.vColors.warning),
                    ),
                  ),
                VButton(
                  label: l10n.cashClose,
                  loading: _closing,
                  onPressed: hasCounted ? () => _close(dayKey, count) : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DifferenceRow extends StatelessWidget {
  const _DifferenceRow({required this.difference});

  final Money difference;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (color, label) = difference.isZero
        ? (context.vColors.success, l10n.cashExact)
        : difference.isPositive
        ? (context.vColors.warning, l10n.cashOver)
        : (context.vColors.danger, l10n.cashShort);
    return Row(
      children: [
        Expanded(
          child: Text(l10n.cashDifference, style: context.text.titleMedium),
        ),
        Text(label, style: TextStyle(color: color)),
        const SizedBox(width: VantiaSpacing.sm),
        MoneyText(
          difference,
          style: context.text.titleMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// F-44: suma de todas las cajas del día y estado por persona.
class _GeneralSummary extends ConsumerWidget {
  const _GeneralSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final payments = _dayPayments(ref);
    final summary = PaymentSummary.of(payments);
    final sessions = {
      for (final s in ref.watch(daySessionsProvider).value ?? <CashSession>[])
        s.uid: s,
    };
    final byUser = <String, List<Payment>>{};
    for (final p in payments) {
      byUser.putIfAbsent(p.createdBy, () => []).add(p);
    }
    final uids = {...byUser.keys, ...sessions.keys};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MethodBreakdown(title: l10n.cashGeneralTotal, summary: summary),
        const SizedBox(height: VantiaSpacing.md),
        Text(
          l10n.cashTeam,
          style: context.text.titleMedium?.copyWith(
            color: context.colors.primary,
          ),
        ),
        for (final uid in uids)
          _TeamRow(
            uid: uid,
            name:
                sessions[uid]?.displayName ??
                byUser[uid]?.first.createdByName ??
                '',
            session: sessions[uid],
            total: PaymentSummary.of(byUser[uid] ?? const []).total,
          ),
      ],
    );
  }
}

class _TeamRow extends ConsumerWidget {
  const _TeamRow({
    required this.uid,
    required this.name,
    required this.session,
    required this.total,
  });

  final String uid;
  final String name;
  final CashSession? session;
  final Money total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final s = session;
    final status = s == null
        ? l10n.cashStatusNone
        : s.isClosed
        ? l10n.cashStatusClosed
        : l10n.cashStatusOpen;
    final diff = s?.difference;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name.isEmpty ? '—' : name),
      subtitle: Text(
        [
          status,
          if (s?.isClosed ?? false)
            '${l10n.cashDifference}: ${(diff ?? const Money.zero()).format()}',
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MoneyText(total),
          if (s?.isClosed ?? false)
            IconButton(
              tooltip: l10n.cashReopen,
              icon: const Icon(Icons.lock_open_rounded),
              onPressed: () => _reopen(context, ref, s!),
            ),
        ],
      ),
    );
  }

  Future<void> _reopen(
    BuildContext context,
    WidgetRef ref,
    CashSession s,
  ) async {
    final l10n = context.l10n;
    final reason = await showReasonDialog(
      context,
      title: l10n.cashReopenTitle,
      label: l10n.cashReopenReason,
      confirm: l10n.cashReopen,
    );
    if (reason == null || !context.mounted) return;
    final r = await ref
        .read(cashRepositoryProvider)
        .reopen(dayKey: s.dayKey, uid: s.uid, reason: reason);
    if (!context.mounted) return;
    showSnack(
      context,
      r.fold((_) => l10n.cashReopenDone, (f) => failureMessage(l10n, f)),
    );
  }
}
