import 'package:flutter/material.dart';
import 'package:vantia/core/widgets/empty_state.dart';
import 'package:vantia/l10n/l10n.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  // TODO(F-60): lista real de productos.
  @override
  Widget build(BuildContext context) =>
      EmptyState(message: context.l10n.productsEmpty, badge: '0');
}
