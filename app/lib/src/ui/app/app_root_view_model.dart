import 'dart:async';

import '../../common/app_services.dart';
import '../../common/repository_failure.dart';
import '../../domain/entities/institution.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/registered_device.dart';
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

  /// D17: A0 · Configurar dispositivo (an Admin registers this tablet).
  deviceSetup,

  /// D17: A1 on a registered tablet (no password).
  deviceHome,

  /// D17: A2b · Identificação (nº mecanográfico or e-mail + PIN).
  deviceIdentify,

  /// D17: the Admin revoked this tablet on the Dashboard.
  deviceRevoked,
}

/// What the identification on a registered tablet is for.
enum DeviceIdentifyPurpose { pin, cart, removeRegistration }

/// Why the tablet went back to its A1.
enum DeviceNotice { idle, tooManyAttempts, signInFailed, registrationRemoved }

/// Owns the authentication / lock / institution flow and creates the
/// [SessionController] once the user is inside an institution.
class AppRootViewModel extends ViewModel {
  AppRootViewModel(this.services, {this.idleTimeout = deviceIdleTimeout}) {
    unawaited(_start());
  }

  /// [deviceIdleTimeout], shorter in tests.
  final Duration idleTimeout;

  Future<void> _start() async {
    // D17: a registered tablet signs itself in with its own account.
    device = await services.deviceCredentials.load();
    if (isDisposed) return;
    listen(services.auth.authStateChanges(), _onAuthChanged);
  }

  /// D17: inactivity on a registered tablet ends the person's session.
  static const deviceIdleTimeout = Duration(minutes: 5);

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

  /// D17: this tablet's own sign-in, when it's registered.
  DeviceCredentials? device;

  /// D17: the carts this tablet serves and its current name (from its
  /// document; empty until read).
  List<String> deviceCartIds = const [];
  String? deviceName;
  DeviceNotice? deviceNotice;
  DeviceIdentifyPurpose identifyPurpose = DeviceIdentifyPurpose.pin;

  /// D17: the cart scanned on A3 before the person identifies.
  String? pendingCartId;
  bool _settingUp = false;
  Future<void>? _deviceSignIn;
  Timer? _idleTimer;

  bool get isRegisteredDevice => device != null;

  /// A saved session exists on this device (enables PIN / cart login).
  bool get hasSavedSession => user != null && remembered?.uid == user!.uid;

  Future<void> _onAuthChanged(AuthUser? next) async {
    // A0: the Admin signs in to register the tablet; that's not a session.
    if (_settingUp) return;
    if (device != null) return _onDeviceAuth(next);
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
      // Super has no membership: its PIN is on its platformAdmins marker.
      final pinHash = isSuper
          ? await services.support.myPinHash()
          : await services.credentials.fetchPinHash(institutionId, uid);
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


  /// Signs out and forgets the device session ("Não é a Ana?"). On a
  /// registered tablet (D17) the person's session ends and the tablet stays
  /// signed in.
  Future<void> signOut() async {
    if (device != null) {
      endDeviceSession();
      return;
    }
    await _leaveSupport();
    await services.deviceSession.forget();
    await services.auth.signOut();
  }

  void _closeSession() {
    session?.dispose();
    session = null;
  }

  // ---------------------------------------------------------------------
  // D17: registered tablet
  // ---------------------------------------------------------------------

  Future<void> _onDeviceAuth(AuthUser? next) async {
    final credentials = device!;
    user = next;
    if (next == null) {
      await _signInDevice();
      return;
    }
    if ((next.email ?? '').toLowerCase() != credentials.email.toLowerCase()) {
      // Someone else's session left on the tablet: the tablet signs in as itself.
      await services.auth.signOut();
      await _signInDevice();
      return;
    }
    if (stage == RootStage.starting) await _checkDevice();
  }

  /// Coalesces the sign-in (auth stream + explicit calls).
  Future<void> _signInDevice() => _deviceSignIn ??= _doSignInDevice().whenComplete(() => _deviceSignIn = null);

  Future<void> _doSignInDevice() async {
    final credentials = device;
    if (credentials == null) return;
    try {
      user = await services.auth.signInWithEmailPassword(credentials.email, credentials.password);
    } on Object {
      if (isDisposed) return;
      deviceNotice = DeviceNotice.signInFailed;
      stage = RootStage.deviceHome;
      notify();
      return;
    }
    await _checkDevice();
  }

  /// Reads this tablet's document: its carts and name, or that it was revoked.
  Future<void> _checkDevice() async {
    final credentials = device;
    if (credentials == null) return;
    try {
      final doc = await services.devices.getDevice(credentials.institutionId, credentials.deviceId);
      if (isDisposed) return;
      if (doc == null || doc.revoked) {
        stage = RootStage.deviceRevoked;
        notify();
        return;
      }
      deviceCartIds = doc.cartIds;
      deviceName = doc.name;
    } on RepositoryFailure catch (failure) {
      if (isDisposed) return;
      if (failure.reason == RepositoryFailureReason.permissionDenied) {
        stage = RootStage.deviceRevoked;
        notify();
        return;
      }
      // Offline: the carts read last time stay.
    }
    if (deviceNotice == DeviceNotice.signInFailed) deviceNotice = null;
    if (stage != RootStage.ready && stage != RootStage.deviceIdentify) stage = RootStage.deviceHome;
    notify();
  }

  /// A1 › "Configurar dispositivo".
  Future<void> beginDeviceSetup() async {
    _settingUp = true;
    if (device != null) {
      // From "Este dispositivo foi desativado": forget the old registration.
      await services.deviceCredentials.clear();
      device = null;
      deviceCartIds = const [];
      deviceName = null;
    }
    _closeSession();
    if (services.auth.currentUser != null) await services.auth.signOut();
    user = null;
    stage = RootStage.deviceSetup;
    notify();
  }

  /// A0 › "Cancelar": back to the ordinary A1.
  Future<void> cancelDeviceSetup() async {
    if (services.auth.currentUser != null) await services.auth.signOut();
    user = null;
    _settingUp = false;
    hasPin = false;
    stage = RootStage.signedOut;
    notify();
  }

  /// A0 finished: the Admin was signed out; the tablet signs in as itself.
  Future<void> finishDeviceSetup(DeviceCredentials credentials) async {
    device = credentials;
    deviceName = credentials.deviceName;
    deviceNotice = null;
    if (services.auth.currentUser != null) await services.auth.signOut();
    await _signInDevice();
    _settingUp = false;
  }

  /// A1 (tablet) › "Entrar com PIN".
  void showDeviceIdentify({DeviceIdentifyPurpose purpose = DeviceIdentifyPurpose.pin}) {
    identifyPurpose = purpose;
    if (purpose != DeviceIdentifyPurpose.cart) pendingCartId = null;
    deviceNotice = null;
    stage = RootStage.deviceIdentify;
    notify();
  }

  /// Back to the tablet's A1.
  void showDeviceHome({DeviceNotice? notice}) {
    pendingCartId = null;
    deviceNotice = notice;
    stage = RootStage.deviceHome;
    notify();
  }

  /// A3 on a registered tablet: the scanned cart must be one of the
  /// tablet's; then the person identifies.
  Future<ActionResult<void>> enterCartOnDevice(CartQrTarget target) => run(() async {
        final credentials = device;
        if (credentials == null) throw const ActionError('noSavedSession');
        if (target.institutionId != credentials.institutionId || !deviceCartIds.contains(target.cartId)) {
          throw const RepositoryFailure(RepositoryFailureReason.permissionDenied);
        }
        pendingCartId = target.cartId;
        showDeviceIdentify(purpose: DeviceIdentifyPurpose.cart);
      });

  /// A2b identified [person] with their PIN. Returns an error code for the
  /// identification screen, or null once the session is open.
  Future<String?> onDevicePersonIdentified(Membership person) async {
    final credentials = device;
    if (credentials == null) return 'generic';
    if (identifyPurpose == DeviceIdentifyPurpose.removeRegistration) {
      if (person.role != Role.institutionAdmin) return 'notAdmin';
      await services.deviceCredentials.clear();
      device = null;
      deviceCartIds = const [];
      deviceName = null;
      _closeSession();
      await services.auth.signOut();
      user = null;
      hasPin = false;
      deviceNotice = DeviceNotice.registrationRemoved;
      stage = RootStage.signedOut;
      notify();
      return null;
    }
    final carts = <String>{};
    for (final cartId in deviceCartIds) {
      if (person.role == Role.institutionAdmin) {
        carts.add(cartId);
        continue;
      }
      try {
        final registered = await services.carts.watchResponsibleUsers(credentials.institutionId, cartId).first;
        if (registered.any((r) => r.uid == person.uid && r.cartId == cartId)) carts.add(cartId);
      } on RepositoryFailure {
        // Not readable: not offered.
      }
    }
    final scoped = pendingCartId;
    if (scoped != null && !carts.contains(scoped)) return 'notOnCart';
    if (carts.isEmpty) return 'noCarts';
    Institution institution;
    try {
      institution = await services.institutions.getInstitution(credentials.institutionId) ??
          Institution(id: credentials.institutionId, name: credentials.institutionName);
    } on RepositoryFailure {
      institution = Institution(id: credentials.institutionId, name: credentials.institutionName);
    }
    if (isDisposed) return null;
    _closeSession();
    hasPin = false;
    session = SessionController(
      services: services,
      user: AuthUser(uid: person.uid, email: person.email),
      institution: institution,
      membership: person,
      institutionCount: 1,
      scopedCartId: scoped,
      allowedCartIds: carts,
      deviceName: deviceName ?? credentials.deviceName,
    );
    pendingCartId = null;
    deviceNotice = null;
    stage = RootStage.ready;
    touch();
    notify();
    return null;
  }

  /// "Terminar sessão", or [deviceIdleTimeout] without a touch.
  void endDeviceSession({DeviceNotice? notice}) {
    _idleTimer?.cancel();
    _idleTimer = null;
    _closeSession();
    showDeviceHome(notice: notice);
  }

  /// Any touch on a registered tablet restarts the inactivity timer.
  void touch() {
    if (device == null || session == null) return;
    _idleTimer?.cancel();
    _idleTimer = Timer(idleTimeout, () {
      if (!isDisposed && session != null) endDeviceSession(notice: DeviceNotice.idle);
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _stopSupportWatch();
    _closeSession();
    super.dispose();
  }
}
