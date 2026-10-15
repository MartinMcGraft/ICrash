import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../domain/entities/cart_report.dart';

/// Labels the PDF needs, resolved by the View from l10n (the PDF builder
/// stays free of BuildContext).
class ReportPdfLabels {
  const ReportPdfLabels({
    required this.title,
    required this.institution,
    required this.dateLabel,
    required this.date,
    required this.byLabel,
    required this.drawersLabel,
    required this.drawers,
    required this.positionsLabel,
    required this.positions,
    required this.findingsTitle,
    required this.findings,
    required this.linesTitle,
    required this.lines,
    required this.notesLabel,
    required this.signatureTitle,
    required this.signatureText,
  });

  final String title;
  final String institution;
  final String dateLabel;
  final String date;
  final String byLabel;
  final String drawersLabel;
  final String drawers;
  final String positionsLabel;
  final String positions;
  final String findingsTitle;
  final List<String> findings;
  final String linesTitle;
  final List<String> lines;
  final String notesLabel;
  final String signatureTitle;

  /// "Assinado por … em …" or "Por assinar".
  final String signatureText;
}

/// Report PDF with header, summary, detail and signature block (audit §4.4:
/// the old export had no institution, cart, period, author or signature).
Future<Uint8List> buildReportPdf(CartReport report, ReportPdfLabels labels) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/IBMPlexSans-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/IBMPlexSans-SemiBold.ttf'));
  final doc = pw.Document(
    title: labels.title,
    author: report.createdByName,
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  final navy = PdfColor.fromInt(0xFF1F4E6B);
  final grey = PdfColor.fromInt(0xFF555149);
  pw.Widget row(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(children: [
          pw.Expanded(child: pw.Text(label, style: pw.TextStyle(color: grey, fontSize: 10))),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ]),
      );
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(40),
    header: (context) => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('I-Crash', style: pw.TextStyle(color: navy, fontWeight: pw.FontWeight.bold)),
        pw.Text(labels.institution, style: pw.TextStyle(color: grey, fontSize: 9)),
      ],
    ),
    build: (context) => [
      pw.SizedBox(height: 16),
      pw.Text(labels.title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 12),
      row(labels.dateLabel, labels.date),
      row(labels.byLabel, report.createdByName),
      if (report.kind == ReportKind.monthlyCheck) ...[
        row(labels.drawersLabel, labels.drawers),
        row(labels.positionsLabel, labels.positions),
      ],
      pw.Divider(color: PdfColors.grey400),
      if (labels.findings.isNotEmpty) ...[
        pw.Text(labels.findingsTitle, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        for (final f in labels.findings) pw.Bullet(text: f, style: const pw.TextStyle(fontSize: 10)),
      ],
      if (labels.lines.isNotEmpty) ...[
        pw.Text(labels.linesTitle, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        for (final l in labels.lines) pw.Bullet(text: l, style: const pw.TextStyle(fontSize: 10)),
      ],
      if (report.notes != null) ...[
        pw.SizedBox(height: 12),
        pw.Text(labels.notesLabel, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(report.notes!, style: const pw.TextStyle(fontSize: 10)),
      ],
      pw.SizedBox(height: 32),
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400), borderRadius: pw.BorderRadius.circular(6)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(labels.signatureTitle, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text(labels.signatureText, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    ],
  ));
  return doc.save();
}
