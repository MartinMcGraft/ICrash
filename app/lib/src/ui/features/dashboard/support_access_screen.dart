import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/support_access.dart';
import '../../core/format.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/fit.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/status.dart';
import 'support_access_view_model.dart';

String supportDurationText(AppLocalizations l10n, Duration d) =>
    d.inDays >= 1 ? l10n.supportDurationDays(d.inDays) : l10n.supportDurationHours(d.inHours);

/// D18 · Acesso do suporte (Dashboard, the institution's own Admin).
class SupportAccessScreen extends StatefulWidget {
  const SupportAccessScreen({super.key});

  @override
  State<SupportAccessScreen> createState() => _SupportAccessScreenState();
}

class _SupportAccessScreenState extends State<SupportAccessScreen> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.read(context);
    return ViewModelBuilder<SupportAccessViewModel>(
      create: (services) => SupportAccessViewModel(services, session),
      builder: (context, vm) {
        final format = IcFormat.of(context);
        final open = vm.openWindow;
        return Padding(
          padding: contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(title: l10n.supportTitle, subtitle: l10n.supportSubtitle),
              const SizedBox(height: IcSpace.s20),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 400,
                      child: SurfaceCard(
                        elevated: false,
                        padding: const EdgeInsets.all(IcSpace.s20),
                        child: vm.state == LoadState.loading
                            ? const StateView.loading()
                            : open == null
                                ? _OpenForm(vm: vm, reason: _reason)
                                : _OpenWindow(vm: vm, window: open),
                      ),
                    ),
                    const SizedBox(width: IcSpace.s20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionTitle(l10n.supportLogTitle),
                          const SizedBox(height: IcSpace.s12),
                          Expanded(
                            child: FitDataTable(
                              columns: [
                                TableColumnSpec(l10n.supportLogWhen, flex: 2),
                                TableColumnSpec(l10n.supportLogWho, flex: 3),
                                TableColumnSpec(l10n.supportLogAction, flex: 2),
                              ],
                              emptyText: l10n.supportLogEmpty,
                              rows: [
                                for (final e in vm.log)
                                  [
                                    CellText(e.at == null ? '—' : format.dateTime(e.at!)),
                                    CellText(e.superEmail ?? e.superUid, primary: true),
                                    CellText(e.action == 'enter' ? l10n.supportLogEnter : l10n.supportLogLeave),
                                  ],
                              ],
                            ),
                          ),
                        ],
                      ),
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
}

class _OpenForm extends StatelessWidget {
  const _OpenForm({required this.vm, required this.reason});
  final SupportAccessViewModel vm;
  final TextEditingController reason;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.supportClosedTitle, style: IcText.titleS),
        const SizedBox(height: IcSpace.s8),
        Text(l10n.supportClosedHelp, style: IcText.bodyS.copyWith(color: IcColors.textSecondary)),
        const SizedBox(height: IcSpace.s16),
        LabeledField(
          label: l10n.supportReasonLabel,
          hint: l10n.supportReasonHint,
          controller: reason,
          inputFormatters: [LengthLimitingTextInputFormatter(500)],
        ),
        const SizedBox(height: IcSpace.s16),
        Text(l10n.supportDurationLabel, style: IcText.labelS.copyWith(color: IcColors.textSecondary)),
        const SizedBox(height: 6),
        SegmentedTabs<Duration>(
          items: [for (final d in SupportWindow.durations) TabItem(d, supportDurationText(l10n, d))],
          selected: vm.duration,
          onChanged: vm.setDuration,
        ),
        const Spacer(),
        IcButton(
          label: l10n.supportOpenAction,
          icon: IcIcon.escudo,
          expand: true,
          busy: vm.busy,
          onPressed: () async {
            final result = await vm.open(reason.text);
            if (!context.mounted) return;
            showResult(
              context,
              result,
              success: l10n.supportOpened,
              failure: switch (result.code) {
                'reasonRequired' => l10n.supportReasonRequired,
                _ => null,
              },
            );
            if (result.isOk) reason.clear();
          },
        ),
      ],
    );
  }
}

class _OpenWindow extends StatelessWidget {
  const _OpenWindow({required this.vm, required this.window});
  final SupportAccessViewModel vm;
  final SupportWindow window;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = IcFormat.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Notice(kind: NoticeKind.warning, title: l10n.supportOpenTitle(format.dateTime(window.endsAt))),
        const SizedBox(height: IcSpace.s16),
        InfoRow(label: l10n.supportReasonLabel, value: window.reason),
        InfoRow(label: l10n.supportGrantedBy, value: window.grantedByName ?? window.grantedBy),
        if (window.startsAt != null) InfoRow(label: l10n.supportSince, value: format.dateTime(window.startsAt!)),
        const Spacer(),
        IcButton(
          label: l10n.supportCloseAction,
          icon: IcIcon.fechar,
          style: IcButtonStyle.danger,
          expand: true,
          busy: vm.busy,
          onPressed: () async {
            final ok = await confirmAction(
              context,
              title: l10n.supportCloseAction,
              message: l10n.supportCloseConfirm,
              confirmLabel: l10n.supportCloseAction,
              destructive: true,
            );
            if (!ok || !context.mounted) return;
            final result = await vm.close();
            if (context.mounted) showResult(context, result, success: l10n.supportClosed);
          },
        ),
      ],
    );
  }
}
