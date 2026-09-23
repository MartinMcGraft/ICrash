import 'entities/batch.dart';
import 'entities/cart_product_assignment.dart';
import 'entities/cart_status.dart';

/// Cross-cart dashboard alert kinds (spec section 49). Deliberately computed
/// at read-time rather than stored on the assignment: an approaching expiry
/// becomes true purely from the passage of time, with no write ever
/// happening to the assignment itself.
enum AssignmentAlert { expired, expiringSoon, belowMinimum }

/// Pure, Firebase-free implementations of the conservative-expiry / no-FEFO
/// rules (spec sections 22-28, 48, 58-59). [FirestoreInventoryRepository]
/// calls these instead of recomputing the logic inline, so the critical
/// business rule is covered by plain unit tests independent of the emulator.
class InventoryRules {
  const InventoryRules._();

  /// Daily consumption only ever decreases the aggregate; it must never be
  /// allowed to go negative (spec section 43). Callers should offer a
  /// correction flow instead of forcing this below zero.
  static int applyConsumption(int currentQuantity, int amount) {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'must be positive');
    }
    final result = currentQuantity - amount;
    if (result < 0) {
      throw StateError('Consuming $amount from $currentQuantity would go negative');
    }
    return result;
  }

  /// A newly replenished batch can only pull the known nearest expiry
  /// earlier, never later, and never erases the influence of an existing
  /// batch (spec section 26). This is what keeps expiry warnings
  /// conservative: a false-positive "check this expiry" beats silently
  /// assuming an earlier lot is gone.
  static DateTime conservativeEarliestExpiryAfterReplenishment({
    required DateTime? currentEarliestKnownExpiry,
    required DateTime newBatchExpiry,
  }) {
    if (currentEarliestKnownExpiry == null) return newBatchExpiry;
    return newBatchExpiry.isBefore(currentEarliestKnownExpiry) ? newBatchExpiry : currentEarliestKnownExpiry;
  }

  /// Only a physical audit may recompute the nearest expiry from scratch,
  /// strictly from the batches physically confirmed present (spec section 27).
  static DateTime? earliestExpiryFromConfirmedBatches(List<Batch> confirmedBatches) {
    if (confirmedBatches.isEmpty) return null;
    return confirmedBatches.map((batch) => batch.expiryDate).reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// The cross-cart dashboard alert (spec section 49) for one assignment,
  /// or `null` if nothing needs attention. Checked in order: already
  /// expired, then expiring within the institution's configurable horizon
  /// (spec section 46), then below its own explicit [CartProductAssignment.minimumQuantity]
  /// — deliberately not "below target", since a minimum is opt-in per
  /// assignment and whether target alone should alert is an open clinical
  /// question (see docs/OPEN_DECISIONS.md) this app does not answer.
  static AssignmentAlert? computeAlert(
    CartProductAssignment assignment, {
    required int expiryWarningDays,
    required DateTime now,
  }) {
    final expiry = assignment.earliestKnownExpiry;
    if (expiry != null) {
      if (!expiry.isAfter(now)) return AssignmentAlert.expired;
      if (!expiry.isAfter(now.add(Duration(days: expiryWarningDays)))) return AssignmentAlert.expiringSoon;
    }
    final minimum = assignment.minimumQuantity;
    if (minimum != null && assignment.currentQuantity <= minimum) return AssignmentAlert.belowMinimum;
    return null;
  }

  /// The cart's status (spec section 40), derived automatically from its
  /// assignments' alerts rather than left as an arbitrary manual value —
  /// except [CartStatus.outOfService], which stays a manual, administrative
  /// override (nothing in the inventory data can tell a cart is physically
  /// out of service) and always wins over whatever the assignments say.
  static CartStatus computeEffectiveCartStatus({
    required CartStatus manualStatus,
    required List<CartProductAssignment> cartAssignments,
    required int expiryWarningDays,
    required DateTime now,
  }) {
    if (manualStatus == CartStatus.outOfService) return CartStatus.outOfService;
    var replenishmentRequired = false;
    for (final assignment in cartAssignments) {
      final alert = computeAlert(assignment, expiryWarningDays: expiryWarningDays, now: now);
      // Expired takes priority and short-circuits: only a physical audit may
      // reconcile an expired lot (spec sections 25-28), so nothing below it
      // changes that outcome.
      if (alert == AssignmentAlert.expired) return CartStatus.auditRequired;
      if (alert == AssignmentAlert.belowMinimum) replenishmentRequired = true;
    }
    return replenishmentRequired ? CartStatus.replenishmentRequired : CartStatus.operational;
  }
}
