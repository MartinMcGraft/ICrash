import '../entities/product.dart';
import '../entities/usage_event.dart';

/// Builds a CSV export of a history event list (spec section 51's export
/// requirement, scoped to CSV rather than PDF for this prototype — see
/// `docs/APP.md`, Localisation). Pure and Flutter-independent so it can be unit
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
        usageEventTypeCsvLabel(event.type),
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

/// Portuguese label used in exported files (exports are institution
/// documents, written in the institution's language).
String usageEventTypeCsvLabel(UsageEventType type) => switch (type) {
      UsageEventType.consumption => 'Consumo',
      UsageEventType.replenishment => 'Reposição',
      UsageEventType.correction => 'Correção',
      UsageEventType.auditReconciliation => 'Reconciliação',
    };

/// One row of the B9 events export, with every name already resolved.
class EventCsvRow {
  const EventCsvRow({
    required this.when,
    required this.cart,
    required this.place,
    required this.product,
    required this.type,
    required this.amount,
    required this.user,
  });
  final DateTime? when;
  final String cart;

  /// "Gaveta 2 · B3" (or empty).
  final String place;
  final String product;
  final UsageEventType type;
  final int amount;
  final String user;
}

/// B9 "Exportar CSV" (audit C10: always *when, who, where*). Semicolon
/// separated, which spreadsheet apps open directly in pt-PT locales.
String buildEventsCsv(List<EventCsvRow> rows) {
  String cell(String v) => v.contains(';') || v.contains('"') || v.contains('\n') ? '"${v.replaceAll('"', '""')}"' : v;
  final buffer = StringBuffer()..writeln(['Data', 'Carrinho', 'Local', 'Produto', 'Tipo', 'Quantidade', 'Utilizador'].join(';'));
  for (final r in rows) {
    buffer.writeln([
      r.when == null ? '' : _formatDateTime(r.when!),
      r.cart,
      r.place,
      r.product,
      usageEventTypeCsvLabel(r.type),
      '${r.amount > 0 ? '+' : ''}${r.amount}',
      r.user,
    ].map(cell).join(';'));
  }
  return buffer.toString();
}
