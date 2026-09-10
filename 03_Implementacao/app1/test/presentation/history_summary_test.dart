import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/domain/entities/cart.dart';
import 'package:icrash_app/src/domain/entities/product.dart';
import 'package:icrash_app/src/domain/entities/usage_event.dart';
import 'package:icrash_app/src/presentation/reports/history_summary.dart';

const _adrenalina = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
const _amiodarona = Product(id: 'p2', institutionId: 'inst-a', name: 'Amiodarona');
const _cartA = Cart(id: 'cart-1', institutionId: 'inst-a', name: 'Carro 1');
const _cartB = Cart(id: 'cart-2', institutionId: 'inst-a', name: 'Carro 2');

UsageEvent _event({
  required String productId,
  required UsageEventType type,
  required int amount,
  String cartId = 'cart-1',
  DateTime? serverTimestamp,
}) =>
    UsageEvent(
      id: 'e',
      institutionId: 'inst-a',
      actorUid: 'me',
      cartId: cartId,
      assignmentId: 'a1',
      productId: productId,
      type: type,
      amount: amount,
      serverTimestamp: serverTimestamp,
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

  test('summarizeByCart groups separately per cart and sorts by cart name', () {
    final events = [
      _event(productId: 'p1', type: UsageEventType.consumption, amount: -2, cartId: 'cart-2'),
      _event(productId: 'p1', type: UsageEventType.replenishment, amount: 5, cartId: 'cart-1'),
    ];

    final summaries = summarizeByCart(events, const [_cartA, _cartB]);

    expect(summaries, hasLength(2));
    expect(summaries[0].cartName, 'Carro 1');
    expect(summaries[0].replenished, 5);
    expect(summaries[1].cartName, 'Carro 2');
    expect(summaries[1].consumed, 2);
  });

  test('summarizeByCart resolves a missing cart to a placeholder name', () {
    final events = [_event(productId: 'p1', type: UsageEventType.consumption, amount: -1, cartId: 'does-not-exist')];

    final summaries = summarizeByCart(events, const []);

    expect(summaries.single.cartName, 'Carro removido');
  });

  test('summarizeByPeriod buckets by calendar day', () {
    final events = [
      _event(
          productId: 'p1',
          type: UsageEventType.consumption,
          amount: -2,
          serverTimestamp: DateTime(2026, 3, 5, 9)),
      _event(
          productId: 'p1',
          type: UsageEventType.consumption,
          amount: -1,
          serverTimestamp: DateTime(2026, 3, 5, 18)),
      _event(
          productId: 'p1',
          type: UsageEventType.replenishment,
          amount: 4,
          serverTimestamp: DateTime(2026, 3, 6, 8)),
    ];

    final summaries = summarizeByPeriod(events, SummaryPeriodUnit.day);

    expect(summaries, hasLength(2));
    expect(summaries[0].periodStart, DateTime(2026, 3, 5));
    expect(summaries[0].consumed, 3);
    expect(summaries[1].periodStart, DateTime(2026, 3, 6));
    expect(summaries[1].replenished, 4);
  });

  test('summarizeByPeriod buckets by week starting on Monday', () {
    // 2026-03-05 is a Thursday; 2026-03-09 is the following Monday.
    final events = [
      _event(
          productId: 'p1',
          type: UsageEventType.consumption,
          amount: -1,
          serverTimestamp: DateTime(2026, 3, 5)),
      _event(
          productId: 'p1',
          type: UsageEventType.consumption,
          amount: -1,
          serverTimestamp: DateTime(2026, 3, 9)),
    ];

    final summaries = summarizeByPeriod(events, SummaryPeriodUnit.week);

    expect(summaries, hasLength(2));
    expect(summaries[0].periodStart, DateTime(2026, 3, 2));
    expect(summaries[1].periodStart, DateTime(2026, 3, 9));
  });

  test('summarizeByPeriod buckets by calendar month and skips events with no serverTimestamp yet', () {
    final events = [
      _event(productId: 'p1', type: UsageEventType.consumption, amount: -1, serverTimestamp: DateTime(2026, 3, 5)),
      _event(productId: 'p1', type: UsageEventType.consumption, amount: -1, serverTimestamp: DateTime(2026, 3, 20)),
      _event(productId: 'p1', type: UsageEventType.consumption, amount: -9),
    ];

    final summaries = summarizeByPeriod(events, SummaryPeriodUnit.month);

    expect(summaries, hasLength(1));
    expect(summaries.single.periodStart, DateTime(2026, 3));
    expect(summaries.single.consumed, 2);
  });
}
