import '../entities/institution.dart';
import '../entities/membership.dart';
import '../entities/role.dart';

abstract class InstitutionRepository {
  /// Institutions the current user has an active membership in.
  Stream<List<Institution>> watchMyInstitutions();

  Future<Institution?> getInstitution(String institutionId);

  Future<Membership?> getMyMembership(String institutionId);

  /// Platform-super-admin only (spec section 16).
  Future<Institution> createInstitution(Institution institution);

  /// Every membership of [institutionId], for the members-management screen.
  /// Institution admin only (spec section 16); readable by any active member
  /// per Rules, but only an admin sees the management UI over it.
  Stream<List<Membership>> watchMembers(String institutionId);

  /// Creates a brand-new member: a Firebase Auth account for [email] plus an
  /// active `memberships`/`memberIndex` pair, written atomically. There is no
  /// Cloud Function yet (spec Phase 1 has none) to invite an existing user by
  /// e-mail alone, so this always provisions a fresh account.
  Future<void> createMember(
    String institutionId, {
    required String email,
    required String password,
    required Role role,
  });

  /// Changes an existing member's role. Institution admin only; a member can
  /// never change their own role or status (enforced by Rules).
  Future<void> updateMemberRole(String institutionId, String uid, Role role);

  /// Enables or disables an existing member, keeping `memberIndex` in sync.
  Future<void> setMembershipStatus(String institutionId, String uid, MembershipStatus status);
}
