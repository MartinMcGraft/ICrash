import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/product.dart';
import '../../domain/gtin.dart';
import '../../domain/repositories/product_repository.dart';
import 'firestore_codec.dart';
import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

class FirestoreProductRepository implements ProductRepository {
  FirestoreProductRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const _timestampFields = ['createdAt', 'updatedAt'];

  @override
  Stream<List<Product>> watchProducts(String institutionId) {
    return _firestore
        .collection(FirestorePaths.products(institutionId))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.id, institutionId, normalizeTimestamps(doc.data(), _timestampFields)))
            .toList())
        .handleError((Object error) => throw mapFirebaseException(error));
  }

  @override
  Future<Product?> findByGtin(String institutionId, String gtin) async {
    try {
      // GTINs are stored padded to 14 digits since 29 Oct 2026 (P16); older
      // products may hold the code as typed, so look for those forms too.
      final snapshot = await _firestore
          .collection(FirestorePaths.products(institutionId))
          .where('gtin', whereIn: gtinLookupForms(gtin))
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return Product.fromMap(doc.id, institutionId, normalizeTimestamps(doc.data(), _timestampFields));
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<Product> createProduct(String institutionId, Product product) async {
    try {
      final ref = _firestore.collection(FirestorePaths.products(institutionId)).doc();
      await ref.set({
        ...product.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final created = await ref.get();
      return Product.fromMap(ref.id, institutionId, normalizeTimestamps(created.data()!, _timestampFields));
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<void> updateProduct(String institutionId, Product product) async {
    try {
      await _firestore.collection(FirestorePaths.products(institutionId)).doc(product.id).update({
        ...product.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }
}
