import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/usage_event.dart';
import '../../domain/repositories/usage_repository.dart';
import 'firestore_codec.dart';
import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

class FirestoreUsageRepository implements UsageRepository {
  FirestoreUsageRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<UsageEvent>> watchRecentEvents(String institutionId, {int limit = 50}) {
    return _firestore
        .collection(FirestorePaths.usageEvents(institutionId))
        .orderBy('serverTimestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(_toEvents(institutionId))
        .handleError((Object error) => throw mapFirebaseException(error));
  }

  @override
  Stream<List<UsageEvent>> watchEventsForAssignment(String institutionId, String assignmentId) {
    return _firestore
        .collection(FirestorePaths.usageEvents(institutionId))
        .where('assignmentId', isEqualTo: assignmentId)
        .orderBy('serverTimestamp', descending: true)
        .snapshots()
        .map(_toEvents(institutionId))
        .handleError((Object error) => throw mapFirebaseException(error));
  }

  @override
  Stream<Set<String>> watchUsedAssignmentIds(String institutionId, String cartId) {
    return _firestore
        .collection(FirestorePaths.usageEvents(institutionId))
        .where('cartId', isEqualTo: cartId)
        .snapshots()
        .map((snapshot) => {for (final doc in snapshot.docs) doc.data()['assignmentId'] as String? ?? ''}..remove(''))
        .handleError((Object error) => throw mapFirebaseException(error));
  }

  List<UsageEvent> Function(QuerySnapshot<Map<String, Object?>>) _toEvents(String institutionId) {
    return (snapshot) => snapshot.docs
        .map((doc) => UsageEvent.fromMap(
              doc.id,
              institutionId,
              doc.data(),
              serverTimestamp: timestampToDateTime(doc.data()['serverTimestamp']),
            ))
        .toList();
  }
}
