import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/features/products/domain/product.dart';

import '../helpers/fakes.dart';
import '../helpers/pump_app.dart';

const gaseosa = Product(
  id: 'g',
  name: 'Gaseosa 500 ml',
  price: Money(250),
  barcode: '7750182000123',
  stock: 2,
);
const pan = Product(
  id: 'p',
  name: 'Pan francés',
  price: Money(50),
  category: 'Panadería',
);

Future<void> _enter(WidgetTester t, String label, String text) async {
  final column = find.ancestor(
    of: find.text(label),
    matching: find.byType(Column),
  );
  await t.enterText(
    find
        .descendant(of: column.first, matching: find.byType(TextFormField))
        .first,
    text,
  );
}

void main() {
  group('Cart', () {
    test('suma, resta y respeta el stock', () {
      var cart = const Cart().add(gaseosa).add(pan, 3);
      expect(cart.total, const Money(400));
      expect(cart.canAdd(gaseosa), isTrue);
      cart = cart.add(gaseosa);
      expect(cart.canAdd(gaseosa), isFalse);
      expect(cart.canAdd(pan), isTrue); // sin control de stock
      cart = cart.add(pan, -3);
      expect(cart.quantityOf('p'), 0);
      expect(cart.toItems().single.quantity, 2);
    });

    test('búsqueda sin tildes por nombre, código o categoría', () {
      final all = [gaseosa, pan];
      expect(searchProducts(all, 'frances').single.id, 'p');
      expect(searchProducts(all, 'PANADERIA').single.id, 'p');
      expect(searchProducts(all, '7750182').single.id, 'g');
      expect(searchProducts(all, '').length, 2);
    });
  });

  testWidgets('alta por código de barras y luego reabre el existente (F-61)', (
    tester,
  ) async {
    final products = FakeProductRepository();
    await tester.pumpVantiaApp(
      products: products,
      scan: () async => '7750182000999',
    );
    await tester.tap(find.bySemanticsLabel('Productos'));
    await tester.pumpAndSettle();
    expect(find.text('Aún no has registrado productos'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Código de barras'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo producto'), findsOneWidget);
    expect(find.text('7750182000999'), findsOneWidget);

    await _enter(tester, 'Nombre', 'Galletas');
    await _enter(tester, 'Precio', '1.50');
    await _enter(tester, 'Stock', '12');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    final saved = products.products.values.single;
    expect(
      (saved.name, saved.price, saved.stock),
      ('Galletas', const Money(150), 12),
    );
    expect(find.text('Galletas'), findsOneWidget);
    expect(find.text('Stock: 12'), findsOneWidget);

    // Escanear el mismo código abre la edición.
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Código de barras'));
    await tester.pumpAndSettle();
    expect(find.text('Editar producto'), findsOneWidget);
  });

  testWidgets('producto sin código (F-62) y búsqueda (F-60)', (tester) async {
    final products = FakeProductRepository()..seed(gaseosa);
    await tester.pumpVantiaApp(products: products);
    await tester.tap(find.bySemanticsLabel('Productos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Producto sin código'));
    await tester.pumpAndSettle();
    await _enter(tester, 'Nombre', 'Pan francés');
    await _enter(tester, 'Precio', '0.50');
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Sin control de stock'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'gase');
    await tester.pumpAndSettle();
    expect(find.text('Gaseosa 500 ml'), findsOneWidget);
    expect(find.text('Pan francés'), findsNothing);
  });

  testWidgets('venta con productos prellena el pago (F-63)', (tester) async {
    final products = FakeProductRepository()
      ..seed(gaseosa)
      ..seed(pan);
    final payments = FakePaymentRepository(clock: () => fixedNow);
    await tester.pumpVantiaApp(
      products: products,
      payments: payments,
      scan: () async => '7750182000123',
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar productos vendidos'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Efectivo'));
    await tester.pumpAndSettle();
    expect(find.text('Productos vendidos'), findsOneWidget);

    await tester.tap(find.byTooltip('Escanear')); // +1 gaseosa
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Agregar Gaseosa 500 ml')); // +1 gaseosa
    await tester.tap(find.byTooltip('Agregar Gaseosa 500 ml')); // supera stock
    await tester.pumpAndSettle();
    expect(find.text('Sin stock suficiente de Gaseosa 500 ml'), findsOneWidget);
    await tester.tap(find.byTooltip('Agregar Pan francés'));
    await tester.pumpAndSettle();
    expect(find.text('S/ 5.50'), findsOneWidget);

    // Esperar a que se oculte el aviso de stock (cubre la parte inferior).
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar pago'), findsOneWidget);
    final submit = find.widgetWithText(FilledButton, 'Registrar pago');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    final p = payments.payments.values.single;
    expect(p.amount, const Money(550));
    expect(p.items.map((i) => (i.productId, i.quantity)), [('g', 2), ('p', 1)]);
  });

  testWidgets('colaborador ve productos en solo lectura', (tester) async {
    final products = FakeProductRepository()..seed(pan);
    await tester.pumpVantiaApp(
      products: products,
      auth: collaboratorAuth(),
      business: collaboratorBusiness(),
    );
    await tester.tap(find.bySemanticsLabel('Productos'));
    await tester.pumpAndSettle();
    expect(
      find.text('Solo el dueño puede crear o editar productos.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
  });
}
