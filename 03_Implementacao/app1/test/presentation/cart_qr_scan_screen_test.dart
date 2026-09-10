import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/presentation/scanning/cart_qr_scan_screen.dart';
import 'package:icrash_app/src/services/internal_qr_payload.dart';

import '../fakes/fake_repositories.dart';

class _HostScreen extends StatelessWidget {
  const _HostScreen({required this.scanner, required this.onResult});

  final FakeInternalQrScannerService scanner;
  final void Function(Object? result) onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await showCartQrScanScreen(context, createScanner: () => scanner);
            onResult(result);
          },
          child: const Text('Abrir scanner'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('decodes a scanned cart QR payload and pops with the target', (tester) async {
    final scanner = FakeInternalQrScannerService();
    Object? result = 'unset';
    await tester.pumpWidget(MaterialApp(home: _HostScreen(scanner: scanner, onResult: (r) => result = r)));

    await tester.tap(find.text('Abrir scanner'));
    await tester.pumpAndSettle();
    expect(find.text('Ler código do carro'), findsOneWidget);

    scanner.emit('icrash://v1/cart/inst-a/cart-1');
    await tester.pumpAndSettle();

    expect(result, isA<CartQrTarget>());
    final target = result as CartQrTarget;
    expect(target.institutionId, 'inst-a');
    expect(target.cartId, 'cart-1');
    expect(scanner.disposed, isTrue);
  });

  testWidgets('shows a retry message for an unrecognized payload', (tester) async {
    final scanner = FakeInternalQrScannerService();
    await tester.pumpWidget(MaterialApp(home: _HostScreen(scanner: scanner, onResult: (_) {})));

    await tester.tap(find.text('Abrir scanner'));
    await tester.pumpAndSettle();

    scanner.emit('https://example.com');
    await tester.pumpAndSettle();

    expect(find.textContaining('não é um código de carro reconhecido'), findsOneWidget);
    expect(find.text('Ler código do carro'), findsOneWidget, reason: 'still on the scan screen, not popped');
  });

  testWidgets('cancelling returns null', (tester) async {
    final scanner = FakeInternalQrScannerService();
    Object? result = 'unset';
    await tester.pumpWidget(MaterialApp(home: _HostScreen(scanner: scanner, onResult: (r) => result = r)));

    await tester.tap(find.text('Abrir scanner'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(scanner.disposed, isTrue);
  });
}
