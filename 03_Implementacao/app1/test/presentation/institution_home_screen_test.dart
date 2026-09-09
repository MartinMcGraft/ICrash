import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/cart.dart';
import 'package:icrash_app/src/domain/entities/institution.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
import 'package:icrash_app/src/domain/entities/role.dart';
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

  testWidgets('can still open the legacy app', (tester) async {
    await tester.pumpWidget(_wrap(buildTestServices(carts: FakeCartRepository())));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Aplicação anterior (referência)'));
    await tester.pumpAndSettle();

    expect(find.text('Registration'), findsOneWidget);
  });
}
