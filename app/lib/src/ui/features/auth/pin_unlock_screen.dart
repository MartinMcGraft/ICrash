import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/repositories/device_session_repository.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/labels.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/layout.dart';
import 'pin_unlock_view_model.dart';

/// A2 · Desbloquear com PIN — person on the left, keypad on the right.
class PinUnlockScreen extends StatelessWidget {
  const PinUnlockScreen({
    super.key,
    required this.user,
    required this.onUnlocked,
    required this.onNotMe,
  });

  final RememberedUser user;
  final Future<void> Function() onUnlocked;

  /// "Não é a Ana? Iniciar sessão" (also used after too many attempts).
  final Future<void> Function() onNotMe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<PinUnlockViewModel>(
      create: (services) => PinUnlockViewModel(
        deviceSession: services.deviceSession,
        user: user,
        onUnlocked: onUnlocked,
        onTooManyAttempts: onNotMe,
      ),
      builder: (context, vm) {
        final compact = isCompactHeight(context);
        final subtitle = [roleTextFromId(l10n, user.roleId), user.service].whereType<String>().join(' · ');
        final person = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 56 : 88,
              height: compact ? 56 : 88,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: IcColors.navy50, shape: BoxShape.circle),
              child: Text(user.initials, style: IcText.titleL.copyWith(color: IcColors.textLink)),
            ),
            const SizedBox(height: IcSpace.s12),
            Text(user.displayName, style: compact ? IcText.titleM : IcText.titleL, textAlign: TextAlign.center),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: IcSpace.s12),
              Text(subtitle, style: IcText.bodyM.copyWith(color: IcColors.textSecondary)),
            ],
            const SizedBox(height: IcSpace.s12),
            Semantics(
              label: l10n.pinDigitsSemantics(vm.entered, PinUnlockViewModel.pinLength),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < PinUnlockViewModel.pinLength; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < vm.entered ? IcColors.actionPrimary : null,
                          border: i < vm.entered ? null : Border.all(color: vm.wrongPin ? IcColors.dangerFg : IcColors.borderStrong, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: IcSpace.s12),
            Semantics(
              liveRegion: true,
              child: Text(
                vm.wrongPin ? l10n.pinWrong(vm.attemptsLeft) : l10n.pinWorksOffline,
                style: IcText.bodyS.copyWith(color: vm.wrongPin ? IcColors.dangerFg : IcColors.textMuted),
              ),
            ),
            const SizedBox(height: IcSpace.s12),
            IcButton(
              label: l10n.pinNotMe(user.displayName.split(' ').first),
              style: IcButtonStyle.ghost,
              onPressed: onNotMe,
            ),
          ],
        );
        return Scaffold(
          body: SafeArea(
            child: Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                final char = event.character;
                if (char != null && RegExp(r'^\d$').hasMatch(char)) {
                  vm.addDigit(int.parse(char));
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.backspace) {
                  vm.deleteDigit();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Center(
                child: SingleChildScrollView(
                  padding: contentPadding(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      person,
                      SizedBox(width: compact ? 48 : 120),
                      _Keypad(vm: vm, compact: compact),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.vm, required this.compact});
  final PinUnlockViewModel vm;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final keyW = compact ? 72.0 : 88.0;
    final keyH = compact ? 52.0 : 64.0;
    Widget key({required Widget child, required VoidCallback onTap, required String label, bool muted = false}) => Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: Material(
            color: muted ? IcColors.bgSurfaceMuted : IcColors.bgSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(IcRadius.lg),
              side: const BorderSide(color: IcColors.borderDefault),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(onTap: onTap, child: SizedBox(width: keyW, height: keyH, child: Center(child: child))),
          ),
        );
    Widget digit(int d) => key(label: '$d', onTap: () => vm.addDigit(d), child: Text('$d', style: IcText.numberL));
    Widget row(List<Widget> children) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(width: IcSpace.s12), c],
          ],
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row([digit(1), digit(2), digit(3)]),
        const SizedBox(height: IcSpace.s12),
        row([digit(4), digit(5), digit(6)]),
        const SizedBox(height: IcSpace.s12),
        row([digit(7), digit(8), digit(9)]),
        const SizedBox(height: IcSpace.s12),
        row([
          SizedBox(width: keyW, height: keyH),
          digit(0),
          key(
            label: l10n.pinDelete,
            muted: true,
            onTap: vm.deleteDigit,
            child: const IcIconView(IcIcon.apagar, color: IcColors.textSecondary),
          ),
        ]),
      ],
    );
  }
}
