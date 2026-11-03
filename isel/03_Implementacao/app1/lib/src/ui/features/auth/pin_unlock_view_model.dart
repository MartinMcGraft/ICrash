import '../../../domain/repositories/device_session_repository.dart';
import '../../core/mvvm/view_model.dart';

/// A2 · Desbloquear com PIN (proposal D3: unlocks the session saved on this
/// device; works offline).
class PinUnlockViewModel extends ViewModel {
  PinUnlockViewModel({required this.deviceSession, required this.user, required this.onUnlocked, required this.onTooManyAttempts});

  static const pinLength = 4;
  static const maxAttempts = 5;

  final DeviceSessionRepository deviceSession;
  final RememberedUser user;
  final Future<void> Function() onUnlocked;

  /// After [maxAttempts] wrong PINs the saved session is dropped and the
  /// person must sign in with their password.
  final Future<void> Function() onTooManyAttempts;

  String _digits = '';
  int _failures = 0;
  bool wrongPin = false;

  int get entered => _digits.length;
  int get attemptsLeft => maxAttempts - _failures;

  void addDigit(int digit) {
    if (_digits.length >= pinLength || busy) return;
    wrongPin = false;
    _digits += '$digit';
    notify();
    if (_digits.length == pinLength) _verify();
  }

  void deleteDigit() {
    if (_digits.isEmpty || busy) return;
    _digits = _digits.substring(0, _digits.length - 1);
    notify();
  }

  Future<void> _verify() async {
    final result = await run(() => deviceSession.verifyPin(user.uid, _digits));
    if (result.isOk && result.value == true) {
      await onUnlocked();
      return;
    }
    _failures++;
    _digits = '';
    wrongPin = true;
    notify();
    if (_failures >= maxAttempts) await onTooManyAttempts();
  }
}
