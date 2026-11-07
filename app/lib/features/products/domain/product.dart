import 'package:flutter/foundation.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/features/payments/domain/payment.dart';

@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.barcode,
    this.category,
    this.stock,
    this.active = true,
  });

  final String id;
  final String name;
  final Money price;
  final String? barcode;
  final String? category;

  /// `null` = sin control de stock.
  final int? stock;
  final bool active;

  bool get tracksStock => stock != null;

  Product copyWith({
    String? name,
    Money? price,
    String? barcode,
    String? category,
    int? Function()? stock,
    bool? active,
  }) => Product(
    id: id,
    name: name ?? this.name,
    price: price ?? this.price,
    barcode: barcode ?? this.barcode,
    category: category ?? this.category,
    stock: stock == null ? this.stock : stock(),
    active: active ?? this.active,
  );
}

@immutable
class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.price,
    this.barcode,
    this.category,
    this.stock,
  });

  final String name;
  final Money price;
  final String? barcode;
  final String? category;
  final int? stock;
}

abstract interface class ProductRepository {
  Stream<List<Product>> watchActive(String businessId);

  Future<Product?> findByBarcode(String businessId, String barcode);

  Future<Result<String>> save(
    String businessId,
    ProductDraft draft, {
    String? id,
  });

  Future<Result<void>> deactivate(String businessId, String id);
}

/// Carrito de la venta con productos (F-63).
@immutable
class Cart {
  const Cart([this.lines = const {}]);

  /// productId → (producto, cantidad)
  final Map<String, (Product, int)> lines;

  Cart add(Product p, [int qty = 1]) {
    final current = lines[p.id]?.$2 ?? 0;
    final next = current + qty;
    final copy = Map.of(lines);
    if (next <= 0) {
      copy.remove(p.id);
    } else {
      copy[p.id] = (p, next);
    }
    return Cart(copy);
  }

  int quantityOf(String id) => lines[id]?.$2 ?? 0;

  bool get isEmpty => lines.isEmpty;

  Money get total => Money.sum(lines.values.map((l) => l.$1.price * l.$2));

  /// ¿Se puede agregar una unidad más sin exceder el stock?
  bool canAdd(Product p) => !p.tracksStock || quantityOf(p.id) < p.stock!;

  List<PaymentItem> toItems() => [
    for (final (p, qty) in lines.values)
      PaymentItem(
        productId: p.id,
        name: p.name,
        quantity: qty,
        unitPrice: p.price,
      ),
  ];
}

/// Filtro de búsqueda (nombre, código o categoría, sin tildes).
List<Product> searchProducts(List<Product> products, String query) {
  final q = normalize(query);
  if (q.isEmpty) return products;
  return [
    for (final p in products)
      if (normalize(p.name).contains(q) ||
          (p.barcode?.contains(q) ?? false) ||
          normalize(p.category ?? '').contains(q))
        p,
  ];
}

String normalize(String s) {
  const from = 'áéíóúüñÁÉÍÓÚÜÑ';
  const to = 'aeiouunAEIOUUN';
  final b = StringBuffer();
  for (final ch in s.trim().split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i] : ch);
  }
  return b.toString().toLowerCase();
}
