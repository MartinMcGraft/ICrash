import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/credential_repository.dart';
import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

/// Firestore-backed [CredentialRepository]:
/// `institutions/{i}/memberships/{uid}/private/credentials` { pinHash }.
class FirestoreCredentialRepository implements CredentialRepository {
  FirestoreCredentialRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, Object?>> _ref(String institutionId, String uid) =>
      _firestore.doc(FirestorePaths.credentials(institutionId, uid));

  @override
  Future<String?> fetchPinHash(String institutionId, String uid) async {
    try {
      final doc = await _ref(institutionId, uid).get();
      return doc.data()?['pinHash'] as String?;
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<void> setPinHash(String institutionId, String uid, String pinHash) async {
    final adminUid = _auth.currentUser?.uid;
    try {
      await _ref(institutionId, uid).set({
        'pinHash': pinHash,
        'updatedAt': FieldValue.serverTimestamp(),
        if (adminUid != null) 'updatedBy': adminUid,
      });
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }
}
