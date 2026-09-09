import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/institution.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/role.dart';
import '../../domain/repositories/institution_repository.dart';
import 'firestore_codec.dart';
import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

const _timestampFields = ['createdAt', 'updatedAt'];

class FirestoreInstitutionRepository implements InstitutionRepository {
  FirestoreInstitutionRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw mapFirebaseException(FirebaseAuthException(code: 'unauthenticated'));
    return uid;
  }

  @override
  Stream<List<Institution>> watchMyInstitutions() {
    // Queries the denormalized `memberIndex` collection group, not
    // `memberships` directly: Firestore only authorizes a collection-group
    // query against a rule declared with a `{path=**}` wildcard, and keeping
    // that wildcard rule on a separate collection name (rather than also
    // putting it on `memberships`) avoids a `list`-validation conflict with
    // the nested `institutions/{id}/memberships/{uid}` rule. See
    // firestore.rules and docs/FIREBASE_MODEL.md for the full story.
    return _firestore
        .collectionGroup('memberIndex')
        .where('uid', isEqualTo: _uid)
        .where('status', isEqualTo: MembershipStatus.active.id)
        .snapshots()
        .asyncMap((snapshot) async {
      final institutions = <Institution>[];
      for (final membershipDoc in snapshot.docs) {
        final institutionRef = membershipDoc.reference.parent.parent;
        if (institutionRef == null) continue;
        final institutionDoc = await institutionRef.get();
        final data = institutionDoc.data();
        if (data == null) continue;
        institutions.add(Institution.fromMap(institutionDoc.id, normalizeTimestamps(data, _timestampFields)));
      }
      return institutions;
    }).handleError((Object error) => throw mapFirebaseException(error));
  }

  @override
  Future<Institution?> getInstitution(String institutionId) async {
    try {
      final doc = await _firestore.collection(FirestorePaths.institutions).doc(institutionId).get();
      final data = doc.data();
      if (data == null) return null;
      return Institution.fromMap(doc.id, normalizeTimestamps(data, _timestampFields));
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<Membership?> getMyMembership(String institutionId) async {
    try {
      final doc = await _firestore.collection(FirestorePaths.memberships(institutionId)).doc(_uid).get();
      final data = doc.data();
      if (data == null) return null;
      return Membership.fromMap(_uid, institutionId, normalizeTimestamps(data, _timestampFields));
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<Institution> createInstitution(Institution institution) async {
    try {
      final ref = _firestore.collection(FirestorePaths.institutions).doc();
      final data = {
        ...institution.toMap(),
        'createdBy': _uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await ref.set(data);
      final created = await ref.get();
      return Institution.fromMap(ref.id, normalizeTimestamps(created.data()!, _timestampFields));
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }
}
