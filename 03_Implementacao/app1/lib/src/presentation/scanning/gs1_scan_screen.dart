import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../common/l10n/app_localizations.dart';
import '../../services/gs1_camera_scanner_service.dart';
import '../../services/gs1_data_matrix_parser.dart';
import '../../services/gs1_hid_scanner_service.dart';
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
      setState(() => _lastError = AppLocalizations.of(context).gs1ScanError);
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
    final l10n = AppLocalizations.of(context);
    final scanner = _scanner;
    final isHid = scanner is HidGs1ScannerService;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.gs1ScanTitle)),
      body: Column(
        children: [
          Expanded(
            child: switch (scanner) {
              MobileScannerGs1Service() => MobileScanner(controller: scanner.controller),
              HidGs1ScannerService() => _HidScanInput(scanner: scanner),
              _ => const _ScannerPreviewPlaceholder(),
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  isHid ? l10n.gs1ScanInstructionHid : l10n.gs1ScanInstructionCamera,
                  textAlign: TextAlign.center,
                ),
                if (_lastError != null) ...[
                  const SizedBox(height: 8),
                  Text(_lastError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.actionCancelManualEntry),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A HID barcode scanner emulates a keyboard, so a plain focused text field
/// already receives its input — the field's own `onSubmitted` (triggered by
/// the Enter the scanner sends after the code) is the entire "detection"
/// step. Re-focuses itself after every scan so the next one doesn't need a
/// manual click back into the field.
class _HidScanInput extends StatefulWidget {
  const _HidScanInput({required this.scanner});

  final HidGs1ScannerService scanner;

  @override
  State<_HidScanInput> createState() => _HidScanInputState();
}

class _HidScanInputState extends State<_HidScanInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSubmitted(String value) {
    widget.scanner.feedLine(value.trim());
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.keyboard_outlined, size: 48),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).gs1HidWaitingLabel,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: _onSubmitted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerPreviewPlaceholder extends StatelessWidget {
  const _ScannerPreviewPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black12,
      child: Center(child: Text(AppLocalizations.of(context).scannerPreviewUnavailable)),
    );
  }
}
