import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/services/pin_hasher.dart';

void main() {
  // Few iterations keep the tests fast; the count travels with each hash.
  final hasher = PinHasher(iterations: 1000);

  test('a hash verifies its own PIN and no other', () async {
    final encoded = await hasher.hash('1234');
    expect(encoded, startsWith(r'pbkdf2-sha256$1000$'));
    expect(await hasher.verify('1234', encoded), isTrue);
    expect(await hasher.verify('1235', encoded), isFalse);
  });

  test('the salt makes two hashes of the same PIN differ', () async {
    expect(await hasher.hash('1234'), isNot(await hasher.hash('1234')));
  });

  test('only 4-digit PINs are accepted; malformed hashes never verify', () async {
    expect(PinHasher.isValidPin('1234'), isTrue);
    expect(PinHasher.isValidPin('123'), isFalse);
    expect(PinHasher.isValidPin('12a4'), isFalse);
    expect(() => hasher.hash('12345'), throwsArgumentError);
    expect(await hasher.verify('1234', r'sha256$x'), isFalse);
    expect(await hasher.verify('1234', r'pbkdf2-sha256$1000$%%%$%%%'), isFalse);
  });

  test('uses standard PBKDF2-HMAC-SHA256, the same as the Node seed scripts', () async {
    // Expected value from crypto.pbkdf2Sync('1234', 'salt-for-tests-1', 1000, 32, 'sha256')
    // (identical to Python's hashlib.pbkdf2_hmac).
    const expected = r'pbkdf2-sha256$1000$c2FsdC1mb3ItdGVzdHMtMQ==$yGloleHkdAyoaW/Eb0SMpPM7gAhWmYdCkJvDYomXLK0=';
    expect(await hasher.hashWithSalt('1234', utf8.encode('salt-for-tests-1')), expected);
    expect(await hasher.verify('1234', expected), isTrue);
  });
}
