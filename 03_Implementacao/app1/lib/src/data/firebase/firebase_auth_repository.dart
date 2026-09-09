import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/repositories/auth_repository.dart';
import 'firestore_exception_mapper.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final fb.FirebaseAuth _auth;

  static AuthUser? _map(fb.User? user) => user == null ? null : AuthUser(uid: user.uid, email: user.email);

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<AuthUser> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user == null) {
        throw mapFirebaseException(fb.FirebaseAuthException(code: 'unauthenticated'));
      }
      return _map(user)!;
    } on fb.FirebaseAuthException catch (error) {
      throw mapFirebaseException(error);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
