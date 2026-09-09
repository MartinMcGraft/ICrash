import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/main.dart';

void main() {
  testWidgets('The I-Crash home menu loads with its existing entry points', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('I-Crash'), findsOneWidget);
    expect(find.text('Registration'), findsOneWidget);
    expect(find.text('QR Code Reader'), findsOneWidget);
    expect(find.text('Data matrix scan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
