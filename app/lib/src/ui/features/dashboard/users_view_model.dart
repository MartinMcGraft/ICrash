import '../../../common/app_services.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/membership.dart';
import '../../../domain/entities/role.dart';
import '../../../services/pin_hasher.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';

enum UsersFilter { all, managers, professionals, invited }

/// B7 · Utilizadores e permissões.
class UsersViewModel extends ViewModel {
  UsersViewModel(this.services, this.session) {
    final id = session.institution.id;
    listen(services.institutions.watchMembers(id), (v) {
      _members = List.of(v)..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
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
  }

  final AppServices services;
  final SessionController session;

  /// Firebase Auth's own minimum is 6; the app asks for 8.
  static const minPasswordLength = 8;

  LoadState state = LoadState.loading;
  UsersFilter filter = UsersFilter.all;
  String query = '';

  /// Role whose permissions are shown in the side panel.
  Role permissionRole = Role.user;

  List<Membership> _members = const [];
  Map<Role, Set<AppPermission>> _permissions = const {};

  static bool _isManagerRole(Role r) => r == Role.manager || r == Role.institutionAdmin;

  int get total => _members.length;
  int get managerCount => _members.where((m) => _isManagerRole(m.role)).length;
  int get professionalCount => _members.where((m) => m.role == Role.user).length;
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
        UsersFilter.managers => _isManagerRole(m.role),
        UsersFilter.professionals => m.role == Role.user,
        UsersFilter.invited => m.status == MembershipStatus.invited,
      };
      if (!inFilter) return false;
      if (q.isEmpty) return true;
      return m.label.toLowerCase().contains(q) || (m.email ?? '').toLowerCase().contains(q);
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
  /// `passwordTooShort`, `pinInvalid`.
  Future<ActionResult<void>> createUser({
    required String name,
    required String email,
    required Role role,
    required String password,
    required String pin,
  }) =>
      run(() async {
        final normalized = email.trim().toLowerCase();
        if (_members.any((m) => (m.email ?? '').toLowerCase() == normalized)) throw const ActionError('emailTaken');
        if (password.length < minPasswordLength) throw const ActionError('passwordTooShort');
        if (!PinHasher.isValidPin(pin)) throw const ActionError('pinInvalid');
        await services.institutions.createMember(
          session.institution.id,
          email: normalized,
          password: password,
          pinHash: await services.pinHasher.hash(pin),
          role: role,
          displayName: name.trim(),
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
