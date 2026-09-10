import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/presentation/scanning/gs1_scan_screen.dart';
import 'package:icrash_app/src/services/gs1_data_matrix_parser.dart';
import 'package:icrash_app/src/services/gs1_hid_scanner_service.dart';
import 'package:icrash_app/src/services/scanner_service.dart';

import '../fakes/fake_repositories.dart';

class _HostScreen extends StatelessWidget {
  const _HostScreen({required this.scanner, required this.onResult});

  final Gs1DataMatrixScannerService scanner;
  final void Function(Object? result) onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await showGs1ScanScreen(context, createScanner: () => scanner);
            onResult(result);
          },
          child: const Text('Abrir scanner'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('parses a scanned GS1 payload and pops with the result', (tester) async {
    final scanner = FakeGs1DataMatrixScannerService();
    Object? result = 'unset';
    await tester.pumpWidget(MaterialApp(home: _HostScreen(scanner: scanner, onResult: (r) => result = r)));

    await tester.tap(find.text('Abrir scanner'));
    await tester.pumpAndSettle();
    expect(find.text('Digitalizar código GS1'), findsOneWidget);

    scanner.emit('0105412345678900');
    await tester.pumpAndSettle();

    expect(result, isA<Gs1ParsedData>());
    expect((result as Gs1ParsedData).gtin, '05412345678900');
    expect(scanner.disposed, isTrue);
  });

  testWidgets('shows a retry message and keeps listening when a payload has no recognized GS1 data', (tester) async {
    final scanner = FakeGs1DataMatrixScannerService();
    await tester.pumpWidget(MaterialApp(home: _HostScreen(scanner: scanner, onResult: (_) {})));

    await tester.tap(find.text('Abrir scanner'));
    await tester.pumpAndSettle();

    scanner.emit('not a GS1 payload');
    await tester.pumpAndSettle();

    expect(find.textContaining('Tente novamente'), findsOneWidget);
    expect(find.text('Digitalizar código GS1'), findsOneWidget, reason: 'still on the scan screen, not popped');
  });

  testWidgets('cancelling returns null so the caller falls back to manual entry', (tester) async {
    final scanner = FakeGs1DataMatrixScannerService();
    Object? result = 'unset';
    await tester.pumpWidget(MaterialApp(home: _HostScreen(scanner: scanner, onResult: (r) => result = r)));

    await tester.tap(find.text('Abrir scanner'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar e inserir manualmente'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(scanner.disposed, isTrue);
  });

  testWidgets('HID mode: typing a code into the focused field and pressing Enter parses and pops', (tester) async {
    final scanner = HidGs1ScannerService();
    Object? result = 'unset';
    await tester.pumpWidget(MaterialApp(home: _HostScreen(scanner: scanner, onResult: (r) => result = r)));

    await tester.tap(find.text('Abrir scanner'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.keyboard_outlined), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0105412345678900');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(result, isA<Gs1ParsedData>());
    expect((result as Gs1ParsedData).gtin, '05412345678900');
  });
}
