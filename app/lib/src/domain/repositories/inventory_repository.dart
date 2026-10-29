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
  /// expired products and slots below their target, computed at read-time
  /// via `InventoryHealth.slotHealth` rather than stored). Rules gate each
  /// cart exactly as [watchAssignments] does per-cart, so a normal user only
  /// ever sees assignments in carts they're responsible for.
  Stream<List<CartProductAssignment>> watchAllAssignments(String institutionId);

  Future<CartProductAssignment?> getAssignment(String institutionId, String cartId, String assignmentId);

  /// Places a product in a slot. Throws [RepositoryFailure] with
  /// [RepositoryFailureReason.conflict] when the product is already in this
  /// cart, or with code `slotTaken` when the slot (drawer + slot id) already
  /// holds a product. Both checks are best-effort queries (Firestore rules
  /// can't express uniqueness); the database enforces them later.
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
    required String newDrawerId,
    required String newSlotId,
    required String actorUid,
  });

  /// Removes a placement that has no history yet (P1: a used placement can't
  /// be deleted; the rules refuse it). Its batches are marked removed, never
  /// deleted (DB1). Used by "trocar produto", "Limpar posição" and "remove
  /// orphan" before the slot was ever used.
  Future<void> deleteAssignment({
    required String institutionId,
    required String cartId,
    required String assignmentId,
  });

  /// Changes the slot's target quantity without touching stock or history.
  /// Manager+ only (Rules: structural fields). Used by the dashboard grid
  /// editor (design v2, B4 "Posição"). Throws [RepositoryFailure] with code
  /// `targetBelowCurrent` when the new target is below the current stock.
  /// There is no minimum quantity (D10).
  Future<void> updateAssignmentSettings({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int targetQuantity,
  });

  /// The placement's batches still in the slot (removed ones are history
  /// and left out).
  Stream<List<Batch>> watchBatches(String institutionId, String cartId, String assignmentId);

  /// A fresh id for a usage event, so a caller can keep it before the write
  /// completes (A10 "Desfazer último" corrects that exact event).
  String newUsageEventId(String institutionId);

  /// Decrements `currentQuantity` by [amount] and appends a [UsageEvent] of
  /// type `consumption` (with id [eventId] when given). Never touches batch
  /// records or `earliestKnownExpiry`. Returns the event's id.
  Future<String> recordConsumption({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int amount,
    required String actorUid,
    String? eventId,
  });

  /// Increments `currentQuantity`, stores the new [Batch], and conservatively
  /// lowers `earliestKnownExpiry` only if the new batch expires sooner than
  /// the current value (spec section 26). Never removes existing batches.
  /// The replenishment event records the id of the batch it created (R27).
  Future<void> recordReplenishment({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int amount,
    required Batch batch,
    required String actorUid,
  });

  /// Applies a physical audit's findings in one atomic write: sets
  /// `currentQuantity` to [confirmedQuantity], recomputes
  /// `earliestKnownExpiry` strictly from [confirmedBatches] (spec section 27),
  /// marks every other batch removed (never deleted, DB1) and writes the
  /// event.
  Future<void> reconcileAfterAudit({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int confirmedQuantity,
    required List<Batch> confirmedBatches,
    required String actorUid,
  });

  /// Compensating event that never mutates the original (spec section 44).
  /// [reason] is optional (P15 asks whether it should be mandatory).
  Future<void> recordCorrection({
    required String institutionId,
    required String cartId,
    required String assignmentId,
    required int amount,
    required String correctsEventId,
    required String actorUid,
    String? reason,
  });
}
