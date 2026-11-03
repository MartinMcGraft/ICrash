import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/registered_device.dart';
import '../../domain/entities/role.dart';
import '../../domain/repositories/device_repository.dart';
import 'firebase_bootstrap.dart';
import 'firestore_codec.dart';
import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

/// Firestore-backed [DeviceRepository] (D17). The tablet's account is
/// registered to each bound cart exactly like a person (`responsibleUsers` +
/// `responsibleUserIds`), so the existing cart rules give it those carts and
/// nothing else.
class FirestoreDeviceRepository implements DeviceRepository {
  FirestoreDeviceRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _devices(String institutionId) =>
      _firestore.collection('${FirestorePaths.institutions}/$institutionId/devices');

  RegisteredDevice _fromDoc(String institutionId, DocumentSnapshot<Map<String, dynamic>> doc) => RegisteredDevice.fromMap(
        doc.id,
        institutionId,
        normalizeTimestamps(doc.data() ?? const {}, const ['registeredAt', 'revokedAt']),
      );

  @override
  Stream<List<RegisteredDevice>> watchDevices(String institutionId) => _devices(institutionId)
      .snapshots()
      .map((snapshot) => [for (final doc in snapshot.docs) _fromDoc(institutionId, doc)])
      .handleError((Object error) => throw mapFirebaseException(error));

  @override
  Future<RegisteredDevice?> getDevice(String institutionId, String deviceId) async {
    try {
      final doc = await _devices(institutionId).doc(deviceId).get();
      return doc.exists ? _fromDoc(institutionId, doc) : null;
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  static String _randomPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    final random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  void _registerToCart(WriteBatch batch, String institutionId, String cartId, String uid, String byUid) {
    batch.set(_firestore.collection(FirestorePaths.responsibleUsers(institutionId, cartId)).doc(uid), {
      'uid': uid,
      'assignedBy': byUid,
      'assignedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_firestore.collection(FirestorePaths.carts(institutionId)).doc(cartId), {
      'responsibleUserIds': FieldValue.arrayUnion([uid]),
    });
  }

  void _unregisterFromCart(WriteBatch batch, String institutionId, String cartId, String uid) {
    batch.delete(_firestore.collection(FirestorePaths.responsibleUsers(institutionId, cartId)).doc(uid));
    batch.update(_firestore.collection(FirestorePaths.carts(institutionId)).doc(cartId), {
      'responsibleUserIds': FieldValue.arrayRemove([uid]),
    });
  }

  @override
  Future<DeviceCredentials> registerDevice(
    String institutionId, {
    required String institutionName,
    required String name,
    required List<String> cartIds,
    required String byUid,
    String? byName,
  }) async {
    try {
      final ref = _devices(institutionId).doc();
      final email = 'device-${ref.id.toLowerCase()}@$institutionId.devices.icrash.invalid';
      final password = _randomPassword();
      final isolatedAuth = await createIsolatedAccountCreationAuth();
      final String uid;
      try {
        final credential = await isolatedAuth.createUserWithEmailAndPassword(email: email, password: password);
        uid = credential.user!.uid;
      } finally {
        await isolatedAuth.app.delete();
      }
      final batch = _firestore.batch();
      batch.set(_firestore.collection(FirestorePaths.memberships(institutionId)).doc(uid), {
        'uid': uid,
        'role': Role.device.id,
        'status': MembershipStatus.active.id,
        'displayName': name,
        'deviceId': ref.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.set(ref, {
        'name': name,
        'cartIds': cartIds,
        'authUid': uid,
        'registeredBy': byUid,
        'registeredByName': ?byName,
        'registeredAt': FieldValue.serverTimestamp(),
      });
      for (final cartId in cartIds) {
        _registerToCart(batch, institutionId, cartId, uid, byUid);
      }
      await batch.commit();
      return DeviceCredentials(
        institutionId: institutionId,
        institutionName: institutionName,
        deviceId: ref.id,
        deviceName: name,
        email: email,
        password: password,
      );
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<void> updateDevice(String institutionId, RegisteredDevice device, {required String name, required List<String> cartIds}) async {
    try {
      final batch = _firestore.batch();
      batch.update(_devices(institutionId).doc(device.id), {'name': name, 'cartIds': cartIds});
      batch.update(_firestore.collection(FirestorePaths.memberships(institutionId)).doc(device.authUid), {
        'displayName': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final before = device.cartIds.toSet();
      final after = cartIds.toSet();
      for (final cartId in after.difference(before)) {
        _registerToCart(batch, institutionId, cartId, device.authUid, '');
      }
      for (final cartId in before.difference(after)) {
        _unregisterFromCart(batch, institutionId, cartId, device.authUid);
      }
      await batch.commit();
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<void> revokeDevice(String institutionId, RegisteredDevice device) async {
    try {
      final batch = _firestore.batch();
      batch.update(_devices(institutionId).doc(device.id), {'revokedAt': FieldValue.serverTimestamp()});
      batch.update(_firestore.collection(FirestorePaths.memberships(institutionId)).doc(device.authUid), {
        'status': MembershipStatus.disabled.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      for (final cartId in device.cartIds) {
        _unregisterFromCart(batch, institutionId, cartId, device.authUid);
      }
      await batch.commit();
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }
}
