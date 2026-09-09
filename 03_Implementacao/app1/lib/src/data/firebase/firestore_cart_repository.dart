import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_responsible_user.dart';
import '../../domain/repositories/cart_repository.dart';
import 'firestore_codec.dart';
import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

class FirestoreCartRepository implements CartRepository {
  FirestoreCartRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser?.uid ?? '';

  @override
  Stream<List<Cart>> watchAccessibleCarts(String institutionId) {
    // Security rules already restrict a non-manager to carts they are
    // assigned to; this listens to the full collection and lets the rules
    // decide what is actually returned.
    return _firestore
        .collection(FirestorePaths.carts(institutionId))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Cart.fromMap(doc.id, institutionId, normalizeTimestamps(doc.data(), const ['createdAt', 'updatedAt'])))
            .toList())
        .handleError((Object error) => throw mapFirebaseException(error));
  }

  @override
  Future<Cart?> getCart(String institutionId, String cartId) async {
    try {
      final doc = await _firestore.collection(FirestorePaths.carts(institutionId)).doc(cartId).get();
      final data = doc.data();
      if (data == null) return null;
      return Cart.fromMap(doc.id, institutionId, normalizeTimestamps(data, const ['createdAt', 'updatedAt']));
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<Cart> createCart(String institutionId, Cart cart) async {
    try {
      final ref = _firestore.collection(FirestorePaths.carts(institutionId)).doc();
      await ref.set({
        ...cart.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final created = await ref.get();
      return Cart.fromMap(ref.id, institutionId, normalizeTimestamps(created.data()!, const ['createdAt', 'updatedAt']));
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<void> updateCart(String institutionId, Cart cart) async {
    try {
      await _firestore.collection(FirestorePaths.carts(institutionId)).doc(cart.id).update({
        ...cart.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Stream<List<CartResponsibleUser>> watchResponsibleUsers(String institutionId, String cartId) {
    return _firestore
        .collection(FirestorePaths.responsibleUsers(institutionId, cartId))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CartResponsibleUser.fromMap(doc.id, cartId, doc.data())).toList())
        .handleError((Object error) => throw mapFirebaseException(error));
  }

  @override
  Future<void> assignResponsibleUser(String institutionId, String cartId, String uid) async {
    try {
      await _firestore.collection(FirestorePaths.responsibleUsers(institutionId, cartId)).doc(uid).set({
        'uid': uid,
        'assignedBy': _uid,
        'assignedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<void> removeResponsibleUser(String institutionId, String cartId, String uid) async {
    try {
      await _firestore.collection(FirestorePaths.responsibleUsers(institutionId, cartId)).doc(uid).delete();
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }
}
