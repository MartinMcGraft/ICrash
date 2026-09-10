import 'dart:async';

import 'scanner_service.dart';

/// HID/keyboard-wedge [Gs1DataMatrixScannerService] (spec section 32:
/// "USB/Bluetooth HID scanners; keyboard-style scanner input... especially
/// important for Windows", where `mobile_scanner` has no camera support at
/// all). A HID barcode scanner behaves exactly like a keyboard typing very
/// fast and finishing with Enter — no special driver integration is needed,
/// only a focused text field to type into. [feedLine] is called by that
/// field's `onSubmitted` (see `gs1_scan_screen.dart`'s HID branch); this
/// class only owns the resulting stream, not the field itself.
class HidGs1ScannerService implements Gs1DataMatrixScannerService {
  final _controller = StreamController<String>.broadcast();

  void feedLine(String rawLine) {
    if (rawLine.isEmpty) return;
    _controller.add(rawLine);
  }

  @override
  Stream<String> scanRawPayloads() => _controller.stream;

  @override
  void dispose() => _controller.close();
}
