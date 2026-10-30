import 'dart:async';

import '../../common/app_services.dart';
import '../../common/repository_failure.dart';
import '../../domain/entities/institution.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/role.dart';
import '../../domain/entities/support_access.dart';
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

  /// D18: the signed-in account is Super; [institutions] are then the ones
  /// with an open support window ([supportWindows]).
  bool isSuper = false;
  Map<String, SupportWindow> supportWindows = const {};

  /// D18: Super's window ended or was closed while inside (the picker says so).
  bool supportEnded = false;
  Timer? _supportTimer;
  StreamSubscription<SupportWindow?>? _supportSub;
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
      isSuper = await services.support.isPlatformAdmin();
      if (isSuper) {
        // D18: Super sees only the institutions whose Admin opened a window.
        final open = await services.support.openInstitutions();
        institutions = [for (final (institution, _) in open) institution];
        supportWindows = {for (final (institution, window) in open) institution.id: window};
      } else {
        institutions = await services.institutions.watchMyInstitutions().first;
      }
    } on RepositoryFailure catch (failure) {
      loadError = failure;
      institutions = const [];
    }
    if (isDisposed) return;
    if (isSuper) {
      stage = RootStage.pickingInstitution;
      notify();
      return;
    }
    // D16: a user belongs to one institution, so there's no picker for them;
    // an old account with several memberships opens the first by name. Only
    // Super moves between institutions (support access, D18).
    if (institutions.isNotEmpty) {
      final sorted = List.of(institutions)..sort((a, b) => a.name.compareTo(b.name));
      await selectInstitution(sorted.first);
    } else {
      stage = RootStage.noInstitution;
      notify();
    }
  }

  Future<void> selectInstitution(Institution institution) => _open(institution);

  Future<void> _open(Institution institution, {String? scopedCartId}) async {
    final current = user;
    if (current == null) return;
    final window = isSuper ? supportWindows[institution.id] : null;
    Membership? membership;
    if (isSuper) {
      // D18: Super has no membership; inside a window it works as an Admin.
      // Entering is logged for the institution's Admin.
      if (window == null || !window.isOpenAt(DateTime.now())) {
        supportEnded = true;
        await loadInstitutions();
        return;
      }
      membership = Membership(
        uid: current.uid,
        institutionId: institution.id,
        role: Role.platformSuperAdmin,
        status: MembershipStatus.active,
        displayName: current.email ?? current.uid,
        email: current.email,
      );
      try {
        await services.support.log(institution.id, grantId: window.grantId, action: 'enter', superUid: current.uid, superEmail: current.email);
      } on RepositoryFailure {
        supportEnded = true;
        await loadInstitutions();
        return;
      }
      supportEnded = false;
      _watchSupport(institution, window);
    } else {
      try {
        membership = await services.institutions.getMyMembership(institution.id);
      } on RepositoryFailure {
        membership = null;
      }
    }
    await services.deviceSession.remember(RememberedUser(
      uid: current.uid,
      displayName: membership?.displayName ?? current.email ?? current.uid,
      roleId: membership?.role.id,
      service: membership?.service,
      institutionName: institution.name,
    ));
    remembered = await services.deviceSession.rememberedUser();
    await _refreshPin(institution.id, current.uid);
    _closeSession();
    session = SessionController(
      services: services,
      user: current,
      institution: institution,
      membership: membership,
      institutionCount: institutions.length,
      scopedCartId: scopedCartId,
      supportWindow: window,
    );
    stage = RootStage.ready;
    notify();
  }

  /// Super goes back to the list of institutions with an open window.
  Future<void> switchInstitution() async {
    await _leaveSupport();
    _closeSession();
    await loadInstitutions();
  }

  /// D18: ends Super's session when the window's time is up or the Admin
  /// closes it.
  void _watchSupport(Institution institution, SupportWindow window) {
    _stopSupportWatch();
    final remaining = window.endsAt.difference(DateTime.now());
    _supportTimer = Timer(remaining.isNegative ? Duration.zero : remaining, _supportOver);
    _supportSub = services.support.watchWindow(institution.id).listen((current) {
      if (current == null || current.grantId != window.grantId || !current.isOpenAt(DateTime.now())) _supportOver();
    }, onError: (_) {});
  }

  void _stopSupportWatch() {
    _supportTimer?.cancel();
    _supportTimer = null;
    unawaited(_supportSub?.cancel());
    _supportSub = null;
  }

  void _supportOver() {
    if (isDisposed || session?.supportWindow == null) return;
    _stopSupportWatch();
    _closeSession();
    supportEnded = true;
    unawaited(loadInstitutions());
  }

  /// Logs Super leaving the institution it's in (best effort: once the window
  /// ended the rules refuse it).
  Future<void> _leaveSupport() async {
    final current = session;
    final window = current?.supportWindow;
    _stopSupportWatch();
    if (current == null || window == null) return;
    try {
      await services.support.log(current.institution.id,
          grantId: window.grantId, action: 'leave', superUid: current.user.uid, superEmail: current.user.email);
    } on RepositoryFailure {
      // The window already ended.
    }
  }

  /// DB3: the PIN is set by the administration. After each sign-in the
  /// device copies the user's PIN hash, so A2 and A9 can check it offline.
  /// Offline or refused, the copy already on the device is kept.
  Future<void> _refreshPin(String institutionId, String uid) async {
    try {
      final pinHash = await services.credentials.fetchPinHash(institutionId, uid);
      await services.deviceSession.cachePinHash(uid, pinHash);
    } on RepositoryFailure {
      // Keep the cached hash.
    }
    hasPin = await services.deviceSession.hasPin(uid);
  }

  /// Profile › "Bloquear": only meaningful with a PIN.
  Future<void> lock() async {
    if (!hasPin) return;
    _closeSession();
    stage = RootStage.locked;
    notify();
  }


  /// Signs out and forgets the device session ("Não é a Ana?").
  Future<void> signOut() async {
    await _leaveSupport();
    await services.deviceSession.forget();
    await services.auth.signOut();
  }

  void _closeSession() {
    session?.dispose();
    session = null;
  }

  @override
  void dispose() {
    _stopSupportWatch();
    _closeSession();
    super.dispose();
  }
}
