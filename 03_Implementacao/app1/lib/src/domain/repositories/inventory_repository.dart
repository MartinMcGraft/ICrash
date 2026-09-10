import '../entities/batch.dart';
import '../entities/cart_product_assignment.dart';

/// Owns the [CartProductAssignment] aggregate and its [Batch] records.
///
/// CRITICAL (spec sections 22-28, 58-59): [recordConsumption] and
/// [recordReplenishment] must never pick a batch to decrement or infer
/// FEFO/FIFO. Consumption only ever changes `currentQuantity`. Only
/// [reconcileAfterAudit] may remove batches and advance `earliestKnownExpiry`,
/// because only a physical audit can establish a lot is actually gone.
abstract class InventoryRepository {
  Stream<List<CartProductAssignment>> watchAssignments(String institutionId, String cartId);

  /// Every assignment across every cart in [institutionId] the current user
  /// can access (spec section 49: cross-cart dashboard alerts — expiring/
  /// expired products and stock below its minimum, computed at read-time
  /// via `InventoryRules.computeAlert` rather than stored). Rules gate each
  /// cart exactly as [watchAssignments] does per-cart, so a normal user only
  /// ever sees assignments in carts they're responsible for.
  Stream<List<CartProductAssignment>> watchAllAssignments(String institutionId);

  Future<CartProductAssignment?> getAssignment(String institutionId, String cartId, String assignmentId);

  Future<CartProductAssignment> createAssignment(String institutionId, String cartId, CartProductAssignment assignment);

  /// Moves an assignment onto a different slot within the same cart, without
  /// touching its product/quantities/history. Exists to recover an
  /// assignment whose slot was removed by a drawer merge/split in
  /// `SlotEditorScreen` (the slot id it pointed at no longer exists) — never
  /// used for a routine re-slotting of a still-valid assignment.
  Future<void> reassignSlot({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required String newSlotId,
    required String actorUid,
  });

  /// Permanently removes an assignment and its batches, without touching
  /// past `usageEvents` (spec sections 43-45: history is immutable and
  /// outlives the assignment that produced it). Used to let a manager drop
  /// an assignment whose slot no longer exists after a drawer merge/split,
  /// when reassigning it to a different slot isn't the right call.
  Future<void> deleteAssignment({
    required String institutionId,
    required String cartId,
    required String assignmentId,
  });

  Stream<List<Batch>> watchBatches(String institutionId, String cartId, String assignmentId);

  /// Decrements `currentQuantity` by [amount] and appends a [UsageEvent] of
  /// type `consumption`. Never touches batch records or `earliestKnownExpiry`.
  Future<void> recordConsumption({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int amount,
    required String actorUid,
  });

  /// Increments `currentQuantity`, stores the new [Batch], and conservatively
  /// lowers `earliestKnownExpiry` only if the new batch expires sooner than
  /// the current value (spec section 26). Never removes existing batches.
  Future<void> recordReplenishment({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int amount,
    required Batch batch,
    required String actorUid,
  });

  /// Applies a physical audit's findings: replaces the confirmed batch set,
  /// recomputes `currentQuantity` and `earliestKnownExpiry` strictly from
  /// [confirmedBatches] and [confirmedQuantity] (spec section 27).
  Future<void> reconcileAfterAudit({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int confirmedQuantity,
    required List<Batch> confirmedBatches,
    required String actorUid,
  });

  /// Compensating event that never mutates the original (spec section 44).
  Future<void> recordCorrection({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int amount,
    required String correctsEventId,
    required String actorUid,
  });
}
