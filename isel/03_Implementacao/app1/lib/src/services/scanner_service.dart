/// Two intentionally separate scanning domains (spec section 29): the
/// internal I-Crash QR identifies cart/drawer/slot, while GS1 Data Matrix
/// carries medicine GTIN/lot/expiry. Never call medicine scanning "QR".
///
/// `InternalQrScannerService` remains a contract only — internal QR/cart
/// navigation is a later workstream (spec section 67). `Gs1DataMatrixScannerService`
/// is implemented by `MobileScannerGs1Service` (camera) and, in tests, by a
/// fake that pushes canned payloads — see `gs1_camera_scanner_service.dart`
/// and `test/fakes/fake_repositories.dart`. Business logic (the assignment
/// dialog) depends on this interface only, never on `MobileScanner` directly
/// (spec section 32).
abstract class InternalQrScannerService {
  /// Decodes a scanned `icrash://v1/...` payload into a resolvable id.
  /// Resolution/authorization happens in the repository/application layer,
  /// never in the scanner itself (spec section 33).
  Stream<String> scanPayloads();

  void dispose();
}

abstract class Gs1DataMatrixScannerService {
  /// Raw decoded payload strings, unparsed — GS1 AI parsing (spec section
  /// 31) is a separate, camera-independent step; see
  /// `gs1_data_matrix_parser.dart`.
  Stream<String> scanRawPayloads();

  void dispose();
}
