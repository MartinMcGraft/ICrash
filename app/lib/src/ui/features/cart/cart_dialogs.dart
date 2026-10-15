import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/cart_status.dart';
import '../../../services/internal_qr_payload.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/status.dart';

/// "Alterar estado" (manager+). Proposal D7: the state can also follow an
/// automatic rule (set per cart in the Dashboard); a manual change here
/// always wins until the rule next applies.
Future<CartStatus?> showChangeStatusDialog(BuildContext context, CartStatus current) {
  final l10n = AppLocalizations.of(context);
  return showDialog<CartStatus>(
    context: context,
    builder: (context) {
      var selected = current;
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.changeStateAction),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final status in CartStatus.values)
                  Semantics(
                    selected: selected == status,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(IcRadius.md),
                      onTap: () => setState(() => selected = status),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              selected == status ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: selected == status ? IcColors.actionPrimary : IcColors.borderStrong,
                            ),
                            const SizedBox(width: IcSpace.s12),
                            CartStateChip(status: status),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: IcSpace.s12),
                Text(l10n.autoStateRule, style: IcText.bodyS.copyWith(color: IcColors.textMuted)),
              ],
            ),
          ),
          actions: [
            IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
            IcButton(label: l10n.actionSave, onPressed: () => Navigator.of(context).pop(selected)),
          ],
        ),
      );
    },
  );
}

/// "Mostrar código QR": QR + a readable code for manual entry (audit §4.4)
/// + printable label.
Future<void> showCartQrDialog(BuildContext context, Cart cart) {
  final l10n = AppLocalizations.of(context);
  final payload = encodeCartQrPayload(cart.institutionId, cart.id);
  final readable = '${cart.institutionId}/${cart.id}';
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.cartQrScreenTitle),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(cart.name, style: IcText.titleS, textAlign: TextAlign.center),
              const SizedBox(height: IcSpace.s16),
              Semantics(
                label: l10n.cartQrSemanticLabel(cart.name),
                image: true,
                child: QrImageView(data: payload, size: 220, backgroundColor: Colors.white),
              ),
              const SizedBox(height: IcSpace.s12),
              SelectableText(readable, style: IcText.mono.copyWith(color: IcColors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: IcSpace.s12),
              Text(l10n.cartQrInstruction, textAlign: TextAlign.center, style: IcText.bodyM.copyWith(color: IcColors.textSecondary)),
            ],
          ),
        ),
      ),
      actions: [
        IcButton(
          label: l10n.printLabel,
          icon: IcIcon.descarregar,
          style: IcButtonStyle.secondary,
          onPressed: () => Printing.layoutPdf(
            name: cart.name,
            onLayout: (_) async {
              final doc = pw.Document();
              doc.addPage(pw.Page(
                pageFormat: PdfPageFormat.a6,
                build: (_) => pw.Center(
                  child: pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(cart.name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 12),
                      pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: payload, width: 160, height: 160),
                      pw.SizedBox(height: 8),
                      pw.Text(readable, style: const pw.TextStyle(fontSize: 7)),
                    ],
                  ),
                ),
              ));
              return doc.save();
            },
          ),
        ),
        IcButton(label: l10n.actionClose, onPressed: () => Navigator.of(context).pop()),
      ],
    ),
  );
}
