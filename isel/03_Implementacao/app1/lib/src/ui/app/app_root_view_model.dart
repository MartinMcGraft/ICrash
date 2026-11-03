import '../../common/app_services.dart';
import '../../common/repository_failure.dart';
import '../../domain/entities/institution.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/device_session_repository.dart';
import '../../services/internal_qr_payload.dart';
import '../core/mvvm/view_model.dart';
import '../core/session/session.dart';

enum RootStage {
  starting,

  /// A1 with no saved session (password only).
  signedOut,

  /// A1 with a saved session protected by a PIN (PIN / cart login offered).
  locked,

  /// A2
  pin,

  /// A3
  cartLogin,
  pickingInstitution,
  noInstitution,
  ready,
}

/// Owns the authentication / lock / institution flow and creates the
/// [SessionController] once the user is inside an institution.
class AppRootViewModel extends ViewModel {
  AppRootViewModel(this.services) {
    listen(services.auth.authStateChanges(), _onAuthChanged);
  }

  final AppServices services;

  RootStage stage = RootStage.starting;
  AuthUser? user;
  RememberedUser? remembered;
  bool hasPin = false;
  List<Institution> institutions = const [];
  SessionController? session;
  Object? loadError;
  bool _firstAuthEvent = true;

  /// A saved session exists on this device (enables PIN / cart login).
  bool get hasSavedSession => user != null && remembered?.uid == user!.uid;

  Future<void> _onAuthChanged(AuthUser? next) async {
    final cold = _firstAuthEvent;
    _firstAuthEvent = false;
    user = next;
    remembered = await services.deviceSession.rememberedUser();
    if (next == null) {
      _closeSession();
      hasPin = false;
      stage = RootStage.signedOut;
      notify();
      return;
    }
    hasPin = remembered?.uid == next.uid && await services.deviceSession.hasPin(next.uid);
    if (cold && hasPin) {
      stage = RootStage.locked;
      notify();
      return;
    }
    if (stage == RootStage.starting || stage == RootStage.signedOut) {
      await loadInstitutions();
    }
  }

  /// Called by the login screen after a successful password sign-in (the
  /// auth stream does not re-emit when the same user signs in again).
  Future<void> onPasswordSignIn() => loadInstitutions();

  void showPin() {
    stage = RootStage.pin;
    notify();
  }

  void showCartLogin() {
    stage = RootStage.cartLogin;
    notify();
  }

  void showLogin() {
    stage = hasSavedSession && hasPin ? RootStage.locked : RootStage.signedOut;
    notify();
  }

  /// A2 succeeded.
  Future<void> onPinUnlocked() => loadInstitutions();

  /// A3: opens a session limited to [target]'s cart.
  Future<ActionResult<void>> enterCart(CartQrTarget target) => run(() async {
        if (user == null) throw const ActionError('noSavedSession');
        final cart = await services.carts.getCart(target.institutionId, target.cartId);
        if (cart == null || cart.archived) throw const RepositoryFailure(RepositoryFailureReason.notFound);
        final list = await services.institutions.watchMyInstitutions().first;
        final institution = list.where((i) => i.id == target.institutionId).firstOrNull;
        if (institution == null) throw const RepositoryFailure(RepositoryFailureReason.permissionDenied);
        institutions = list;
        await _open(institution, scopedCartId: cart.id);
      });

  Future<void>? _loading;

  /// Coalesces concurrent calls (auth stream + login callback).
  Future<void> loadInstitutions() => _loading ??= _loadInstitutions().whenComplete(() => _loading = null);

  Future<void> _loadInstitutions() async {
    stage = RootStage.starting;
    loadError = null;
    notify();
    try {
      institutions = await services.institutions.watchMyInstitutions().first;
    } on RepositoryFailure catch (failure) {
      loadError = failure;
      institutions = const [];
    }
    if (isDisposed) return;
    if (institutions.length == 1) {
      await selectInstitution(institutions.single);
    } else {
      stage = institutions.isEmpty ? RootStage.noInstitution : RootStage.pickingInstitution;
      notify();
    }
  }

  Future<void> selectInstitution(Institution institution) => _open(institution);

  Future<void> _open(Institution institution, {String? scopedCartId}) async {
    final current = user;
    if (current == null) return;
    Membership? membership;
    try {
      membership = await services.institutions.getMyMembership(institution.id);
    } on RepositoryFailure {
      membership = null;
    }
    await services.deviceSession.remember(RememberedUser(
      uid: current.uid,
      displayName: membership?.displayName ?? current.email ?? current.uid,
      roleId: membership?.role.id,
      service: membership?.service,
      institutionName: institution.name,
    ));
    remembered = await services.deviceSession.rememberedUser();
    _closeSession();
    session = SessionController(
      services: services,
      user: current,
      institution: institution,
      membership: membership,
      institutionCount: institutions.length,
      scopedCartId: scopedCartId,
    );
    stage = RootStage.ready;
    notify();
  }

  void switchInstitution() {
    _closeSession();
    stage = RootStage.pickingInstitution;
    notify();
  }

  /// Profile › "Bloquear": only meaningful with a PIN.
  Future<void> lock() async {
    if (!hasPin) return;
    _closeSession();
    stage = RootStage.locked;
    notify();
  }

  Future<ActionResult<void>> setPin(String pin) => run(() async {
        final current = user;
        if (current == null) throw const ActionError('noSavedSession');
        await services.deviceSession.setPin(current.uid, pin);
        hasPin = true;
      });

  /// Signs out and forgets the device session ("Não é a Ana?").
  Future<void> signOut() async {
    await services.deviceSession.forget();
    await services.auth.signOut();
  }

  void _closeSession() {
    session?.dispose();
    session = null;
  }

  @override
  void dispose() {
    _closeSession();
    super.dispose();
  }
}
