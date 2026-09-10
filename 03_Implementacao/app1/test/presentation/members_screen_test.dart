import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/l10n/app_localizations.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/institution.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
import 'package:icrash_app/src/domain/entities/role.dart';
import 'package:icrash_app/src/domain/repositories/auth_repository.dart';
import 'package:icrash_app/src/presentation/members/members_screen.dart';

import '../fakes/fake_repositories.dart';

const _institution = Institution(id: 'inst-a', name: 'Hospital A');

Widget _wrap(AppServices services) {
  return AppServicesScope(
    services: services,
    child: MaterialApp(
      locale: const Locale('pt', 'PT'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MembersScreen(institution: _institution),
    ),
  );
}

Membership _member(
  String uid,
  Role role, {
  MembershipStatus status = MembershipStatus.active,
}) => Membership(
  uid: uid,
  institutionId: _institution.id,
  role: role,
  status: status,
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

  testWidgets('lists members with their role and status', (tester) async {
    final institutions = FakeInstitutionRepository(
      members: [_member('me', Role.institutionAdmin)],
    );
    await tester.pumpWidget(
      _wrap(
        buildTestServices(
          auth: FakeAuthRepository(signedInUser: const AuthUser(uid: 'me')),
          institutions: institutions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('me'), findsOneWidget);
    expect(find.text('Administrador da instituição'), findsOneWidget);
    expect(find.text('Ativo'), findsOneWidget);
  });

  testWidgets('creates a new member via the dialog', (tester) async {
    final institutions = FakeInstitutionRepository();
    await tester.pumpWidget(
      _wrap(buildTestServices(institutions: institutions)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Novo membro'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'novo@icrash.pt');
    await tester.enterText(find.byType(TextFormField).last, 'palavra-passe');
    await tester.tap(find.widgetWithText(FilledButton, 'Criar'));
    await tester.pumpAndSettle();

    expect(institutions.members, hasLength(1));
    expect(institutions.members.single.role, Role.user);
    expect(find.textContaining('member-1'), findsOneWidget);
  });

  testWidgets(
    'does not show the member-management menu on the signed-in user\'s own row',
    (tester) async {
      final institutions = FakeInstitutionRepository(
        members: [
          _member('me', Role.institutionAdmin),
          _member('other', Role.user),
        ],
      );
      await tester.pumpWidget(
        _wrap(
          buildTestServices(
            auth: FakeAuthRepository(signedInUser: const AuthUser(uid: 'me')),
            institutions: institutions,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    },
  );

  testWidgets('disables a member', (tester) async {
    final institutions = FakeInstitutionRepository(
      members: [_member('other', Role.user)],
    );
    await tester.pumpWidget(
      _wrap(
        buildTestServices(
          auth: FakeAuthRepository(signedInUser: const AuthUser(uid: 'me')),
          institutions: institutions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desativar'));
    await tester.pumpAndSettle();

    expect(institutions.members.single.status, MembershipStatus.disabled);
    expect(find.text('Desativado'), findsOneWidget);
  });
}
