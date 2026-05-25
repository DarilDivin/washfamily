import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/laundry_product_model.dart';

class LaundryProductRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _productsRef(String laundryId) =>
      _db.collection('laundries').doc(laundryId).collection('products');

  Stream<List<LaundryProductModel>> streamProducts(String laundryId) {
    return _productsRef(laundryId).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => LaundryProductModel.fromJson(
              d.data() as Map<String, dynamic>, d.id))
          .where((p) => p.isAvailable)
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Stream<List<LaundryProductModel>> streamAllProducts(String laundryId) {
    return _productsRef(laundryId).snapshots().map((snap) => snap.docs
        .map((d) => LaundryProductModel.fromJson(
            d.data() as Map<String, dynamic>, d.id))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name)));
  }

  Future<String> addProduct({
    required String laundryId,
    required LaundryProductModel product,
  }) async {
    final ref = _productsRef(laundryId).doc();
    await ref.set(product.copyWith(id: ref.id, laundryId: laundryId).toJson());
    return ref.id;
  }

  Future<void> updateProduct({
    required String laundryId,
    required String productId,
    required Map<String, dynamic> fields,
  }) async {
    await _productsRef(laundryId).doc(productId).update(fields);
  }

  Future<void> deleteProduct({
    required String laundryId,
    required String productId,
  }) async {
    await _productsRef(laundryId).doc(productId).delete();
  }

  Future<void> setProductAvailable({
    required String laundryId,
    required String productId,
    required bool isAvailable,
  }) async {
    await _productsRef(laundryId)
        .doc(productId)
        .update({'isAvailable': isAvailable});
  }

  /// Décrémente atomiquement le stock de 1.
  /// Throw 'out_of_stock' si stockQuantity <= 0 avant décrément.
  Future<void> decrementStock({
    required String laundryId,
    required String productId,
  }) async {
    final ref = _productsRef(laundryId).doc(productId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final stock =
          (snap.data()! as Map<String, dynamic>)['stockQuantity'] as int? ?? 0;
      if (stock <= 0) throw Exception('out_of_stock');
      tx.update(ref, {'stockQuantity': stock - 1});
    });
  }

  Future<void> incrementStock({
    required String laundryId,
    required String productId,
  }) async {
    final ref = _productsRef(laundryId).doc(productId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final stock =
          (snap.data()! as Map<String, dynamic>)['stockQuantity'] as int? ?? 0;
      tx.update(ref, {'stockQuantity': stock + 1});
    });
  }
}
