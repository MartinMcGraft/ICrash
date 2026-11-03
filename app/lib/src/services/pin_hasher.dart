import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// Salted, slow PIN hashes (DB3; DATABASE.md USER `pinHash`: "the encoded
/// hash: algorithm, salt and hash in one string"; §1.5: salted, never
/// checked for uniqueness).
///
/// Encoded as `pbkdf2-sha256$<iterations>$<salt, base64>$<hash, base64>`.
/// The iteration count travels with each hash, so [defaultIterations] can be
/// tuned later without invalidating PINs already set. The seed scripts
/// (`firebase/firestore-tests/`) and `firebase/tools/set_password.mjs`
/// produce the same format with Node's `crypto.pbkdf2Sync`.
///
/// INTERIM, under Firebase only: the hash is stored where its user can read
/// it, so a 4-digit PIN can be brute-forced offline. The real check moves to
/// the institution's server (docs/FIREBASE.md §9).
class PinHasher {
  PinHasher({this.iterations = defaultIterations, Random? random}) : _random = random ?? Random.secure();

  static const scheme = 'pbkdf2-sha256';

  /// Aimed at about 0.2 s per check on a cart tablet (release build). Pure
  /// Dart PBKDF2 speed varies a lot by device: measure on the target tablet
  /// and adjust; old hashes keep their own count.
  static const defaultIterations = 60000;

  static const pinLength = 4;
  static const _saltBytes = 16;
  static const _hashBits = 256;

  final int iterations;
  final Random _random;

  /// A PIN is exactly [pinLength] digits (A2's keypad).
  static bool isValidPin(String pin) => RegExp('^\\d{$pinLength}\$').hasMatch(pin);

  Future<String> hash(String pin) => hashWithSalt(pin, List<int>.generate(_saltBytes, (_) => _random.nextInt(256)));

  /// [hash] with a given salt, to check the encoding against Node's output.
  @visibleForTesting
  Future<String> hashWithSalt(String pin, List<int> salt) async {
    if (!isValidPin(pin)) throw ArgumentError.value(pin, 'pin', 'must be $pinLength digits');
    final derived = await _derive(pin, salt, iterations);
    return '$scheme\$$iterations\$${base64Encode(salt)}\$${base64Encode(derived)}';
  }

  /// Whether [pin] matches [encoded]. False for a malformed hash.
  Future<bool> verify(String pin, String encoded) async {
    final parts = encoded.split(r'$');
    if (parts.length != 4 || parts[0] != scheme) return false;
    final rounds = int.tryParse(parts[1]);
    if (rounds == null || rounds <= 0) return false;
    final List<int> salt;
    final List<int> expected;
    try {
      salt = base64Decode(parts[2]);
      expected = base64Decode(parts[3]);
    } on FormatException {
      return false;
    }
    final actual = await _derive(pin, salt, rounds);
    if (actual.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < actual.length; i++) {
      diff |= actual[i] ^ expected[i];
    }
    return diff == 0;
  }

  static Future<List<int>> _derive(String pin, List<int> salt, int rounds) async {
    final algorithm = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: rounds, bits: _hashBits);
    final key = await algorithm.deriveKey(secretKey: SecretKey(utf8.encode(pin)), nonce: salt);
    return key.extractBytes();
  }
}
