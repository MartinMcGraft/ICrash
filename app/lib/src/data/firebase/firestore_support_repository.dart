import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/institution.dart';
import '../../domain/entities/support_access.dart';
import '../../domain/repositories/support_repository.dart';
import 'firestore_codec.dart';
import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

const _windowTimestamps = ['startsAt', 'endsAt', 'closedAt'];

/// Firestore-backed [SupportRepository] (D18). The rules decide who may do
/// what; see firestore.rules `support`, `supportGrants`, `supportLog`.
class FirestoreSupportRepository implements SupportRepository {
  FirestoreSupportRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser?.uid ?? '';

  DocumentReference<Map<String, dynamic>> _current(String institutionId) =>
      _firestore.doc('${FirestorePaths.institutions}/$institutionId/support/current');

  @override
  Future<bool> isPlatformAdmin() async {
    if (_uid.isEmpty) return false;
    try {
      return (await _firestore.collection('platformAdmins').doc(_uid).get()).exists;
    } on FirebaseException {
      return false;
    }
  }

  @override
  Future<String?> myPinHash() async {
    if (_uid.isEmpty) return null;
    try {
      final data = (await _firestore.collection('platformAdmins').doc(_uid).get()).data();
      final hash = data?['pinHash'];
      return hash is String && hash.isNotEmpty ? hash : null;
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Stream<SupportWindow?> watchWindow(String institutionId) => _current(institutionId)
      .snapshots()
      .map((snapshot) {
        final data = snapshot.data();
        return data == null ? null : SupportWindow.fromMap(institutionId, normalizeTimestamps(data, _windowTimestamps));
      })
      .handleError((Object error) => throw mapFirebaseException(error));

  @override
  Future<SupportWindow> openWindow(
    String institutionId, {
    required String reason,
    required Duration duration,
    required String byUid,
    String? byName,
  }) async {
    try {
      final grant = _firestore.collection('${FirestorePaths.institutions}/$institutionId/supportGrants').doc();
      final endsAt = DateTime.now().add(duration);
      final data = {
        'grantId': grant.id,
        'reason': reason,
        'grantedBy': byUid,
        'grantedByName': ?byName,
        'startsAt': FieldValue.serverTimestamp(),
        'endsAt': Timestamp.fromDate(endsAt),
      };
      final batch = _firestore.batch()
        ..set(grant, data)
        ..set(_current(institutionId), data);
      await batch.commit();
      return SupportWindow(
        grantId: grant.id,
        institutionId: institutionId,
        reason: reason,
        grantedBy: byUid,
        grantedByName: byName,
        startsAt: DateTime.now(),
        endsAt: endsAt,
      );
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<void> closeWindow(String institutionId, {required String byUid}) async {
    try {
      final current = await _current(institutionId).get();
      final grantId = current.data()?['grantId'] as String?;
      final close = {'closedAt': FieldValue.serverTimestamp(), 'closedBy': byUid};
      final batch = _firestore.batch()..update(_current(institutionId), close);
      if (grantId != null && grantId.isNotEmpty) {
        batch.update(_firestore.doc('${FirestorePaths.institutions}/$institutionId/supportGrants/$grantId'), close);
      }
      await batch.commit();
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Stream<List<SupportLogEntry>> watchLog(String institutionId) => _firestore
      .collection('${FirestorePaths.institutions}/$institutionId/supportLog')
      .orderBy('at', descending: true)
      .limit(100)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => SupportLogEntry.fromMap(doc.id, normalizeTimestamps(doc.data(), const ['at'])))
          .toList())
      .handleError((Object error) => throw mapFirebaseException(error));

  @override
  Future<void> log(String institutionId,
      {required String grantId, required String action, required String superUid, String? superEmail}) async {
    try {
      await _firestore.collection('${FirestorePaths.institutions}/$institutionId/supportLog').add({
        'superUid': superUid,
        'superEmail': ?superEmail,
        'grantId': grantId,
        'action': action,
        'at': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<List<(Institution, SupportWindow)>> openInstitutions() async {
    try {
      final institutions = await _firestore.collection(FirestorePaths.institutions).get();
      final now = DateTime.now();
      final result = <(Institution, SupportWindow)>[];
      for (final doc in institutions.docs) {
        final current = await _current(doc.id).get();
        final data = current.data();
        if (data == null) continue;
        final window = SupportWindow.fromMap(doc.id, normalizeTimestamps(data, _windowTimestamps));
        if (window.isOpenAt(now)) result.add((Institution.fromMap(doc.id, doc.data()), window));
      }
      result.sort((a, b) => a.$1.name.compareTo(b.$1.name));
      return result;
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }
}
