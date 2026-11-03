import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/cart_report.dart';
import '../../../domain/inventory_health.dart';
import '../../core/format.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/labels.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/fit.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/status.dart';
import '../../shells/profile_menu.dart';
import 'report_pdf.dart';
import 'report_view_model.dart';

String reportTitle(AppLocalizations l10n, CartReport r) =>
    r.kind == ReportKind.monthlyCheck ? l10n.reportKindMonthlyCheck : l10n.reportKindEmergency;

String findingText(AppLocalizations l10n, ReportFinding f) {
  final issue = switch (f.issue) {
    FindingIssue.expired => l10n.slotHealthExpired.toLowerCase(),
    FindingIssue.expiring => l10n.slotHealthExpiring.toLowerCase(),
    FindingIssue.missing => l10n.slotHealthMissing.toLowerCase(),
    FindingIssue.lowStock => l10n.slotHealthLowStock.toLowerCase(),
    FindingIssue.other => l10n.findingOther,
  };
  return '${f.productName} (${f.position}) — $issue${f.detail == null ? '' : ' · ${f.detail}'}';
}

/// A9 · Relatório — assinar.
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key, required this.reportId});
  final String reportId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.read(context);
    return ViewModelBuilder<ReportViewModel>(
      create: (services) => ReportViewModel(services, session, reportId),
      builder: (context, vm) {
        final report = vm.report;
        if (vm.state == LoadState.loading) return const StateView.loading();
        if (report == null) return StateView.message(message: l10n.stateLoadError, icon: IcIcon.relatorio);
        final format = IcFormat.of(context);
        final compact = isCompactHeight(context);
        return Padding(
          padding: contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: report.kind == ReportKind.monthlyCheck ? l10n.reportMonthlyTitle : l10n.reportEmergencyTitle,
                subtitle: '${report.cartName} · ${format.monthYear(report.createdAt)}',
                onBack: () => Navigator.of(context).maybePop(),
                trailing: [
                  StatusPill(
                    text: report.isSigned ? l10n.reportSigned : l10n.reportPendingSignature,
                    tone: report.isSigned ? PillTone.ok : PillTone.warning,
                  ),
                ],
              ),
              SizedBox(height: compact ? IcSpace.s12 : IcSpace.s20),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SurfaceCard(
                        elevated: false,
                        padding: const EdgeInsets.all(IcSpace.s20),
                        // Phones scroll; tablets page long finding lists instead.
                        child: allowsScroll(context)
                            ? SingleChildScrollView(child: _ReportBody(report: report, fill: false))
                            : _ReportBody(report: report, fill: true),
                      ),
                    ),
                    SizedBox(width: compact ? IcSpace.s12 : IcSpace.s20),
                    SidePanel(child: _SignPanel(vm: vm, report: report)),
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

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report, required this.fill});
  final CartReport report;

  /// Fill the given height (tablet+) and page the item list instead of
  /// growing past it.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = IcFormat.of(context);
    final session = SessionScope.of(context);
    final creatorRole = session.members[report.createdByUid]?.role;
    final by = creatorRole == null ? report.createdByName : '${report.createdByName} · ${roleText(l10n, creatorRole)}';
    final items = <Widget>[
      if (report.kind == ReportKind.monthlyCheck)
        for (final f in report.findings)
          Text('• ${findingText(l10n, f)}', style: IcText.bodyS, maxLines: fill ? 1 : null, overflow: fill ? TextOverflow.ellipsis : null)
      else
        for (final line in report.lines)
          Row(children: [
            Expanded(child: Text(line.productName, style: IcText.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text(IcFormat.signed(-line.amount), style: IcText.labelM.copyWith(color: IcColors.dangerFg)),
          ]),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${reportTitle(l10n, report)} — ${report.cartName}', style: IcText.titleS),
        const SizedBox(height: IcSpace.s12),
        InfoRow(label: l10n.reportDate, value: format.dateTime(report.createdAt), bold: true),
        InfoRow(
          label: report.kind == ReportKind.monthlyCheck ? l10n.reportCheckedBy : l10n.reportStartedBy,
          value: by,
          bold: true,
        ),
        if (report.kind == ReportKind.monthlyCheck) ...[
          InfoRow(label: l10n.drawersTitle, value: l10n.xOfY(report.drawersChecked, report.drawersTotal), bold: true),
          InfoRow(label: l10n.reportPositionsChecked, value: l10n.xOfY(report.positionsChecked, report.positionsTotal), bold: true),
        ] else if (report.periodStart != null && report.periodEnd != null)
          InfoRow(
            label: l10n.reportPeriod,
            value: '${format.time(report.periodStart!)} – ${format.time(report.periodEnd!)}',
            bold: true,
          ),
        const SizedBox(height: IcSpace.s8),
        const Divider(),
        const SizedBox(height: IcSpace.s12),
        Text(
          report.kind == ReportKind.monthlyCheck
              ? l10n.reportFindings(report.findings.length)
              : l10n.emergencyConsumptions(report.lines.fold(0, (sum, l) => sum + l.amount)),
          style: IcText.labelM,
        ),
        const SizedBox(height: IcSpace.s8),
        if (report.kind == ReportKind.monthlyCheck && report.findings.isEmpty)
          Text(l10n.reportNoFindings, style: IcText.bodyS.copyWith(color: IcColors.textSecondary))
        else if (fill)
          Expanded(child: FitList(itemCount: items.length, itemExtent: 24, spacing: 0, itemBuilder: (context, i) => items[i]))
        else
          for (final item in items) Padding(padding: const EdgeInsets.only(bottom: 6), child: item),
        if (report.notes != null) ...[
          const SizedBox(height: IcSpace.s12),
          Text(l10n.reportNotes, style: IcText.labelM),
          const SizedBox(height: IcSpace.s4),
          Text(report.notes!, style: IcText.bodyS, maxLines: fill ? 3 : null, overflow: fill ? TextOverflow.ellipsis : null),
        ],
      ],
    );
  }
}

class _SignPanel extends StatefulWidget {
  const _SignPanel({required this.vm, required this.report});
  final ReportViewModel vm;
  final CartReport report;

  @override
  State<_SignPanel> createState() => _SignPanelState();
}

class _SignPanelState extends State<_SignPanel> {
  final _pin = TextEditingController();

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = IcFormat.of(context);
    final vm = widget.vm;
    final report = widget.report;
    final compact = isCompactHeight(context);
    final download = IcButton(
      label: l10n.downloadPdf,
      icon: IcIcon.descarregar,
      style: IcButtonStyle.secondary,
      expand: true,
      onPressed: () => downloadReportPdf(context, report),
    );
    if (report.isSigned) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.reportSigned, style: IcText.titleS),
          const SizedBox(height: IcSpace.s12),
          ToneLine(
            tone: HealthTone.ok,
            icon: IcIcon.assinar,
            text: l10n.signedByOn(report.signedByName ?? '', format.dateTime(report.signedAt ?? report.createdAt)),
          ),
          const SizedBox(height: IcSpace.s12),
          Text(l10n.reportLockedHelp, style: IcText.bodyS.copyWith(color: IcColors.textSecondary)),
          const Spacer(),
          download,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.signReport, style: IcText.titleS),
        const SizedBox(height: IcSpace.s8),
        if (!compact) Text(l10n.signReportHelp, style: IcText.bodyS.copyWith(color: IcColors.textSecondary)),
        const SizedBox(height: IcSpace.s12),
        CheckRow(label: l10n.confirmCheck, value: vm.confirmed, onChanged: vm.setConfirmed),
        const SizedBox(height: IcSpace.s8),
        LabeledField(
          label: l10n.pinLabel,
          controller: _pin,
          obscure: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
        ),
        const Spacer(),
        IcButton(
          label: l10n.signReport,
          icon: IcIcon.assinar,
          size: compact ? IcButtonSize.m : IcButtonSize.l,
          expand: true,
          busy: vm.busy,
          onPressed: () async {
            final result = await vm.sign(_pin.text);
            if (!context.mounted) return;
            if (result.code == 'noPin') {
              showMessage(context, l10n.signNeedsPin);
              await showSetPinDialog(context, AppActionsScope.of(context));
              return;
            }
            showResult(
              context,
              result,
              success: l10n.reportSignedMessage,
              failure: switch (result.code) {
                'notConfirmed' => l10n.signNeedsConfirmation,
                'wrongPin' => l10n.signWrongPin,
                _ => null,
              },
            );
            _pin.clear();
          },
        ),
        const SizedBox(height: IcSpace.s12),
        download,
      ],
    );
  }
}

/// Opens the system print/save dialog with the report PDF (A9 and B9).
Future<void> downloadReportPdf(BuildContext context, CartReport report) async {
  final l10n = AppLocalizations.of(context);
  final format = IcFormat.of(context);
  final session = SessionScope.read(context);
  final labels = ReportPdfLabels(
    title: '${reportTitle(l10n, report)} — ${report.cartName}',
    institution: session.institution.name,
    dateLabel: l10n.reportDate,
    date: format.dateTime(report.createdAt),
    byLabel: report.kind == ReportKind.monthlyCheck ? l10n.reportCheckedBy : l10n.reportStartedBy,
    drawersLabel: l10n.drawersTitle,
    drawers: l10n.xOfY(report.drawersChecked, report.drawersTotal),
    positionsLabel: l10n.reportPositionsChecked,
    positions: l10n.xOfY(report.positionsChecked, report.positionsTotal),
    findingsTitle: l10n.reportFindings(report.findings.length),
    findings: [for (final f in report.findings) findingText(l10n, f)],
    linesTitle: l10n.emergencyConsumptions(report.lines.fold(0, (sum, l) => sum + l.amount)),
    lines: [for (final line in report.lines) '${line.productName}: ${IcFormat.signed(-line.amount)}'],
    notesLabel: l10n.reportNotes,
    signatureTitle: l10n.signReport,
    signatureText: report.isSigned
        ? l10n.signedByOn(report.signedByName ?? '', format.dateTime(report.signedAt ?? report.createdAt))
        : l10n.reportPendingSignature,
  );
  await Printing.layoutPdf(name: labels.title, onLayout: (_) => buildReportPdf(report, labels));
}
