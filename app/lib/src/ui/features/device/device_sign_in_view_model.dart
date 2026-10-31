import '../../../common/app_services.dart';
import '../../../domain/entities/membership.dart';
import '../../../domain/entities/role.dart';
import '../../../services/pin_hasher.dart';
import '../../core/mvvm/view_model.dart';

/// Why A2b refused.
enum DeviceSignInError {
  /// The PIN was typed before the number / e-mail.
  enterIdentifier,

  /// Unknown person or wrong PIN (one message for both, so the tablet doesn't
  /// tell which numbers exist).
  wrongCredentials,

  /// The administration hasn't set this person's PIN yet.
  noPin,

  /// "Remover registo": only an Admin may.
  notAdmin,

  /// The person isn't registered to any of this tablet's carts.
  noCarts,

  /// A3: the person isn't registered to the scanned cart.
  notOnCart,
  generic,
}

/// A2b · Identificação (D17, 30 Oct 2026): on a registered tablet a person
/// types their nº mecanográfico or e-mail and their PIN. The PIN is checked
/// on the tablet against the hash the administration set (DB3), which the
/// tablet's account may read.
class DeviceSignInViewModel extends ViewModel {
  DeviceSignInViewModel({
    required this.services,
    required this.institutionId,
    required this.onIdentified,
    required this.onTooManyAttempts,
  });

  static const pinLength = PinHasher.pinLength;
  static const maxAttempts = 5;

  final AppServices services;
  final String institutionId;

  /// Opens the person's session; returns an error code (`notAdmin`,
  /// `noCarts`, `notOnCart`) or null.
  final Future<String?> Function(Membership person) onIdentified;

  /// After [maxAttempts] failures the tablet goes back to its A1.
  final Future<void> Function() onTooManyAttempts;

  String identifier = '';
  String _digits = '';
  int _failures = 0;
  DeviceSignInError? error;

  int get entered => _digits.length;
  int get attemptsLeft => maxAttempts - _failures;

  void setIdentifier(String value) {
    identifier = value;
    if (error == DeviceSignInError.enterIdentifier) error = null;
    notify();
  }

  void addDigit(int digit) {
    if (_digits.length >= pinLength || busy) return;
    if (error != DeviceSignInError.wrongCredentials) error = null;
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
    if (identifier.trim().isEmpty) {
      _digits = '';
      error = DeviceSignInError.enterIdentifier;
      notify();
      return;
    }
    final pin = _digits;
    final result = await run(() async {
      final members = await services.institutions.watchMembers(institutionId).first;
      final person = members.where((m) => m.role != Role.device && m.isActive && m.matches(identifier)).firstOrNull;
      if (person == null) throw const ActionError('wrongCredentials');
      final hash = await services.credentials.fetchPinHash(institutionId, person.uid);
      if (hash == null) throw const ActionError('noPin');
      if (!await services.pinHasher.verify(pin, hash)) throw const ActionError('wrongCredentials');
      final code = await onIdentified(person);
      if (code != null) throw ActionError(code);
    });
    if (isDisposed || result.isOk) return;
    _digits = '';
    error = switch (result.code) {
      'wrongCredentials' => DeviceSignInError.wrongCredentials,
      'noPin' => DeviceSignInError.noPin,
      'notAdmin' => DeviceSignInError.notAdmin,
      'noCarts' => DeviceSignInError.noCarts,
      'notOnCart' => DeviceSignInError.notOnCart,
      _ => DeviceSignInError.generic,
    };
    if (error == DeviceSignInError.wrongCredentials) _failures++;
    notify();
    if (_failures >= maxAttempts) await onTooManyAttempts();
  }
}
