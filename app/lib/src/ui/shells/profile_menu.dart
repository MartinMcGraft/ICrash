import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/l10n/app_localizations.dart';
import '../../common/locale_scope.dart';
import '../core/icons/ic_icons.dart';
import '../core/labels.dart';
import '../core/session/session.dart';
import '../core/theme/tokens.dart';
import '../core/widgets/layout.dart';

/// "Perfil": who is signed in plus account actions. Shared by both shells.
Future<void> showProfileMenu(BuildContext context) {
  final session = SessionScope.read(context);
  final actions = AppActionsScope.of(context);
  final l10n = AppLocalizations.of(context);
  final localeScope = LocaleScope.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      Widget item(IcIcon icon, String label, VoidCallback onTap, {Color color = IcColors.textPrimary}) => InkWell(
            onTap: () {
              Navigator.of(dialogContext).pop();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: IcSpace.s20, vertical: 14),
              child: Row(
                children: [
                  IcIconView(icon, size: 22, color: color),
                  const SizedBox(width: IcSpace.s12),
                  Expanded(child: Text(label, style: IcText.labelL.copyWith(color: color))),
                ],
              ),
            ),
          );
      final subtitle = [roleText(l10n, session.role), session.institution.name].join(' · ');
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(IcSpace.s20, IcSpace.s20, IcSpace.s20, IcSpace.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.myName, style: IcText.titleM),
                      const SizedBox(height: 2),
                      Text(subtitle, style: IcText.bodyS.copyWith(color: IcColors.textSecondary)),
                      const SizedBox(height: IcSpace.s16),
                      Text(l10n.languageSwitcherTooltip, style: IcText.labelS.copyWith(color: IcColors.textSecondary)),
                      const SizedBox(height: 6),
                      SegmentedTabs<String>(
                        items: [TabItem('pt', l10n.languagePortuguese), TabItem('en', l10n.languageEnglish)],
                        selected: localeScope.locale.languageCode,
                        onChanged: (code) {
                          localeScope.setLocale(Locale(code));
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                item(IcIcon.cadeado, actions.hasPin ? l10n.profileChangePin : l10n.profileSetPin, () => showSetPinDialog(context, actions)),
                if (actions.hasPin) item(IcIcon.cadeado, l10n.profileLockNow, () => actions.lock()),
                if (actions.switchInstitution != null) item(IcIcon.escudo, l10n.profileSwitchInstitution, actions.switchInstitution!),
                if (actions.switchShell != null)
                  item(
                    actions.showingDashboard ? IcIcon.carro : IcIcon.painel,
                    actions.showingDashboard ? l10n.viewAsApp : l10n.viewAsDashboard,
                    actions.switchShell!,
                  ),
                const Divider(),
                item(IcIcon.sair, l10n.actionSignOut, () => actions.signOut(), color: IcColors.dangerFg),
                const SizedBox(height: IcSpace.s8),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Asks for a 4-digit PIN twice and stores it on this device.
Future<void> showSetPinDialog(BuildContext context, AppActions actions) async {
  final l10n = AppLocalizations.of(context);
  final first = TextEditingController();
  final second = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final messenger = ScaffoldMessenger.of(context);
  final pin = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.profileSetPin),
      content: SizedBox(
        width: 360,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.pinSetupHelp, style: IcText.bodyM.copyWith(color: IcColors.textSecondary)),
              const SizedBox(height: IcSpace.s16),
              LabeledField(
                label: l10n.pinNewLabel,
                controller: first,
                obscure: true,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                validator: (v) => (v == null || v.length != 4) ? l10n.pinFourDigits : null,
              ),
              const SizedBox(height: IcSpace.s12),
              LabeledField(
                label: l10n.pinRepeatLabel,
                controller: second,
                obscure: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                validator: (v) => v != first.text ? l10n.pinMismatch : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.actionCancel)),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) Navigator.of(context).pop(first.text);
          },
          child: Text(l10n.actionSave),
        ),
      ],
    ),
  );
  first.dispose();
  second.dispose();
  if (pin == null) return;
  final ok = await actions.setPin(pin);
  messenger.showSnackBar(SnackBar(content: Text(ok ? l10n.pinSaved : l10n.actionGenericError)));
}
