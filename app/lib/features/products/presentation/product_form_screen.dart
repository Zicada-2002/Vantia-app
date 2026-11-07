import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/core/observability/analytics.dart';
import 'package:vantia/core/validation/validators.dart';
import 'package:vantia/core/widgets/error_messages.dart';
import 'package:vantia/core/widgets/money_field.dart';
import 'package:vantia/core/widgets/v_button.dart';
import 'package:vantia/core/widgets/v_text_field.dart';
import 'package:vantia/features/products/application/product_providers.dart';
import 'package:vantia/features/products/domain/product.dart';
import 'package:vantia/l10n/l10n.dart';

/// F-61 / F-62: alta y edición de producto.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId, this.barcode});

  final String? productId;
  final String? barcode;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _barcode = TextEditingController();
  final _category = TextEditingController();
  final _stock = TextEditingController();
  Product? _editing;

  @override
  void initState() {
    super.initState();
    _barcode.text = widget.barcode ?? '';
    final id = widget.productId;
    if (id != null) {
      _editing = ref
          .read(productsProvider)
          .value
          ?.where((p) => p.id == id)
          .firstOrNull;
      final p = _editing;
      if (p != null) {
        _name.text = p.name;
        _price.text = p.price.format(withSymbol: false).replaceAll(',', '');
        _barcode.text = p.barcode ?? '';
        _category.text = p.category ?? '';
        _stock.text = p.stock?.toString() ?? '';
      }
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _price, _barcode, _category, _stock]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final session = ref.read(sessionProvider);
    if (session is! SessionReady) return;
    final l10n = context.l10n;
    final r = await ref
        .read(productRepositoryProvider)
        .save(
          session.businessId,
          ProductDraft(
            name: _name.text,
            price: MoneyField.read(_price) ?? const Money.zero(),
            barcode: _barcode.text,
            category: _category.text,
            stock: int.tryParse(_stock.text.trim()),
          ),
          id: _editing?.id,
        );
    if (!mounted) return;
    r.fold((_) {
      if (_editing == null) {
        ref.read(analyticsProvider).log(AnalyticsEvent.productCreated, {
          'has_barcode': _barcode.text.trim().isNotEmpty,
        }).ignore();
      }
      showSnack(context, l10n.productSaved);
      context.pop();
    }, (f) => showSnack(context, failureMessage(l10n, f)));
  }

  Future<void> _deactivate() async {
    final session = ref.read(sessionProvider) as SessionReady;
    await ref
        .read(productRepositoryProvider)
        .deactivate(session.businessId, _editing!.id);
    if (!mounted) return;
    showSnack(context, context.l10n.productDeactivated);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing == null ? l10n.productNew : l10n.productEdit),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(VantiaSpacing.page),
          children: [
            VTextField(
              label: l10n.fieldProductName,
              hint: l10n.hintProductName,
              controller: _name,
              validator: validatorFor(context, Validators.required),
            ),
            const SizedBox(height: VantiaSpacing.md),
            MoneyField(
              label: l10n.fieldPrice,
              controller: _price,
              validator: (v) => Money.tryParse(v ?? '') == null
                  ? l10n.errInvalidAmount
                  : null,
            ),
            const SizedBox(height: VantiaSpacing.md),
            VTextField(
              label: l10n.fieldBarcode,
              hint: l10n.hintOptional,
              controller: _barcode,
              keyboardType: TextInputType.number,
              suffix: IconButton(
                tooltip: l10n.cartScan,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                onPressed: () async {
                  final code = await ref.read(barcodeScannerProvider)(context);
                  if (code != null) _barcode.text = code;
                },
              ),
            ),
            const SizedBox(height: VantiaSpacing.md),
            VTextField(
              label: l10n.fieldCategory,
              hint: l10n.hintOptional,
              controller: _category,
            ),
            const SizedBox(height: VantiaSpacing.md),
            VTextField(
              label: l10n.fieldStock,
              hint: l10n.hintStock,
              controller: _stock,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: VantiaSpacing.xl),
            VButton(label: l10n.productSave, onPressed: _save),
            if (_editing != null) ...[
              const SizedBox(height: VantiaSpacing.md),
              VButton(
                variant: VButtonVariant.text,
                label: l10n.productDeactivate,
                onPressed: _deactivate,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
