import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/core/result/failure.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/features/products/domain/product.dart';

class FirestoreProductRepository implements ProductRepository {
  FirestoreProductRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String bid) =>
      _db.collection('businesses/$bid/products');

  static Product _map(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Product(
      id: d.id,
      name: m['name'] as String? ?? '',
      price: Money((m['priceCents'] as num? ?? 0).toInt()),
      barcode: m['barcode'] as String?,
      category: m['category'] as String?,
      stock: (m['stock'] as num?)?.toInt(),
      active: m['active'] as bool? ?? true,
    );
  }

  @override
  Stream<List<Product>> watchActive(String businessId) => _col(businessId)
      .where('active', isEqualTo: true)
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(_map).toList());

  @override
  Future<Product?> findByBarcode(String businessId, String barcode) async {
    final q = await _col(
      businessId,
    ).where('barcode', isEqualTo: barcode).limit(1).get();
    return q.docs.isEmpty ? null : _map(q.docs.first);
  }

  @override
  Future<Result<String>> save(
    String businessId,
    ProductDraft draft, {
    String? id,
  }) async {
    final ref = id == null ? _col(businessId).doc() : _col(businessId).doc(id);
    final data = <String, Object?>{
      'name': draft.name.trim(),
      'priceCents': draft.price.cents,
      'barcode': _clean(draft.barcode),
      'category': _clean(draft.category),
      'stock': draft.stock,
      'active': true,
      'updatedAt': FieldValue.serverTimestamp(),
      if (id == null) 'createdAt': FieldValue.serverTimestamp(),
    }..removeWhere((k, v) => v == null && k != 'stock');
    try {
      // Offline-first: no se espera la confirmación del servidor.
      ref.set(data, SetOptions(merge: true)).ignore();
      return Ok(ref.id);
    } on FirebaseException catch (e) {
      return Err(UnexpectedFailure(e.code, e));
    }
  }

  @override
  Future<Result<void>> deactivate(String businessId, String id) async {
    _col(businessId).doc(id).update({
      'active': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }).ignore();
    return const Ok(null);
  }

  static String? _clean(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
