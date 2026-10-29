/// The signed-in user's identity, decoupled from `firebase_auth`'s `User`
/// type so the domain/presentation layers never import Firebase directly.
class AuthUser {
  const AuthUser({required this.uid, this.email});

  final String uid;
  final String? email;
}

/// Authentication is email+password for the prototype, but the interface
/// stays provider-agnostic so future mechanisms (NFC card, staff QR,
/// institutional SSO) can be added without touching callers (spec section 14).
abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();

  AuthUser? get currentUser;

  Future<AuthUser> signInWithEmailPassword(String email, String password);

  // No password reset here (DB3): credentials are set and reset by the
  // administration only. See docs/FIREBASE.md §9 for how a reset is done.

  Future<void> signOut();
}
