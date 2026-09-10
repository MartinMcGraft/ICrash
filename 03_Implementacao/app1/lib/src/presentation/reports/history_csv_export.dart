import '../../domain/entities/product.dart';
import '../../domain/entities/usage_event.dart';
import '../cart/assignment_status_label.dart';

/// Builds a CSV export of a history event list (spec section 51's export
/// requirement, scoped to CSV rather than PDF for this prototype — see
/// `docs/ARCHITECTURE.md`). Pure and Flutter-independent so it can be unit
/// tested without a widget tree; the caller decides what to do with the
/// resulting string (this app copies it to the clipboard rather than
/// writing a file, to avoid adding a file-system dependency).
String buildHistoryCsv(List<UsageEvent> events, List<Product> products) {
  String productName(String productId) {
    for (final product in products) {
      if (product.id == productId) return product.name;
    }
    return 'Produto removido';
  }

  final buffer = StringBuffer();
  buffer.writeln(
    ['Data', 'Tipo', 'Produto', 'Quantidade'].map(_csvCell).join(','),
  );
  for (final event in events) {
    buffer.writeln(
      [
        event.serverTimestamp == null
            ? ''
            : _formatDateTime(event.serverTimestamp!),
        usageEventTypeLabelPt(event.type),
        productName(event.productId),
        '${event.amount > 0 ? '+' : ''}${event.amount}',
      ].map(_csvCell).join(','),
    );
  }
  return buffer.toString();
}

String _csvCell(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String _formatDateTime(DateTime dateTime) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dateTime.day)}/${two(dateTime.month)}/${dateTime.year} ${two(dateTime.hour)}:${two(dateTime.minute)}';
}
