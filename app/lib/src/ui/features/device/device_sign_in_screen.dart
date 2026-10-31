import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/membership.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/layout.dart';
import '../auth/pin_unlock_screen.dart';
import 'device_sign_in_view_model.dart';

/// A2b · Identificação (D17): nº mecanográfico or e-mail on the left, the
/// A2 keypad on the right.
class DeviceSignInScreen extends StatefulWidget {
  const DeviceSignInScreen({
    super.key,
    required this.institutionId,
    required this.title,
    this.subtitle,
    required this.onIdentified,
    required this.onCancel,
    required this.onTooManyAttempts,
  });

  final String institutionId;
  final String title;

  /// The tablet's name, or the scanned cart.
  final String? subtitle;
  final Future<String?> Function(Membership person) onIdentified;
  final VoidCallback onCancel;
  final Future<void> Function() onTooManyAttempts;

  @override
  State<DeviceSignInScreen> createState() => _DeviceSignInScreenState();
}

class _DeviceSignInScreenState extends State<DeviceSignInScreen> {
  final _identifier = TextEditingController();

  @override
  void dispose() {
    _identifier.dispose();
    super.dispose();
  }

  String? _message(AppLocalizations l10n, DeviceSignInViewModel vm) => switch (vm.error) {
        null => null,
        DeviceSignInError.enterIdentifier => l10n.deviceEnterIdentifierFirst,
        DeviceSignInError.wrongCredentials => l10n.deviceWrongCredentials(vm.attemptsLeft),
        DeviceSignInError.noPin => l10n.deviceNoPin,
        DeviceSignInError.notAdmin => l10n.deviceRemoveNotAdmin,
        DeviceSignInError.noCarts => l10n.deviceNoCartsForPerson,
        DeviceSignInError.notOnCart => l10n.deviceNotOnCart,
        DeviceSignInError.generic => l10n.loginErrorGeneric,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<DeviceSignInViewModel>(
      create: (services) => DeviceSignInViewModel(
        services: services,
        institutionId: widget.institutionId,
        onIdentified: widget.onIdentified,
        onTooManyAttempts: widget.onTooManyAttempts,
      ),
      builder: (context, vm) {
        final compact = isCompactHeight(context);
        final message = _message(l10n, vm);
        final form = SizedBox(
          width: compact ? 300 : 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(header: true, child: Text(widget.title, style: compact ? IcText.titleM : IcText.titleL)),
              if (widget.subtitle != null) ...[
                const SizedBox(height: IcSpace.s4),
                Text(widget.subtitle!, style: IcText.bodyM.copyWith(color: IcColors.textSecondary)),
              ],
              SizedBox(height: compact ? IcSpace.s12 : IcSpace.s20),
              LabeledField(
                label: l10n.deviceIdentifierLabel,
                controller: _identifier,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                onChanged: vm.setIdentifier,
              ),
              SizedBox(height: compact ? IcSpace.s12 : IcSpace.s20),
              Text(l10n.pinLabel, style: IcText.labelS.copyWith(color: IcColors.textSecondary)),
              const SizedBox(height: IcSpace.s8),
              Semantics(
                label: l10n.pinDigitsSemantics(vm.entered, DeviceSignInViewModel.pinLength),
                child: Row(
                  children: [
                    for (var i = 0; i < DeviceSignInViewModel.pinLength; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < vm.entered ? IcColors.actionPrimary : null,
                            border: i < vm.entered
                                ? null
                                : Border.all(color: message != null ? IcColors.dangerFg : IcColors.borderStrong, width: 2),
                          ),
                        ),
                      ),
                    if (vm.busy) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
              ),
              const SizedBox(height: IcSpace.s12),
              Semantics(
                liveRegion: true,
                child: Text(
                  message ?? l10n.deviceSignInHint,
                  style: IcText.bodyS.copyWith(color: message != null ? IcColors.dangerFg : IcColors.textMuted),
                ),
              ),
              SizedBox(height: compact ? IcSpace.s8 : IcSpace.s16),
              Align(
                alignment: Alignment.centerLeft,
                child: IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: widget.onCancel),
              ),
            ],
          ),
        );
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: contentPadding(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    form,
                    SizedBox(width: compact ? 40 : 96),
                    PinKeypad(onDigit: vm.addDigit, onDelete: vm.deleteDigit, compact: compact),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
