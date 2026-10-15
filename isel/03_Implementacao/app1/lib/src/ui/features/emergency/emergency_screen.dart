import 'dart:math';

import 'package:flutter/material.dart';

import '../../../common/app_services.dart';
import '../../../common/l10n/app_localizations.dart';
import '../../../domain/inventory_health.dart';
import '../../core/format.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/fit.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/slot_grid.dart';
import '../../core/widgets/status.dart';
import '../../shells/shell_navigation.dart';
import '../reports/report_screen.dart';
import 'emergency_view_model.dart';

/// A10 · Modo de emergência.
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key, required this.cartId});
  final String cartId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.read(context);
    final sync = AppServicesScope.of(context).sync;
    return ViewModelBuilder<EmergencyViewModel>(
      create: (services) => EmergencyViewModel(services, session, cartId),
      builder: (context, vm) {
        final emergency = vm.emergency;
        if (!vm.ready) return const StateView.loading();
        if (emergency == null) {
          return StateView.message(message: l10n.emergencyNotActive, icon: IcIcon.emergencia);
        }
        final format = IcFormat.of(context);
        final compact = isCompactHeight(context);
        final minutes = max(0, DateTime.now().difference(emergency.startedAt).inMinutes);
        return Padding(
          padding: contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Red header (Figma "Modo de emergência · …").
              Container(
                padding: EdgeInsets.symmetric(horizontal: IcSpace.s20, vertical: compact ? IcSpace.s8 : 14),
                decoration: BoxDecoration(color: IcColors.emergencyBg, borderRadius: BorderRadius.circular(IcRadius.lg)),
                child: Row(
                  children: [
                    const IcIconView(IcIcon.emergencia, color: IcColors.emergencyFg),
                    const SizedBox(width: IcSpace.s16),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.emergencyHeader(emergency.cartName), style: IcText.titleS.copyWith(color: IcColors.emergencyFg)),
                            if (!compact)
                              Text(
                                l10n.emergencyStarted(format.time(emergency.startedAt), minutes, emergency.startedByName),
                                style: IcText.bodyS.copyWith(color: IcColors.red100),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Material(
                      color: IcColors.bgSurface,
                      borderRadius: BorderRadius.circular(IcRadius.md),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(IcRadius.md),
                        onTap: vm.busy ? null : () => _end(context, vm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: IcSpace.s16, vertical: IcSpace.s12),
                          child: Text(l10n.emergencyEnd, style: IcText.labelL.copyWith(color: IcColors.dangerFg)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? IcSpace.s12 : IcSpace.s20),
              if (vm.drawers.length > 1) ...[
                SegmentedTabs<int>(
                  selected: vm.drawerIndex,
                  onChanged: vm.selectDrawer,
                  items: [for (var i = 0; i < vm.drawers.length; i++) TabItem(i, l10n.drawerShort(i + 1))],
                ),
                SizedBox(height: compact ? IcSpace.s8 : IcSpace.s16),
              ],
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!compact) ...[
                            Text(l10n.emergencyHelp, style: IcText.bodyS.copyWith(color: IcColors.textSecondary)),
                            const SizedBox(height: IcSpace.s8),
                          ],
                          Expanded(child: _Grid(vm: vm)),
                        ],
                      ),
                    ),
                    SizedBox(width: compact ? IcSpace.s12 : IcSpace.s20),
                    SidePanel(
                      child: ListenableBuilder(
                        listenable: sync,
                        builder: (context, _) => _Log(vm: vm, pending: sync.pendingWrites),
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

  Future<void> _end(BuildContext context, EmergencyViewModel vm) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirmAction(
      context,
      title: l10n.emergencyEnd,
      message: l10n.emergencyEndConfirm,
      confirmLabel: l10n.emergencyEnd,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final result = await vm.end();
    if (!context.mounted) return;
    if (!result.isOk) return showResult(context, result);
    final reportId = result.value;
    if (reportId == null) {
      Navigator.of(context).maybePop();
    } else {
      Navigator.of(context).pushReplacement(sectionRoute((_) => ReportScreen(reportId: reportId)));
    }
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.vm});
  final EmergencyViewModel vm;

  Future<void> _consume(BuildContext context, SlotCellData cell, int units) async {
    final l10n = AppLocalizations.of(context);
    final result = await vm.consume(cell, units);
    if (!context.mounted) return;
    if (!result.isOk) {
      showResult(context, result, failure: result.code == 'empty' ? l10n.emergencyNothingLeft : null);
    }
  }

  Future<void> _askQuantity(BuildContext context, SlotCellData cell) async {
    final l10n = AppLocalizations.of(context);
    var value = 1;
    final units = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(cell.productName ?? ''),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.quantityLabel, style: IcText.bodyM),
              const SizedBox(width: IcSpace.s16),
              QuantityStepper(
                label: l10n.quantityLabel,
                value: value,
                min: 1,
                max: max(1, cell.current ?? 1),
                onChanged: (v) => setState(() => value = v),
              ),
            ],
          ),
          actions: [
            IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
            IcButton(label: l10n.confirmConsumption, onPressed: () => Navigator.of(context).pop(value)),
          ],
        ),
      ),
    );
    if (units != null && context.mounted) await _consume(context, cell, units);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cells = vm.cells;
    if (cells.isEmpty) return StateView.message(message: l10n.monthlyCheckEmptyDrawer, icon: IcIcon.gaveta);
    final compact = isCompactHeight(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = IcSpace.s12;
        Widget cellAt(SlotCellData cell, double width, double height) => SizedBox(
              width: width,
              height: height,
              child: SlotCell(
                data: cell,
                selected: false,
                compact: compact,
                onTap: () => _consume(context, cell, 1),
                onLongPress: () => _askQuantity(context, cell),
              ),
            );
        if (compact || !constraints.maxHeight.isFinite) {
          // Phone: 3 columns, scroll vertically.
          const columns = 3;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return SingleChildScrollView(
            child: Wrap(spacing: gap, runSpacing: gap, children: [for (final cell in cells) cellAt(cell, width, 64)]),
          );
        }
        // Tablet and larger: pick the column count that gives the biggest
        // cells while every product stays on screen (no scrolling).
        final n = cells.length;
        var best = (columns: 1, width: 0.0, height: 0.0, score: -1.0);
        for (var c = 1; c <= n; c++) {
          final r = (n / c).ceil();
          final w = (constraints.maxWidth - gap * (c - 1)) / c;
          final h = min((constraints.maxHeight - gap * (r - 1)) / r, 96.0);
          if (w <= 0 || h <= 0) continue;
          final score = min(w / 2.2, h);
          if (score > best.score) best = (columns: c, width: w, height: h, score: score);
        }
        return Align(
          alignment: Alignment.topLeft,
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [for (final cell in cells) cellAt(cell, best.width, best.height)],
          ),
        );
      },
    );
  }
}

class _Log extends StatelessWidget {
  const _Log({required this.vm, required this.pending});
  final EmergencyViewModel vm;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totals = vm.emergency?.totalsByProduct() ?? const [];
    final count = totals.fold<int>(0, (sum, t) => sum + t.$3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.emergencyConsumptions(count), style: IcText.titleS),
        const SizedBox(height: IcSpace.s12),
        Expanded(
          child: FitList(
            itemCount: totals.length,
            itemExtent: 28,
            spacing: 0,
            itemBuilder: (context, i) {
              final (_, name, amount) = totals[i];
              return Row(
                children: [
                  Expanded(child: Text(name, style: IcText.bodyS, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text(IcFormat.signed(-amount), style: IcText.labelM.copyWith(color: IcColors.dangerFg)),
                ],
              );
            },
          ),
        ),
        if (vm.failedWrites > 0) ...[
          Notice(kind: NoticeKind.warning, title: l10n.emergencyNotSent(vm.failedWrites)),
          const SizedBox(height: IcSpace.s8),
        ],
        if (pending > 0) ...[
          ToneLine(tone: HealthTone.warning, icon: IcIcon.relogio, text: l10n.syncPending(pending), style: IcText.bodyS),
          const SizedBox(height: IcSpace.s12),
        ],
        IcButton(
          label: l10n.undoLast,
          icon: IcIcon.voltar,
          style: IcButtonStyle.secondary,
          expand: true,
          onPressed: totals.isEmpty || vm.busy
              ? null
              : () async {
                  final result = await vm.undoLast();
                  if (context.mounted && !result.isOk) showResult(context, result);
                },
        ),
      ],
    );
  }
}
