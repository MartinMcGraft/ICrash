import 'entities/batch.dart';

/// A stock change refused by a business rule. [code] is the same string the
/// ViewModels use for [ActionError] codes, so the View shows one message for
/// it wherever it is raised (domain, repository or ViewModel).
class StockRuleViolation implements Exception {
  const StockRuleViolation(this.code);

  /// `belowZero`: the change would take the slot below 0 units.
  static const belowZero = 'belowZero';

  /// `exceedsTarget`: the change would put more units in the slot than its
  /// target (P5: no overfill; DATABASE.md `currNumberCC ≤ maxNumberCC`).
  static const exceedsTarget = 'exceedsTarget';

  /// `targetBelowCurrent`: a new target lower than the stock already there.
  static const targetBelowCurrent = 'targetBelowCurrent';

  /// `invalidTarget`: a target of 0 or less (`maxNumberCC > 0`).
  static const invalidTarget = 'invalidTarget';

  final String code;

  @override
  String toString() => 'StockRuleViolation($code)';
}

/// Pure, Firebase-free implementations of the stock rules: conservative
/// expiry, no FEFO (spec sections 22-28, 48, 58-59), and the stock bounds
/// `0 ≤ current ≤ target` (P5, D10: there is no minimum stock).
/// [FirestoreInventoryRepository] calls these instead of recomputing the
/// logic inline, so the critical rules are covered by plain unit tests.
class InventoryRules {
  const InventoryRules._();

  /// Throws [StockRuleViolation] unless `0 ≤ current ≤ target` and
  /// `target > 0`. Every path that writes a quantity calls this.
  static void checkStock(int current, int target) {
    if (target <= 0) throw const StockRuleViolation(StockRuleViolation.invalidTarget);
    if (current < 0) throw const StockRuleViolation(StockRuleViolation.belowZero);
    if (current > target) throw const StockRuleViolation(StockRuleViolation.exceedsTarget);
  }

  /// A new target for an existing placement must stay above 0 and must not
  /// drop below the units already in the slot (Q6, 29 Oct: block it; the
  /// stock is lowered first by recording consumption or a correction).
  static void checkNewTarget({required int current, required int newTarget}) {
    if (newTarget <= 0) throw const StockRuleViolation(StockRuleViolation.invalidTarget);
    if (newTarget < current) throw const StockRuleViolation(StockRuleViolation.targetBelowCurrent);
  }

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

  /// Replenishment raises the aggregate, never above the target (P5).
  static int applyReplenishment(int currentQuantity, int amount, {required int target}) {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'must be positive');
    }
    final result = currentQuantity + amount;
    checkStock(result, target);
    return result;
  }

  /// A correction moves the aggregate by a signed [amount], staying within
  /// `0 ≤ current ≤ target` (spec section 44, P5).
  static int applyCorrection(int currentQuantity, int amount, {required int target}) {
    if (amount == 0) {
      throw ArgumentError.value(amount, 'amount', 'must not be zero');
    }
    final result = currentQuantity + amount;
    checkStock(result, target);
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
