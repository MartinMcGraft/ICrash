import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/l10n/app_localizations.dart';
import '../check_state.dart';
import '../icons/ic_icons.dart';
import '../theme/tokens.dart';
import 'ic_button.dart';

export '../check_state.dart';

/// Content padding of every App/Dashboard screen (Figma "Conteúdo":
/// 28 vertical, 32 horizontal; 16/20 on phone).
EdgeInsets contentPadding(BuildContext context) {
  final compact = MediaQuery.sizeOf(context).height < 500;
  return compact
      ? const EdgeInsets.fromLTRB(IcSpace.s16, IcSpace.s16, IcSpace.s16, IcSpace.s16)
      : const EdgeInsets.fromLTRB(IcSpace.s32, 28, IcSpace.s32, 28);
}

bool isCompactHeight(BuildContext context) => MediaQuery.sizeOf(context).height < 500;

/// Figma "Cabeçalho de página": optional back button, title, subtitle.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.onBack, this.trailing = const []});

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  /// Right-aligned actions (sync indicator, buttons, search…).
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactHeight(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (onBack != null) ...[
          IcIconButton(icon: IcIcon.voltar, tooltip: AppLocalizations.of(context).actionBackTooltip, onPressed: onBack),
          const SizedBox(width: IcSpace.s12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: compact ? IcText.titleM : IcText.titleL, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: (compact ? IcText.bodyS : IcText.bodyM).copyWith(color: IcColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        for (final widget in trailing) ...[const SizedBox(width: IcSpace.s12), widget],
      ],
    );
  }
}

/// White surface with the default border, radius 14 and elevation 1.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(IcSpace.s16),
    this.onTap,
    this.borderColor = IcColors.borderDefault,
    this.borderWidth = 1,
    this.color = IcColors.bgSurface,
    this.elevated = true,
    this.radius = IcRadius.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color borderColor;
  final double borderWidth;
  final Color color;
  final bool elevated;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: elevated ? icElevation1 : null,
      ),
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: borderColor, width: borderWidth),
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? Padding(padding: padding, child: child) : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

/// Right-hand column panel (cart menu, slot detail, report signing…).
class SidePanel extends StatelessWidget {
  const SidePanel({super.key, required this.child, this.width = 340, this.padding = const EdgeInsets.all(IcSpace.s20)});

  final Widget child;
  final double width;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactHeight(context);
    return SizedBox(
      width: compact ? width * 0.7 : width,
      child: SurfaceCard(
        elevated: false,
        padding: compact ? const EdgeInsets.all(IcSpace.s12) : padding,
        child: child,
      ),
    );
  }
}

class TabItem<T> {
  const TabItem(this.value, this.label);
  final T value;
  final String label;
}

/// Figma "Filtros" / "Separador" segmented tabs.
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({super.key, required this.items, required this.selected, required this.onChanged});

  final List<TabItem<T>> items;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(IcSpace.s4),
      decoration: BoxDecoration(color: IcColors.bgSurfaceMuted, borderRadius: BorderRadius.circular(IcRadius.md)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, item) in items.indexed) ...[
              if (index > 0) const SizedBox(width: IcSpace.s4),
              _Segment(
                label: item.label,
                active: item.value == selected,
                onTap: () => onChanged(item.value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: active,
      button: true,
      child: Material(
        color: active ? IcColors.actionPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: IcSpace.s16),
            alignment: Alignment.center,
            child: Text(label, style: IcText.labelM.copyWith(color: active ? IcColors.textOnDark : IcColors.textSecondary)),
          ),
        ),
      ),
    );
  }
}

/// Figma "Pesquisa".
class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.hint, required this.onChanged, this.width = 320, this.controller, this.autofocus = false});

  final String hint;
  final ValueChanged<String> onChanged;
  final double? width;
  final TextEditingController? controller;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: IcSize.touchMin,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        style: IcText.bodyM,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 8),
            child: IcIconView(IcIcon.pesquisar, size: 20, color: IcColors.textMuted),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 20),
        ),
      ),
    );
  }
}

/// Figma "Campo": small label above a 48 px box.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.onSubmitted,
    this.onChanged,
    this.autofillHints,
    this.trailing,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
    this.autofocus = false,
    this.initialValue,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;

  /// Widget beside the box (e.g. a scan button).
  final Widget? trailing;
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      autofillHints: autofillHints,
      readOnly: readOnly,
      onTap: onTap,
      inputFormatters: inputFormatters,
      autofocus: autofocus,
      style: IcText.bodyM,
      decoration: InputDecoration(hintText: hint),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: IcText.labelS.copyWith(color: IcColors.textSecondary)),
        const SizedBox(height: 6),
        if (trailing == null) field else Row(children: [Expanded(child: field), const SizedBox(width: IcSpace.s8), trailing!]),
      ],
    );
  }
}

/// Figma "Quantidade": − value + (48 px buttons).
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({super.key, required this.value, required this.onChanged, this.min = 0, this.max = 9999, required this.label});

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  /// Accessible name ("Quantidade").
  final String label;

  @override
  Widget build(BuildContext context) {
    Widget button(IcIcon icon, VoidCallback? onTap, String tooltip) => IcIconButton(
          icon: icon,
          tooltip: tooltip,
          onPressed: onTap,
          background: IcColors.actionSecondary,
          foreground: onTap == null ? IcColors.textMuted : IcColors.textLink,
        );
    return Semantics(
      label: label,
      value: '$value',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(IcIcon.menos, value > min ? () => onChanged(value - 1) : null, '−'),
          SizedBox(
            width: 64,
            child: Text('$value', textAlign: TextAlign.center, style: IcText.numberL),
          ),
          button(IcIcon.mais, value < max ? () => onChanged(value + 1) : null, '+'),
        ],
      ),
    );
  }
}


/// Figma "Caixa de verificação" (por verificar / verificado / problema).
class CheckBox3 extends StatelessWidget {
  const CheckBox3({super.key, required this.state, this.size = 28});
  final CheckState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: switch (state) {
          CheckState.unchecked => IcColors.bgSurface,
          CheckState.checked => IcColors.okFg,
          CheckState.problem => IcColors.dangerFg,
        },
        borderRadius: BorderRadius.circular(IcRadius.sm),
        border: state == CheckState.unchecked ? Border.all(color: IcColors.borderStrong, width: 2) : null,
      ),
      alignment: Alignment.center,
      child: switch (state) {
        CheckState.unchecked => null,
        CheckState.checked => IcIconView(IcIcon.confirmar, size: size * 0.64, color: IcColors.textOnDark),
        CheckState.problem => IcIconView(IcIcon.alerta, size: size * 0.64, color: IcColors.textOnDark),
      },
    );
  }
}

/// Simple checkbox + label row (two-state), 48 px tall.
class CheckRow extends StatelessWidget {
  const CheckRow({super.key, required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: label,
      button: true,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(IcRadius.sm),
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: IcSize.touchMin),
          child: Row(
            children: [
              Opacity(
                opacity: onChanged == null ? 0.5 : 1,
                child: CheckBox3(state: value ? CheckState.checked : CheckState.unchecked),
              ),
              const SizedBox(width: IcSpace.s12),
              Expanded(child: Text(label, style: IcText.bodyM)),
            ],
          ),
        ),
      ),
    );
  }
}

enum MetricTone { neutral, ok, warning, danger }

/// Figma "Indicador".
class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.label, required this.value, this.caption, this.tone = MetricTone.neutral});

  final String label;
  final String value;
  final String? caption;
  final MetricTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      MetricTone.neutral => IcColors.textPrimary,
      MetricTone.ok => IcColors.okFg,
      MetricTone.warning => IcColors.warningFg,
      MetricTone.danger => IcColors.dangerFg,
    };
    return SurfaceCard(
      elevated: false,
      padding: const EdgeInsets.symmetric(horizontal: IcSpace.s20, vertical: IcSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: IcText.labelM.copyWith(color: IcColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: IcSpace.s4),
          Text(value, style: IcText.numberL.copyWith(color: color)),
          if (caption != null) ...[
            const SizedBox(height: IcSpace.s4),
            Text(caption!, style: IcText.bodyS.copyWith(color: IcColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

enum EventKind { consumption, replenishment, correction, check, emergency }

/// Figma "Linha de evento".
class EventRow extends StatelessWidget {
  const EventRow({
    super.key,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.when,
  });

  final EventKind kind;
  final String title;

  /// "Carro Urgência 1 › Gaveta 2 › B3 · Ana Silva".
  final String subtitle;

  /// "−2", "+2", "—".
  final String amount;
  final String when;

  @override
  Widget build(BuildContext context) {
    final (bg, icon, amountColor) = switch (kind) {
      EventKind.consumption => (IcColors.infoBg, IcIcon.menos, IcColors.infoFg),
      EventKind.replenishment => (IcColors.okBg, IcIcon.mais, IcColors.okFg),
      EventKind.correction => (IcColors.neutralBg, IcIcon.editar, IcColors.neutralFg),
      EventKind.check => (IcColors.okBg, IcIcon.calendario, IcColors.okFg),
      EventKind.emergency => (IcColors.dangerBg, IcIcon.emergencia, IcColors.dangerFg),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: IcSpace.s16, vertical: IcSpace.s12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
            alignment: Alignment.center,
            child: IcIconView(icon, size: 18, color: amountColor),
          ),
          const SizedBox(width: IcSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: IcText.labelM, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: IcText.bodyS.copyWith(color: IcColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: IcSpace.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: IcText.labelL.copyWith(color: amountColor)),
              const SizedBox(height: 2),
              Text(when, style: IcText.bodyS.copyWith(color: IcColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class TableColumnSpec {
  const TableColumnSpec(this.label, {this.flex = 1, this.width, this.alignEnd = false});
  final String label;
  final int flex;

  /// Fixed width instead of [flex].
  final double? width;
  final bool alignEnd;
}

/// Dashboard data table (Figma "Tabela": warm header row, 57 px rows).
class DataTableCard extends StatelessWidget {
  const DataTableCard({
    super.key,
    required this.columns,
    required this.rows,
    this.selectedIndex,
    this.onRowTap,
    this.emptyText,
    this.rowHeight,
  });

  final List<TableColumnSpec> columns;
  final List<List<Widget>> rows;
  final int? selectedIndex;
  final ValueChanged<int>? onRowTap;
  final String? emptyText;

  /// Fixed row height (border included). Used by [FitDataTable] to page rows
  /// so tables never scroll on tablets and larger screens.
  final double? rowHeight;

  /// Height of the header row (fixed so paging can be computed).
  static const headerHeight = 40.0;

  Widget _cell(TableColumnSpec spec, Widget child) {
    final aligned = Align(alignment: spec.alignEnd ? Alignment.centerRight : Alignment.centerLeft, child: child);
    return spec.width != null ? SizedBox(width: spec.width, child: aligned) : Expanded(flex: spec.flex, child: aligned);
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      elevated: false,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: IcColors.bgSurfaceMuted,
            height: headerHeight,
            padding: const EdgeInsets.symmetric(horizontal: IcSpace.s16),
            child: Row(
              children: [
                for (final (index, spec) in columns.indexed) ...[
                  if (index > 0) const SizedBox(width: IcSpace.s16),
                  _cell(spec, Text(spec.label, style: IcText.labelS.copyWith(color: IcColors.textSecondary))),
                ],
              ],
            ),
          ),
          if (rows.isEmpty && emptyText != null)
            Padding(
              padding: const EdgeInsets.all(IcSpace.s24),
              child: Text(emptyText!, style: IcText.bodyM.copyWith(color: IcColors.textSecondary)),
            ),
          for (final (rowIndex, cells) in rows.indexed)
            Material(
              color: rowIndex == selectedIndex ? IcColors.navy50 : IcColors.bgSurface,
              child: InkWell(
                onTap: onRowTap == null ? null : () => onRowTap!(rowIndex),
                child: Container(
                  constraints: rowHeight == null ? const BoxConstraints(minHeight: 56) : null,
                  height: rowHeight,
                  padding: EdgeInsets.symmetric(horizontal: IcSpace.s16, vertical: rowHeight == null ? IcSpace.s12 : 0),
                  decoration: BoxDecoration(
                    border: rowIndex == rows.length - 1 ? null : const Border(bottom: BorderSide(color: IcColors.borderDefault)),
                  ),
                  child: Row(
                    children: [
                      for (final (index, spec) in columns.indexed) ...[
                        if (index > 0) const SizedBox(width: IcSpace.s16),
                        _cell(spec, index < cells.length ? cells[index] : const SizedBox.shrink()),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Primary text cell / secondary text cell for [DataTableCard].
class CellText extends StatelessWidget {
  const CellText(this.text, {super.key, this.primary = false, this.color});
  final String text;
  final bool primary;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: primary ? IcText.labelM.copyWith(color: color) : IcText.bodyS.copyWith(color: color ?? IcColors.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
}

/// Loading / error / empty placeholders (Figma "04 · Padrões e estados").
class StateView extends StatelessWidget {
  const StateView.loading({super.key})
      : icon = null,
        message = null,
        onRetry = null,
        _loading = true;
  const StateView.message({super.key, required this.message, this.icon = IcIcon.info, this.onRetry}) : _loading = false;

  final IcIcon? icon;
  final String? message;
  final VoidCallback? onRetry;
  final bool _loading;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: Semantics(label: AppLocalizations.of(context).stateLoading, child: const CircularProgressIndicator()),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(IcSpace.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IcIconView(icon!, size: 32, color: IcColors.textMuted),
            const SizedBox(height: IcSpace.s12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(message!, textAlign: TextAlign.center, style: IcText.bodyM.copyWith(color: IcColors.textSecondary)),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: IcSpace.s16),
              IcButton(label: AppLocalizations.of(context).stateRetry, onPressed: onRetry, style: IcButtonStyle.secondary),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Section" title above a block (e.g. "Gavetas", "Carrinhos que precisam
/// de atenção").
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Semantics(header: true, child: Text(text, style: IcText.titleS))),
        ?trailing,
      ],
    );
  }
}

/// Key/value line (A6 detail panel, A9 report header).
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value, this.valueColor, this.bold = false});
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: IcText.bodyS.copyWith(color: IcColors.textSecondary))),
          const SizedBox(width: IcSpace.s12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: (bold ? IcText.labelM : IcText.bodyS).copyWith(color: valueColor ?? IcColors.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
