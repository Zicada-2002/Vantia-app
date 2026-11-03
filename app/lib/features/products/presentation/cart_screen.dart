import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/widgets/error_messages.dart';
import 'package:vantia/core/widgets/money_text.dart';
import 'package:vantia/core/widgets/v_button.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';
import 'package:vantia/features/payments/presentation/payment_form_screen.dart';
import 'package:vantia/features/products/application/product_providers.dart';
import 'package:vantia/features/products/domain/product.dart';
import 'package:vantia/features/products/presentation/products_screen.dart';
import 'package:vantia/l10n/l10n.dart';

/// F-63: carrito de la venta con productos → formulario de pago prellenado.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({required this.method, super.key});

  final PaymentMethod method;

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  Cart _cart = const Cart();
  String _query = '';

  void _add(Product p) {
    if (!_cart.canAdd(p)) {
      showSnack(context, context.l10n.cartOutOfStock(p.name));
      return;
    }
    setState(() => _cart = _cart.add(p));
  }

  Future<void> _scan() async {
    final code = await ref.read(barcodeScannerProvider)(context);
    if (code == null || !mounted) return;
    final products = ref.read(productsProvider).value ?? const <Product>[];
    final match = products.where((p) => p.barcode == code).firstOrNull;
    if (match == null) {
      showSnack(context, context.l10n.cartUnknownBarcode(code));
    } else {
      _add(match);
    }
  }

  void _continue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => PaymentFormScreen(
          method: widget.method,
          prefill: PaymentPrefill(
            amount: _cart.total,
            items: _cart.toItems(),
            description: _cart.lines.values
                .map((l) => '${l.$2} ${l.$1.name}')
                .join(', '),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final products = searchProducts(
      ref.watch(productsProvider).value ?? const [],
      _query,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cartTitle),
        actions: [
          IconButton(
            tooltip: l10n.cartScan,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: _scan,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(VantiaSpacing.md),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.productsSearch,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? Center(child: Text(l10n.cartEmpty))
                : ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (_, i) {
                      final p = products[i];
                      final qty = _cart.quantityOf(p.id);
                      return ProductTile(
                        product: p,
                        onTap: () => _add(p),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (qty > 0) ...[
                              IconButton(
                                tooltip: '−',
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () =>
                                    setState(() => _cart = _cart.add(p, -1)),
                              ),
                              Text('$qty', style: context.text.titleMedium),
                            ],
                            IconButton(
                              tooltip: '${l10n.cartAdd} ${p.name}',
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => _add(p),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(VantiaSpacing.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.cartTotal,
                          style: context.text.titleMedium,
                        ),
                      ),
                      MoneyText(_cart.total, style: context.text.titleLarge),
                    ],
                  ),
                  const SizedBox(height: VantiaSpacing.md),
                  VButton(
                    label: l10n.cartContinue,
                    onPressed: _cart.isEmpty ? null : _continue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
