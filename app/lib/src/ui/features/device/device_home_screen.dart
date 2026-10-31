import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/status.dart';
import '../auth/login_screen.dart';

/// A1 on a registered tablet (D17): no password. The tablet is signed in as
/// itself; a person enters with their PIN, or by scanning the cart.
/// With [revoked], the Admin revoked the tablet on the Dashboard.
class DeviceHomeScreen extends StatelessWidget {
  const DeviceHomeScreen({
    super.key,
    required this.institutionName,
    required this.deviceName,
    required this.onUsePin,
    required this.onCartLogin,
    required this.onRemoveRegistration,
    required this.onSetUpAgain,
    this.revoked = false,
    this.notice,
  });

  final String institutionName;
  final String deviceName;
  final VoidCallback onUsePin;
  final VoidCallback onCartLogin;
  final VoidCallback onRemoveRegistration;
  final VoidCallback onSetUpAgain;
  final bool revoked;

  /// Why the tablet came back here (inactivity, too many attempts…).
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final compact = isCompactHeight(context);
    final brandWidth = compact ? 280.0 : (width * 0.4).clamp(220.0, 520.0);
    final gap = SizedBox(height: compact ? IcSpace.s12 : IcSpace.s16);
    return Scaffold(
      body: Row(
        children: [
          LoginBrandPanel(width: brandWidth, compact: compact, institutionName: institutionName),
          Expanded(
            child: SafeArea(
              left: false,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(compact ? IcSpace.s16 : IcSpace.s24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                header: true,
                                child: Text(deviceName, style: compact ? IcText.titleM : IcText.titleL),
                              ),
                            ),
                            const LanguageTabs(),
                          ],
                        ),
                        const SizedBox(height: IcSpace.s4),
                        Text(l10n.deviceRegisteredTo(institutionName), style: IcText.bodyM.copyWith(color: IcColors.textSecondary)),
                        gap,
                        if (revoked) ...[
                          Notice(kind: NoticeKind.critical, title: l10n.deviceRevokedTitle, message: l10n.deviceRevokedMessage),
                          gap,
                          IcButton(
                            label: l10n.deviceSetUp,
                            icon: IcIcon.opcoes,
                            size: compact ? IcButtonSize.m : IcButtonSize.l,
                            expand: true,
                            onPressed: onSetUpAgain,
                          ),
                        ] else ...[
                          if (notice != null) ...[
                            Notice(kind: NoticeKind.info, title: notice!),
                            gap,
                          ],
                          IcButton(
                            label: l10n.loginUsePin,
                            icon: IcIcon.cadeado,
                            size: compact ? IcButtonSize.m : IcButtonSize.l,
                            expand: true,
                            onPressed: onUsePin,
                          ),
                          SizedBox(height: compact ? IcSpace.s8 : IcSpace.s12),
                          IcButton(
                            label: l10n.loginCartLogin,
                            icon: IcIcon.qr,
                            style: IcButtonStyle.secondary,
                            size: compact ? IcButtonSize.m : IcButtonSize.l,
                            expand: true,
                            onPressed: onCartLogin,
                          ),
                          gap,
                          Text(l10n.deviceNoPasswordNote, style: IcText.bodyS.copyWith(color: IcColors.textSecondary)),
                          SizedBox(height: compact ? IcSpace.s8 : IcSpace.s12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IcButton(
                              label: l10n.deviceRemoveRegistration,
                              style: IcButtonStyle.ghost,
                              onPressed: onRemoveRegistration,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
