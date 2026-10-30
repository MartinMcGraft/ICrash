import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/institution.dart';
import '../../../domain/entities/support_access.dart';
import '../../core/format.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/status.dart';

/// Institution choice, for Super only (D16, D18): the institutions whose
/// Admin opened a support window, each with the time it ends. Stateless: the
/// list and actions come from the app root ViewModel.
class InstitutionPickerScreen extends StatelessWidget {
  const InstitutionPickerScreen({
    super.key,
    required this.institutions,
    required this.onSelect,
    required this.onSignOut,
    this.loadFailed = false,
    this.onRetry,
    this.supportWindows,
    this.supportEnded = false,
    this.onRefresh,
  });

  /// D18: Super's open windows by institution id (`null` for other users).
  final Map<String, SupportWindow>? supportWindows;

  /// D18: Super's previous window ended or was closed.
  final bool supportEnded;
  final VoidCallback? onRefresh;

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
                  PageHeader(
                    title: supportWindows == null ? l10n.institutionSelectionTitle : l10n.supportPickerTitle,
                    subtitle: supportWindows == null ? null : l10n.supportPickerSubtitle,
                    trailing: [
                      if (onRefresh != null) IcIconButton(icon: IcIcon.sincronizar, tooltip: l10n.actionRefresh, onPressed: onRefresh),
                    ],
                  ),
                  const SizedBox(height: IcSpace.s20),
                  if (supportEnded) ...[
                    Notice(kind: NoticeKind.warning, title: l10n.supportEnded),
                    const SizedBox(height: IcSpace.s12),
                  ],
                  if (institutions.isEmpty)
                    StateView.message(
                      message: loadFailed
                          ? l10n.stateLoadError
                          : (supportWindows == null ? l10n.institutionSelectionEmpty : l10n.supportPickerEmpty),
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(institution.name, style: IcText.labelL),
                                      if (supportWindows?[institution.id] case final window?)
                                        Text(
                                          l10n.supportPickerUntil(IcFormat.of(context).dateTime(window.endsAt), window.reason),
                                          style: IcText.bodyS.copyWith(color: IcColors.textSecondary),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
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
