import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/repository_failure.dart';
import 'package:icrash_app/src/data/firebase/firestore_exception_mapper.dart';

void main() {
  group('mapFirebaseException', () {
    test('auth errors keep their specific reason (FirebaseAuthException extends FirebaseException)', () {
      RepositoryFailureReason reasonOf(String code) =>
          mapFirebaseException(FirebaseAuthException(code: code)).reason;

      expect(reasonOf('email-already-in-use'), RepositoryFailureReason.conflict);
      expect(reasonOf('weak-password'), RepositoryFailureReason.invalidInput);
      expect(reasonOf('network-request-failed'), RepositoryFailureReason.offline);
      expect(reasonOf('wrong-password'), RepositoryFailureReason.unauthenticated);
    });

    test('Firestore errors are mapped by code', () {
      final failure = mapFirebaseException(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
      expect(failure.reason, RepositoryFailureReason.permissionDenied);
    });
  });
}
