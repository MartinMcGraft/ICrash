import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_paths.dart';

/// D16 (30 Oct 2026): an **Admin** (membership role `institutionAdmin`) or a
/// **Super** (a `platformAdmins/{uid}` marker, the I-Crash team) sees every
/// cart of the institution; a **Manager** only the carts they're registered
/// to (`responsibleUserIds`). Firestore rules can't filter a query for us,
/// so queries are shaped to match the rule (see firestore.rules, carts).
Future<bool> seesWholeInstitution(FirebaseFirestore firestore, String institutionId, String uid) async {
  if (uid.isEmpty) return false;
  try {
    final marker = await firestore.collection('platformAdmins').doc(uid).get();
    if (marker.exists) return true;
  } on FirebaseException {
    // Not a platform admin (or the marker can't be read): fall through.
  }
  final membership = await firestore.collection(FirestorePaths.memberships(institutionId)).doc(uid).get();
  return membership.data()?['role'] == 'institutionAdmin';
}
