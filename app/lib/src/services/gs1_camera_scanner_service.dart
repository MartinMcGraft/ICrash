import 'package:mobile_scanner/mobile_scanner.dart';

import 'scanner_service.dart';

/// Camera-based [Gs1DataMatrixScannerService] (spec section 32): business
/// logic depends only on the interface, never on [MobileScanner] directly.
/// Android/iOS/macOS/web only — `mobile_scanner` has no Windows/Linux desktop
/// support, matching the legacy QR reader's own platform gating; callers must
/// check platform support before constructing this (see `gs1_scan_screen.dart`).
class MobileScannerGs1Service implements Gs1DataMatrixScannerService {
  MobileScannerGs1Service() : controller = MobileScannerController(formats: const [BarcodeFormat.dataMatrix]);

  /// Exposed so the presentation layer can bind the camera preview
  /// (`MobileScanner(controller: ...)`) to the same controller this service
  /// reads from, without the screen touching `MobileScanner`'s detection API.
  final MobileScannerController controller;

  @override
  Stream<String> scanRawPayloads() =>
      controller.barcodes.map((capture) => capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue).where(
        (value) => value != null && value.isNotEmpty,
      ).cast<String>();

  @override
  void dispose() => controller.dispose();
}
