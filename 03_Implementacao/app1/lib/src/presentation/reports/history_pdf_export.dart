import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/product.dart';
import '../../domain/entities/usage_event.dart';
import '../cart/assignment_status_label.dart';

/// Builds a printable/shareable PDF export of a history event list (spec
/// section 51's export requirement, alongside [buildHistoryCsv]). Renders
/// with the `pdf` package (pure Dart, no platform channel) and is handed to
/// `Printing.layoutPdf`/`Printing.sharePdf` by the caller, which opens the
/// platform's own print/share sheet — no filesystem access is requested
/// directly by this app.
Future<Uint8List> buildHistoryPdf(
  List<UsageEvent> events,
  List<Product> products, {
  required String title,
}) async {
  String productName(String productId) {
    for (final product in products) {
      if (product.id == productId) return product.name;
    }
    return 'Produto removido';
  }

  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) => pw.Text(
        title,
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
      ),
      build: (context) => [
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(2),
            2: pw.FlexColumnWidth(3),
            3: pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                for (final header in ['Data', 'Tipo', 'Produto', 'Quantidade'])
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      header,
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
              ],
            ),
            for (final event in events)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      event.serverTimestamp == null
                          ? ''
                          : _formatDateTime(event.serverTimestamp!),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(usageEventTypeLabel(event.type)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(productName(event.productId)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      '${event.amount > 0 ? '+' : ''}${event.amount}',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    ),
  );
  return document.save();
}

String _formatDateTime(DateTime dateTime) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(dateTime.day)}/${two(dateTime.month)}/${dateTime.year} ${two(dateTime.hour)}:${two(dateTime.minute)}';
}
