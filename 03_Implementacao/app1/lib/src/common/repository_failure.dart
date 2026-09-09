/// Error surfaced by a repository, wrapping the underlying Firebase/platform
/// exception behind a domain-friendly reason so the presentation layer never
/// needs to know about `FirebaseException`, `PlatformException`, etc.
class RepositoryFailure implements Exception {
  const RepositoryFailure(this.reason, {this.cause});

  final RepositoryFailureReason reason;
  final Object? cause;

  @override
  String toString() => 'RepositoryFailure(${reason.name}${cause != null ? ', cause: $cause' : ''})';
}

enum RepositoryFailureReason {
  unauthenticated,
  permissionDenied,
  notFound,
  offline,
  conflict,
  unknown,
}
