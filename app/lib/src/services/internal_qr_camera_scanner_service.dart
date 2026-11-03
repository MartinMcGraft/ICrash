import 'package:mobile_scanner/mobile_scanner.dart';

import 'scanner_service.dart';

/// Camera-based [InternalQrScannerService] (spec section 32): business logic
/// depends only on the interface, never on [MobileScanner] directly. Mirrors
/// `gs1_camera_scanner_service.dart`'s pattern, restricted to `qrCode`
/// instead of `dataMatrix` since internal cart/drawer identification always
/// uses a plain QR code (spec section 29 — never the medicine domain's Data
/// Matrix). Android/iOS/macOS/web only, same platform gate as the GS1 scanner.
class MobileScannerInternalQrService implements InternalQrScannerService {
  MobileScannerInternalQrService() : controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);

  final MobileScannerController controller;

  @override
  Stream<String> scanPayloads() =>
      controller.barcodes.map((capture) => capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue).where(
        (value) => value != null && value.isNotEmpty,
      ).cast<String>();

  @override
  void dispose() => controller.dispose();
}
