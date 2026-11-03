import 'dart:async';

import 'package:mobile_scanner/mobile_scanner.dart';

/// Symbology of a scanned code.
enum CodeFormat { qr, dataMatrix, barcode, unknown }

class ScannedCode {
  const ScannedCode(this.raw, this.format);
  final String raw;
  final CodeFormat format;
}

/// One scanner for everything design v2 A11 reads: QR (carts), GS1 Data
/// Matrix (packages) and 1D barcodes (EAN-13 / Code 128 — audit D9), from
/// the camera or from a USB/HID reader that types into a field.
abstract class CodeScannerService {
  Stream<ScannedCode> scans();
  bool get usesCamera;
  Future<void> toggleTorch();
  void dispose();
}

class CameraCodeScannerService implements CodeScannerService {
  CameraCodeScannerService()
      : controller = MobileScannerController(
          formats: const [BarcodeFormat.qrCode, BarcodeFormat.dataMatrix, BarcodeFormat.ean13, BarcodeFormat.code128],
        );

  final MobileScannerController controller;

  @override
  bool get usesCamera => true;

  @override
  Stream<ScannedCode> scans() => controller.barcodes.expand((capture) sync* {
        for (final barcode in capture.barcodes) {
          final raw = barcode.rawValue;
          if (raw == null || raw.isEmpty) continue;
          yield ScannedCode(raw, switch (barcode.format) {
            BarcodeFormat.qrCode => CodeFormat.qr,
            BarcodeFormat.dataMatrix => CodeFormat.dataMatrix,
            BarcodeFormat.ean13 || BarcodeFormat.code128 => CodeFormat.barcode,
            _ => CodeFormat.unknown,
          });
          break;
        }
      });

  @override
  Future<void> toggleTorch() => controller.toggleTorch();

  @override
  void dispose() => controller.dispose();
}

/// Desktop / no camera: a USB scanner types the code followed by Enter.
class KeyboardCodeScannerService implements CodeScannerService {
  final _controller = StreamController<ScannedCode>.broadcast();

  void feedLine(String line) {
    final raw = line.trim();
    if (raw.isEmpty) return;
    _controller.add(ScannedCode(raw, _guess(raw)));
  }

  static CodeFormat _guess(String raw) {
    if (raw.startsWith('icrash://')) return CodeFormat.qr;
    if (RegExp(r'^\d{8,14}$').hasMatch(raw)) return CodeFormat.barcode;
    if (raw.contains('\x1D') || raw.startsWith('01') || raw.startsWith(']d2')) return CodeFormat.dataMatrix;
    return CodeFormat.unknown;
  }

  @override
  bool get usesCamera => false;

  @override
  Stream<ScannedCode> scans() => _controller.stream;

  @override
  Future<void> toggleTorch() async {}

  @override
  void dispose() => _controller.close();
}
