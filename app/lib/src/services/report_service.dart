/// Placeholder contract for workstream H (spec section 51): consumption/
/// audit/history reports rendered locally to PDF, with CSV/Excel export
/// possible later without changing this interface.
abstract class ReportService {
  Future<List<int>> generateUsageReportPdf({
    required String institutionId,
    DateTime? from,
    DateTime? to,
    String? cartId,
  });
}
