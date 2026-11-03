import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/core/observability/analytics.dart';
import 'package:vantia/core/time/clock.dart';
import 'package:vantia/core/time/lima_time.dart';
import 'package:vantia/core/widgets/error_messages.dart';
import 'package:vantia/core/widgets/money_field.dart';
import 'package:vantia/core/widgets/money_text.dart';
import 'package:vantia/core/widgets/payment_method_icon.dart';
import 'package:vantia/core/widgets/v_button.dart';
import 'package:vantia/core/widgets/v_text_field.dart';
import 'package:vantia/features/automation/application/receipt_providers.dart';
import 'package:vantia/features/payments/application/payment_providers.dart';
import 'package:vantia/features/payments/domain/payment.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';
import 'package:vantia/l10n/l10n.dart';

/// Datos que pueden llegar prellenados (OCR, carrito de productos).
class PaymentPrefill {
  const PaymentPrefill({
    this.amount,
    this.occurredAt,
    this.operationNumber,
    this.payerName,
    this.description,
    this.items = const [],
    this.source = PaymentSource.manual,
    this.receiptFilePath,
    this.detectedMethod,
  });

  final Money? amount;
  final String? receiptFilePath;
  final PaymentMethod? detectedMethod;
  final DateTime? occurredAt;
  final String? operationNumber;
  final String? payerName;
  final String? description;
  final List<PaymentItem> items;
  final PaymentSource source;
}

/// F-21 (efectivo) / F-22 (digital): "Confirmar pago".
class PaymentFormScreen extends ConsumerStatefulWidget {
  const PaymentFormScreen({
    required this.method,
    super.key,
    this.prefill = const PaymentPrefill(),
    this.onScanReceipt,
  });

  final PaymentMethod method;
  final PaymentPrefill prefill;

  /// Abre el escáner de comprobantes (M7). Devuelve datos para prellenar.
  final Future<PaymentPrefill?> Function(BuildContext)? onScanReceipt;

  @override
  ConsumerState<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends ConsumerState<PaymentFormScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _change = TextEditingController();
  final _description = TextEditingController();
  final _operation = TextEditingController();
  final _payer = TextEditingController();
  late DateTime _limaWall; // hora de pared en Lima
  late PaymentSource _source;
  late List<PaymentItem> _items;
  String? _receiptFile;
  bool _saving = false;

  bool get _isCash => widget.method == PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _applyPrefill(widget.prefill, initial: true);
  }

  void _applyPrefill(PaymentPrefill p, {bool initial = false}) {
    final when = p.occurredAt ?? (initial ? ref.read(clockProvider)() : null);
    if (when != null) _limaWall = LimaTime.toLima(when);
    if (p.amount != null) {
      _amount.text = p.amount!.format(withSymbol: false).replaceAll(',', '');
    }
    if (p.operationNumber != null) _operation.text = p.operationNumber!;
    if (p.payerName != null) _payer.text = p.payerName!;
    if (p.description != null) _description.text = p.description!;
    if (initial) _items = p.items;
    _source = p.source;
    if (p.receiptFilePath != null) _receiptFile = p.receiptFilePath;
  }

  @override
  void dispose() {
    for (final c in [_amount, _change, _description, _operation, _payer]) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime get _occurredAt => LimaTime.fromLima(_limaWall);

  Money get _received => MoneyField.read(_amount) ?? const Money.zero();
  Money get _changeValue => MoneyField.read(_change) ?? const Money.zero();

  PaymentDraft get _draft => PaymentDraft(
    method: widget.method,
    received: _received,
    change: _isCash ? _changeValue : const Money.zero(),
    occurredAt: _occurredAt,
    description: _description.text,
    operationNumber: _isCash ? null : _operation.text,
    payerName: _isCash ? null : _payer.text,
    source: _source,
    items: _items,
  );

  String? _draftErrorMessage(PaymentDraftError e) {
    final l10n = context.l10n;
    return switch (e) {
      PaymentDraftError.amountRequired => l10n.errAmountRequired,
      PaymentDraftError.changeInvalid => l10n.errChangeInvalid,
      PaymentDraftError.changeTooBig => l10n.errChangeTooBig,
      PaymentDraftError.futureDate => l10n.errFutureDate,
    };
  }

  Future<void> _pickDate() async {
    final now = LimaTime.toLima(ref.read(clockProvider)());
    final picked = await showDatePicker(
      context: context,
      initialDate: _limaWall,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) {
      setState(
        () => _limaWall = DateTime.utc(
          picked.year,
          picked.month,
          picked.day,
          _limaWall.hour,
          _limaWall.minute,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _limaWall.hour, minute: _limaWall.minute),
    );
    if (picked != null) {
      setState(
        () => _limaWall = DateTime.utc(
          _limaWall.year,
          _limaWall.month,
          _limaWall.day,
          picked.hour,
          picked.minute,
        ),
      );
    }
  }

  Future<void> _scan() async {
    final scan = widget.onScanReceipt ?? ref.read(receiptScannerProvider).scan;
    final result = await scan(context);
    if (result == null || !mounted) return;
    setState(() => _applyPrefill(result));
    final l10n = context.l10n;
    if (result.amount == null) {
      showSnack(context, l10n.ocrNoAmount);
    } else if (result.detectedMethod != null &&
        result.detectedMethod != widget.method) {
      showSnack(context, l10n.ocrOtherMethod(result.detectedMethod!.label));
    }
    ref.read(analyticsProvider).log(AnalyticsEvent.ocrScan, {
      'success': result.amount != null,
    }).ignore();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final l10n = context.l10n;
    final draft = _draft;
    final error = draft.validate(now: ref.read(clockProvider)());
    if (error != null) {
      showSnack(context, _draftErrorMessage(error)!);
      return;
    }
    final session = ref.read(sessionProvider);
    if (session is! SessionReady) return;
    final repo = ref.read(paymentRepositoryProvider);

    final op = draft.operationNumber?.trim() ?? '';
    if (op.isNotEmpty &&
        await repo.existsOperation(
          ref.read(paymentScopeProvider)!,
          method: draft.method.id,
          operationNumber: op,
        )) {
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.duplicateTitle),
          content: Text(l10n.duplicateBody(draft.method.label, op)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.registerAnyway),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    setState(() => _saving = true);

    final receiptPath = _receiptFile == null
        ? null
        : await ref
              .read(receiptStorageProvider)
              .upload(session.businessId, _receiptFile!);
    final result = await repo.create(
      businessId: session.businessId,
      userId: session.uid,
      userName: ref.read(currentUserNameProvider),
      draft: PaymentDraft(
        method: draft.method,
        received: draft.received,
        change: draft.change,
        occurredAt: draft.occurredAt,
        description: draft.description,
        operationNumber: draft.operationNumber,
        payerName: draft.payerName,
        source: draft.source,
        items: draft.items,
        receiptPath: receiptPath,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold((_) {
      ref.read(analyticsProvider).log(AnalyticsEvent.paymentRegistered, {
        'method': draft.method.id,
        'source': draft.source.name,
      }).ignore();
      showSnack(context, l10n.paymentRegistered(draft.net.format()));
      context.pop();
    }, (f) => showSnack(context, failureMessage(l10n, f)));
  }

  String? _validateAmount(String? v) {
    final l10n = context.l10n;
    final m = Money.tryParse(v ?? '');
    if (v == null || v.trim().isEmpty) return l10n.errAmountRequired;
    if (m == null) return l10n.errInvalidAmount;
    if (!m.isPositive) return l10n.errAmountRequired;
    return null;
  }

  String? _validateChange(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final l10n = context.l10n;
    final m = Money.tryParse(v);
    if (m == null) return l10n.errInvalidAmount;
    if (m >= _received && _received.isPositive) return l10n.errChangeTooBig;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final net = _draft.net;
    final canSubmit = _received.isPositive && !_saving;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.confirmPaymentTitle), centerTitle: false),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(VantiaSpacing.page),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(VantiaSpacing.md),
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(VantiaRadius.md),
                ),
                child: PaymentMethodIcon(widget.method, size: 64),
              ),
            ),
            if (!_isCash) ...[
              const SizedBox(height: VantiaSpacing.md),
              VButton(
                variant: VButtonVariant.outlined,
                icon: Icons.document_scanner_outlined,
                label: l10n.scanReceipt,
                onPressed: _scan,
              ),
            ],
            const SizedBox(height: VantiaSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: VTextField(
                    label: l10n.fieldDate,
                    readOnly: true,
                    onTap: _pickDate,
                    controller: TextEditingController(
                      text:
                          '${_limaWall.year}-${_two(_limaWall.month)}-${_two(_limaWall.day)}',
                    ),
                  ),
                ),
                const SizedBox(width: VantiaSpacing.md),
                Expanded(
                  child: VTextField(
                    label: l10n.fieldTime,
                    readOnly: true,
                    onTap: _pickTime,
                    controller: TextEditingController(
                      text: '${_two(_limaWall.hour)}:${_two(_limaWall.minute)}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VantiaSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MoneyField(
                    label: _isCash
                        ? l10n.fieldAmountReceived
                        : l10n.fieldAmount,
                    hint: l10n.hintAmount,
                    controller: _amount,
                    validator: _validateAmount,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_isCash) ...[
                  const SizedBox(width: VantiaSpacing.md),
                  Expanded(
                    child: MoneyField(
                      label: l10n.fieldChange,
                      hint: l10n.hintChange,
                      controller: _change,
                      validator: _validateChange,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ],
            ),
            if (!_isCash) ...[
              const SizedBox(height: VantiaSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: VTextField(
                      label: l10n.fieldOperation,
                      hint: l10n.hintOptional,
                      controller: _operation,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: VantiaSpacing.md),
                  Expanded(
                    child: VTextField(
                      label: l10n.fieldPayer,
                      hint: l10n.hintOptional,
                      controller: _payer,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: VantiaSpacing.md),
            VTextField(
              label: l10n.fieldDescription,
              hint: l10n.hintDescription,
              controller: _description,
            ),
            if (_items.isNotEmpty) ...[
              const SizedBox(height: VantiaSpacing.md),
              Text(l10n.detailProducts, style: context.text.titleSmall),
              for (final i in _items)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${i.quantity} × ${i.name}'),
                  trailing: MoneyText(i.subtotal),
                ),
            ],
            if (_isCash && _received.isPositive) ...[
              const SizedBox(height: VantiaSpacing.md),
              Row(
                children: [
                  Expanded(child: Text(l10n.netSale)),
                  MoneyText(net, style: context.text.titleMedium),
                ],
              ),
            ],
            const SizedBox(height: VantiaSpacing.lg),
            VButton(
              label: l10n.registerPayment,
              loading: _saving,
              onPressed: canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
