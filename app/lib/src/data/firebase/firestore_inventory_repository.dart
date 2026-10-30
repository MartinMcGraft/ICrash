import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../common/repository_failure.dart';
import '../../domain/entities/batch.dart';
import '../../domain/entities/cart_product_assignment.dart';
import '../../domain/entities/usage_event.dart';
import '../../domain/inventory_rules.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'firestore_access.dart';
import 'firestore_codec.dart';
import 'firestore_exception_mapper.dart';
import 'firestore_paths.dart';

const _assignmentTimestampFields = ['updatedAt', 'earliestKnownExpiry', 'usedAt'];

/// Firestore-backed [InventoryRepository].
///
/// CRITICAL: every write here goes through a transaction that reads the
/// assignment first, so `currentQuantity` and `earliestKnownExpiry` are
/// never derived by summing batches, and concurrent daily-consumption writes
/// from different devices cannot silently clobber one another
/// (spec sections 22-28, offline/concurrency note in docs/FIREBASE.md).
class FirestoreInventoryRepository implements InventoryRepository {
  FirestoreInventoryRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser?.uid ?? '';

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

  /// D16: an Admin or Super reads every assignment with one collection-group
  /// query (the rules allow it only to them); a Manager gets the assignments
  /// of the carts they're registered to, one listener per cart.
  @override
  Stream<List<CartProductAssignment>> watchAllAssignments(String institutionId) {
    final uid = _uid;
    return Stream.fromFuture(seesWholeInstitution(_firestore, institutionId, uid)).asyncExpand(
      (all) => all ? _watchInstitutionAssignments(institutionId) : _watchMyCartsAssignments(institutionId, uid),
    );
  }

  Stream<List<CartProductAssignment>> _watchMyCartsAssignments(String institutionId, String uid) {
    final perCart = <String, List<CartProductAssignment>>{};
    final subs = <String, StreamSubscription<List<CartProductAssignment>>>{};
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? cartsSub;
    late final StreamController<List<CartProductAssignment>> controller;
    void emit() => controller.add([for (final list in perCart.values) ...list]);
    controller = StreamController<List<CartProductAssignment>>(
      onListen: () {
        cartsSub = _firestore
            .collection(FirestorePaths.carts(institutionId))
            .where('responsibleUserIds', arrayContains: uid)
            .snapshots()
            .listen((snapshot) {
          final ids = snapshot.docs.map((d) => d.id).toSet();
          for (final id in subs.keys.toList()) {
            if (!ids.contains(id)) {
              unawaited(subs.remove(id)!.cancel());
              perCart.remove(id);
            }
          }
          for (final id in ids) {
            subs.putIfAbsent(
              id,
              () => watchAssignments(institutionId, id).listen((list) {
                perCart[id] = list;
                emit();
              }, onError: controller.addError),
            );
          }
          if (ids.isEmpty) emit();
        }, onError: (Object error) => controller.addError(mapFirebaseException(error)));
      },
      onCancel: () async {
        await cartsSub?.cancel();
        for (final sub in subs.values) {
          await sub.cancel();
        }
      },
    );
    return controller.stream;
  }

  Stream<List<CartProductAssignment>> _watchInstitutionAssignments(String institutionId) {
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
      // DB1: batches are never deleted. They're marked removed and stay as
      // history; only the placement document goes (and only while it has no
      // history, see firestore.rules).
      final batches = await _firestore.collection(FirestorePaths.batches(institutionId, cartId, assignmentId)).get();
      final writeBatch = _firestore.batch();
      for (final doc in batches.docs) {
        if (doc.data()['removedAt'] == null) {
          writeBatch.update(doc.reference, {'removedAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
        }
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

  /// P1/P2: the first History event for a placement marks the placement,
  /// its slot and its drawer as used (`usedAt`), in the same transaction as
  /// the event. Firestore rules can't query `usageEvents`, so this marker is
  /// what lets them refuse deleting a used slot or placement. Reads only;
  /// must run before the transaction's first write.
  Future<_UseMarks> _readUseMarks(
    Transaction transaction,
    String institutionId,
    String cartId,
    Map<String, Object?> assignment,
  ) async {
    if (assignment['usedAt'] != null) return const _UseMarks();
    final drawerId = assignment['drawerId'] as String?;
    final slotId = assignment['slotId'] as String?;
    // Old placements without drawerId: only the placement can be marked.
    if (drawerId == null || slotId == null || slotId.isEmpty) return const _UseMarks(assignment: true);
    final drawerRef = _firestore.collection(FirestorePaths.drawers(institutionId, cartId)).doc(drawerId);
    final slotRef = _firestore.collection(FirestorePaths.slots(institutionId, cartId, drawerId)).doc(slotId);
    final drawer = await transaction.get(drawerRef);
    final slot = await transaction.get(slotRef);
    return _UseMarks(
      assignment: true,
      others: [
        if (drawer.exists && drawer.data()?['usedAt'] == null) drawerRef,
        if (slot.exists && slot.data()?['usedAt'] == null) slotRef,
      ],
    );
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
        // Removed batches stay in Firestore as history (DB1) and are left out
        // here. Filtered on the device: a `removedAt == null` query would also
        // drop every batch written before the field existed.
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              final expiry = timestampToDateTime(data['expiryDate']) ?? DateTime.now();
              return Batch.fromMap(doc.id, assignmentId, data, expiry, removedAt: timestampToDateTime(data['removedAt']));
            })
            .where((batch) => batch.isActive)
            .toList())
        .handleError((Object error) => throw mapFirebaseException(error));
  }

  DocumentReference<Map<String, Object?>> _assignmentRef(String institutionId, String cartId, String assignmentId) =>
      _firestore.collection(FirestorePaths.assignments(institutionId, cartId)).doc(assignmentId);

  @override
  String newUsageEventId(String institutionId) => _firestore.collection(FirestorePaths.usageEvents(institutionId)).doc().id;

  @override
  Future<String> recordConsumption({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int amount,
    required String actorUid,
    String? eventId,
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Consumption amount must be positive');
    }
    final eventRef = _firestore.collection(FirestorePaths.usageEvents(institutionId)).doc(eventId);
    try {
      await _firestore.runTransaction((transaction) async {
        final ref = _assignmentRef(institutionId, cartId, assignmentId);
        final snapshot = await transaction.get(ref);
        final data = snapshot.data();
        if (data == null) {
          throw StateError('Assignment $assignmentId not found');
        }
        final marks = await _readUseMarks(transaction, institutionId, cartId, data);
        final currentQuantity = (data['currentQuantity'] as num?)?.toInt() ?? 0;
        final updatedQuantity = InventoryRules.applyConsumption(currentQuantity, amount);
        marks.write(transaction);
        transaction.update(ref, {
          ...marks.assignmentFields,
          'currentQuantity': updatedQuantity,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': actorUid,
        });
        transaction.set(
          eventRef,
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
    return eventRef.id;
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
        final marks = await _readUseMarks(transaction, institutionId, cartId, data);
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

        marks.write(transaction);
        transaction.update(ref, {
          ...marks.assignmentFields,
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
            batchId: batchRef.id,
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
    StockRuleViolation? violation;
    try {
      final ref = _assignmentRef(institutionId, cartId, assignmentId);
      final batchesCollection = _firestore.collection(FirestorePaths.batches(institutionId, cartId, assignmentId));
      // Client transactions can't run queries, so the batch ids are listed
      // first; each batch is then read again inside the transaction.
      final listed = await batchesCollection.get();
      final confirmedIds = {for (final b in confirmedBatches) b.id};
      final earliestExpiry = InventoryRules.earliestExpiryFromConfirmedBatches(confirmedBatches);

      // One atomic write: the quantity, the expiry, the batches found gone
      // and the logbook row change together or not at all.
      await _firestore.runTransaction((transaction) async {
        final data = (await transaction.get(ref)).data();
        if (data == null) throw StateError('Assignment $assignmentId not found');
        final batchSnapshots = [for (final doc in listed.docs) await transaction.get(doc.reference)];
        final marks = await _readUseMarks(transaction, institutionId, cartId, data);
        final previousQuantity = (data['currentQuantity'] as num?)?.toInt() ?? 0;
        try {
          InventoryRules.checkStock(confirmedQuantity, (data['targetQuantity'] as num?)?.toInt() ?? 0);
        } on StockRuleViolation catch (v) {
          violation = v;
          return;
        }
        marks.write(transaction);
        transaction.update(ref, {
          ...marks.assignmentFields,
          'currentQuantity': confirmedQuantity,
          'earliestKnownExpiry': earliestExpiry == null ? null : Timestamp.fromDate(earliestExpiry),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': actorUid,
        });
        // DB1: a batch the audit didn't find is marked removed, never deleted.
        // Confirmed batches are kept as they are.
        for (final snapshot in batchSnapshots) {
          final batchData = snapshot.data();
          if (batchData == null || batchData['removedAt'] != null || confirmedIds.contains(snapshot.id)) continue;
          transaction.update(snapshot.reference, {'removedAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
        }
        transaction.set(
          _firestore.collection(FirestorePaths.usageEvents(institutionId)).doc(),
          UsageEvent(
            id: '',
            institutionId: institutionId,
            actorUid: actorUid,
            cartId: cartId,
            assignmentId: assignmentId,
            productId: data['productId'] as String? ?? '',
            type: UsageEventType.auditReconciliation,
            amount: confirmedQuantity - previousQuantity,
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
  Future<void> recordCorrection({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int amount,
    required String correctsEventId,
    required String actorUid,
    String? reason,
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
        final marks = await _readUseMarks(transaction, institutionId, cartId, data);
        final currentQuantity = (data['currentQuantity'] as num?)?.toInt() ?? 0;
        final target = (data['targetQuantity'] as num?)?.toInt() ?? 0;
        final int updated;
        try {
          updated = InventoryRules.applyCorrection(currentQuantity, amount, target: target);
        } on StockRuleViolation catch (v) {
          violation = v;
          return;
        }
        marks.write(transaction);
        transaction.update(ref, {
          ...marks.assignmentFields,
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
            reason: reason == null || reason.trim().isEmpty ? null : reason.trim(),
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

/// What [FirestoreInventoryRepository._readUseMarks] found still unmarked.
class _UseMarks {
  const _UseMarks({this.assignment = false, this.others = const []});

  /// Whether the placement itself still needs `usedAt`.
  final bool assignment;

  /// The drawer and slot documents that still need `usedAt`.
  final List<DocumentReference<Map<String, Object?>>> others;

  Map<String, Object?> get assignmentFields => assignment ? {'usedAt': FieldValue.serverTimestamp()} : const {};

  void write(Transaction transaction) {
    for (final ref in others) {
      transaction.update(ref, {'usedAt': FieldValue.serverTimestamp()});
    }
  }
}
