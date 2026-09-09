/// Centralizes every Firestore collection path so the collection layout
/// (documented in `docs/FIREBASE_MODEL.md`) has one source of truth instead
/// of being scattered across repository implementations.
class FirestorePaths {
  const FirestorePaths._();

  static const String platformAdmins = 'platformAdmins';
  static const String institutions = 'institutions';

  static String memberships(String institutionId) => 'institutions/$institutionId/memberships';

  static String products(String institutionId) => 'institutions/$institutionId/products';

  static String carts(String institutionId) => 'institutions/$institutionId/carts';

  static String responsibleUsers(String institutionId, String cartId) =>
      'institutions/$institutionId/carts/$cartId/responsibleUsers';

  static String drawers(String institutionId, String cartId) =>
      'institutions/$institutionId/carts/$cartId/drawers';

  static String slots(String institutionId, String cartId, String drawerId) =>
      'institutions/$institutionId/carts/$cartId/drawers/$drawerId/slots';

  static String assignments(String institutionId, String cartId) =>
      'institutions/$institutionId/carts/$cartId/assignments';

  static String batches(String institutionId, String cartId, String assignmentId) =>
      'institutions/$institutionId/carts/$cartId/assignments/$assignmentId/batches';

  static String usageEvents(String institutionId) => 'institutions/$institutionId/usageEvents';

  static String auditEvents(String institutionId) => 'institutions/$institutionId/auditEvents';
}
