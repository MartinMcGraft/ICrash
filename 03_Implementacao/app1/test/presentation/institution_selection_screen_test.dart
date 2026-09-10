import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/l10n/app_localizations.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/institution.dart';
import 'package:icrash_app/src/presentation/dashboard/institution_home_screen.dart';
import 'package:icrash_app/src/presentation/institution/institution_selection_screen.dart';

import '../fakes/fake_repositories.dart';

Widget _wrap(AppServices services) {
  // AppServicesScope must wrap MaterialApp (as it does in lib/main.dart),
  // not just `home`: a pushed route sits alongside `home` under the
  // Navigator, so scoping it only around `home` would hide it from screens
  // reached via Navigator.push.
  return AppServicesScope(
    services: services,
    child: MaterialApp(
      locale: const Locale('pt', 'PT'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const InstitutionSelectionScreen(),
    ),
  );
}

void main() {
  testWidgets('shows an empty state when the user has no institution', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(buildTestServices(institutions: FakeInstitutionRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Ainda não tem acesso'), findsOneWidget);
  });

  testWidgets(
    'lists institutions and opens the institution home screen on tap',
    (tester) async {
      const institution = Institution(id: 'inst-a', name: 'Hospital A');
      await tester.pumpWidget(
        _wrap(
          buildTestServices(
            institutions: FakeInstitutionRepository(
              institutions: const [institution],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hospital A'), findsOneWidget);

      await tester.tap(find.text('Hospital A'));
      await tester.pumpAndSettle();

      expect(find.byType(InstitutionHomeScreen), findsOneWidget);
    },
  );

  testWidgets('signs out when the logout action is tapped', (tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(_wrap(buildTestServices(auth: auth)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Terminar sessão'));
    await tester.pumpAndSettle();

    expect(auth.signOutCallCount, 1);
  });
}
