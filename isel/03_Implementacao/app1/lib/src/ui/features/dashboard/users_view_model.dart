import 'dart:math';

import '../../../common/app_services.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/membership.dart';
import '../../../domain/entities/role.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';

enum UsersFilter { all, managers, professionals, invited }

/// B7 · Utilizadores e permissões.
class UsersViewModel extends ViewModel {
  UsersViewModel(this.services, this.session, {Random? random}) : _random = random ?? Random.secure() {
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
  final Random _random;

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

  List<Membership> get visible {
    final q = query.trim().toLowerCase();
    return _members.where((m) {
      final inFilter = switch (filter) {
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

  /// "Convidar utilizador": creates the account with a random password the
  /// admin never sees, then sends the password-reset e-mail so the person
  /// chooses their own password (replaces the old "invent a temporary
  /// password and pass it on" flow, audit §4.4).
  Future<ActionResult<void>> invite({required String name, required String email, required Role role}) => run(() async {
        final normalized = email.trim().toLowerCase();
        if (_members.any((m) => (m.email ?? '').toLowerCase() == normalized)) throw const ActionError('emailTaken');
        await services.institutions.createMember(
          session.institution.id,
          email: normalized,
          password: _randomPassword(),
          role: role,
          displayName: name.trim(),
        );
        await services.auth.sendPasswordReset(normalized);
      });

  Future<ActionResult<void>> resendInvite(Membership member) => run(() async {
        final email = member.email;
        if (email == null) throw const ActionError('noEmail');
        await services.auth.sendPasswordReset(email);
      });

  String _randomPassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!#%+=?';
    return List.generate(20, (_) => chars[_random.nextInt(chars.length)]).join();
  }
}
