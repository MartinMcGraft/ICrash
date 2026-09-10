import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/cart.dart';
import 'package:icrash_app/src/domain/entities/cart_product_assignment.dart';
import 'package:icrash_app/src/domain/entities/product.dart';
import 'package:icrash_app/src/presentation/cart/product_search_screen.dart';

import '../fakes/fake_repositories.dart';

const _cart = Cart(id: 'cart-1', institutionId: 'inst-a', name: 'Carro 1');

Widget _wrap(AppServices services, {bool canManage = true}) {
  return AppServicesScope(
    services: services,
    child: MaterialApp(home: ProductSearchScreen(cart: _cart, canManage: canManage)),
  );
}

void main() {
  testWidgets('shows a hint before typing anything', (tester) async {
    await tester.pumpWidget(_wrap(buildTestServices()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Escreva o nome de um produto'), findsOneWidget);
  });

  testWidgets('finds an assigned product by name and shows nothing for a non-match', (tester) async {
    const adrenaline = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
    const amiodarone = Product(id: 'p2', institutionId: 'inst-a', name: 'Amiodarona');
    const assignment1 = CartProductAssignment(
      id: 'a1',
      cartId: 'cart-1',
      slotId: 'r0c0',
      productId: 'p1',
      currentQuantity: 3,
      targetQuantity: 5,
    );
    const assignment2 = CartProductAssignment(
      id: 'a2',
      cartId: 'cart-1',
      slotId: 'r0c1',
      productId: 'p2',
      currentQuantity: 1,
      targetQuantity: 2,
    );
    await tester.pumpWidget(_wrap(buildTestServices(
      products: FakeProductRepository(products: [adrenaline, amiodarone]),
      inventory: FakeInventoryRepository(assignments: [assignment1, assignment2]),
    )));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'adren');
    await tester.pumpAndSettle();

    expect(find.text('Adrenalina'), findsOneWidget);
    expect(find.text('Amiodarona'), findsNothing);
  });

  testWidgets('opens the assignment dialog for a search result', (tester) async {
    const product = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
    const assignment = CartProductAssignment(
      id: 'a1',
      cartId: 'cart-1',
      slotId: 'r0c0',
      productId: 'p1',
      currentQuantity: 3,
      targetQuantity: 5,
    );
    await tester.pumpWidget(_wrap(buildTestServices(
      products: FakeProductRepository(products: [product]),
      inventory: FakeInventoryRepository(assignments: [assignment]),
    )));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Adrenalina');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Adrenalina'));
    await tester.pumpAndSettle();

    expect(find.text('Atual: 3   Alvo: 5'), findsOneWidget);
  });
}
