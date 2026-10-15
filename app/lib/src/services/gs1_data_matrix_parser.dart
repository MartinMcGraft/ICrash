/// Parses the GS1 Application Identifiers this app needs out of a raw GS1
/// Data Matrix payload (spec section 31): AI 01 (GTIN, 14 digits), AI 10
/// (batch/lot, variable length) and AI 17 (expiry date, 6-digit YYMMDD).
/// Deliberately independent of any camera/scanner code — scanner recognition
/// and GS1 parsing are separate layers (spec section 31) so this can be
/// unit-tested with plain strings, no camera involved.
class Gs1ParsedData {
  const Gs1ParsedData({this.gtin, this.lotNumber, this.expiryDate});

  final String? gtin;
  final String? lotNumber;
  final DateTime? expiryDate;

  bool get isEmpty => gtin == null && lotNumber == null && expiryDate == null;
}

/// GS1's field separator between variable-length AIs (ASCII 29, "GS").
const _fnc1 = '\x1D';

/// Best-effort GS1 element-string parser for the three AIs this app needs.
///
/// Real GS1 Data Matrix payloads terminate a variable-length AI (like AI 10)
/// with an FNC1 separator; when a scanned payload omits it (common with
/// cheaper printers/scanners), this falls back to stopping at the next
/// recognized AI prefix instead — which means a lot number that happens to
/// start with "01" or "17" would be truncated early. This mirrors the
/// trade-off already accepted by the legacy prototype's regex-based parser,
/// just without duplicating three copies of it.
Gs1ParsedData parseGs1DataMatrix(String raw) {
  var input = raw;
  if (input.startsWith(_fnc1)) input = input.substring(1);

  String? gtin;
  String? lotNumber;
  DateTime? expiryDate;

  var i = 0;
  while (i < input.length) {
    if (input.startsWith(_fnc1, i)) {
      i++;
      continue;
    }

    final gtinMatch = _matchFixedDigits(input, i, '01', 14);
    if (gtinMatch != null) {
      gtin = gtinMatch;
      i += 2 + 14;
      continue;
    }

    final expiryMatch = _matchFixedDigits(input, i, '17', 6);
    if (expiryMatch != null) {
      expiryDate = _parseYyMmDd(expiryMatch);
      i += 2 + 6;
      continue;
    }

    if (input.startsWith('10', i)) {
      final start = i + 2;
      var end = start;
      while (end < input.length && input[end] != _fnc1 && !_startsKnownAi(input, end)) {
        end++;
      }
      final value = input.substring(start, end);
      lotNumber = value.isEmpty ? null : value;
      i = end;
      continue;
    }

    // Unrecognized AI or stray character: skip one character rather than
    // looping forever or aborting the whole parse over one bad field.
    i++;
  }

  return Gs1ParsedData(gtin: gtin, lotNumber: lotNumber, expiryDate: expiryDate);
}

final _digitsOnly = RegExp(r'^\d+$');

String? _matchFixedDigits(String input, int index, String ai, int length) {
  if (!input.startsWith(ai, index)) return null;
  final start = index + ai.length;
  final end = start + length;
  if (end > input.length) return null;
  final value = input.substring(start, end);
  return _digitsOnly.hasMatch(value) ? value : null;
}

bool _startsKnownAi(String input, int index) =>
    input.startsWith('01', index) || input.startsWith('17', index) || input.startsWith('10', index);

/// GS1 general specification: a 2-digit year 00-50 means 2000-2050, 51-99
/// means 1951-1999. Day "00" means "last day of the month" per the spec;
/// treated here as the 1st rather than computed, since medicine expiry
/// dates using day 00 are rare and this is only ever a pre-fill the user can
/// correct (spec section 30's mandatory manual-fallback requirement).
DateTime? _parseYyMmDd(String yymmdd) {
  final year = int.parse(yymmdd.substring(0, 2));
  final month = int.parse(yymmdd.substring(2, 4));
  final day = int.parse(yymmdd.substring(4, 6));
  final fullYear = year <= 50 ? 2000 + year : 1900 + year;
  if (month < 1 || month > 12) return null;
  return DateTime(fullYear, month, day == 0 ? 1 : day);
}
