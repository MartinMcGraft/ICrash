import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/domain/entities/batch.dart';
import 'package:icrash_app/src/domain/entities/cart_drawer.dart';
import 'package:icrash_app/src/domain/entities/cart_product_assignment.dart';
import 'package:icrash_app/src/domain/entities/cart_report.dart';
import 'package:icrash_app/src/domain/monthly_check.dart';

void main() {
  final now = DateTime(2026, 10, 30, 10);
  const drawers = [
    CartDrawer(id: 'd2', cartId: 'c1', number: 2, name: 'Circulação', rows: 1, columns: 3),
    CartDrawer(id: 'd1', cartId: 'c1', number: 1, name: 'Via aérea', rows: 1, columns: 3),
  ];

  List<CheckItem> build(List<CartProductAssignment> assignments, Map<String, List<Batch>> batches) => buildCheckItems(
        drawers: drawers,
        numberOf: (d) => d.number!,
        assignments: assignments,
        drawerIdOf: (a) => a.drawerId,
        positionOf: (a) => a.slotId == 'r0c0' ? 'A1' : 'A2',
        productName: (id) => 'Produto $id',
        warningDaysOf: (_) => 30,
        batchesByAssignment: batches,
        now: now,
      );

  group('"Gestão mensal" lists only expired and expiring lots (D4, D23)', () {
    test('one item per expired or expiring lot; valid and removed lots are left out', () {
      final items = build([
        const CartProductAssignment(id: 'a1', cartId: 'c1', drawerId: 'd1', slotId: 'r0c0', productId: 'p1', currentQuantity: 4, targetQuantity: 4),
      ], {
        'a1': [
          Batch(id: 'b-expired', assignmentId: 'a1', lotNumber: 'L1', expiryDate: DateTime(2026, 10, 29), quantity: 1),
          Batch(id: 'b-expiring', assignmentId: 'a1', lotNumber: 'L2', expiryDate: DateTime(2026, 11, 29), quantity: 1),
          Batch(id: 'b-valid', assignmentId: 'a1', lotNumber: 'L3', expiryDate: DateTime(2027, 6, 30), quantity: 1),
          Batch(id: 'b-gone', assignmentId: 'a1', expiryDate: DateTime(2026, 9, 1), quantity: 1).removed(now),
        ],
      });
      expect(items.map((i) => i.batchId), ['b-expired', 'b-expiring']);
      expect(items.first.issue, FindingIssue.expired);
      expect(items.last.issue, FindingIssue.expiring);
      expect(items.first.drawerName, 'Via aérea');
    });

    test('a lot expiring today is "expiring", not expired', () {
      expect(expiryIssue(DateTime(2026, 10, 30), warningDays: 30, now: now), FindingIssue.expiring);
      expect(expiryIssue(DateTime(2026, 10, 29), warningDays: 30, now: now), FindingIssue.expired);
      expect(expiryIssue(DateTime(2026, 12, 30), warningDays: 30, now: now), isNull);
    });

    test('a slot without batch records uses its earliest known expiry; empty slots are skipped', () {
      final items = build([
        CartProductAssignment(
            id: 'a2', cartId: 'c1', drawerId: 'd2', slotId: 'r0c1', productId: 'p2', currentQuantity: 2, targetQuantity: 2,
            earliestKnownExpiry: DateTime(2026, 10, 1)),
        CartProductAssignment(
            id: 'a3', cartId: 'c1', drawerId: 'd2', slotId: 'r0c0', productId: 'p3', currentQuantity: 0, targetQuantity: 2,
            earliestKnownExpiry: DateTime(2026, 10, 1)),
      ], const {});
      expect(items.single.assignmentId, 'a2');
      expect(items.single.batchId, isNull);
      expect(items.single.issue, FindingIssue.expired);
    });

    test('items come by drawer number, then position', () {
      final expired = DateTime(2026, 10, 1);
      final items = build([
        CartProductAssignment(id: 'x', cartId: 'c1', drawerId: 'd2', slotId: 'r0c0', productId: 'p1', currentQuantity: 1, targetQuantity: 1, earliestKnownExpiry: expired),
        CartProductAssignment(id: 'y', cartId: 'c1', drawerId: 'd1', slotId: 'r0c1', productId: 'p2', currentQuantity: 1, targetQuantity: 1, earliestKnownExpiry: expired),
        CartProductAssignment(id: 'z', cartId: 'c1', drawerId: 'd1', slotId: 'r0c0', productId: 'p3', currentQuantity: 1, targetQuantity: 1, earliestKnownExpiry: expired),
      ], const {});
      expect(items.map((i) => i.assignmentId), ['z', 'y', 'x']);
    });

    test('resuming keeps answered lots that are no longer in the stock, and drops answers a state no longer allows', () {
      final replaced = CheckItem(
        assignmentId: 'a1', drawerId: 'd1', drawerNumber: 1, drawerName: 'Via aérea', position: 'A1', productName: 'Adrenalina',
        issue: FindingIssue.expired, expiryDate: DateTime(2026, 10, 1), batchId: 'old', lotNumber: 'L1', quantity: 2,
      ).answer(CheckOutcome.replaced, units: 2, newExpiry: DateTime(2027, 6, 30));
      final nowExpired = CheckItem(
        assignmentId: 'a2', drawerId: 'd2', drawerNumber: 2, position: 'A1', productName: 'Atropina',
        issue: FindingIssue.expired, expiryDate: DateTime(2026, 10, 29), batchId: 'b2',
      );
      final keptBefore = nowExpired.answer(CheckOutcome.kept).toJson()..['issue'] = 'expiring';
      final merged = mergeSavedAnswers([nowExpired], {replaced.id: replaced.toJson(), nowExpired.id: keptBefore});
      expect(merged.map((i) => i.id), [replaced.id, nowExpired.id]);
      expect(merged.first.outcome, CheckOutcome.replaced);
      expect(merged.first.newExpiry, DateTime(2027, 6, 30));
      expect(merged.last.outcome, isNull, reason: 'an expired lot can\'t stay "Mantido"');
    });

    test('an expired lot can\'t be kept; outcomes per state live in one table', () {
      expect(checkOutcomes[FindingIssue.expired], [CheckOutcome.replaced, CheckOutcome.removed]);
      expect(checkOutcomes[FindingIssue.expiring], [CheckOutcome.kept, CheckOutcome.replaced]);
    });
  });
}
