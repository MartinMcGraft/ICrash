import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../core/format.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/fit.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/status.dart';
import '../../shells/shell_navigation.dart';
import '../reports/report_screen.dart';
import 'activity_list.dart';
import 'reports_history_view_model.dart';

export 'reports_history_view_model.dart' show ReportsHistoryTab;

/// B9 · Relatórios e histórico.
class ReportsHistoryScreen extends StatelessWidget {
  const ReportsHistoryScreen({super.key, this.initialTab = ReportsHistoryTab.reports});
  final ReportsHistoryTab initialTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.read(context);
    return ViewModelBuilder<ReportsHistoryViewModel>(
      create: (services) => ReportsHistoryViewModel(services, session, tab: initialTab),
      builder: (context, vm) {
        final format = IcFormat.of(context);
        return Padding(
          padding: contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: l10n.reportsHistoryTitle,
                subtitle: SessionScope.of(context).institution.name,
                trailing: [
                  IcButton(
                    label: l10n.exportCsv,
                    icon: IcIcon.descarregar,
                    style: IcButtonStyle.secondary,
                    onPressed: () => _exportCsv(context, vm),
                  ),
                ],
              ),
              const SizedBox(height: IcSpace.s20),
              Row(
                children: [
                  SegmentedTabs<ReportsHistoryTab>(
                    selected: vm.tab,
                    onChanged: vm.setTab,
                    items: [
                      TabItem(ReportsHistoryTab.reports, l10n.tabReports),
                      TabItem(ReportsHistoryTab.events, l10n.tabEvents),
                      TabItem(ReportsHistoryTab.statistics, l10n.tabStatistics),
                    ],
                  ),
                  const Spacer(),
                  _MenuButton<String?>(
                    icon: IcIcon.carro,
                    label: l10n.filterCart(vm.cartName ?? l10n.filterAllCarts),
                    items: [(null, l10n.filterAllCarts), for (final c in vm.carts) (c.id, c.name)],
                    onSelected: vm.setCart,
                  ),
                  const SizedBox(width: IcSpace.s8),
                  _MenuButton<DateTime>(
                    icon: IcIcon.calendario,
                    label: l10n.filterPeriod(format.monthYear(vm.month)),
                    items: [for (final m in vm.recentMonths) (m, format.monthYear(m))],
                    onSelected: vm.setMonth,
                  ),
                ],
              ),
              const SizedBox(height: IcSpace.s20),
              Expanded(
                child: switch (vm.state) {
                  LoadState.loading => const StateView.loading(),
                  LoadState.error => StateView.message(message: l10n.stateLoadError),
                  // Tables and lists page instead of scrolling (tablet+).
                  LoadState.ready => switch (vm.tab) {
                      ReportsHistoryTab.reports => _ReportsTable(vm: vm),
                      ReportsHistoryTab.events => _EventsList(vm: vm),
                      ReportsHistoryTab.statistics => _Statistics(vm: vm),
                    },
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportCsv(BuildContext context, ReportsHistoryViewModel vm) async {
    final l10n = AppLocalizations.of(context);
    final csv = vm.exportCsv(removedProduct: l10n.productRemoved, removedCart: l10n.cartRemoved);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exportCsv),
        content: SizedBox(
          width: 640,
          height: 360,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.exportCsvHelp(vm.events.length), style: IcText.bodyS.copyWith(color: IcColors.textSecondary)),
              const SizedBox(height: IcSpace.s12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(IcSpace.s12),
                  decoration: BoxDecoration(
                    color: IcColors.bgSurfaceSunken,
                    borderRadius: BorderRadius.circular(IcRadius.md),
                  ),
                  child: SingleChildScrollView(child: SelectableText(csv, style: IcText.mono)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IcButton(label: l10n.actionClose, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
          IcButton(
            label: l10n.copyCsv,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (context.mounted) {
                Navigator.of(context).pop();
                showMessage(context, l10n.csvCopied);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Figma filter button ("Carrinho: todos", "Período: outubro 2026").
class _MenuButton<T> extends StatelessWidget {
  const _MenuButton({required this.icon, required this.label, required this.items, required this.onSelected});
  final IcIcon icon;
  final String label;
  final List<(T, String)> items;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return IcButton(
      label: label,
      icon: icon,
      style: IcButtonStyle.secondary,
      onPressed: () async {
        final box = context.findRenderObject()! as RenderBox;
        final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
        final topLeft = box.localToGlobal(Offset(0, box.size.height + 4), ancestor: overlay);
        final picked = await showMenu<int>(
          context: context,
          position: RelativeRect.fromRect(topLeft & const Size(1, 1), Offset.zero & overlay.size),
          items: [for (final (i, item) in items.indexed) PopupMenuItem(value: i, child: Text(item.$2))],
        );
        if (picked != null) onSelected(items[picked].$1);
      },
    );
  }
}

class _ReportsTable extends StatelessWidget {
  const _ReportsTable({required this.vm});
  final ReportsHistoryViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = IcFormat.of(context);
    final reports = vm.reports;
    return FitDataTable(
      columns: [
        TableColumnSpec(l10n.columnReport, flex: 4),
        TableColumnSpec(l10n.columnCart, flex: 4),
        TableColumnSpec(l10n.columnDate, flex: 3),
        TableColumnSpec(l10n.columnState, flex: 3),
        TableColumnSpec(l10n.columnSignedBy, flex: 4),
        const TableColumnSpec('', width: 190, alignEnd: true),
      ],
      emptyText: l10n.reportsEmptyPeriod,
      onRowTap: (i) => ShellNavigationScope.of(context).openReport(reports[i].id),
      rows: [
        for (final r in reports)
          [
            CellText(reportTitle(l10n, r), primary: true),
            CellText(r.cartName),
            CellText(format.date(r.createdAt)),
            Align(
              alignment: Alignment.centerLeft,
              child: StatusPill(
                text: r.isSigned ? l10n.reportSigned : l10n.reportPendingSignatureShort,
                tone: r.isSigned ? PillTone.ok : PillTone.warning,
              ),
            ),
            CellText(r.isSigned ? '${r.signedByName ?? ''} · ${format.time(r.signedAt ?? r.createdAt)}' : '—'),
            r.isSigned
                ? IcButton(
                    label: l10n.downloadPdf,
                    icon: IcIcon.descarregar,
                    style: IcButtonStyle.ghost,
                    onPressed: () => downloadReportPdf(context, r),
                  )
                : IcButton(
                    label: l10n.actionOpen,
                    style: IcButtonStyle.secondary,
                    onPressed: () => ShellNavigationScope.of(context).openReport(r.id),
                  ),
          ],
      ],
    );
  }
}

class _EventsList extends StatelessWidget {
  const _EventsList({required this.vm});
  final ReportsHistoryViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final events = vm.events;
    final carts = vm.cartsById;
    final products = vm.productsById;
    if (events.isEmpty) return StateView.message(message: l10n.eventsEmptyPeriod, icon: IcIcon.historico);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (vm.eventsCapped) ...[
          Notice(kind: NoticeKind.info, title: l10n.eventsCapped(ReportsHistoryViewModel.eventLimit)),
          const SizedBox(height: IcSpace.s12),
        ],
        Expanded(
          child: FitList(
            itemCount: events.length,
            itemExtent: 64,
            spacing: 0,
            itemBuilder: (context, i) => DecoratedBox(
              decoration: BoxDecoration(
                color: IcColors.bgSurface,
                border: Border(
                  left: const BorderSide(color: IcColors.borderDefault),
                  right: const BorderSide(color: IcColors.borderDefault),
                  top: BorderSide(color: i == 0 ? IcColors.borderDefault : IcColors.bgSurfaceMuted),
                  bottom: const BorderSide(color: IcColors.borderDefault),
                ),
              ),
              child: buildEventRow(context, event: events[i], carts: carts, products: products, position: vm.positionOf(events[i])),
            ),
          ),
        ),
      ],
    );
  }
}

class _Statistics extends StatelessWidget {
  const _Statistics({required this.vm});
  final ReportsHistoryViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final products = vm.productSummary(removedLabel: l10n.productRemoved).where((p) => p.consumed > 0 || p.replenished > 0).take(10).toList();
    final carts = vm.cartSummary(removedLabel: l10n.cartRemoved);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: MetricTile(label: l10n.statConsumed, value: '${vm.consumedUnits}')),
            const SizedBox(width: IcSpace.s12),
            Expanded(child: MetricTile(label: l10n.statReplenished, value: '${vm.replenishedUnits}')),
            const SizedBox(width: IcSpace.s12),
            Expanded(child: MetricTile(label: l10n.statChecks, value: '${vm.checksDone}')),
            const SizedBox(width: IcSpace.s12),
            Expanded(
              child: MetricTile(
                label: l10n.statEmergencies,
                value: '${vm.emergencies}',
                tone: vm.emergencies > 0 ? MetricTone.danger : MetricTone.neutral,
              ),
            ),
            const SizedBox(width: IcSpace.s12),
            Expanded(
              child: MetricTile(
                label: l10n.statPendingSignatures,
                value: '${vm.pendingSignatures}',
                tone: vm.pendingSignatures > 0 ? MetricTone.warning : MetricTone.neutral,
              ),
            ),
          ],
        ),
        const SizedBox(height: IcSpace.s24),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatTable(
                  title: l10n.statTopProducts,
                  firstColumn: l10n.productLabel,
                  emptyText: l10n.eventsEmptyPeriod,
                  consumedLabel: l10n.statConsumed,
                  replenishedLabel: l10n.statReplenished,
                  rows: [
                    for (final p in products)
                      [
                        _BarCell(label: p.productName, value: p.consumed, max: products.first.consumed),
                        CellText('${p.consumed}'),
                        CellText('${p.replenished}'),
                      ],
                  ],
                ),
              ),
              const SizedBox(width: IcSpace.s20),
              Expanded(
                child: _StatTable(
                  title: l10n.statByCart,
                  firstColumn: l10n.columnCart,
                  emptyText: l10n.eventsEmptyPeriod,
                  consumedLabel: l10n.statConsumed,
                  replenishedLabel: l10n.statReplenished,
                  rows: [
                    for (final c in carts)
                      [
                        CellText(c.cartName, primary: true),
                        CellText('${c.consumed}'),
                        CellText('${c.replenished}'),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Section title + paged table (statistics tab).
class _StatTable extends StatelessWidget {
  const _StatTable({
    required this.title,
    required this.firstColumn,
    required this.consumedLabel,
    required this.replenishedLabel,
    required this.emptyText,
    required this.rows,
  });

  final String title;
  final String firstColumn;
  final String consumedLabel;
  final String replenishedLabel;
  final String emptyText;
  final List<List<Widget>> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(title),
        const SizedBox(height: IcSpace.s12),
        Expanded(
          child: FitDataTable(
            columns: [
              TableColumnSpec(firstColumn, flex: 5),
              TableColumnSpec(consumedLabel, flex: 2, alignEnd: true),
              TableColumnSpec(replenishedLabel, flex: 2, alignEnd: true),
            ],
            emptyText: emptyText,
            rows: rows,
          ),
        ),
      ],
    );
  }
}

/// Product name over a thin bar proportional to consumption.
class _BarCell extends StatelessWidget {
  const _BarCell({required this.label, required this.value, required this.max});
  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    final fraction = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: IcText.labelM, overflow: TextOverflow.ellipsis),
        const SizedBox(height: IcSpace.s4),
        ClipRRect(
          borderRadius: BorderRadius.circular(IcRadius.full),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: IcColors.bgSurfaceSunken,
            color: IcColors.actionPrimary,
          ),
        ),
      ],
    );
  }
}
