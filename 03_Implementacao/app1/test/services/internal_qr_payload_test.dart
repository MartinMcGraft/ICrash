import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/services/internal_qr_payload.dart';

void main() {
  test('encodes and decodes a round trip', () {
    final payload = encodeCartQrPayload('inst-a', 'cart-1');
    final target = decodeCartQrPayload(payload);

    expect(payload, 'icrash://v1/cart/inst-a/cart-1');
    expect(target?.institutionId, 'inst-a');
    expect(target?.cartId, 'cart-1');
  });

  test('rejects a payload with the wrong scheme', () {
    expect(decodeCartQrPayload('https://v1/cart/inst-a/cart-1'), isNull);
  });

  test('rejects a payload with the wrong version', () {
    expect(decodeCartQrPayload('icrash://v2/cart/inst-a/cart-1'), isNull);
  });

  test('rejects a payload for a different resource kind', () {
    expect(decodeCartQrPayload('icrash://v1/drawer/inst-a/drawer-1'), isNull);
  });

  test('rejects malformed or unrelated text', () {
    expect(decodeCartQrPayload('not a uri at all'), isNull);
    expect(decodeCartQrPayload('0105412345678900'), isNull);
  });
}
