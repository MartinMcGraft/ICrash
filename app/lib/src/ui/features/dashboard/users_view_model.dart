import '../../../common/app_services.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/membership.dart';
import '../../../domain/entities/registered_device.dart';
import '../../../domain/entities/role.dart';
import '../../../services/pin_hasher.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';

/// D16: Admins (the institution's IT) and Managers (health professionals);
/// D17: the registered tablets.
enum UsersFilter { all, admins, managers, invited, devices }

/// B7 · Utilizadores e permissões.
class UsersViewModel extends ViewModel {
  UsersViewModel(this.services, this.session) {
    final id = session.institution.id;
    listen(services.institutions.watchMembers(id), (v) {
      // D17: a tablet's own account isn't a person.
      _members = [for (final m in v) if (m.role != Role.device) m]
        ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
      state = LoadState.ready;
      notify();
    }, onError: (_) {
      state = LoadState.error;
      notify();
    });
    listen(services.permissions.watchPermissions(id), (v) {
      _permissions = v;
      notify();
    });
    listen(services.devices.watchDevices(id), (v) {
      devices = List.of(v)
        ..sort((a, b) => a.revoked == b.revoked ? a.name.toLowerCase().compareTo(b.name.toLowerCase()) : (a.revoked ? 1 : -1));
      notify();
    }, onError: (_) {});
    listen(services.carts.watchAccessibleCarts(id), (v) {
      carts = [for (final c in v) if (!c.archived) c]..sort((a, b) => a.name.compareTo(b.name));
      notify();
    }, onError: (_) {});
  }

  /// D17: the institution's registered tablets (revoked ones last).
  List<RegisteredDevice> devices = const [];

  /// The carts a tablet can serve.
  List<Cart> carts = const [];

  int get deviceCount => devices.where((d) => !d.revoked).length;

  List<RegisteredDevice> get visibleDevices {
    final q = query.trim().toLowerCase();
    return q.isEmpty ? devices : devices.where((d) => d.name.toLowerCase().contains(q)).toList();
  }

  /// "Carro 1, Carro 3" for a tablet's carts (an id when the cart is gone).
  String cartNames(RegisteredDevice device) {
    final names = {for (final c in carts) c.id: c.name};
    return device.cartIds.map((id) => names[id] ?? id).join(', ');
  }

  /// "Alterar": name and carts (at least one, Martim 30 Oct). Error codes
  /// `nameRequired`, `noCarts`.
  Future<ActionResult<void>> updateDevice(RegisteredDevice device, {required String name, required List<String> cartIds}) =>
      run(() async {
        final trimmed = name.trim();
        if (trimmed.isEmpty) throw const ActionError('nameRequired');
        if (cartIds.isEmpty) throw const ActionError('noCarts');
        await services.devices.updateDevice(session.institution.id, device, name: trimmed, cartIds: cartIds);
      });

  /// "Revogar": the tablet loses access at its next request and shows
  /// "Este dispositivo foi desativado".
  Future<ActionResult<void>> revokeDevice(RegisteredDevice device) =>
      run(() => services.devices.revokeDevice(session.institution.id, device));

  final AppServices services;
  final SessionController session;

  /// Firebase Auth's own minimum is 6; the app asks for 8.
  static const minPasswordLength = 8;

  LoadState state = LoadState.loading;
  UsersFilter filter = UsersFilter.all;
  String query = '';

  /// Role whose permissions are shown in the side panel: the Manager (an
  /// Admin has every permission, D16).
  Role permissionRole = Role.manager;

  List<Membership> _members = const [];
  Map<Role, Set<AppPermission>> _permissions = const {};

  static bool _isAdminRole(Role r) => r == Role.institutionAdmin || r == Role.platformSuperAdmin;

  int get total => _members.length;
  int get adminCount => _members.where((m) => _isAdminRole(m.role)).length;
  int get managerCount => _members.where((m) => m.role == Role.manager).length;
  int get invitedCount => _members.where((m) => m.status == MembershipStatus.invited).length;

  bool get canManage => session.isInstitutionAdmin;
  bool isMe(Membership m) => m.uid == session.user.uid;

  /// The filter in effect: the "invited" tab disappears once nobody is
  /// invited (DB3: users are created active), so it falls back to "all".
  UsersFilter get effectiveFilter => filter == UsersFilter.invited && invitedCount == 0 ? UsersFilter.all : filter;

  List<Membership> get visible {
    final q = query.trim().toLowerCase();
    return _members.where((m) {
      final inFilter = switch (effectiveFilter) {
        UsersFilter.all => true,
        UsersFilter.admins => _isAdminRole(m.role),
        UsersFilter.managers => m.role == Role.manager,
        UsersFilter.invited => m.status == MembershipStatus.invited,
        UsersFilter.devices => false,
      };
      if (!inFilter) return false;
      if (q.isEmpty) return true;
      return m.label.toLowerCase().contains(q) ||
          (m.email ?? '').toLowerCase().contains(q) ||
          (m.userNumber ?? '').toLowerCase().contains(q);
    }).toList();
  }

  Set<AppPermission> permissionsOf(Role role) => _permissions[role] ?? defaultPermissionsFor(role);

  void setFilter(UsersFilter value) {
    filter = value;
    notify();
  }

  void setQuery(String value) {
    query = value;
    notify();
  }

  void setPermissionRole(Role role) {
    permissionRole = role;
    notify();
  }

  Future<ActionResult<void>> togglePermission(AppPermission permission, bool granted) =>
      run(() => services.permissions.setPermission(session.institution.id, permissionRole, permission, granted));

  Future<ActionResult<void>> changeRole(Membership member, Role role) => run(() async {
        if (isMe(member)) throw const ActionError('self');
        await services.institutions.updateMemberRole(session.institution.id, member.uid, role);
      });

  Future<ActionResult<void>> setActive(Membership member, bool active) => run(() async {
        if (isMe(member)) throw const ActionError('self');
        await services.institutions.setMembershipStatus(
          session.institution.id,
          member.uid,
          active ? MembershipStatus.active : MembershipStatus.disabled,
        );
      });

  /// "Criar utilizador" (DB3, 28 Oct): the administrator chooses the
  /// person's password and PIN and hands them over; nobody else can change
  /// them. The account is created with that password (no reset e-mail) and
  /// the PIN is stored as a salted slow hash. Error codes `emailTaken`,
  /// `passwordTooShort`, `pinInvalid`, `numberTaken` (D17: the nº
  /// mecanográfico identifies the person on a registered tablet).
  Future<ActionResult<void>> createUser({
    required String name,
    required String email,
    required Role role,
    required String password,
    required String pin,
    String? userNumber,
  }) =>
      run(() async {
        final normalized = email.trim().toLowerCase();
        final number = userNumber?.trim() ?? '';
        if (_members.any((m) => (m.email ?? '').toLowerCase() == normalized)) throw const ActionError('emailTaken');
        if (number.isNotEmpty && _members.any((m) => m.userNumber == number)) throw const ActionError('numberTaken');
        if (password.length < minPasswordLength) throw const ActionError('passwordTooShort');
        if (!PinHasher.isValidPin(pin)) throw const ActionError('pinInvalid');
        await services.institutions.createMember(
          session.institution.id,
          email: normalized,
          password: password,
          pinHash: await services.pinHasher.hash(pin),
          role: role,
          displayName: name.trim(),
          userNumber: number.isEmpty ? null : number,
        );
      });

  /// "Definir novo PIN" for another member (DB3). An administrator can't set
  /// their own (code `self`); another administrator does it.
  Future<ActionResult<void>> setMemberPin(Membership member, String pin) => run(() async {
        if (isMe(member)) throw const ActionError('self');
        if (!PinHasher.isValidPin(pin)) throw const ActionError('pinInvalid');
        await services.credentials.setPinHash(session.institution.id, member.uid, await services.pinHasher.hash(pin));
      });
}
