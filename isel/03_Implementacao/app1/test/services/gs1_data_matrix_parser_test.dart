import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/services/gs1_data_matrix_parser.dart';

void main() {
  test('parses GTIN, expiry and lot with no separators between them', () {
    final result = parseGs1DataMatrix('01054123456789001726063010LOTE99');

    expect(result.gtin, '05412345678900');
    expect(result.expiryDate, DateTime(2026, 6, 30));
    expect(result.lotNumber, 'LOTE99');
  });

  test('parses fields out of order, since GS1 element order is not fixed', () {
    // "10" + "LOTE99" + "17" + "260630" + "01" + "05412345678900" — lot first this time.
    final result = parseGs1DataMatrix('10LOTE99172606300105412345678900');

    expect(result.lotNumber, 'LOTE99');
    expect(result.expiryDate, DateTime(2026, 6, 30));
    expect(result.gtin, '05412345678900');
  });

  test('honors an FNC1 separator terminating the lot before the next AI', () {
    final result = parseGs1DataMatrix('10LOT-1\x1D17260630\x1D0105412345678900');

    expect(result.lotNumber, 'LOT-1');
    expect(result.expiryDate, DateTime(2026, 6, 30));
    expect(result.gtin, '05412345678900');
  });

  test('a lot without a separator is truncated at the next recognized AI (documented limitation)', () {
    final result = parseGs1DataMatrix('10LOT0117260630');

    // "01" inside "LOT01" looks like the start of AI 01 without a separator.
    expect(result.lotNumber, 'LOT');
    expect(result.gtin, isNull);
  });

  test('interprets the two-digit year per the GS1 general specification', () {
    expect(parseGs1DataMatrix('17500101').expiryDate, DateTime(2050, 1, 1));
    expect(parseGs1DataMatrix('17510101').expiryDate, DateTime(1951, 1, 1));
  });

  test('treats day 00 as the 1st of the month rather than crashing', () {
    expect(parseGs1DataMatrix('17260600').expiryDate, DateTime(2026, 6, 1));
  });

  test('returns an empty result for a payload with no recognized AI', () {
    final result = parseGs1DataMatrix('not a gs1 payload at all');

    expect(result.isEmpty, isTrue);
    expect(result.gtin, isNull);
    expect(result.lotNumber, isNull);
    expect(result.expiryDate, isNull);
  });

  test('strips a leading FNC1-in-first-position marker before parsing', () {
    final result = parseGs1DataMatrix('\x1D0105412345678900');

    expect(result.gtin, '05412345678900');
  });

  test('ignores a GTIN field that is shorter than the required 14 digits', () {
    final result = parseGs1DataMatrix('01ABCD12345678'); // "01" + only 12 chars, not the required 14

    expect(result.gtin, isNull);
  });

  test('ignores a GTIN field of the right length but containing non-digits', () {
    final result = parseGs1DataMatrix('01ABCD1234567890'); // "01" + 14 chars, not all digits

    expect(result.gtin, isNull);
  });
}
