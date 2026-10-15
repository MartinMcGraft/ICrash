import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../core/format.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/scanner_viewport.dart';
import '../../core/widgets/status.dart';
import '../../shells/shell_navigation.dart';
import 'scanner_view_model.dart';

/// A11 · Ler código.
class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  String _error(AppLocalizations l10n, ScanError error) => switch (error) {
        ScanError.unreadable => l10n.gs1ScanError,
        ScanError.unknownProduct => l10n.gs1UnknownGtin,
        ScanError.notACart => l10n.cartQrScanError,
        ScanError.otherInstitution => l10n.scanOtherInstitution,
        ScanError.notInAnyCart => l10n.scanNotInAnyCart,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.read(context);
    final navigation = ShellNavigationScope.of(context);
    return ViewModelBuilder<ScannerViewModel>(
      create: (services) => ScannerViewModel(services, session, onCart: navigation.openCart),
      builder: (context, vm) {
        final compact = isCompactHeight(context);
        final format = IcFormat.of(context);
        final data = vm.lastData;
        final product = vm.lastProduct;
        return Padding(
          padding: contentPadding(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ScannerViewport(
                  scanner: vm.scanner,
                  caption: vm.mode == ScanMode.product ? l10n.scanProductCaption : l10n.cartLoginCaption,
                ),
              ),
              SizedBox(width: compact ? IcSpace.s12 : IcSpace.s20),
              SizedBox(
                width: compact ? 280 : 360,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(header: true, child: Text(l10n.navScan, style: compact ? IcText.titleM : IcText.titleL)),
                    const SizedBox(height: IcSpace.s12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SegmentedTabs<ScanMode>(
                        selected: vm.mode,
                        onChanged: vm.setMode,
                        items: [TabItem(ScanMode.product, l10n.scanModeProduct), TabItem(ScanMode.cart, l10n.scanModeCart)],
                      ),
                    ),
                    const SizedBox(height: IcSpace.s12),
                    if (!compact) Text(l10n.scanHelp, style: IcText.bodyS.copyWith(color: IcColors.textSecondary)),
                    const SizedBox(height: IcSpace.s12),
                    if (vm.error != null) ...[
                      Notice(kind: NoticeKind.warning, title: _error(l10n, vm.error!)),
                      const SizedBox(height: IcSpace.s12),
                    ],
                    if (data != null && product != null)
                      SurfaceCard(
                        elevated: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(l10n.scanLastRead, style: IcText.labelS.copyWith(color: IcColors.textMuted)),
                            const SizedBox(height: IcSpace.s4),
                            Text(product.name, style: IcText.titleS),
                            const SizedBox(height: IcSpace.s4),
                            Text(
                              [
                                if (data.gtin != null) 'GTIN ${data.gtin}',
                                if (data.lotNumber != null) l10n.scanLot(data.lotNumber!),
                                if (data.expiryDate != null) l10n.scanExpiry(format.numeric(data.expiryDate!)),
                              ].join(' · '),
                              style: IcText.bodyS.copyWith(color: IcColors.textSecondary),
                            ),
                            if (session.canReplenish) ...[
                              const SizedBox(height: IcSpace.s12),
                              IcButton(
                                label: l10n.scanReplenishThis,
                                icon: IcIcon.mais,
                                expand: true,
                                busy: vm.busy,
                                onPressed: () async {
                                  final result = await vm.locateLastProduct();
                                  if (!context.mounted) return;
                                  final location = result.value;
                                  if (location == null) {
                                    return showResult(context, result, failure: l10n.scanNotInAnyCart);
                                  }
                                  ShellNavigationScope.of(context).openDrawer(location.cartId, location.drawerId, slotId: location.slotId);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        if (vm.scanner.usesCamera) ...[
                          Expanded(
                            child: IcButton(
                              label: l10n.scannerTorch,
                              icon: IcIcon.lanterna,
                              style: IcButtonStyle.secondary,
                              expand: true,
                              onPressed: vm.toggleTorch,
                            ),
                          ),
                          const SizedBox(width: IcSpace.s12),
                        ],
                        Expanded(
                          child: IcButton(
                            label: l10n.scanManual,
                            icon: IcIcon.teclado,
                            style: IcButtonStyle.secondary,
                            expand: true,
                            onPressed: () => _manual(context, vm),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _manual(BuildContext context, ScannerViewModel vm) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.scanManual),
        content: SizedBox(
          width: 400,
          child: LabeledField(
            label: vm.mode == ScanMode.product ? l10n.scanManualProductLabel : l10n.cartLoginCodeLabel,
            controller: controller,
            autofocus: true,
            onSubmitted: (v) => Navigator.of(context).pop(v),
          ),
        ),
        actions: [
          IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
          IcButton(label: l10n.actionConfirm, onPressed: () => Navigator.of(context).pop(controller.text)),
        ],
      ),
    );
    controller.dispose();
    if (text != null && text.trim().isNotEmpty) await vm.submitManual(text);
  }
}
