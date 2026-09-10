import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/l10n/app_localizations.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/common/repository_failure.dart';
import 'package:icrash_app/src/presentation/auth/login_screen.dart';

import '../fakes/fake_repositories.dart';

Widget _wrap(AppServices services) {
  return AppServicesScope(
    services: services,
    child: MaterialApp(
      locale: const Locale('pt', 'PT'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LoginScreen(),
    ),
  );
}

void main() {
  testWidgets('shows validation errors when submitted empty', (tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(_wrap(buildTestServices(auth: auth)));

    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Indique o e-mail'), findsOneWidget);
    expect(find.text('Indique a palavra-passe'), findsOneWidget);
    expect(auth.lastEmail, isNull);
  });

  testWidgets('submits entered credentials to AuthRepository', (tester) async {
    final auth = FakeAuthRepository();
    await tester.pumpWidget(_wrap(buildTestServices(auth: auth)));

    await tester.enterText(find.byType(TextFormField).first, 'nurse@icrash.pt');
    await tester.enterText(find.byType(TextFormField).last, 's3nha-segura');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(auth.lastEmail, 'nurse@icrash.pt');
    expect(auth.lastPassword, 's3nha-segura');
    expect(
      find.text('Não foi possível iniciar sessão. Tente novamente.'),
      findsNothing,
    );
  });

  testWidgets('shows a friendly message on invalid credentials', (
    tester,
  ) async {
    final auth = FakeAuthRepository(
      signInError: const RepositoryFailure(
        RepositoryFailureReason.unauthenticated,
      ),
    );
    await tester.pumpWidget(_wrap(buildTestServices(auth: auth)));

    await tester.enterText(find.byType(TextFormField).first, 'nurse@icrash.pt');
    await tester.enterText(find.byType(TextFormField).last, 'wrong');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Credenciais inválidas. Verifique o e-mail e a palavra-passe.'),
      findsOneWidget,
    );
  });
}
