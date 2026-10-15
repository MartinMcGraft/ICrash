import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/institution.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/layout.dart';

/// Institution choice, shown only when the user belongs to more than one
/// (audit §4.4: skip automatically when there is a single institution).
/// Stateless: the list and actions come from the app root ViewModel.
class InstitutionPickerScreen extends StatelessWidget {
  const InstitutionPickerScreen({
    super.key,
    required this.institutions,
    required this.onSelect,
    required this.onSignOut,
    this.loadFailed = false,
    this.onRetry,
  });

  final List<Institution> institutions;
  final ValueChanged<Institution> onSelect;
  final VoidCallback onSignOut;
  final bool loadFailed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: contentPadding(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(title: l10n.institutionSelectionTitle),
                  const SizedBox(height: IcSpace.s20),
                  if (institutions.isEmpty)
                    StateView.message(
                      message: loadFailed ? l10n.stateLoadError : l10n.institutionSelectionEmpty,
                      onRetry: loadFailed ? onRetry : null,
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: institutions.length,
                        separatorBuilder: (_, _) => const SizedBox(height: IcSpace.s12),
                        itemBuilder: (context, index) {
                          final institution = institutions[index];
                          return SurfaceCard(
                            onTap: () => onSelect(institution),
                            padding: const EdgeInsets.symmetric(horizontal: IcSpace.s16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(color: IcColors.navy50, borderRadius: BorderRadius.circular(IcRadius.md)),
                                  alignment: Alignment.center,
                                  child: const IcIconView(IcIcon.escudo, color: IcColors.textLink),
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: Text(institution.name, style: IcText.labelL)),
                                const IcIconView(IcIcon.seguinte, color: IcColors.textSecondary),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: IcSpace.s20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IcButton(label: l10n.actionSignOut, icon: IcIcon.sair, style: IcButtonStyle.ghost, onPressed: onSignOut),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
