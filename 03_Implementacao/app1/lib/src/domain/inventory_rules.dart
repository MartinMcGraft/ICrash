import 'entities/batch.dart';

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
}
