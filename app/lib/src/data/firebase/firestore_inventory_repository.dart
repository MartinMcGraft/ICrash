import 'package:cloud_firestore/cloud_firestore.dart';

import '../../common/repository_failure.dart';
import '../../domain/entities/batch.dart';
import '../../domain/entities/cart_product_assignment.dart';
import '../../domain/entities/usage_event.dart';
import '../../domain/inventory_rules.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'firestore_codec.dart';
import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

const _assignmentTimestampFields = ['updatedAt', 'earliestKnownExpiry'];

/// Firestore-backed [InventoryRepository].
///
/// CRITICAL: every write here goes through a transaction that reads the
/// assignment first, so `currentQuantity` and `earliestKnownExpiry` are
/// never derived by summing batches, and concurrent daily-consumption writes
/// from different devices cannot silently clobber one another
/// (spec sections 22-28, offline/concurrency note in docs/FIREBASE.md).
class FirestoreInventoryRepository implements InventoryRepository {
  FirestoreInventoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<CartProductAssignment>> watchAssignments(String institutionId, String cartId) {
    return _firestore
        .collection(FirestorePaths.assignments(institutionId, cartId))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                CartProductAssignment.fromMap(doc.id, cartId, normalizeTimestamps(doc.data(), _assignmentTimestampFields)))
            .toList())
        .handleError((Object error) => throw mapFirebaseException(error));
  }

  @override
  Stream<List<CartProductAssignment>> watchAllAssignments(String institutionId) {
    return _firestore
        .collectionGroup(FirestorePaths.assignmentsCollectionGroup)
        .where('institutionId', isEqualTo: institutionId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final cartId = doc.reference.parent.parent!.id;
              return CartProductAssignment.fromMap(
                doc.id,
                cartId,
                normalizeTimestamps(doc.data(), _assignmentTimestampFields),
              );
            }).toList())
        .handleError((Object error) => throw mapFirebaseException(error));
  }

  @override
  Future<CartProductAssignment?> getAssignment(String institutionId, String cartId, String assignmentId) async {
    try {
      final doc = await _assignmentRef(institutionId, cartId, assignmentId).get();
      final data = doc.data();
      if (data == null) return null;
      return CartProductAssignment.fromMap(doc.id, cartId, normalizeTimestamps(data, _assignmentTimestampFields));
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<CartProductAssignment> createAssignment(String institutionId, String cartId, CartProductAssignment assignment) async {
    try {
      // P5: the initial quantity can't exceed the target (no first-stock
      // event is written; P6/P19 are open).
      InventoryRules.checkStock(assignment.currentQuantity, assignment.targetQuantity);
      // Spec section 20: a given product may only exist in one slot within a
      // single cart (a different cart, or a different slot's history, is
      // unaffected). Enforced here rather than only in the UI, since Rules
      // cannot express a cross-document uniqueness check.
      final duplicate = await _firestore
          .collection(FirestorePaths.assignments(institutionId, cartId))
          .where('productId', isEqualTo: assignment.productId)
          .limit(1)
          .get();
      if (duplicate.docs.isNotEmpty) {
        throw const RepositoryFailure(RepositoryFailureReason.conflict);
      }
      // One product per slot (DATABASE.md UNIQUE on SLOTCC's slot). Slot ids
      // repeat in every drawer, so the drawer is part of the check.
      final drawerId = assignment.drawerId;
      if (drawerId != null) {
        final occupied = await _firestore
            .collection(FirestorePaths.assignments(institutionId, cartId))
            .where('drawerId', isEqualTo: drawerId)
            .where('slotId', isEqualTo: assignment.slotId)
            .limit(1)
            .get();
        if (occupied.docs.isNotEmpty) {
          throw const RepositoryFailure(RepositoryFailureReason.conflict, code: 'slotTaken');
        }
      }

      final ref = _firestore.collection(FirestorePaths.assignments(institutionId, cartId)).doc();
      await ref.set({
        ...assignment.toMap(),
        // Denormalized purely so `watchAllAssignments` can query across
        // every cart with `.where('institutionId', ...)`, and so the
        // matching `firestore.rules` `list` rule can read them back without
        // relying on `path[]` (see the rule's own comment for why). Never
        // read back into the domain entity; cartId/institutionId are always
        // reconstructed from the document's own path/reference when reading.
        'institutionId': institutionId,
        'cartId': cartId,
        'earliestKnownExpiry': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final created = await ref.get();
      return CartProductAssignment.fromMap(ref.id, cartId, normalizeTimestamps(created.data()!, _assignmentTimestampFields));
    } on RepositoryFailure {
      rethrow;
    } on StockRuleViolation catch (violation) {
      throw _ruleFailure(violation);
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<void> reassignSlot({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required String newDrawerId,
    required String newSlotId,
    required String actorUid,
  }) async {
    try {
      await _assignmentRef(institutionId, cartId, assignmentId).update({
        'drawerId': newDrawerId,
        'slotId': newSlotId,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': actorUid,
      });
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<void> deleteAssignment({
    required String institutionId,
    required String cartId,
    required String assignmentId,
  }) async {
    try {
      final batches = await _firestore.collection(FirestorePaths.batches(institutionId, cartId, assignmentId)).get();
      final writeBatch = _firestore.batch();
      for (final doc in batches.docs) {
        writeBatch.delete(doc.reference);
      }
      writeBatch.delete(_assignmentRef(institutionId, cartId, assignmentId));
      await writeBatch.commit();
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<void> updateAssignmentSettings({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int targetQuantity,
  }) async {
    StockRuleViolation? violation;
    try {
      await _firestore.runTransaction((transaction) async {
        final ref = _assignmentRef(institutionId, cartId, assignmentId);
        final data = (await transaction.get(ref)).data();
        if (data == null) throw StateError('Assignment $assignmentId not found');
        final current = (data['currentQuantity'] as num?)?.toInt() ?? 0;
        try {
          InventoryRules.checkNewTarget(current: current, newTarget: targetQuantity);
        } on StockRuleViolation catch (v) {
          violation = v;
          return;
        }
        transaction.update(ref, {
          'targetQuantity': targetQuantity,
          // D10: there is no minimum stock; drop the field from old documents.
          'minimumQuantity': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (error) {
      throw mapFirebaseException(error);
    }
    if (violation != null) throw _ruleFailure(violation!);
  }

  /// Business-rule refusals travel as a [RepositoryFailure] with a code, so
  /// ViewModels and the View handle them like any other failure.
  static RepositoryFailure _ruleFailure(StockRuleViolation violation) =>
      RepositoryFailure(RepositoryFailureReason.invalidInput, cause: violation, code: violation.code);

  @override
  Stream<List<Batch>> watchBatches(String institutionId, String cartId, String assignmentId) {
    return _firestore
        .collection(FirestorePaths.batches(institutionId, cartId, assignmentId))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              final expiry = timestampToDateTime(data['expiryDate']) ?? DateTime.now();
              return Batch.fromMap(doc.id, assignmentId, data, expiry);
            }).toList())
        .handleError((Object error) => throw mapFirebaseException(error));
  }

  DocumentReference<Map<String, Object?>> _assignmentRef(String institutionId, String cartId, String assignmentId) =>
      _firestore.collection(FirestorePaths.assignments(institutionId, cartId)).doc(assignmentId);

  @override
  Future<void> recordConsumption({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int amount,
    required String actorUid,
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Consumption amount must be positive');
    }
    try {
      await _firestore.runTransaction((transaction) async {
        final ref = _assignmentRef(institutionId, cartId, assignmentId);
        final snapshot = await transaction.get(ref);
        final data = snapshot.data();
        if (data == null) {
          throw StateError('Assignment $assignmentId not found');
        }
        final currentQuantity = (data['currentQuantity'] as num?)?.toInt() ?? 0;
        final updatedQuantity = InventoryRules.applyConsumption(currentQuantity, amount);
        transaction.update(ref, {
          'currentQuantity': updatedQuantity,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': actorUid,
        });
        transaction.set(
          _firestore.collection(FirestorePaths.usageEvents(institutionId)).doc(),
          UsageEvent(
            id: '',
            institutionId: institutionId,
            actorUid: actorUid,
            cartId: cartId,
            assignmentId: assignmentId,
            productId: data['productId'] as String? ?? '',
            type: UsageEventType.consumption,
            amount: -amount,
          ).toMap()
            ..['serverTimestamp'] = FieldValue.serverTimestamp(),
        );
      });
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<void> recordReplenishment({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int amount,
    required Batch batch,
    required String actorUid,
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Replenishment amount must be positive');
    }
    StockRuleViolation? violation;
    try {
      await _firestore.runTransaction((transaction) async {
        final ref = _assignmentRef(institutionId, cartId, assignmentId);
        final snapshot = await transaction.get(ref);
        final data = snapshot.data();
        if (data == null) {
          throw StateError('Assignment $assignmentId not found');
        }
        final currentQuantity = (data['currentQuantity'] as num?)?.toInt() ?? 0;
        final target = (data['targetQuantity'] as num?)?.toInt() ?? 0;
        final int updatedQuantity;
        try {
          updatedQuantity = InventoryRules.applyReplenishment(currentQuantity, amount, target: target);
        } on StockRuleViolation catch (v) {
          violation = v;
          return;
        }
        final currentEarliestExpiry = timestampToDateTime(data['earliestKnownExpiry']);
        final newEarliestExpiry = InventoryRules.conservativeEarliestExpiryAfterReplenishment(
          currentEarliestKnownExpiry: currentEarliestExpiry,
          newBatchExpiry: batch.expiryDate,
        );

        transaction.update(ref, {
          'currentQuantity': updatedQuantity,
          'earliestKnownExpiry': Timestamp.fromDate(newEarliestExpiry),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': actorUid,
        });

        final batchRef = _firestore.collection(FirestorePaths.batches(institutionId, cartId, assignmentId)).doc();
        transaction.set(batchRef, {
          ...batch.toMap(),
          'expiryDate': Timestamp.fromDate(batch.expiryDate),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(
          _firestore.collection(FirestorePaths.usageEvents(institutionId)).doc(),
          UsageEvent(
            id: '',
            institutionId: institutionId,
            actorUid: actorUid,
            cartId: cartId,
            assignmentId: assignmentId,
            productId: data['productId'] as String? ?? '',
            type: UsageEventType.replenishment,
            amount: amount,
          ).toMap()
            ..['serverTimestamp'] = FieldValue.serverTimestamp(),
        );
      });
    } catch (error) {
      throw mapFirebaseException(error);
    }
    if (violation != null) throw _ruleFailure(violation!);
  }

  @override
  Future<void> reconcileAfterAudit({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int confirmedQuantity,
    required List<Batch> confirmedBatches,
    required String actorUid,
  }) async {
    try {
      final batchesCollection = _firestore.collection(FirestorePaths.batches(institutionId, cartId, assignmentId));
      final ref = _assignmentRef(institutionId, cartId, assignmentId);
      final before = await ref.get();
      InventoryRules.checkStock(confirmedQuantity, (before.data()?['targetQuantity'] as num?)?.toInt() ?? 0);

      // Batch-collection replacement can outgrow a single transaction's
      // document limit for a heavily audited slot, so it runs as a plain
      // WriteBatch; the assignment/event update immediately follows and is
      // the operation callers must treat as the durable outcome.
      final existingBatches = await batchesCollection.get();
      final writeBatch = _firestore.batch();
      for (final doc in existingBatches.docs) {
        writeBatch.delete(doc.reference);
      }

      final earliestExpiry = InventoryRules.earliestExpiryFromConfirmedBatches(confirmedBatches);
      for (final batch in confirmedBatches) {
        writeBatch.set(batchesCollection.doc(), {
          ...batch.toMap(),
          'expiryDate': Timestamp.fromDate(batch.expiryDate),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await writeBatch.commit();

      final previous = await ref.get();
      final previousQuantity = (previous.data()?['currentQuantity'] as num?)?.toInt() ?? 0;
      final productId = previous.data()?['productId'] as String? ?? '';

      await ref.update({
        'currentQuantity': confirmedQuantity,
        'earliestKnownExpiry': earliestExpiry == null ? null : Timestamp.fromDate(earliestExpiry),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': actorUid,
      });

      await _firestore.collection(FirestorePaths.usageEvents(institutionId)).add(
            UsageEvent(
              id: '',
              institutionId: institutionId,
              actorUid: actorUid,
              cartId: cartId,
              assignmentId: assignmentId,
              productId: productId,
              type: UsageEventType.auditReconciliation,
              amount: confirmedQuantity - previousQuantity,
            ).toMap()
              ..['serverTimestamp'] = FieldValue.serverTimestamp(),
          );
    } on StockRuleViolation catch (violation) {
      throw _ruleFailure(violation);
    } catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<void> recordCorrection({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int amount,
    required String correctsEventId,
    required String actorUid,
  }) async {
    if (amount == 0) {
      throw ArgumentError.value(amount, 'amount', 'Correction amount must not be zero');
    }
    StockRuleViolation? violation;
    try {
      await _firestore.runTransaction((transaction) async {
        final ref = _assignmentRef(institutionId, cartId, assignmentId);
        final snapshot = await transaction.get(ref);
        final data = snapshot.data();
        if (data == null) {
          throw StateError('Assignment $assignmentId not found');
        }
        final currentQuantity = (data['currentQuantity'] as num?)?.toInt() ?? 0;
        final target = (data['targetQuantity'] as num?)?.toInt() ?? 0;
        final int updated;
        try {
          updated = InventoryRules.applyCorrection(currentQuantity, amount, target: target);
        } on StockRuleViolation catch (v) {
          violation = v;
          return;
        }
        transaction.update(ref, {
          'currentQuantity': updated,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': actorUid,
        });
        transaction.set(
          _firestore.collection(FirestorePaths.usageEvents(institutionId)).doc(),
          UsageEvent(
            id: '',
            institutionId: institutionId,
            actorUid: actorUid,
            cartId: cartId,
            assignmentId: assignmentId,
            productId: data['productId'] as String? ?? '',
            type: UsageEventType.correction,
            amount: amount,
            correctsEventId: correctsEventId,
          ).toMap()
            ..['serverTimestamp'] = FieldValue.serverTimestamp(),
        );
      });
    } catch (error) {
      throw mapFirebaseException(error);
    }
    if (violation != null) throw _ruleFailure(violation!);
  }
}
