/// Two intentionally separate scanning domains (spec section 29): the
/// internal I-Crash QR identifies cart/drawer/slot, while GS1 Data Matrix
/// carries medicine GTIN/lot/expiry. Never call medicine scanning "QR".
///
/// Full camera/HID/mock implementations and GS1 field parsing land with the
/// scanner workstream (spec sections 30-32); this is the contract other
/// layers depend on so business logic never imports `MobileScanner` directly.
abstract class InternalQrScannerService {
  /// Decodes a scanned `icrash://v1/...` payload into a resolvable id.
  /// Resolution/authorization happens in the repository/application layer,
  /// never in the scanner itself (spec section 33).
  Stream<String> scanPayloads();

  void dispose();
}

abstract class Gs1DataMatrixScannerService {
  Stream<String> scanRawPayloads();

  void dispose();
}
