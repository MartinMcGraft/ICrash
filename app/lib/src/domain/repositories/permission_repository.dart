import '../entities/app_permission.dart';
import '../entities/role.dart';

/// Per-user-type permissions (design v2 B7, proposal D2).
abstract class PermissionRepository {
  Stream<Map<Role, Set<AppPermission>>> watchPermissions(String institutionId);
  Future<void> setPermission(String institutionId, Role role, AppPermission permission, bool granted);
}
