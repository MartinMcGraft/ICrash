import '../entities/institution.dart';
import '../entities/membership.dart';

abstract class InstitutionRepository {
  /// Institutions the current user has an active membership in.
  Stream<List<Institution>> watchMyInstitutions();

  Future<Institution?> getInstitution(String institutionId);

  Future<Membership?> getMyMembership(String institutionId);

  /// Platform-super-admin only (spec section 16).
  Future<Institution> createInstitution(Institution institution);
}
