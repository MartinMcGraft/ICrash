import 'package:flutter/widgets.dart';

import '../../../common/app_services.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/emergency_session.dart';
import '../../../domain/entities/institution.dart';
import '../../../domain/entities/membership.dart';
import '../../../domain/entities/role.dart';
import '../../../domain/entities/support_access.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../mvvm/view_model.dart';

/// App-wide state once a user is inside an institution: who they are, what
/// they may do, which emergency sessions are open and, for a cart login
/// (design v2 A3), which single cart the session is limited to.
///
/// Feature ViewModels read it; only the app root creates it.
class SessionController extends ViewModel {
  SessionController({
    required this.services,
    required this.user,
    required this.institution,
    required this.membership,
    required this.institutionCount,
    this.scopedCartId,
    this.supportWindow,
    this.allowedCartIds,
    this.deviceName,
  }) {
    listen(services.institutions.watchMembers(institution.id), (members) {
      _members = {for (final m in members) m.uid: m};
      notify();
    }, onError: (_) {});
    listen(services.emergency.watchActive(institution.id), (sessions) {
      _emergencies = {for (final s in sessions) s.cartId: s};
      notify();
    });
    listen(services.permissions.watchPermissions(institution.id), (permissions) {
      _permissions = permissions;
      notify();
    });
  }

  final AppServices services;
  final AuthUser user;
  final Institution institution;
  final Membership? membership;
  final int institutionCount;

  /// Set when the session was opened by scanning a cart (A3): only this
  /// cart is reachable.
  final String? scopedCartId;

  /// D18: set when Super works in this institution through a support
  /// window; the shells show a banner until it ends.
  final SupportWindow? supportWindow;

  /// D17: on a registered tablet, the carts this person may open there (the
  /// tablet's carts they're registered to; all of them for an Admin).
  final Set<String>? allowedCartIds;

  /// D17: set when the person signed in on a registered tablet. Firebase is
  /// signed in as the tablet, so the session can do only what a Manager on
  /// the tablet's carts may do: no structure, users or credentials.
  final String? deviceName;

  bool get onDevice => deviceName != null;

  /// Whether this session may open [cartId] (A3 cart login, D17 tablet).
  bool mayOpenCart(String cartId) =>
      (scopedCartId == null || cartId == scopedCartId) && (allowedCartIds == null || allowedCartIds!.contains(cartId));

  Map<String, Membership> _members = {};
  Map<String, EmergencySession> _emergencies = {};
  Map<Role, Set<AppPermission>> _permissions = {};

  Role get role => membership?.role ?? Role.manager;
  bool get _active => membership?.isActive ?? false;

  /// D16: an **Admin** (or Super) does everything in the institution: every
  /// cart, the structure (drawers, grid, catalogue, templates), users and
  /// shifts. Firestore Rules enforce the same split.
  bool get isInstitutionAdmin =>
      _active && !onDevice && (role == Role.institutionAdmin || role == Role.platformSuperAdmin);

  /// The institution's own Admin, never Super: opens support access (D18)
  /// and sets credentials.
  bool get isOwnAdmin => _active && !onDevice && role == Role.institutionAdmin;

  /// UI permission toggles (stub, B7) on top of the role.
  bool can(AppPermission permission) =>
      (_permissions[role] ?? defaultPermissionsFor(role)).contains(permission);

  /// D16: a **Manager** has every cart action on the carts they're
  /// registered to (the only carts they see; the Rules check the
  /// registration); B7 can switch actions off.
  bool get canReplenish => _active && can(AppPermission.replenish);
  bool get canConsume => _active && can(AppPermission.recordConsumption);
  bool get canChangeCartState => _active && can(AppPermission.changeCartState);

  /// Structure stays with the Admin (D16; the Rules allow only Admin/Super).
  bool get canEditStructure => isInstitutionAdmin;
  bool get canUseEmergency => can(AppPermission.emergencyMode);
  bool get canMonthlyCheck => can(AppPermission.monthlyCheck);

  String get myName => membership?.displayName ?? user.email ?? user.uid;

  String nameOf(String uid) {
    if (uid == user.uid) return myName;
    return _members[uid]?.label ?? uid;
  }

  Map<String, Membership> get members => _members;

  bool isEmergencyActive(String cartId) => _emergencies.containsKey(cartId);
  EmergencySession? emergencyFor(String cartId) => _emergencies[cartId];
  Iterable<EmergencySession> get activeEmergencies => _emergencies.values;
}

/// Provides the [SessionController] to the widget tree.
class SessionScope extends InheritedNotifier<SessionController> {
  const SessionScope({super.key, required SessionController session, required super.child}) : super(notifier: session);

  static SessionController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope.of() called with no SessionScope ancestor');
    return scope!.notifier!;
  }

  /// Read without subscribing (for ViewModel construction).
  static SessionController read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope.read() called with no SessionScope ancestor');
    return scope!.notifier!;
  }
}

/// Actions the shells expose to every screen (profile menu, lock, switch
/// institution) without screens knowing about the app root.
class AppActions {
  const AppActions({
    required this.signOut,
    required this.lock,
    required this.switchInstitution,
    required this.hasPin,
    this.switchShell,
    this.showingDashboard = false,
  });

  final Future<void> Function() signOut;

  /// Locks the app behind the PIN (only offered when [hasPin]).
  final Future<void> Function() lock;

  /// Null when the user belongs to a single institution.
  final VoidCallback? switchInstitution;

  /// Whether this device holds the user's PIN (set by the administration,
  /// DB3; users can't set or change it themselves).
  final bool hasPin;

  /// Debug builds only: flips between the App and the Dashboard shell so
  /// both can be tried on one computer.
  final VoidCallback? switchShell;
  final bool showingDashboard;
}

class AppActionsScope extends InheritedWidget {
  const AppActionsScope({super.key, required this.actions, required super.child});
  final AppActions actions;

  static AppActions of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppActionsScope>()!.actions;

  @override
  bool updateShouldNotify(AppActionsScope oldWidget) =>
      actions.hasPin != oldWidget.actions.hasPin || actions.showingDashboard != oldWidget.actions.showingDashboard;
}
