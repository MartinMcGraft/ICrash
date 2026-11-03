import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../services/code_scanner_service.dart';
import '../../../services/gs1_data_matrix_parser.dart';
import '../../../services/scanned_product_code.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/theme/tokens.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/scanner_viewport.dart';
import '../../core/widgets/status.dart';

/// Scans one product code (Data Matrix / barcode) and returns its data.
class ProductScanViewModel extends ViewModel {
  ProductScanViewModel(this.scanner, this.onResult) {
    listen(scanner.scans(), (code) {
      final data = productDataFromScan(code);
      if (data == null) {
        unreadable = true;
        notify();
      } else {
        onResult(data);
      }
    });
  }

  final CodeScannerService scanner;
  final ValueChanged<Gs1ParsedData> onResult;
  bool unreadable = false;

  /// Typing the code instead of scanning it (RV-24).
  bool manual = false;
  String manualText = '';

  void showManual() {
    manual = true;
    unreadable = false;
    notify();
  }

  void setManualText(String value) => manualText = value;

  /// A GTIN (8–14 digits) or a GS1 string typed by hand.
  void submitManual() {
    final raw = manualText.trim();
    if (raw.isEmpty) return;
    final format = RegExp(r'^\d{8,14}$').hasMatch(raw) ? CodeFormat.barcode : CodeFormat.dataMatrix;
    final data = productDataFromScan(ScannedCode(raw, format));
    if (data == null) {
      unreadable = true;
      notify();
    } else {
      onResult(data);
    }
  }

  @override
  void dispose() {
    super.dispose();
    scanner.dispose();
  }
}

Future<Gs1ParsedData?> showProductScanSheet(BuildContext context) {
  return showDialog<Gs1ParsedData>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext);
      return Dialog(
        child: SizedBox(
          width: 560,
          height: 480,
          child: Padding(
            padding: const EdgeInsets.all(IcSpace.s20),
            child: ViewModelBuilder<ProductScanViewModel>(
              create: (services) => ProductScanViewModel(
                services.createCodeScanner(),
                (data) => Navigator.of(dialogContext).pop(data),
              ),
              builder: (context, vm) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.gs1ScanTitle, style: IcText.titleM),
                  const SizedBox(height: IcSpace.s12),
                  if (vm.unreadable) ...[
                    Notice(kind: NoticeKind.warning, title: l10n.gs1ScanError),
                    const SizedBox(height: IcSpace.s12),
                  ],
                  if (vm.manual) ...[
                    // RV-24: "Inserir manualmente" opens a field to type the
                    // GTIN or the GS1 text printed on the package.
                    LabeledField(
                      label: l10n.scanManualProductLabel,
                      autofocus: true,
                      onChanged: vm.setManualText,
                      onSubmitted: (_) => vm.submitManual(),
                    ),
                    const Spacer(),
                  ] else
                    Expanded(child: ScannerViewport(scanner: vm.scanner, caption: l10n.gs1ScanInstructionCamera)),
                  const SizedBox(height: IcSpace.s12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IcButton(
                        label: l10n.actionCancel,
                        style: IcButtonStyle.ghost,
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                      const SizedBox(width: IcSpace.s12),
                      if (vm.manual)
                        IcButton(label: l10n.actionConfirm, icon: IcIcon.confirmar, onPressed: vm.submitManual)
                      else
                        IcButton(
                          label: l10n.scanEnterManually,
                          icon: IcIcon.teclado,
                          style: IcButtonStyle.secondary,
                          onPressed: vm.showManual,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
