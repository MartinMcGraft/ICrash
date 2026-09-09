import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/product.dart';
import 'package:icrash_app/src/presentation/products/products_screen.dart';

import '../fakes/fake_repositories.dart';

Widget _wrap(AppServices services, {bool canManage = false}) {
  return AppServicesScope(
    services: services,
    child: MaterialApp(home: ProductsScreen(institutionId: 'inst-a', canManage: canManage)),
  );
}

void main() {
  testWidgets('shows an empty state when the institution has no products', (tester) async {
    await tester.pumpWidget(_wrap(buildTestServices(products: FakeProductRepository())));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ainda não existem produtos'), findsOneWidget);
  });

  testWidgets('lists products', (tester) async {
    const product = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina', unitDescription: '1 mg/mL');
    await tester.pumpWidget(_wrap(buildTestServices(products: FakeProductRepository(products: [product]))));
    await tester.pumpAndSettle();

    expect(find.text('Adrenalina'), findsOneWidget);
    expect(find.text('1 mg/mL'), findsOneWidget);
  });

  testWidgets('hides "Novo produto" for a non-manager', (tester) async {
    await tester.pumpWidget(_wrap(buildTestServices(products: FakeProductRepository())));
    await tester.pumpAndSettle();

    expect(find.text('Novo produto'), findsNothing);
  });

  testWidgets('creates a new product via the dialog', (tester) async {
    final products = FakeProductRepository();
    await tester.pumpWidget(_wrap(buildTestServices(products: products), canManage: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Novo produto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Adrenalina');
    await tester.tap(find.widgetWithText(FilledButton, 'Criar'));
    await tester.pumpAndSettle();

    expect(products.lastCreated?.name, 'Adrenalina');
    expect(find.text('Adrenalina'), findsOneWidget);
  });
}
