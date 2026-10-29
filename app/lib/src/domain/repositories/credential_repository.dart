/// Credentials issued by the administration (DB3, 28 Oct): only an
/// institution admin sets a user's password and PIN; users can never change
/// their own. INTERIM, under Firebase: the PIN hash is stored per membership
/// and checked on the device; the real check moves to the institution's
/// server (docs/FIREBASE.md §9).
abstract class CredentialRepository {
  /// The encoded PIN hash of [uid] in [institutionId] (see `PinHasher`), or
  /// null when the administration hasn't set a PIN yet. Readable by that
  /// user and by institution admins only.
  Future<String?> fetchPinHash(String institutionId, String uid);

  /// Sets [uid]'s PIN hash. Institution admins only, never for themselves
  /// (rules).
  Future<void> setPinHash(String institutionId, String uid, String pinHash);
}
