import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/batch.dart';
import 'package:icrash_app/src/domain/entities/cart.dart';
import 'package:icrash_app/src/domain/entities/cart_drawer.dart';
import 'package:icrash_app/src/domain/entities/cart_product_assignment.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
import 'package:icrash_app/src/domain/entities/product.dart';
import 'package:icrash_app/src/domain/entities/role.dart';
import 'package:icrash_app/src/domain/entities/usage_event.dart';
import 'package:icrash_app/src/domain/repositories/auth_repository.dart';
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

  testWidgets('a manager long-pressing an empty slot assigns a product', (tester) async {
    const product = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
    final inventory = FakeInventoryRepository();
    await tester.pumpWidget(_wrap(buildTestServices(
      institutions: FakeInstitutionRepository(myMembership: _manager()),
      products: FakeProductRepository(products: [product]),
      inventory: inventory,
    )));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('1,1'));
    await tester.pumpAndSettle();

    expect(find.text('Atribuir produto'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<Product>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adrenalina').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Atribuir'));
    await tester.pumpAndSettle();

    expect(inventory.lastCreated?.productId, 'p1');
    expect(inventory.lastCreated?.slotId, 'r0c0');
    expect(find.text('Adrenalina'), findsOneWidget);
  });

  testWidgets('refuses to assign a product already assigned elsewhere in the same cart', (tester) async {
    const product = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
    const existing = CartProductAssignment(
      id: 'assignment-1',
      cartId: 'cart-1',
      slotId: 'r1c0',
      productId: 'p1',
      currentQuantity: 0,
      targetQuantity: 1,
    );
    final inventory = FakeInventoryRepository(assignments: [existing]);
    await tester.pumpWidget(_wrap(buildTestServices(
      institutions: FakeInstitutionRepository(myMembership: _manager()),
      products: FakeProductRepository(products: [product]),
      inventory: inventory,
    )));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('1,1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<Product>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adrenalina').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Atribuir'));
    await tester.pumpAndSettle();

    expect(inventory.assignments, hasLength(1));
    expect(find.textContaining('já está atribuído a outro slot'), findsOneWidget);
  });

  testWidgets('records consumption on an assigned slot', (tester) async {
    const assignment = CartProductAssignment(
      id: 'assignment-1',
      cartId: 'cart-1',
      slotId: 'r0c0',
      productId: 'p1',
      currentQuantity: 5,
      targetQuantity: 10,
    );
    const product = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
    final inventory = FakeInventoryRepository(assignments: [assignment]);
    await tester.pumpWidget(_wrap(buildTestServices(
      auth: FakeAuthRepository(signedInUser: const AuthUser(uid: 'me')),
      institutions: FakeInstitutionRepository(myMembership: _manager()),
      products: FakeProductRepository(products: [product]),
      inventory: inventory,
    )));
    await tester.pumpAndSettle();

    expect(find.text('5/10'), findsOneWidget);

    await tester.longPress(find.text('Adrenalina'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Registar consumo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '2');
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(inventory.assignments.single.currentQuantity, 3);
  });

  testWidgets('replenishes stock by scanning a GS1 code, pre-filling lot/expiry and warning on unknown GTIN',
      (tester) async {
    const assignment = CartProductAssignment(
      id: 'assignment-1',
      cartId: 'cart-1',
      slotId: 'r0c0',
      productId: 'p1',
      currentQuantity: 0,
      targetQuantity: 10,
    );
    const product = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
    final inventory = FakeInventoryRepository(assignments: [assignment]);
    final scanner = FakeGs1DataMatrixScannerService();
    await tester.pumpWidget(_wrap(buildTestServices(
      auth: FakeAuthRepository(signedInUser: const AuthUser(uid: 'me')),
      institutions: FakeInstitutionRepository(myMembership: _manager()),
      products: FakeProductRepository(products: [product]),
      inventory: inventory,
      createGs1Scanner: () => scanner,
    )));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Adrenalina'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Repor stock'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '5');

    await tester.tap(find.widgetWithText(OutlinedButton, 'Digitalizar código GS1'));
    await tester.pumpAndSettle();

    // AI 01 (GTIN, unknown to the catalogue) + AI 17 (expiry 2026-06-30) + AI 10 (lot, no separator).
    scanner.emit('01054123456789001726063010LOTE99');
    await tester.pumpAndSettle();

    expect(find.textContaining('GTIN não reconhecido no catálogo'), findsOneWidget);
    expect(find.text('Validade: 30/06/2026'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(inventory.assignments.single.currentQuantity, 5);
    final batch = inventory.batchesByAssignment['assignment-1']!.single;
    expect(batch.lotNumber, 'LOTE99');
    expect(batch.gtin, '05412345678900');
    expect(batch.source, BatchSource.gs1DataMatrix);
    expect(batch.expiryDate, DateTime(2026, 6, 30));
  });

  testWidgets('corrects a usage event on an assigned slot', (tester) async {
    const assignment = CartProductAssignment(
      id: 'assignment-1',
      cartId: 'cart-1',
      slotId: 'r0c0',
      productId: 'p1',
      currentQuantity: 3,
      targetQuantity: 10,
    );
    const product = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
    final inventory = FakeInventoryRepository(assignments: [assignment]);
    final usage = FakeUsageRepository(events: const [
      UsageEvent(
        id: 'event-1',
        institutionId: 'inst-a',
        actorUid: 'me',
        cartId: 'cart-1',
        assignmentId: 'assignment-1',
        productId: 'p1',
        type: UsageEventType.consumption,
        amount: -2,
      ),
    ]);
    await tester.pumpWidget(_wrap(buildTestServices(
      auth: FakeAuthRepository(signedInUser: const AuthUser(uid: 'me')),
      institutions: FakeInstitutionRepository(myMembership: _manager()),
      products: FakeProductRepository(products: [product]),
      inventory: inventory,
      usage: usage,
    )));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Adrenalina'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Corrigir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(inventory.assignments.single.currentQuantity, 5);
    expect(inventory.lastCorrectedEventId, 'event-1');
  });

  testWidgets('reconciles stock and batches after an audit', (tester) async {
    const assignment = CartProductAssignment(
      id: 'assignment-1',
      cartId: 'cart-1',
      slotId: 'r0c0',
      productId: 'p1',
      currentQuantity: 5,
      targetQuantity: 10,
    );
    const product = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
    final inventory = FakeInventoryRepository(assignments: [assignment]);
    inventory.batchesByAssignment['assignment-1'] = [
      Batch(id: 'batch-1', assignmentId: 'assignment-1', lotNumber: 'L1', expiryDate: DateTime(2027, 1, 1)),
    ];
    await tester.pumpWidget(_wrap(buildTestServices(
      auth: FakeAuthRepository(signedInUser: const AuthUser(uid: 'me')),
      institutions: FakeInstitutionRepository(myMembership: _manager()),
      products: FakeProductRepository(products: [product]),
      inventory: inventory,
    )));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Adrenalina'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Reconciliar'));
    await tester.pumpAndSettle();

    expect(find.text('Lote L1'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '4');
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(inventory.assignments.single.currentQuantity, 4);
    expect(inventory.batchesByAssignment['assignment-1'], hasLength(1));
  });

  testWidgets('hides manager-only actions but keeps consumption/correction for a normal user', (tester) async {
    const assignment = CartProductAssignment(
      id: 'assignment-1',
      cartId: 'cart-1',
      slotId: 'r0c0',
      productId: 'p1',
      currentQuantity: 3,
      targetQuantity: 10,
    );
    const product = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
    await tester.pumpWidget(_wrap(buildTestServices(
      institutions: FakeInstitutionRepository(
        myMembership: const Membership(uid: 'me', institutionId: 'inst-a', role: Role.user, status: MembershipStatus.active),
      ),
      products: FakeProductRepository(products: [product]),
      inventory: FakeInventoryRepository(assignments: [assignment]),
    )));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Adrenalina'));
    await tester.pumpAndSettle();

    expect(find.text('Repor stock'), findsNothing);
    expect(find.text('Reconciliar'), findsNothing);
    expect(find.text('Corrigir'), findsOneWidget);
    expect(find.text('Registar consumo'), findsOneWidget);
  });

  testWidgets('a normal user long-pressing an empty slot only sees an informational message', (tester) async {
    await tester.pumpWidget(_wrap(buildTestServices(
      institutions: FakeInstitutionRepository(
        myMembership: const Membership(uid: 'me', institutionId: 'inst-a', role: Role.user, status: MembershipStatus.active),
      ),
    )));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('1,1'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ainda não tem produto atribuído'), findsOneWidget);
    expect(find.text('Atribuir produto'), findsNothing);
  });
}
