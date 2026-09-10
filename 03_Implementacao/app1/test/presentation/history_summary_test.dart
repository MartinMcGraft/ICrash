import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/domain/entities/product.dart';
import 'package:icrash_app/src/domain/entities/usage_event.dart';
import 'package:icrash_app/src/presentation/reports/history_summary.dart';

const _adrenalina = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
const _amiodarona = Product(id: 'p2', institutionId: 'inst-a', name: 'Amiodarona');

UsageEvent _event({required String productId, required UsageEventType type, required int amount}) => UsageEvent(
      id: 'e',
      institutionId: 'inst-a',
      actorUid: 'me',
      cartId: 'cart-1',
      assignmentId: 'a1',
      productId: productId,
      type: type,
      amount: amount,
    );

void main() {
  test('sums consumption (as a positive magnitude) and replenishment separately per product', () {
    final events = [
      _event(productId: 'p1', type: UsageEventType.consumption, amount: -2),
      _event(productId: 'p1', type: UsageEventType.consumption, amount: -3),
      _event(productId: 'p1', type: UsageEventType.replenishment, amount: 5),
    ];

    final summaries = summarizeByProduct(events, const [_adrenalina]);

    expect(summaries, hasLength(1));
    expect(summaries.single.productName, 'Adrenalina');
    expect(summaries.single.consumed, 5);
    expect(summaries.single.replenished, 5);
    expect(summaries.single.otherAdjustments, 0);
  });

  test('nets correction and reconciliation events into otherAdjustments', () {
    final events = [
      _event(productId: 'p1', type: UsageEventType.correction, amount: 1),
      _event(productId: 'p1', type: UsageEventType.auditReconciliation, amount: -2),
    ];

    final summaries = summarizeByProduct(events, const [_adrenalina]);

    expect(summaries.single.otherAdjustments, -1);
  });

  test('groups separately per product and sorts by product name', () {
    final events = [
      _event(productId: 'p2', type: UsageEventType.consumption, amount: -1),
      _event(productId: 'p1', type: UsageEventType.replenishment, amount: 4),
    ];

    final summaries = summarizeByProduct(events, const [_adrenalina, _amiodarona]);

    expect(summaries, hasLength(2));
    expect(summaries[0].productName, 'Adrenalina');
    expect(summaries[1].productName, 'Amiodarona');
  });

  test('resolves a missing product to a placeholder name', () {
    final events = [_event(productId: 'does-not-exist', type: UsageEventType.consumption, amount: -1)];

    final summaries = summarizeByProduct(events, const []);

    expect(summaries.single.productName, 'Produto removido');
  });

  test('an empty event list yields no summaries', () {
    expect(summarizeByProduct(const [], const [_adrenalina]), isEmpty);
  });
}
