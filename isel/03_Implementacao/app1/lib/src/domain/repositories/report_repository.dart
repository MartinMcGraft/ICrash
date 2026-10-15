import '../entities/cart_report.dart';

/// Monthly-check reports and emergency summaries (design v2 A8–A10, B9).
abstract class ReportRepository {
  Stream<List<CartReport>> watchReports(String institutionId);

  Future<CartReport> createReport(CartReport report);

  /// Proposal D6: name + PIN + date; a signed report can no longer change.
  Future<void> signReport(String institutionId, String reportId, {required String uid, required String name});

  /// Monthly-check draft for one cart ("Guardar e sair"), as opaque JSON.
  Future<Map<String, Object?>?> loadCheckDraft(String institutionId, String cartId);
  Future<void> saveCheckDraft(String institutionId, String cartId, Map<String, Object?> draft);
  Future<void> clearCheckDraft(String institutionId, String cartId);
}
