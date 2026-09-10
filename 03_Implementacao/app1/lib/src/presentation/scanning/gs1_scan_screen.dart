import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/gs1_camera_scanner_service.dart';
import '../../services/gs1_data_matrix_parser.dart';
import '../../services/scanner_service.dart';

/// Pushes a full-screen GS1 Data Matrix scanner (spec sections 29-32) and
/// returns the first successfully parsed result, or `null` if the user
/// cancels — scanning is always optional and retryable, never mandatory
/// (spec section 30). Purely presentational: reads raw payloads from
/// whatever [Gs1DataMatrixScannerService] `createScanner` builds (the real
/// camera service, or a fake in tests) and parses them with
/// [parseGs1DataMatrix], independent of the scan source (spec section 31).
Future<Gs1ParsedData?> showGs1ScanScreen(
  BuildContext context, {
  required Gs1DataMatrixScannerService Function() createScanner,
}) {
  return Navigator.of(context).push<Gs1ParsedData>(
    MaterialPageRoute(builder: (_) => Gs1ScanScreen(createScanner: createScanner)),
  );
}

class Gs1ScanScreen extends StatefulWidget {
  const Gs1ScanScreen({super.key, required this.createScanner});

  final Gs1DataMatrixScannerService Function() createScanner;

  @override
  State<Gs1ScanScreen> createState() => _Gs1ScanScreenState();
}

class _Gs1ScanScreenState extends State<Gs1ScanScreen> {
  late final Gs1DataMatrixScannerService _scanner = widget.createScanner();
  late final StreamSubscription<String> _subscription;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _subscription = _scanner.scanRawPayloads().listen(_onPayload);
  }

  void _onPayload(String raw) {
    final parsed = parseGs1DataMatrix(raw);
    if (parsed.isEmpty) {
      setState(() => _lastError = 'Código lido mas sem GTIN, lote ou validade reconhecidos. Tente novamente.');
      return;
    }
    Navigator.of(context).pop(parsed);
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
      appBar: AppBar(title: const Text('Digitalizar código GS1')),
      body: Column(
        children: [
          Expanded(
            child: scanner is MobileScannerGs1Service
                ? MobileScanner(controller: scanner.controller)
                : const _ScannerPreviewPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Aponte a câmara ao código GS1 Data Matrix da embalagem.',
                  textAlign: TextAlign.center,
                ),
                if (_lastError != null) ...[
                  const SizedBox(height: 8),
                  Text(_lastError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar e inserir manualmente'),
                ),
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
