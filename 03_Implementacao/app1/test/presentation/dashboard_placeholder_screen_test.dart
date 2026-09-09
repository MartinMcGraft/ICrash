import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/institution.dart';
import 'package:icrash_app/src/presentation/dashboard/dashboard_placeholder_screen.dart';

import '../fakes/fake_repositories.dart';

void main() {
  testWidgets('shows the institution name and can still open the legacy app', (tester) async {
    const institution = Institution(id: 'inst-a', name: 'Hospital A');
    await tester.pumpWidget(
      AppServicesScope(
        services: buildTestServices(),
        child: MaterialApp(home: const DashboardPlaceholderScreen(institution: institution)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hospital A'), findsOneWidget);

    await tester.tap(find.text('Abrir aplicação anterior (referência)'));
    await tester.pumpAndSettle();

    expect(find.text('Registration'), findsOneWidget);
  });
}
