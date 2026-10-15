import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../common/l10n/app_localizations.dart';
import '../../core/format.dart';
import '../../core/session/session.dart';
import '../../core/widgets/status.dart';
import '../carts/cart_card.dart';
import 'overview_view_model.dart';

/// "Exportar relatório" on B1: the state of every cart on one page.
Future<Uint8List> buildOverviewPdf(BuildContext context, OverviewViewModel vm) async {
  final l10n = AppLocalizations.of(context);
  final format = IcFormat.of(context);
  final session = SessionScope.read(context);
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/IBMPlexSans-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/IBMPlexSans-SemiBold.ttf'));
  final doc = pw.Document(theme: pw.ThemeData.withFont(base: regular, bold: bold));
  final rows = [
    for (final s in vm.summaries)
      [s.cart.name, s.cart.placeLabel ?? '—', cartStatusText(l10n, s.cart.status), cartAlertLine(l10n, s).$3],
  ];
  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4.landscape,
    build: (_) => [
      pw.Text('${l10n.navOverview} — ${session.institution.name}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.Text(format.dateTime(DateTime.now()), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
      pw.SizedBox(height: 16),
      pw.TableHelper.fromTextArray(
        headers: [l10n.columnCart, l10n.columnServiceLocation, l10n.columnState, l10n.columnAlerts],
        data: rows,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        cellStyle: const pw.TextStyle(fontSize: 10),
        headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEEBE4)),
      ),
    ],
  ));
  return doc.save();
}
