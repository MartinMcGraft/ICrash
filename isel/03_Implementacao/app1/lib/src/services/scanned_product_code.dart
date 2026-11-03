import 'code_scanner_service.dart';
import 'gs1_data_matrix_parser.dart';

/// Turns any scanned code into product data: a GS1 Data Matrix gives GTIN +
/// lot + expiry; a 1D barcode (EAN-13 / Code 128 with digits) gives just the
/// GTIN, normalised to 14 digits like the catalogue stores it. Returns null
/// for codes that carry no product data (e.g. a cart QR).
Gs1ParsedData? productDataFromScan(ScannedCode code) {
  if (code.format == CodeFormat.qr) return null;
  final digits = code.raw.trim();
  if (RegExp(r'^\d{8,14}$').hasMatch(digits)) {
    return Gs1ParsedData(gtin: digits.padLeft(14, '0'));
  }
  final parsed = parseGs1DataMatrix(code.raw);
  return parsed.isEmpty ? null : parsed;
}
