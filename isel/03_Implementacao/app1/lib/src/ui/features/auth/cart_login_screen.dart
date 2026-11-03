import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../services/internal_qr_payload.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/scanner_viewport.dart';
import '../../core/widgets/status.dart';
import 'cart_login_view_model.dart';

/// A3 · Entrar no carro — camera on the left, options on the right.
class CartLoginScreen extends StatelessWidget {
  const CartLoginScreen({super.key, required this.enterCart, required this.onBack});

  final Future<ActionResult<void>> Function(CartQrTarget target) enterCart;
  final VoidCallback onBack;

  String _errorText(AppLocalizations l10n, CartLoginError error) => switch (error) {
        CartLoginError.notACartCode => l10n.cartQrScanError,
        CartLoginError.cartNotFound => l10n.cartLoginNotFound,
        CartLoginError.noAccess => l10n.cartLoginNoAccess,
        CartLoginError.noSavedSession => l10n.loginNeedsSavedSession,
        CartLoginError.generic => l10n.actionGenericError,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<CartLoginViewModel>(
      create: (services) => CartLoginViewModel(scanner: services.createCodeScanner(), enterCart: enterCart),
      builder: (context, vm) {
        final compact = isCompactHeight(context);
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: contentPadding(context),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: ScannerViewport(scanner: vm.scanner, caption: l10n.cartLoginCaption)),
                  const SizedBox(width: IcSpace.s20),
                  SizedBox(
                    width: compact ? 280 : 360,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(header: true, child: Text(l10n.loginCartLogin, style: compact ? IcText.titleM : IcText.titleL)),
                        const SizedBox(height: 14),
                        Text(l10n.cartLoginHelp, style: IcText.bodyM.copyWith(color: IcColors.textSecondary)),
                        const SizedBox(height: 14),
                        if (vm.error != null) ...[
                          Notice(kind: NoticeKind.critical, title: _errorText(l10n, vm.error!)),
                          const SizedBox(height: 14),
                        ],
                        IcButton(
                          label: l10n.cartLoginUseNfc,
                          icon: IcIcon.nfc,
                          style: IcButtonStyle.secondary,
                          expand: true,
                          onPressed: () => ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(l10n.cartLoginNfcUnavailable))),
                        ),
                        const SizedBox(height: 14),
                        if (vm.scanner.usesCamera) ...[
                          IcButton(
                            label: vm.torchOn ? l10n.scannerTorchOff : l10n.scannerTorch,
                            icon: IcIcon.lanterna,
                            style: IcButtonStyle.secondary,
                            expand: true,
                            onPressed: vm.toggleTorch,
                          ),
                          const SizedBox(height: 14),
                        ],
                        IcButton(
                          label: l10n.cartLoginEnterCode,
                          icon: IcIcon.teclado,
                          style: IcButtonStyle.ghost,
                          expand: true,
                          busy: vm.busy,
                          onPressed: () => _askCode(context, vm),
                        ),
                        const Spacer(),
                        IcButton(
                          label: l10n.cartLoginBackToLogin,
                          icon: IcIcon.voltar,
                          style: IcButtonStyle.ghost,
                          expand: true,
                          onPressed: onBack,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _askCode(BuildContext context, CartLoginViewModel vm) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cartLoginEnterCode),
        content: SizedBox(
          width: 400,
          child: LabeledField(
            label: l10n.cartLoginCodeLabel,
            controller: controller,
            hint: l10n.cartLoginCodeHint,
            autofocus: true,
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: Text(l10n.actionConfirm)),
        ],
      ),
    );
    controller.dispose();
    if (code != null && code.trim().isNotEmpty) await vm.submitCode(code);
  }
}
