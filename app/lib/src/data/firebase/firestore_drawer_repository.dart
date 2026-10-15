import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/cart_drawer.dart';
import '../../domain/entities/slot.dart';
import '../../domain/repositories/drawer_repository.dart';
import 'firestore_codec.dart';
import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

class FirestoreDrawerRepository implements DrawerRepository {
  FirestoreDrawerRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<CartDrawer>> watchDrawers(String institutionId, String cartId) {
    return _firestore
        .collection(FirestorePaths.drawers(institutionId, cartId))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CartDrawer.fromMap(doc.id, cartId, normalizeTimestamps(doc.data(), const ['createdAt', 'updatedAt'])))
            .toList())
        .handleError((Object error) => throw mapFirebaseException(error));
  }

  @override
  Future<CartDrawer> createDrawer(String institutionId, String cartId, CartDrawer drawer) async {
    try {
      final ref = _firestore.collection(FirestorePaths.drawers(institutionId, cartId)).doc();
      await ref.set({
        ...drawer.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final created = await ref.get();
      return CartDrawer.fromMap(ref.id, cartId, normalizeTimestamps(created.data()!, const ['createdAt', 'updatedAt']));
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<void> updateDrawer(String institutionId, String cartId, CartDrawer drawer) async {
    try {
      await _firestore.collection(FirestorePaths.drawers(institutionId, cartId)).doc(drawer.id).update({
        ...drawer.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Stream<List<Slot>> watchSlots(String institutionId, String cartId, String drawerId) {
    return _firestore
        .collection(FirestorePaths.slots(institutionId, cartId, drawerId))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Slot.fromMap(doc.id, drawerId, doc.data())).toList())
        .handleError((Object error) => throw mapFirebaseException(error));
  }

  @override
  Future<void> replaceSlots(String institutionId, String cartId, String drawerId, List<Slot> slots) async {
    try {
      final collection = _firestore.collection(FirestorePaths.slots(institutionId, cartId, drawerId));
      final batch = _firestore.batch();
      final existing = await collection.get();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }
      for (final slot in slots) {
        batch.set(collection.doc(slot.id), slot.toMap());
      }
      await batch.commit();
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }
}
