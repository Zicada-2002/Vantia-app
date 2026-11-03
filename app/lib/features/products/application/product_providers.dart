import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/features/products/data/firestore_product_repository.dart';
import 'package:vantia/features/products/domain/product.dart';
import 'package:vantia/features/products/presentation/barcode_scanner_screen.dart';

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => FirestoreProductRepository(FirebaseFirestore.instance),
);

final productsProvider = StreamProvider<List<Product>>((ref) {
  final s = ref.watch(sessionProvider);
  if (s is! SessionReady) return Stream.value(const []);
  return ref.watch(productRepositoryProvider).watchActive(s.businessId);
});

/// Abre el escáner y devuelve el código leído (inyectable en tests).
typedef BarcodeScanner = Future<String?> Function(BuildContext context);

final barcodeScannerProvider = Provider<BarcodeScanner>(
  (ref) =>
      (context) => Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
      ),
);
