import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/cart.dart';
import 'package:icrash_app/src/domain/entities/cart_drawer.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
import 'package:icrash_app/src/domain/entities/role.dart';
import 'package:icrash_app/src/presentation/cart/cart_detail_screen.dart';
import 'package:icrash_app/src/presentation/cart/slot_editor_screen.dart';

import '../fakes/fake_repositories.dart';

const _cart = Cart(id: 'cart-1', institutionId: 'inst-a', name: 'Carro 1');

Widget _wrap(AppServices services) {
  return AppServicesScope(
    services: services,
    child: MaterialApp(home: const CartDetailScreen(cart: _cart)),
  );
}

Membership _membership(Role role) => Membership(uid: 'me', institutionId: _cart.institutionId, role: role, status: MembershipStatus.active);

void main() {
  testWidgets('shows an empty state when the cart has no drawers', (tester) async {
    await tester.pumpWidget(_wrap(buildTestServices(drawers: FakeDrawerRepository())));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ainda não existem gavetas'), findsOneWidget);
  });

  testWidgets('lists drawers and opens the slot editor on tap', (tester) async {
    const drawer = CartDrawer(id: 'drawer-1', cartId: 'cart-1', name: 'Gaveta 1', rows: 2, columns: 2);
    await tester.pumpWidget(_wrap(buildTestServices(drawers: FakeDrawerRepository(drawers: [drawer]))));
    await tester.pumpAndSettle();

    expect(find.text('Gaveta 1'), findsOneWidget);
    expect(find.text('2 linhas × 2 colunas'), findsOneWidget);

    await tester.tap(find.text('Gaveta 1'));
    await tester.pumpAndSettle();

    expect(find.byType(SlotEditorScreen), findsOneWidget);
  });

  testWidgets('shows "Nova gaveta" for a manager and creates a drawer', (tester) async {
    final drawers = FakeDrawerRepository();
    await tester.pumpWidget(_wrap(buildTestServices(
      institutions: FakeInstitutionRepository(myMembership: _membership(Role.manager)),
      drawers: drawers,
    )));
    await tester.pumpAndSettle();

    expect(find.text('Nova gaveta'), findsOneWidget);

    await tester.tap(find.text('Nova gaveta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Gaveta Nova');
    await tester.tap(find.widgetWithText(FilledButton, 'Criar'));
    await tester.pumpAndSettle();

    expect(drawers.lastCreatedDrawer?.name, 'Gaveta Nova');
    expect(find.text('Gaveta Nova'), findsOneWidget);
  });

  testWidgets('hides "Nova gaveta" for a normal user', (tester) async {
    await tester.pumpWidget(_wrap(buildTestServices(
      institutions: FakeInstitutionRepository(myMembership: _membership(Role.user)),
      drawers: FakeDrawerRepository(),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Nova gaveta'), findsNothing);
  });
}
