import 'package:firebase_auth/firebase_auth.dart';

import '../../common/repository_failure.dart';

/// Translates Firebase's own exception types into [RepositoryFailure] so
/// nothing above the data layer needs to know about `FirebaseException` or
/// `FirebaseAuthException`.
RepositoryFailure mapFirebaseException(Object error) {
  // FirebaseAuthException extends FirebaseException, so this check must come
  // first: otherwise every auth error matches the generic branch below and its
  // specific codes (e-mail in use, network failure, ...) are never reached.
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'email-already-in-use':
        return RepositoryFailure(RepositoryFailureReason.conflict, cause: error);
      case 'invalid-email':
      case 'weak-password':
        return RepositoryFailure(RepositoryFailureReason.invalidInput, cause: error);
      case 'network-request-failed':
        return RepositoryFailure(RepositoryFailureReason.offline, cause: error);
      default:
        return RepositoryFailure(RepositoryFailureReason.unauthenticated, cause: error);
    }
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return RepositoryFailure(RepositoryFailureReason.permissionDenied, cause: error);
      case 'unauthenticated':
        return RepositoryFailure(RepositoryFailureReason.unauthenticated, cause: error);
      case 'not-found':
        return RepositoryFailure(RepositoryFailureReason.notFound, cause: error);
      case 'unavailable':
      case 'deadline-exceeded':
        return RepositoryFailure(RepositoryFailureReason.offline, cause: error);
      case 'aborted':
      case 'already-exists':
        return RepositoryFailure(RepositoryFailureReason.conflict, cause: error);
      default:
        return RepositoryFailure(RepositoryFailureReason.unknown, cause: error);
    }
  }
  return RepositoryFailure(RepositoryFailureReason.unknown, cause: error);
}
