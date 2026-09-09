import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/cart.dart';
import 'package:icrash_app/src/domain/entities/cart_drawer.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
import 'package:icrash_app/src/domain/entities/role.dart';
import 'package:icrash_app/src/presentation/cart/slot_editor_screen.dart';

import '../fakes/fake_repositories.dart';

const _cart = Cart(id: 'cart-1', institutionId: 'inst-a', name: 'Carro 1');
const _drawer = CartDrawer(id: 'drawer-1', cartId: 'cart-1', name: 'Gaveta 1', rows: 2, columns: 2);

Widget _wrap(AppServices services) {
  return AppServicesScope(
    services: services,
    child: MaterialApp(home: const SlotEditorScreen(cart: _cart, drawer: _drawer)),
  );
}

Membership _manager() => const Membership(uid: 'me', institutionId: 'inst-a', role: Role.manager, status: MembershipStatus.active);

void main() {
  testWidgets('renders one unit cell per grid position when no slots exist yet', (tester) async {
    await tester.pumpWidget(_wrap(buildTestServices(institutions: FakeInstitutionRepository(myMembership: _manager()))));
    await tester.pumpAndSettle();

    expect(find.text('1,1'), findsOneWidget);
    expect(find.text('1,2'), findsOneWidget);
    expect(find.text('2,1'), findsOneWidget);
    expect(find.text('2,2'), findsOneWidget);
  });

  testWidgets('merges two selected cells and saves the new layout', (tester) async {
    final drawers = FakeDrawerRepository();
    await tester.pumpWidget(_wrap(buildTestServices(
      institutions: FakeInstitutionRepository(myMembership: _manager()),
      drawers: drawers,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1,1'));
    await tester.tap(find.text('1,2'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Juntar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Guardar'));
    await tester.pumpAndSettle();

    final saved = drawers.lastSavedSlots!;
    expect(saved, hasLength(3));
    expect(saved.any((s) => s.columnSpan == 2), isTrue);
  });

  testWidgets('splits a merged slot back into unit cells', (tester) async {
    final drawers = FakeDrawerRepository();
    await tester.pumpWidget(_wrap(buildTestServices(
      institutions: FakeInstitutionRepository(myMembership: _manager()),
      drawers: drawers,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('1,1'));
    await tester.tap(find.text('1,2'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Juntar'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Dividir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Guardar'));
    await tester.pumpAndSettle();

    final saved = drawers.lastSavedSlots!;
    expect(saved, hasLength(4));
    expect(saved.every((s) => s.rowSpan == 1 && s.columnSpan == 1), isTrue);
  });

  testWidgets('hides edit controls for a normal user', (tester) async {
    await tester.pumpWidget(_wrap(buildTestServices(
      institutions: FakeInstitutionRepository(
        myMembership: const Membership(uid: 'me', institutionId: 'inst-a', role: Role.user, status: MembershipStatus.active),
      ),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Juntar'), findsNothing);
    expect(find.byTooltip('Guardar'), findsNothing);
  });
}
