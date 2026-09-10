import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/internal_qr_camera_scanner_service.dart';
import '../../services/internal_qr_payload.dart';
import '../../services/scanner_service.dart';

/// Pushes a full-screen internal-QR scanner (spec sections 29, 33) and
/// returns the decoded [CartQrTarget], or `null` if the user cancels.
/// Mirrors `gs1_scan_screen.dart`'s structure for the other scanning domain.
Future<CartQrTarget?> showCartQrScanScreen(
  BuildContext context, {
  required InternalQrScannerService Function() createScanner,
}) {
  return Navigator.of(context).push<CartQrTarget>(
    MaterialPageRoute(builder: (_) => CartQrScanScreen(createScanner: createScanner)),
  );
}

class CartQrScanScreen extends StatefulWidget {
  const CartQrScanScreen({super.key, required this.createScanner});

  final InternalQrScannerService Function() createScanner;

  @override
  State<CartQrScanScreen> createState() => _CartQrScanScreenState();
}

class _CartQrScanScreenState extends State<CartQrScanScreen> {
  late final InternalQrScannerService _scanner = widget.createScanner();
  late final StreamSubscription<String> _subscription;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _subscription = _scanner.scanPayloads().listen(_onPayload);
  }

  void _onPayload(String raw) {
    final target = decodeCartQrPayload(raw);
    if (target == null) {
      setState(() => _lastError = 'Código lido mas não é um código de carro reconhecido. Tente novamente.');
      return;
    }
    Navigator.of(context).pop(target);
  }

  @override
  void dispose() {
    _subscription.cancel();
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanner = _scanner;
    return Scaffold(
      appBar: AppBar(title: const Text('Ler código do carro')),
      body: Column(
        children: [
          Expanded(
            child: scanner is MobileScannerInternalQrService
                ? MobileScanner(controller: scanner.controller)
                : const _ScannerPreviewPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Aponte a câmara ao código do carro.', textAlign: TextAlign.center),
                if (_lastError != null) ...[
                  const SizedBox(height: 8),
                  Text(_lastError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 12),
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerPreviewPlaceholder extends StatelessWidget {
  const _ScannerPreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black12,
      child: Center(child: Text('Pré-visualização da câmara indisponível.')),
    );
  }
}
