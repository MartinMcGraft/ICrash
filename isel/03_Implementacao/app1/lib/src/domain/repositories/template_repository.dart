import '../entities/cart_template.dart';

/// Cart templates (design v2 B6).
abstract class TemplateRepository {
  Stream<List<CartTemplate>> watchTemplates(String institutionId);
  Future<CartTemplate> saveTemplate(CartTemplate template);
  Future<void> deleteTemplate(String institutionId, String templateId);
}
