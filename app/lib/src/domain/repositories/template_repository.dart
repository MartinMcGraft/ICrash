import '../entities/cart_template.dart';

/// Cart templates (design v2 B6).
abstract class TemplateRepository {
  Stream<List<CartTemplate>> watchTemplates(String institutionId);
  Future<CartTemplate> saveTemplate(CartTemplate template);
  /// P3: templates are never deleted; they're archived (and can be restored).
  Future<void> setArchived(String institutionId, String templateId, {required bool archived});
}
