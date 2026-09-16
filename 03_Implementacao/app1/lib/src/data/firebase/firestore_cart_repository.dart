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
    // The `list` security rule on `carts` cannot safely be a single
    // unconditional "let the rules decide" read for every role -- see the
    // long comment on this collection's rule in firestore.rules for the
    // empirical reason why. A manager+ query must stay fully unfiltered
    // (matching the rule's resource-independent `isManagerOrAbove` branch);
    // a normal user's query must filter by `responsibleUserIds
    // array-contains <their uid>` (matching the rule's other branch, kept
    // in sync by assignResponsibleUser/removeResponsibleUser below). Which
    // query to run is decided once per call from the caller's own
    // membership, then the chosen query is watched reactively.
    final collectionRef = _firestore.collection(FirestorePaths.carts(institutionId));
    return Stream.fromFuture(_isManagerOrAbove(institutionId)).asyncExpand((managerOrAbove) {
      final query = managerOrAbove ? collectionRef : collectionRef.where('responsibleUserIds', arrayContains: _uid);
      return query.snapshots();
    }).map((snapshot) => snapshot.docs
            .map((doc) => Cart.fromMap(doc.id, institutionId, normalizeTimestamps(doc.data(), const ['createdAt', 'updatedAt'])))
            .toList())
        .handleError((Object error) => throw mapFirebaseException(error));
  }

  Future<bool> _isManagerOrAbove(String institutionId) async {
    final doc = await _firestore.collection(FirestorePaths.memberships(institutionId)).doc(_uid).get();
    final role = doc.data()?['role'] as String?;
    return role == 'institutionAdmin' || role == 'manager';
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
        // Denormalized for the `list` rule -- see watchAccessibleCarts.
        // Starts empty; assignResponsibleUser fills it in as normal users
        // are granted access to this specific cart.
        'responsibleUserIds': <String>[],
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
      final batch = _firestore.batch();
      batch.set(_firestore.collection(FirestorePaths.responsibleUsers(institutionId, cartId)).doc(uid), {
        'uid': uid,
        'assignedBy': _uid,
        'assignedAt': FieldValue.serverTimestamp(),
      });
      // Kept in sync with the responsibleUsers subcollection above -- the
      // `carts` list rule reads this denormalized field instead (see
      // watchAccessibleCarts/firestore.rules); never write one without the
      // other, same pattern as memberships/memberIndex.
      batch.update(_firestore.collection(FirestorePaths.carts(institutionId)).doc(cartId), {
        'responsibleUserIds': FieldValue.arrayUnion([uid]),
      });
      await batch.commit();
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<void> removeResponsibleUser(String institutionId, String cartId, String uid) async {
    try {
      final batch = _firestore.batch();
      batch.delete(_firestore.collection(FirestorePaths.responsibleUsers(institutionId, cartId)).doc(uid));
      batch.update(_firestore.collection(FirestorePaths.carts(institutionId)).doc(cartId), {
        'responsibleUserIds': FieldValue.arrayRemove([uid]),
      });
      await batch.commit();
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }
}
