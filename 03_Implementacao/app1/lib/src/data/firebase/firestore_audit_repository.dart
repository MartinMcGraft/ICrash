import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/audit_event.dart';
import '../../domain/repositories/audit_repository.dart';
import 'firestore_codec.dart';
import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

class FirestoreAuditRepository implements AuditRepository {
  FirestoreAuditRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<void> record(AuditEvent event) async {
    try {
      await _firestore.collection(FirestorePaths.auditEvents(event.institutionId)).add({
        ...event.toMap(),
        'serverTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Stream<List<AuditEvent>> watchRecentEvents(String institutionId, {int limit = 100}) {
    return _firestore
        .collection(FirestorePaths.auditEvents(institutionId))
        .orderBy('serverTimestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AuditEvent.fromMap(
                  doc.id,
                  institutionId,
                  doc.data(),
                  serverTimestamp: timestampToDateTime(doc.data()['serverTimestamp']),
                ))
            .toList())
        .handleError((Object error) => throw mapFirebaseException(error));
  }
}
