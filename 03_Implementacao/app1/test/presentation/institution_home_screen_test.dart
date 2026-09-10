import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/cart.dart';
import 'package:icrash_app/src/domain/entities/cart_status.dart';
import 'package:icrash_app/src/domain/entities/institution.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
import 'package:icrash_app/src/domain/entities/product.dart';
import 'package:icrash_app/src/domain/entities/role.dart';
import 'package:icrash_app/src/domain/entities/usage_event.dart';
import 'package:icrash_app/src/presentation/cart/cart_detail_screen.dart';
import 'package:icrash_app/src/presentation/dashboard/institution_home_screen.dart';

import '../fakes/fake_repositories.dart';

const _institution = Institution(id: 'inst-a', name: 'Hospital A');

Widget _wrap(AppServices services) {
  return AppServicesScope(
    services: services,
    child: MaterialApp(home: const InstitutionHomeScreen(institution: _institution)),
  );
}

Membership _membership(Role role) => Membership(uid: 'me', institutionId: _institution.id, role: role, status: MembershipStatus.active);

void main() {
  testWidgets('shows an empty state when the institution has no carts', (tester) async {
    await tester.pumpWidget(_wrap(buildTestServices(carts: FakeCartRepository())));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ainda não existem carros'), findsOneWidget);
  });

  testWidgets('lists carts and opens the cart detail screen on tap', (tester) async {
    const cart = Cart(id: 'cart-1', institutionId: 'inst-a', name: 'Carro 1');
    await tester.pumpWidget(_wrap(buildTestServices(carts: FakeCartRepository(carts: [cart]))));
    await tester.pumpAndSettle();

    expect(find.text('Carro 1'), findsOneWidget);
    expect(find.text('Operacional'), findsOneWidget);

    await tester.tap(find.text('Carro 1'));
    await tester.pumpAndSettle();

    expect(find.byType(CartDetailScreen), findsOneWidget);
  });

  testWidgets('shows "Novo carro" for a manager and creates a cart', (tester) async {
    final carts = FakeCartRepository();
    await tester.pumpWidget(_wrap(buildTestServices(
      institutions: FakeInstitutionRepository(myMembership: _membership(Role.manager)),
      carts: carts,
    )));
    await tester.pumpAndSettle();

    expect(find.text('Novo carro'), findsOneWidget);

    await tester.tap(find.text('Novo carro'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Carro Novo');
    await tester.tap(find.widgetWithText(FilledButton, 'Criar'));
    await tester.pumpAndSettle();

    expect(carts.lastCreated?.name, 'Carro Novo');
    expect(find.text('Carro Novo'), findsOneWidget);
  });

  testWidgets('hides "Novo carro" for a normal user', (tester) async {
    await tester.pumpWidget(_wrap(buildTestServices(
      institutions: FakeInstitutionRepository(myMembership: _membership(Role.user)),
      carts: FakeCartRepository(),
    )));
    await tester.pumpAndSettle();

    expect(find.text('Novo carro'), findsNothing);
  });

  testWidgets('shows "Membros" for an institution admin', (tester) async {
    await tester.pumpWidget(_wrap(buildTestServices(
      institutions: FakeInstitutionRepository(myMembership: _membership(Role.institutionAdmin)),
      carts: FakeCartRepository(),
    )));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Membros'), findsOneWidget);
  });

  testWidgets('hides "Membros" for a manager', (tester) async {
    await tester.pumpWidget(_wrap(buildTestServices(
      institutions: FakeInstitutionRepository(myMembership: _membership(Role.manager)),
      carts: FakeCartRepository(),
    )));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Membros'), findsNothing);
  });

  testWidgets('can still open the legacy app', (tester) async {
    await tester.pumpWidget(_wrap(buildTestServices(carts: FakeCartRepository())));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Aplicação anterior (referência)'));
    await tester.pumpAndSettle();

    expect(find.text('Registration'), findsOneWidget);
  });

  testWidgets('shows cart status counts in the dashboard summary', (tester) async {
    const carts = [
      Cart(id: 'cart-1', institutionId: 'inst-a', name: 'Carro 1'),
      Cart(id: 'cart-2', institutionId: 'inst-a', name: 'Carro 2'),
      Cart(id: 'cart-3', institutionId: 'inst-a', name: 'Carro 3', status: CartStatus.auditRequired),
    ];
    await tester.pumpWidget(_wrap(buildTestServices(carts: FakeCartRepository(carts: carts))));
    await tester.pumpAndSettle();

    expect(find.text('Operacional: 2'), findsOneWidget);
    expect(find.text('Auditoria necessária: 1'), findsOneWidget);
  });

  testWidgets('filters the cart list by name', (tester) async {
    const carts = [
      Cart(id: 'cart-1', institutionId: 'inst-a', name: 'Carro Pediatria'),
      Cart(id: 'cart-2', institutionId: 'inst-a', name: 'Carro Adultos'),
    ];
    await tester.pumpWidget(_wrap(buildTestServices(carts: FakeCartRepository(carts: carts))));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'pedia');
    await tester.pumpAndSettle();

    expect(find.text('Carro Pediatria'), findsOneWidget);
    expect(find.text('Carro Adultos'), findsNothing);
  });

  testWidgets('shows recent activity from usage events', (tester) async {
    const cart = Cart(id: 'cart-1', institutionId: 'inst-a', name: 'Carro 1');
    const product = Product(id: 'p1', institutionId: 'inst-a', name: 'Adrenalina');
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
    await tester.pumpWidget(_wrap(buildTestServices(
      carts: FakeCartRepository(carts: [cart]),
      products: FakeProductRepository(products: [product]),
      usage: FakeUsageRepository(events: [event]),
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('Adrenalina'), findsOneWidget);
    expect(find.textContaining('(-2)'), findsOneWidget);
  });
}
