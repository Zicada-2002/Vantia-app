import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/routes.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/core/widgets/empty_state.dart';
import 'package:vantia/core/widgets/money_text.dart';
import 'package:vantia/features/products/application/product_providers.dart';
import 'package:vantia/features/products/domain/product.dart';
import 'package:vantia/l10n/l10n.dart';

/// F-60: lista de productos con búsqueda.
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(sessionProvider);
    final isOwner = session is SessionReady && session.isOwner;
    final all = ref.watch(productsProvider).value ?? const <Product>[];
    if (all.isEmpty) {
      return EmptyState(message: l10n.productsEmpty, badge: '0');
    }
    final items = searchProducts(all, _query);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VantiaSpacing.page,
            VantiaSpacing.sm,
            VantiaSpacing.page,
            VantiaSpacing.sm,
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.productsSearch,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        if (!isOwner)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VantiaSpacing.page),
            child: Text(
              l10n.productReadOnly,
              style: TextStyle(color: context.vColors.muted),
            ),
          ),
        Expanded(
          child: items.isEmpty
              ? Center(child: Text(l10n.productsNoResults))
              : ListView.separated(
                  padding: const EdgeInsets.only(
                    bottom: VantiaSpacing.bottomSafe,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(indent: 72),
                  itemBuilder: (_, i) => ProductTile(
                    product: items[i],
                    onTap: isOwner
                        ? () => context.push(Routes.productEdit(items[i].id))
                        : null,
                  ),
                ),
        ),
      ],
    );
  }
}

class ProductTile extends StatelessWidget {
  const ProductTile({
    required this.product,
    super.key,
    this.onTap,
    this.trailing,
  });

  final Product product;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = product;
    final low = p.tracksStock && p.stock! <= 0;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: context.colors.surfaceContainerHigh,
        child: Icon(
          p.barcode != null
              ? Icons.qr_code_2_rounded
              : Icons.shopping_bag_outlined,
          color: context.vColors.muted,
        ),
      ),
      title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          if (p.category != null) p.category!,
          if (p.tracksStock)
            l10n.productStock(p.stock!)
          else
            l10n.productNoStock,
        ].join(' · '),
        style: TextStyle(color: low ? context.vColors.danger : null),
      ),
      trailing: trailing ?? MoneyText(p.price),
    );
  }
}
