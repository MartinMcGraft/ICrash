/// GTIN helpers (P16: GTIN is unique when present and optional;
/// DATABASE.md `gtin CHAR(14)`, digits only, EAN-13 padded to 14).

/// The 14-digit form of a GTIN-8, UPC-A (12), EAN-13 or GTIN-14, the way a
/// scan reads it (`scanned_product_code.dart`), so a code typed in B5 or
/// imported from CSV matches its own scan. Returns null for an empty value;
/// a value that isn't 8 or 12–14 digits is returned trimmed, unchanged, for
/// the caller's validation to reject.
String? normalizeGtin(String? raw) {
  if (raw == null) return null;
  final value = raw.replaceAll(RegExp(r'\s'), '');
  if (value.isEmpty) return null;
  if (RegExp(r'^(\d{8}|\d{12,14})$').hasMatch(value)) return value.padLeft(14, '0');
  return value;
}

/// Whether [raw] is a GTIN the catalogue accepts (8 or 12–14 digits).
bool isValidGtin(String raw) => RegExp(r'^(\d{8}|\d{12,14})$').hasMatch(raw.replaceAll(RegExp(r'\s'), ''));

/// Forms the same GTIN may have been stored in before 29 Oct 2026 (as
/// typed, without padding): the 14-digit value and its versions without
/// leading zeros, at 13, 12 and 8 digits. Lets lookups match old data
/// without a migration.
List<String> gtinLookupForms(String gtin) {
  final padded = normalizeGtin(gtin) ?? gtin;
  final forms = <String>{padded};
  for (final length in const [13, 12, 8]) {
    final cut = padded.length - length;
    if (cut > 0 && padded.substring(0, cut).replaceAll('0', '').isEmpty) forms.add(padded.substring(cut));
  }
  return forms.toList();
}
