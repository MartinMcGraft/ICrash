import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/home_menu.dart';

void main() {
  testWidgets('The legacy I-Crash home menu still loads with its existing entry points', (tester) async {
    // Pumped directly (not via MyApp/main.dart) because MyApp now requires a
    // real Firebase app to be initialized for its AppServices/auth gate;
    // this only asserts the legacy screen itself, still reachable from
    // DashboardPlaceholderScreen, keeps working unmodified.
    await tester.pumpWidget(const MaterialApp(home: HomeMenu()));
    await tester.pumpAndSettle();
    expect(find.text('I-Crash'), findsOneWidget);
    expect(find.text('Registration'), findsOneWidget);
    expect(find.text('QR Code Reader'), findsOneWidget);
    expect(find.text('Data matrix scan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
