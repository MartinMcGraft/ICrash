import 'package:firebase_auth/firebase_auth.dart';

import '../../common/repository_failure.dart';

/// Translates Firebase's own exception types into [RepositoryFailure] so
/// nothing above the data layer needs to know about `FirebaseException` or
/// `FirebaseAuthException`.
RepositoryFailure mapFirebaseException(Object error) {
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
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'email-already-in-use':
        return RepositoryFailure(RepositoryFailureReason.conflict, cause: error);
      case 'invalid-email':
      case 'weak-password':
        return RepositoryFailure(RepositoryFailureReason.invalidInput, cause: error);
      default:
        return RepositoryFailure(RepositoryFailureReason.unauthenticated, cause: error);
    }
  }
  return RepositoryFailure(RepositoryFailureReason.unknown, cause: error);
}
