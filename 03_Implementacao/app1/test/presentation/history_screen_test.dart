import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/cart.dart';
import 'package:icrash_app/src/domain/entities/product.dart';
import 'package:icrash_app/src/domain/entities/usage_event.dart';
import 'package:icrash_app/src/presentation/reports/history_screen.dart';

import '../fakes/fake_repositories.dart';

Widget _wrap(AppServices services) {
  return AppServicesScope(
    services: services,
    child: MaterialApp(home: const HistoryScreen(institutionId: 'inst-a')),
  );
}

const _consumption = UsageEvent(
  id: 'e1',
  institutionId: 'inst-a',
  actorUid: 'me',
  cartId: 'cart-1',
  assignmentId: 'a1',
  productId: 'p1',
  type: UsageEventType.consumption,
  amount: -2,
);

const _replenishment = UsageEvent(
  id: 'e2',
  institutionId: 'inst-a',
  actorUid: 'me',
  cartId: 'cart-1',
  assignmentId: 'a1',
  productId: 'p1',
  type: UsageEventType.replenishment,
  amount: 5,
);

void main() {
  testWidgets('shows an empty state when there are no events', (tester) async {
    await tester.pumpWidget(_wrap(buildTestServices(usage: FakeUsageRepository())));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sem eventos'), findsOneWidget);
  });

  testWidgets('lists events with resolved product names', (tester) async {
    const product = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
    await tester.pumpWidget(_wrap(buildTestServices(
      products: FakeProductRepository(products: [product]),
      usage: FakeUsageRepository(events: [_consumption, _replenishment]),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Adrenalina'), findsNWidgets(2));
    expect(find.text('-2'), findsOneWidget);
    expect(find.text('+5'), findsOneWidget);
  });

  testWidgets('filters events by type', (tester) async {
    const product = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
    await tester.pumpWidget(_wrap(buildTestServices(
      products: FakeProductRepository(products: [product]),
      usage: FakeUsageRepository(events: [_consumption, _replenishment]),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Reposição'));
    await tester.pumpAndSettle();

    expect(find.text('+5'), findsOneWidget);
    expect(find.text('-2'), findsNothing);
  });

  testWidgets('exports the visible events as CSV', (tester) async {
    const product = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(_wrap(buildTestServices(
      products: FakeProductRepository(products: [product]),
      usage: FakeUsageRepository(events: [_consumption, _replenishment]),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Exportar CSV'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Data,Tipo,Produto,Quantidade'), findsOneWidget);
    expect(find.textContaining('Consumo,Adrenalina,-2'), findsOneWidget);
    expect(find.textContaining('Reposição,Adrenalina,+5'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Copiar'));
    await tester.pumpAndSettle();

    expect(copied, contains('Consumo,Adrenalina,-2'));
    expect(copied, contains('Reposição,Adrenalina,+5'));
  });

  testWidgets('shows a per-product summary of the visible events', (tester) async {
    const product = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
    await tester.pumpWidget(_wrap(buildTestServices(
      products: FakeProductRepository(products: [product]),
      usage: FakeUsageRepository(events: [_consumption, _replenishment]),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Ver resumo'));
    await tester.pumpAndSettle();

    expect(find.text('Resumo'), findsOneWidget);
    expect(find.text('Adrenalina').last, findsOneWidget);
    expect(find.text('Consumido: 2   Reposto: 5'), findsOneWidget);
  });

  testWidgets('switches the summary dialog to per-cart grouping', (tester) async {
    const product = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
    const cart = Cart(id: 'cart-1', institutionId: 'inst-a', name: 'Carro 1');
    await tester.pumpWidget(_wrap(buildTestServices(
      products: FakeProductRepository(products: [product]),
      carts: FakeCartRepository(carts: [cart]),
      usage: FakeUsageRepository(events: [_consumption, _replenishment]),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Ver resumo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carro'));
    await tester.pumpAndSettle();

    expect(find.text('Carro 1'), findsOneWidget);
    expect(find.text('Consumido: 2   Reposto: 5'), findsOneWidget);
  });

  testWidgets('switches the summary dialog to per-period grouping', (tester) async {
    const product = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
    final timedEvent = UsageEvent(
      id: 'e3',
      institutionId: 'inst-a',
      actorUid: 'me',
      cartId: 'cart-1',
      assignmentId: 'a1',
      productId: 'p1',
      type: UsageEventType.consumption,
      amount: -1,
      serverTimestamp: DateTime(2026, 3, 5),
    );
    await tester.pumpWidget(_wrap(buildTestServices(
      products: FakeProductRepository(products: [product]),
      usage: FakeUsageRepository(events: [timedEvent]),
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Ver resumo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Período'));
    await tester.pumpAndSettle();

    expect(find.text('05/03/2026'), findsOneWidget);
    expect(find.text('Consumido: 1   Reposto: 0'), findsOneWidget);
  });

  testWidgets('offers a PDF export button for the visible events', (tester) async {
    const product = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
    await tester.pumpWidget(_wrap(buildTestServices(
      products: FakeProductRepository(products: [product]),
      usage: FakeUsageRepository(events: [_consumption, _replenishment]),
    )));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Exportar PDF'), findsOneWidget);
  });
}
