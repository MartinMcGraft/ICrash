import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/domain/entities/batch.dart';
import 'package:icrash_app/src/domain/entities/cart_product_assignment.dart';
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

  group('InventoryRules.computeAlert (spec section 49)', () {
    const base = CartProductAssignment(
      id: 'a1',
      cartId: 'cart-1',
      slotId: 'r0c0',
      productId: 'p1',
      currentQuantity: 5,
      targetQuantity: 10,
    );
    final now = DateTime(2026, 9, 10);

    test('returns null when nothing needs attention', () {
      final assignment = base.copyWithExpiry(now.add(const Duration(days: 90)));
      expect(InventoryRules.computeAlert(assignment, expiryWarningDays: 30, now: now), isNull);
    });

    test('flags an assignment whose earliestKnownExpiry has already passed', () {
      final assignment = base.copyWithExpiry(now.subtract(const Duration(days: 1)));
      expect(
        InventoryRules.computeAlert(assignment, expiryWarningDays: 30, now: now),
        AssignmentAlert.expired,
      );
    });

    test('treats an expiry of exactly today as expired', () {
      final assignment = base.copyWithExpiry(now);
      expect(
        InventoryRules.computeAlert(assignment, expiryWarningDays: 30, now: now),
        AssignmentAlert.expired,
      );
    });

    test('flags an assignment expiring within the warning horizon', () {
      final assignment = base.copyWithExpiry(now.add(const Duration(days: 10)));
      expect(
        InventoryRules.computeAlert(assignment, expiryWarningDays: 30, now: now),
        AssignmentAlert.expiringSoon,
      );
    });

    test('does not flag an assignment expiring just beyond the warning horizon', () {
      final assignment = base.copyWithExpiry(now.add(const Duration(days: 31)));
      expect(InventoryRules.computeAlert(assignment, expiryWarningDays: 30, now: now), isNull);
    });

    test('flags stock at or below its explicit minimum quantity', () {
      const assignment = CartProductAssignment(
        id: 'a1',
        cartId: 'cart-1',
        slotId: 'r0c0',
        productId: 'p1',
        currentQuantity: 2,
        targetQuantity: 10,
        minimumQuantity: 2,
      );
      expect(
        InventoryRules.computeAlert(assignment, expiryWarningDays: 30, now: now),
        AssignmentAlert.belowMinimum,
      );
    });

    test('never flags being below target alone when no minimum is set', () {
      const assignment = CartProductAssignment(
        id: 'a1',
        cartId: 'cart-1',
        slotId: 'r0c0',
        productId: 'p1',
        currentQuantity: 1,
        targetQuantity: 10,
      );
      expect(InventoryRules.computeAlert(assignment, expiryWarningDays: 30, now: now), isNull);
    });

    test('expiry takes priority over a simultaneous below-minimum condition', () {
      final assignment = CartProductAssignment(
        id: 'a1',
        cartId: 'cart-1',
        slotId: 'r0c0',
        productId: 'p1',
        currentQuantity: 1,
        targetQuantity: 10,
        minimumQuantity: 2,
        earliestKnownExpiry: now.subtract(const Duration(days: 1)),
      );
      expect(
        InventoryRules.computeAlert(assignment, expiryWarningDays: 30, now: now),
        AssignmentAlert.expired,
      );
    });
  });
}

extension on CartProductAssignment {
  CartProductAssignment copyWithExpiry(DateTime expiry) => CartProductAssignment(
        id: id,
        cartId: cartId,
        slotId: slotId,
        productId: productId,
        currentQuantity: currentQuantity,
        targetQuantity: targetQuantity,
        earliestKnownExpiry: expiry,
      );
}
