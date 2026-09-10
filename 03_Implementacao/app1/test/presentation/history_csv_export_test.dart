import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/domain/entities/product.dart';
import 'package:icrash_app/src/domain/entities/usage_event.dart';
import 'package:icrash_app/src/presentation/reports/history_csv_export.dart';

void main() {
  const product = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');

  test('builds a header row and one row per event', () {
    const event = UsageEvent(
      id: 'e1',
      institutionId: 'inst-a',
      actorUid: 'me',
      cartId: 'cart-1',
      assignmentId: 'a1',
      productId: 'p1',
      type: UsageEventType.consumption,
      amount: -2,
    );

    final csv = buildHistoryCsv([event], [product]);
    final lines = csv.trim().split('\n');

    expect(lines[0], 'Data,Tipo,Produto,Quantidade');
    expect(lines[1], ',Consumo,Adrenalina,-2');
  });

  test('formats the server timestamp when present', () {
    final event = UsageEvent(
      id: 'e1',
      institutionId: 'inst-a',
      actorUid: 'me',
      cartId: 'cart-1',
      assignmentId: 'a1',
      productId: 'p1',
      type: UsageEventType.replenishment,
      amount: 5,
      serverTimestamp: DateTime(2026, 9, 10, 9, 5),
    );

    final csv = buildHistoryCsv([event], [product]);

    expect(csv, contains('10/09/2026 09:05,Reposição,Adrenalina,+5'));
  });

  test('resolves a missing product to a placeholder name', () {
    const event = UsageEvent(
      id: 'e1',
      institutionId: 'inst-a',
      actorUid: 'me',
      cartId: 'cart-1',
      assignmentId: 'a1',
      productId: 'does-not-exist',
      type: UsageEventType.correction,
      amount: 1,
    );

    final csv = buildHistoryCsv([event], [product]);

    expect(csv, contains('Produto removido'));
  });

  test('quotes a product name containing a comma', () {
    const commaProduct = Product(id: 'p2', institutionId: 'inst-a', name: 'Soro, fisiológico');
    const event = UsageEvent(
      id: 'e1',
      institutionId: 'inst-a',
      actorUid: 'me',
      cartId: 'cart-1',
      assignmentId: 'a1',
      productId: 'p2',
      type: UsageEventType.consumption,
      amount: -1,
    );

    final csv = buildHistoryCsv([event], [commaProduct]);

    expect(csv, contains('"Soro, fisiológico"'));
  });

  test('an empty event list yields just the header row', () {
    final csv = buildHistoryCsv(const [], const [product]);

    expect(csv.trim(), 'Data,Tipo,Produto,Quantidade');
  });
}
