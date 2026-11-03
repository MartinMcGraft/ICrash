import '../../../common/repository_failure.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../core/mvvm/view_model.dart';

/// A1 · Iniciar sessão.
class LoginViewModel extends ViewModel {
  LoginViewModel({required this.auth, required this.onSignedIn});

  final AuthRepository auth;

  /// Tells the app root to continue (load institutions).
  final Future<void> Function() onSignedIn;

  RepositoryFailureReason? error;

  Future<void> signIn(String email, String password) async {
    error = null;
    final result = await run(() => auth.signInWithEmailPassword(email.trim(), password));
    if (result.isOk) {
      await onSignedIn();
    } else {
      error = result.failure;
      notify();
    }
  }
}
