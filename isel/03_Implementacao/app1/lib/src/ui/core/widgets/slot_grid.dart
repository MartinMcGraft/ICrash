import 'dart:math';

import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/slot.dart';
import '../../../domain/inventory_health.dart';
import '../icons/ic_icons.dart';
import '../theme/tokens.dart';
import 'status.dart';

/// What one cell shows.
class SlotCellData {
  const SlotCellData({
    required this.slot,
    required this.position,
    required this.health,
    this.productName,
    this.current,
    this.target,
  });

  final Slot slot;

  /// "A1", "B3"…
  final String position;
  final SlotHealth health;
  final String? productName;
  final int? current;
  final int? target;
}

/// Figma "Célula de posição": position, product name, quantity, a state
/// icon when not OK, and a 3 px focus border when selected. State is never
/// colour alone (icon + accessible label).
class SlotCell extends StatelessWidget {
  const SlotCell({
    super.key,
    required this.data,
    required this.selected,
    this.onTap,
    this.onLongPress,
    this.compact = false,
  });

  final SlotCellData data;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Phone layout: no position label, one-line name.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final health = data.health;
    final (Color bg, Color border, double borderWidth) = switch (health) {
      SlotHealth.ok => (IcColors.bgSurface, IcColors.borderDefault, 1.0),
      SlotHealth.expiring || SlotHealth.lowStock => (IcColors.warningBg, IcColors.warningAccent, 1.5),
      SlotHealth.expired || SlotHealth.missing => (IcColors.dangerBg, IcColors.dangerFg, 1.5),
      SlotHealth.free => (IcColors.bgSurfaceMuted, IcColors.borderStrong, 1.0),
    };
    final qtyColor = switch (health) {
      SlotHealth.expiring || SlotHealth.lowStock => IcColors.warningFg,
      SlotHealth.expired || SlotHealth.missing => IcColors.dangerFg,
      _ => IcColors.textSecondary,
    };
    final showIcon = health != SlotHealth.ok && health != SlotHealth.free;
    final name = data.productName ?? l10n.slotHealthFree;
    final qty = data.current == null ? '—' : '${data.current} / ${data.target}';

    final semantics = [
      data.position,
      name,
      if (data.current != null) l10n.slotQuantitySemantics(data.current!, data.target ?? 0),
      if (health != SlotHealth.ok) slotHealthText(l10n, health),
    ].join(', ');

    // The cell adapts to the space the grid gives it: tablets and larger
    // screens never scroll, so a 12-row drawer gets short cells.
    final content = LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        final icon = showIcon ? IcIconView(slotHealthIcon(health), size: 16, color: slotHealthFg(health)) : null;
        final nameStyle = IcText.labelM.copyWith(color: health == SlotHealth.free ? IcColors.textMuted : IcColors.textPrimary);
        final qtyText = Text(qty, style: IcText.labelS.copyWith(color: qtyColor), maxLines: 1);
        if (h.isFinite && h < 48) {
          // Tiny: one line, scaled down if needed.
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[icon, const SizedBox(width: 4)],
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: max(box.maxWidth - 40, 24)),
                    child: Text(name, style: nameStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 6),
                  qtyText,
                ],
              ),
            ),
          );
        }
        if (compact || (h.isFinite && h < 76)) {
          // Medium: name + icon on top, position + quantity below.
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: nameStyle)),
                    if (icon != null) ...[const SizedBox(width: 4), icon],
                  ],
                ),
                Row(
                  children: [
                    if (!compact) Expanded(child: Text(data.position, style: IcText.mono, maxLines: 1)) else const Spacer(),
                    qtyText,
                  ],
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 18,
                child: Row(
                  children: [
                    Expanded(child: Text(data.position, style: IcText.mono)),
                    ?icon,
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(name, maxLines: h > 100 ? 3 : 2, overflow: TextOverflow.ellipsis, style: nameStyle),
                ),
              ),
              qtyText,
            ],
          ),
        );
      },
    );

    final effectiveBorder = selected ? IcColors.borderFocus : border;
    final effectiveWidth = selected ? 3.0 : borderWidth;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semantics,
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: health == SlotHealth.free && !selected
            ? _DashedBorder(color: border, radius: IcRadius.md)
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(IcRadius.md),
                side: BorderSide(color: effectiveBorder, width: effectiveWidth),
              ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, onLongPress: onLongPress, child: content),
      ),
    );
  }
}

/// Lays out [cells] on the drawer's rows × columns grid, honouring merged
/// slots.
///
/// Layout rule (design change, 14 Oct 2026): the grid always fits the width
/// it is given (never scrolls sideways). On tablets and larger screens
/// ([compact] false) it also fits the height, so it never scrolls at all;
/// on phones ([compact] true) cells keep a minimum height and the grid may
/// scroll vertically.
class SlotGrid extends StatelessWidget {
  const SlotGrid({
    super.key,
    required this.rows,
    required this.columns,
    required this.cells,
    required this.selectedSlotIds,
    this.onTap,
    this.onLongPress,
    this.compact = false,
  });

  final int rows;
  final int columns;
  final List<SlotCellData> cells;
  final Set<String> selectedSlotIds;
  final ValueChanged<SlotCellData>? onTap;
  final ValueChanged<SlotCellData>? onLongPress;
  final bool compact;

  /// Cells never grow taller than this, so a 2 × 3 drawer doesn't get
  /// giant tiles.
  static const maxCellHeight = 120.0;

  /// Phone minimum before the grid starts scrolling vertically.
  static const phoneMinCellHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dense = rows > 6 || columns > 8;
        final gap = compact || dense ? 8.0 : 12.0;
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 104.0 * columns;
        final cellWidth = max((width - gap * (columns - 1)) / columns, 1.0);
        final fitHeight = constraints.maxHeight.isFinite
            ? (constraints.maxHeight - gap * (rows - 1)) / rows
            : (compact ? 58.0 : 92.0);
        final double cellHeight;
        if (compact) {
          cellHeight = fitHeight >= phoneMinCellHeight ? min(fitHeight, 90.0) : phoneMinCellHeight;
        } else {
          cellHeight = max(min(fitHeight, maxCellHeight), 1.0);
        }
        final totalWidth = cellWidth * columns + gap * (columns - 1);
        final totalHeight = cellHeight * rows + gap * (rows - 1);
        final grid = SizedBox(
          width: totalWidth,
          height: totalHeight,
          child: Stack(
            children: [
              for (final cell in cells)
                Positioned(
                  left: cell.slot.column * (cellWidth + gap),
                  top: cell.slot.row * (cellHeight + gap),
                  width: cell.slot.columnSpan * cellWidth + (cell.slot.columnSpan - 1) * gap,
                  height: cell.slot.rowSpan * cellHeight + (cell.slot.rowSpan - 1) * gap,
                  child: SlotCell(
                    data: cell,
                    compact: compact,
                    selected: selectedSlotIds.contains(cell.slot.id),
                    onTap: onTap == null ? null : () => onTap!(cell),
                    onLongPress: onLongPress == null ? null : () => onLongPress!(cell),
                  ),
                ),
            ],
          ),
        );
        final overflows = constraints.maxHeight.isFinite && totalHeight > constraints.maxHeight + 0.5;
        if (compact && overflows) {
          return Scrollbar(child: SingleChildScrollView(child: grid));
        }
        return Align(alignment: Alignment.topLeft, child: grid);
      },
    );
  }
}

/// Dashed rounded border for empty ("Livre") cells.
class _DashedBorder extends ShapeBorder {
  const _DashedBorder({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(1);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect.deflate(1), Radius.circular(radius)));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect.deflate(0.5), Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, min(distance + 4, metric.length)), paint);
        distance += 7;
      }
    }
  }

  @override
  ShapeBorder scale(double t) => _DashedBorder(color: color, radius: radius * t);
}
