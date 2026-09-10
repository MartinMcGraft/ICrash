import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/l10n/app_localizations.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/cart_responsible_user.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
import 'package:icrash_app/src/domain/entities/role.dart';
import 'package:icrash_app/src/presentation/cart/responsible_users_screen.dart';

import '../fakes/fake_repositories.dart';

Widget _wrap(AppServices services) {
  return AppServicesScope(
    services: services,
    child: MaterialApp(
      locale: const Locale('pt', 'PT'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ResponsibleUsersScreen(
        institutionId: 'inst-a',
        cartId: 'cart-1',
      ),
    ),
  );
}

Membership _member(String uid, Role role) => Membership(
  uid: uid,
  institutionId: 'inst-a',
  role: role,
  status: MembershipStatus.active,
);

void main() {
  testWidgets('shows an empty state when the institution has no members', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(buildTestServices(institutions: FakeInstitutionRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Ainda não existem membros'), findsOneWidget);
  });

  testWidgets(
    'lists members with a checkbox reflecting current responsibility',
    (tester) async {
      final carts = FakeCartRepository();
      carts.responsibleUsers.add(
        const CartResponsibleUser(uid: 'user-1', cartId: 'cart-1'),
      );
      await tester.pumpWidget(
        _wrap(
          buildTestServices(
            institutions: FakeInstitutionRepository(
              members: [
                _member('user-1', Role.user),
                _member('user-2', Role.user),
              ],
            ),
            carts: carts,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final checkbox1 = tester.widget<CheckboxListTile>(
        find.ancestor(
          of: find.text('user-1'),
          matching: find.byType(CheckboxListTile),
        ),
      );
      final checkbox2 = tester.widget<CheckboxListTile>(
        find.ancestor(
          of: find.text('user-2'),
          matching: find.byType(CheckboxListTile),
        ),
      );
      expect(checkbox1.value, isTrue);
      expect(checkbox2.value, isFalse);
    },
  );

  testWidgets(
    'assigns and removes a responsible user by toggling the checkbox',
    (tester) async {
      final carts = FakeCartRepository();
      await tester.pumpWidget(
        _wrap(
          buildTestServices(
            institutions: FakeInstitutionRepository(
              members: [_member('user-1', Role.user)],
            ),
            carts: carts,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      expect(carts.responsibleUsers.map((r) => r.uid), contains('user-1'));

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      expect(
        carts.responsibleUsers.map((r) => r.uid),
        isNot(contains('user-1')),
      );
    },
  );
}
