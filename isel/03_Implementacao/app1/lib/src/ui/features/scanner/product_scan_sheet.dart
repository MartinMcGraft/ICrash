import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../services/code_scanner_service.dart';
import '../../../services/gs1_data_matrix_parser.dart';
import '../../../services/scanned_product_code.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ic_button.dart';
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
                  Expanded(child: ScannerViewport(scanner: vm.scanner, caption: l10n.gs1ScanInstructionCamera)),
                  const SizedBox(height: IcSpace.s12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IcButton(
                      label: l10n.actionCancelManualEntry,
                      style: IcButtonStyle.ghost,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
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
