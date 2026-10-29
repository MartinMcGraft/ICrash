import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/domain/entities/batch.dart';
import 'package:icrash_app/src/domain/entities/cart_product_assignment.dart';
import 'package:icrash_app/src/domain/inventory_health.dart';
import 'package:icrash_app/src/domain/inventory_rules.dart';

void main() {
  group('InventoryRules.applyConsumption', () {
    test('decreases the aggregate only, never touching batches', () {
      expect(InventoryRules.applyConsumption(5, 1), 4);
    });

    test('rejects a non-positive amount', () {
      expect(() => InventoryRules.applyConsumption(5, 0), throwsArgumentError);
    });

    test('refuses to go negative instead of silently clamping', () {
      expect(() => InventoryRules.applyConsumption(1, 2), throwsStateError);
    });
  });

  group('spec section 58 — critical inventory test case', () {
    final october = DateTime(2026, 10, 1);
    final december = DateTime(2026, 12, 1);

    test('daily consumption changes only the aggregate, never earliestKnownExpiry or batches', () {
      // Initial: currentQuantity = 5, Lot A expiry October, Lot B expiry
      // December, earliestKnownExpiry = October.
      final currentQuantity = InventoryRules.applyConsumption(5, 1);

      // consume(1) => currentQuantity = 4; earliestKnownExpiry is simply
      // never recomputed by consumption, so it is still whatever it was
      // before this call — the rule under test is that nothing here reads
      // or derives it from batches.
      expect(currentQuantity, 4);
    });

    test('only a physical audit confirming Lot A absent may advance earliestKnownExpiry to Lot B', () {
      // Audit confirms Lot A is gone; remaining physically verified
      // inventory is Lot B only.
      final confirmedBatches = [
        Batch(id: 'lot-b', assignmentId: 'a', lotNumber: 'B', expiryDate: december, quantity: 4),
      ];

      expect(InventoryRules.earliestExpiryFromConfirmedBatches(confirmedBatches), december);
      expect(InventoryRules.earliestExpiryFromConfirmedBatches(confirmedBatches), isNot(october));
    });
  });

  group('spec section 59 — second critical inventory test', () {
    final december = DateTime(2026, 12, 1);
    final october = DateTime(2026, 10, 1);
    final january = DateTime(2027, 1, 1);

    test('restocking with an earlier-expiring lot pulls earliestKnownExpiry earlier', () {
      final result = InventoryRules.conservativeEarliestExpiryAfterReplenishment(
        currentEarliestKnownExpiry: december,
        newBatchExpiry: october,
      );

      expect(result, october);
    });

    test('restocking with a later-expiring lot never pushes earliestKnownExpiry later', () {
      final result = InventoryRules.conservativeEarliestExpiryAfterReplenishment(
        currentEarliestKnownExpiry: december,
        newBatchExpiry: january,
      );

      expect(result, december);
    });

    test('the first-ever batch on an assignment simply becomes the known expiry', () {
      final result = InventoryRules.conservativeEarliestExpiryAfterReplenishment(
        currentEarliestKnownExpiry: null,
        newBatchExpiry: october,
      );

      expect(result, october);
    });

    test('subsequent daily consumption must not automatically decrement the new lot', () {
      // Restock added Lot C (expiry October, qty 3); consuming afterwards is
      // still a pure aggregate decrement with no batch selection involved.
      final afterRestock = 5 + 3;
      final afterConsumption = InventoryRules.applyConsumption(afterRestock, 1);
      expect(afterConsumption, 7);
    });
  });

  group('InventoryRules.earliestExpiryFromConfirmedBatches', () {
    test('returns null when nothing is confirmed present', () {
      expect(InventoryRules.earliestExpiryFromConfirmedBatches(const []), isNull);
    });

    test('picks the nearest expiry among several confirmed batches', () {
      final october = DateTime(2026, 10, 1);
      final december = DateTime(2026, 12, 1);
      final batches = [
        Batch(id: '1', assignmentId: 'a', lotNumber: 'B', expiryDate: december),
        Batch(id: '2', assignmentId: 'a', lotNumber: 'A', expiryDate: october),
      ];

      expect(InventoryRules.earliestExpiryFromConfirmedBatches(batches), october);
    });
  });

  group('stock bounds 0 ≤ current ≤ target (P5, D10)', () {
    test('checkStock accepts the bounds themselves', () {
      InventoryRules.checkStock(0, 5);
      InventoryRules.checkStock(5, 5);
    });

    test('checkStock refuses overfill, negatives and a zero target', () {
      expect(() => InventoryRules.checkStock(6, 5), _violation(StockRuleViolation.exceedsTarget));
      expect(() => InventoryRules.checkStock(-1, 5), _violation(StockRuleViolation.belowZero));
      expect(() => InventoryRules.checkStock(0, 0), _violation(StockRuleViolation.invalidTarget));
    });

    test('replenishment may fill the slot but never overfill it', () {
      expect(InventoryRules.applyReplenishment(3, 2, target: 5), 5);
      expect(() => InventoryRules.applyReplenishment(3, 3, target: 5), _violation(StockRuleViolation.exceedsTarget));
    });

    test('a correction stays within 0 … target', () {
      expect(InventoryRules.applyCorrection(3, -3, target: 5), 0);
      expect(InventoryRules.applyCorrection(3, 2, target: 5), 5);
      expect(() => InventoryRules.applyCorrection(3, -4, target: 5), _violation(StockRuleViolation.belowZero));
      expect(() => InventoryRules.applyCorrection(3, 3, target: 5), _violation(StockRuleViolation.exceedsTarget));
    });

    test('a new target below the current stock is refused (Q6)', () {
      InventoryRules.checkNewTarget(current: 4, newTarget: 4);
      expect(
        () => InventoryRules.checkNewTarget(current: 4, newTarget: 3),
        _violation(StockRuleViolation.targetBelowCurrent),
      );
      expect(() => InventoryRules.checkNewTarget(current: 0, newTarget: 0), _violation(StockRuleViolation.invalidTarget));
    });
  });

  group('InventoryHealth.slotHealth: one state, highest priority wins (DB9)', () {
    const base = CartProductAssignment(
      id: 'a1',
      cartId: 'cart-1',
      slotId: 'r0c0',
      productId: 'p1',
      currentQuantity: 10,
      targetQuantity: 10,
    );
    final now = DateTime(2026, 9, 10);
    SlotHealth health(CartProductAssignment a) => InventoryHealth.slotHealth(a, expiryWarningDays: 30, now: now);

    test('no placement is free; a full slot with a far expiry is ok', () {
      expect(InventoryHealth.slotHealth(null, expiryWarningDays: 30, now: now), SlotHealth.free);
      expect(health(base.copyWith(earliestKnownExpiry: now.add(const Duration(days: 90)))), SlotHealth.ok);
    });

    test('below target but not empty is low stock; there is no minimum (D10)', () {
      expect(health(base.copyWith(currentQuantity: 9)), SlotHealth.lowStock);
    });

    test('an expiry of exactly today counts as expired', () {
      expect(health(base.copyWith(earliestKnownExpiry: now)), SlotHealth.expired);
    });

    test('the order is expired > missing > expiring > low stock > ok', () {
      final expired = now.subtract(const Duration(days: 1));
      final expiring = now.add(const Duration(days: 10));
      expect(health(base.copyWith(currentQuantity: 0, earliestKnownExpiry: expired)), SlotHealth.expired);
      expect(health(base.copyWith(currentQuantity: 0, earliestKnownExpiry: expiring)), SlotHealth.missing);
      expect(health(base.copyWith(currentQuantity: 9, earliestKnownExpiry: expiring)), SlotHealth.expiring);
      expect(
        InventoryHealth.applicableStates(base.copyWith(currentQuantity: 9, earliestKnownExpiry: expiring),
            expiryWarningDays: 30, now: now),
        {SlotHealth.expiring, SlotHealth.lowStock},
      );
    });

    test('the priority table ranks every state except free, without ties', () {
      final ranked = SlotHealth.values.where((s) => s != SlotHealth.free);
      expect(slotStatePriority.keys.toSet(), ranked.toSet());
      expect(slotStatePriority.values.toSet().length, slotStatePriority.length);
    });
  });
}

Matcher _violation(String code) => throwsA(isA<StockRuleViolation>().having((v) => v.code, 'code', code));
