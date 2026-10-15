import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/shift.dart';
import '../../core/format.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/fit.dart';
import '../../core/widgets/layout.dart';
import 'shifts_view_model.dart';

String shiftLetter(AppLocalizations l10n, ShiftPeriod p) => switch (p) {
      ShiftPeriod.morning => l10n.shiftMorningShort,
      ShiftPeriod.afternoon => l10n.shiftAfternoonShort,
      ShiftPeriod.night => l10n.shiftNightShort,
    };

String shiftName(AppLocalizations l10n, ShiftPeriod p) => switch (p) {
      ShiftPeriod.morning => l10n.shiftMorning,
      ShiftPeriod.afternoon => l10n.shiftAfternoon,
      ShiftPeriod.night => l10n.shiftNight,
    };

/// Display order matches the Figma (M, T, N).
const _periods = [ShiftPeriod.morning, ShiftPeriod.afternoon, ShiftPeriod.night];

/// B8 · Turnos.
class ShiftsScreen extends StatelessWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.read(context);
    return ViewModelBuilder<ShiftsViewModel>(
      create: (services) => ShiftsViewModel(services, session),
      builder: (context, vm) {
        final format = IcFormat.of(context);
        return Padding(
          padding: contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: l10n.shiftsTitle,
                subtitle: l10n.shiftsWeekOf(format.dayMonth(vm.weekStart), format.date(vm.weekEnd)),
                trailing: [
                  IcButton(label: l10n.previousWeek, icon: IcIcon.voltar, style: IcButtonStyle.secondary, onPressed: vm.previousWeek),
                  IcButton(label: l10n.nextWeek, icon: IcIcon.seguinte, style: IcButtonStyle.secondary, onPressed: vm.nextWeek),
                  if (vm.canEdit)
                    IcButton(label: l10n.addShift, icon: IcIcon.mais, onPressed: vm.carts.isEmpty ? null : () => _add(context, vm)),
                ],
              ),
              const SizedBox(height: IcSpace.s20),
              Row(
                children: [
                  SegmentedTabs<ShiftsView>(
                    selected: vm.view,
                    onChanged: vm.setView,
                    items: [
                      TabItem(ShiftsView.byCart, l10n.shiftsByCart),
                      TabItem(ShiftsView.byPerson, l10n.shiftsByPerson),
                    ],
                  ),
                  const Spacer(),
                  if (vm.canEdit)
                    TextButton(
                      onPressed: () async {
                        final result = await vm.copyPreviousWeek();
                        if (context.mounted) showResult(context, result, success: l10n.shiftsCopied(result.value ?? 0));
                      },
                      child: Text(l10n.copyPreviousWeek),
                    ),
                ],
              ),
              const SizedBox(height: IcSpace.s20),
              Expanded(
                child: switch (vm.state) {
                  LoadState.loading => const StateView.loading(),
                  LoadState.error => StateView.message(message: l10n.stateLoadError),
                  LoadState.ready => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: vm.view == ShiftsView.byCart ? _ByCart(vm: vm) : _ByPerson(vm: vm)),
                        const SizedBox(height: IcSpace.s12),
                        Text(l10n.shiftsLegend, style: IcText.bodyS.copyWith(color: IcColors.textMuted)),
                      ],
                    ),
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _add(BuildContext context, ShiftsViewModel vm) async {
    final l10n = AppLocalizations.of(context);
    final input = await _showShiftDialog(context, vm);
    if (input == null || !context.mounted) return;
    final result = await vm.assign(cartId: input.cartId, day: input.day, period: input.period, uid: input.uid);
    if (!context.mounted) return;
    showResult(context, result, success: l10n.shiftSaved);
  }
}

List<TableColumnSpec> _dayColumns(BuildContext context, ShiftsViewModel vm, String first) {
  final format = IcFormat.of(context);
  return [
    TableColumnSpec(first, flex: 3),
    for (final d in vm.days) TableColumnSpec(format.weekdayDay(d), flex: 2),
  ];
}

class _ByCart extends StatelessWidget {
  const _ByCart({required this.vm});
  final ShiftsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FitDataTable(
      rowHeight: 76,
      columns: _dayColumns(context, vm, l10n.columnCart),
      emptyText: l10n.dashboardCartsEmpty,
      rows: [
        for (final cart in vm.carts)
          [
            CellText(cart.name, primary: true),
            for (final day in vm.days)
              _DayCell(
                lines: [
                  for (final p in _periods)
                    (
                      '${shiftLetter(l10n, p)} · ${vm.shiftAt(cart.id, day, p) == null ? '—' : vm.shortName(vm.shiftAt(cart.id, day, p)!.uid)}',
                      vm.shiftAt(cart.id, day, p) == null,
                    ),
                ],
                onTap: vm.canEdit ? () => _editDay(context, cart.id, day) : null,
              ),
          ],
      ],
    );
  }

  Future<void> _editDay(BuildContext context, String cartId, DateTime day) async {
    final l10n = AppLocalizations.of(context);
    final input = await _showShiftDialog(context, vm, cartId: cartId, day: day);
    if (input == null || !context.mounted) return;
    final result = await vm.assign(cartId: input.cartId, day: input.day, period: input.period, uid: input.uid);
    if (!context.mounted) return;
    showResult(context, result, success: l10n.shiftSaved);
  }
}

class _ByPerson extends StatelessWidget {
  const _ByPerson({required this.vm});
  final ShiftsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FitDataTable(
      rowHeight: 76,
      columns: _dayColumns(context, vm, l10n.columnPerson),
      emptyText: l10n.shiftsNoneThisWeek,
      rows: [
        for (final person in vm.peopleThisWeek)
          [
            CellText(person.label, primary: true),
            for (final day in vm.days)
              _DayCell(
                lines: [
                  for (final s in vm.shiftsOfPerson(person.uid, day)) ('${shiftLetter(l10n, s.period)} · ${vm.cartName(s.cartId)}', false),
                ],
              ),
          ],
      ],
    );
  }
}

/// Figma "Turnos do dia": up to three short lines.
class _DayCell extends StatelessWidget {
  const _DayCell({required this.lines, this.onTap});
  final List<(String text, bool empty)> lines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (lines.isEmpty) Text('—', style: IcText.bodyS.copyWith(color: IcColors.textMuted)),
        for (final (text, empty) in lines)
          Text(
            text,
            style: IcText.bodyS.copyWith(color: empty ? IcColors.textMuted : IcColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(IcRadius.sm),
      child: Padding(padding: const EdgeInsets.all(IcSpace.s4), child: SizedBox(width: double.infinity, child: content)),
    );
  }
}

class _ShiftInput {
  const _ShiftInput(this.cartId, this.day, this.period, this.uid);
  final String cartId;
  final DateTime day;
  final ShiftPeriod period;

  /// `null` clears the shift.
  final String? uid;
}

Future<_ShiftInput?> _showShiftDialog(BuildContext context, ShiftsViewModel vm, {String? cartId, DateTime? day}) {
  final l10n = AppLocalizations.of(context);
  final format = IcFormat.of(context);
  var selectedCart = cartId ?? vm.carts.first.id;
  var selectedDay = day ?? vm.days.first;
  var period = ShiftPeriod.morning;
  String? uid = vm.shiftAt(selectedCart, selectedDay, period)?.uid;
  return showDialog<_ShiftInput>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        void refreshUid() => uid = vm.shiftAt(selectedCart, selectedDay, period)?.uid;
        return AlertDialog(
          title: Text(cartId == null ? l10n.addShift : '${vm.cartName(selectedCart)} · ${format.weekdayDay(selectedDay)}'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (cartId == null) ...[
                  Text(l10n.columnCart, style: IcText.labelS.copyWith(color: IcColors.textSecondary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCart,
                    isExpanded: true,
                    items: [for (final c in vm.carts) DropdownMenuItem(value: c.id, child: Text(c.name))],
                    onChanged: (v) => setState(() {
                      selectedCart = v ?? selectedCart;
                      refreshUid();
                    }),
                  ),
                  const SizedBox(height: IcSpace.s16),
                  Text(l10n.shiftDay, style: IcText.labelS.copyWith(color: IcColors.textSecondary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<DateTime>(
                    initialValue: selectedDay,
                    isExpanded: true,
                    items: [for (final d in vm.days) DropdownMenuItem(value: d, child: Text(format.longDate(d)))],
                    onChanged: (v) => setState(() {
                      selectedDay = v ?? selectedDay;
                      refreshUid();
                    }),
                  ),
                  const SizedBox(height: IcSpace.s16),
                ],
                SegmentedTabs<ShiftPeriod>(
                  selected: period,
                  onChanged: (v) => setState(() {
                    period = v;
                    refreshUid();
                  }),
                  items: [for (final p in _periods) TabItem(p, shiftName(l10n, p))],
                ),
                const SizedBox(height: IcSpace.s16),
                Text(l10n.shiftResponsible, style: IcText.labelS.copyWith(color: IcColors.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String?>(
                  key: ValueKey('$selectedCart|$selectedDay|$period'),
                  initialValue: uid,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem<String?>(value: null, child: Text(l10n.shiftNobody)),
                    for (final m in vm.members) DropdownMenuItem<String?>(value: m.uid, child: Text(m.label)),
                  ],
                  onChanged: (v) => setState(() => uid = v),
                ),
              ],
            ),
          ),
          actions: [
            IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
            IcButton(
              label: l10n.actionSave,
              onPressed: () => Navigator.of(context).pop(_ShiftInput(selectedCart, selectedDay, period, uid)),
            ),
          ],
        );
      },
    ),
  );
}
