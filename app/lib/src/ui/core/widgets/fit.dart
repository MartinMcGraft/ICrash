import 'dart:math';

import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../icons/ic_icons.dart';
import '../theme/tokens.dart';
import 'ic_button.dart';
import 'layout.dart';

/// Screen classes used for the "no scrolling" layout rule:
///
/// - **phone** (landscape height < 500): content may scroll vertically.
/// - **tablet** and **desktop**: nothing scrolls. Grids shrink to fit,
///   long lists and tables are split into pages, side panels sit over the
///   drawer grid instead of beside it.
enum FormFactor { phone, tablet, desktop }

FormFactor formFactorOf(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  if (size.height < 500) return FormFactor.phone;
  if (size.width < 1360) return FormFactor.tablet;
  return FormFactor.desktop;
}

/// True only on phones: the one form factor where vertical scrolling is
/// allowed.
bool allowsScroll(BuildContext context) => formFactorOf(context) == FormFactor.phone;

/// Whether [text] fits on one line of [maxWidth] in [style], with the
/// device's text scale. Used to pick a long or a short label instead of
/// wrapping or cutting it (RV-13).
bool textFits(BuildContext context, String text, TextStyle style, double maxWidth) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: maxWidth);
  final fits = !painter.didExceedMaxLines;
  painter.dispose();
  return fits;
}

/// "1–10 de 212  ‹ ›".
class Pager extends StatelessWidget {
  const Pager({super.key, required this.page, required this.pageSize, required this.total, required this.onPage});

  /// Zero-based.
  final int page;
  final int pageSize;
  final int total;
  final ValueChanged<int> onPage;

  static const height = 48.0;

  int get pages => max(1, (total / pageSize).ceil());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final from = total == 0 ? 0 : page * pageSize + 1;
    final to = min(total, (page + 1) * pageSize);
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(l10n.pagerRange(from, to, total), style: IcText.bodyS.copyWith(color: IcColors.textSecondary)),
          const SizedBox(width: IcSpace.s12),
          Opacity(
            opacity: page > 0 ? 1 : 0.4,
            child: IcIconButton(
              icon: IcIcon.voltar,
              tooltip: l10n.pagerPrevious,
              size: 40,
              onPressed: page > 0 ? () => onPage(page - 1) : null,
            ),
          ),
          const SizedBox(width: IcSpace.s8),
          Opacity(
            opacity: page < pages - 1 ? 1 : 0.4,
            child: IcIconButton(
              icon: IcIcon.seguinte,
              tooltip: l10n.pagerNext,
              size: 40,
              onPressed: page < pages - 1 ? () => onPage(page + 1) : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// How many fixed-height items fit in [available], reserving room for a
/// [Pager] only when one is needed.
({int perPage, bool paged}) _fit({required double available, required double extent, required double spacing, required int columns, required int count}) {
  int rowsIn(double h) => max(1, ((h + spacing) / (extent + spacing)).floor());
  final all = rowsIn(available) * columns;
  if (count <= all) return (perPage: all, paged: false);
  return (perPage: rowsIn(available - Pager.height - IcSpace.s8) * columns, paged: true);
}

/// A list (or grid of equal cards) that scrolls on phones and is split into
/// pages that exactly fit the space on tablets and larger screens.
class FitList extends StatefulWidget {
  const FitList({
    super.key,
    required this.itemCount,
    required this.itemExtent,
    required this.itemBuilder,
    this.spacing = IcSpace.s8,
    this.columns = 1,
    this.minColumnWidth,
  });

  final int itemCount;

  /// Height of one item (all items are laid out with this height).
  final double itemExtent;
  final IndexedWidgetBuilder itemBuilder;
  final double spacing;

  /// Fixed column count, or computed from [minColumnWidth] when given.
  final int columns;
  final double? minColumnWidth;

  @override
  State<FitList> createState() => _FitListState();
}

class _FitListState extends State<FitList> {
  int _page = 0;

  int _columnsFor(double width) {
    final min = widget.minColumnWidth;
    if (min == null) return widget.columns;
    return max(1, ((width + widget.spacing) / (min + widget.spacing)).floor());
  }

  Widget _rows(int start, int end, int columns) {
    final children = <Widget>[];
    for (var i = start; i < end; i += columns) {
      if (children.isNotEmpty) children.add(SizedBox(height: widget.spacing));
      children.add(SizedBox(
        height: widget.itemExtent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var c = 0; c < columns; c++) ...[
              if (c > 0) SizedBox(width: widget.spacing),
              Expanded(child: i + c < end ? widget.itemBuilder(context, i + c) : const SizedBox.shrink()),
            ],
          ],
        ),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: children);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth);
        if (allowsScroll(context) || !constraints.maxHeight.isFinite) {
          return SingleChildScrollView(child: _rows(0, widget.itemCount, columns));
        }
        final fit = _fit(
          available: constraints.maxHeight,
          extent: widget.itemExtent,
          spacing: widget.spacing,
          columns: columns,
          count: widget.itemCount,
        );
        final pages = max(1, (widget.itemCount / fit.perPage).ceil());
        final page = min(_page, pages - 1);
        final start = page * fit.perPage;
        final end = min(widget.itemCount, start + fit.perPage);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _rows(start, end, columns),
            if (fit.paged) ...[
              const Spacer(),
              Pager(page: page, pageSize: fit.perPage, total: widget.itemCount, onPage: (p) => setState(() => _page = p)),
            ],
          ],
        );
      },
    );
  }
}

/// [DataTableCard] that scrolls on phones and pages its rows on tablets and
/// larger screens, so the page itself never scrolls.
class FitDataTable extends StatefulWidget {
  const FitDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.onRowTap,
    this.selectedIndex,
    this.emptyText,
    this.rowHeight = 60,
  });

  final List<TableColumnSpec> columns;
  final List<List<Widget>> rows;
  final ValueChanged<int>? onRowTap;
  final int? selectedIndex;
  final String? emptyText;
  final double rowHeight;

  @override
  State<FitDataTable> createState() => _FitDataTableState();
}

class _FitDataTableState extends State<FitDataTable> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (allowsScroll(context) || !constraints.maxHeight.isFinite) {
          return SingleChildScrollView(
            child: DataTableCard(
              columns: widget.columns,
              rows: widget.rows,
              onRowTap: widget.onRowTap,
              selectedIndex: widget.selectedIndex,
              emptyText: widget.emptyText,
            ),
          );
        }
        // Card border (1 px top + bottom) and header.
        final available = constraints.maxHeight - DataTableCard.headerHeight - 2;
        final fit = _fit(available: available, extent: widget.rowHeight, spacing: 0, columns: 1, count: widget.rows.length);
        final pages = max(1, (widget.rows.length / fit.perPage).ceil());
        final page = min(_page, pages - 1);
        final start = page * fit.perPage;
        final end = min(widget.rows.length, start + fit.perPage);
        final selected = widget.selectedIndex;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DataTableCard(
              columns: widget.columns,
              rows: widget.rows.sublist(start, end),
              rowHeight: widget.rowHeight,
              emptyText: widget.emptyText,
              selectedIndex: selected == null ? null : selected - start,
              onRowTap: widget.onRowTap == null ? null : (i) => widget.onRowTap!(start + i),
            ),
            if (fit.paged) ...[
              const Spacer(),
              Pager(page: page, pageSize: fit.perPage, total: widget.rows.length, onPage: (p) => setState(() => _page = p)),
            ],
          ],
        );
      },
    );
  }
}

/// Body with a right-hand panel that slides in *over* it (design change,
/// 14 Oct 2026): the drawer grid keeps the full width, so it never has to
/// scroll sideways. The panel only shows while there is something to show.
class OverlayPanelLayout extends StatelessWidget {
  const OverlayPanelLayout({
    super.key,
    required this.body,
    required this.panel,
    required this.onClose,
    this.panelWidth = 360,
    this.phonePanelWidth,
  });

  final Widget body;

  /// Null hides the panel.
  final Widget? panel;
  final VoidCallback onClose;
  final double panelWidth;

  /// On a phone the panel is at most 300 px (and 60 % of the width) so the
  /// grid stays visible. A form that needs room (A7 "Repor stock", 2 Nov 2026)
  /// asks for more here: up to 80 % of the width.
  final double? phonePanelWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phone = allowsScroll(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = phonePanelWidth;
        final width = !phone
            ? min(panelWidth, constraints.maxWidth * 0.5)
            : wide != null
                ? min(wide, constraints.maxWidth * 0.8)
                : min(min(panelWidth, 300.0), constraints.maxWidth * 0.6);
        return Stack(
          children: [
            Positioned.fill(child: body),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: width,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: panel == null
                    ? const SizedBox.shrink()
                    : DecoratedBox(
                        key: const ValueKey('panel'),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(IcRadius.lg),
                          boxShadow: const [
                            BoxShadow(color: Color(0x241E1D1A), offset: Offset(-4, 4), blurRadius: 24),
                          ],
                        ),
                        child: Material(
                          color: IcColors.bgSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(IcRadius.lg),
                            side: const BorderSide(color: IcColors.borderDefault),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  phone ? IcSpace.s12 : IcSpace.s20,
                                  phone ? IcSpace.s12 : IcSpace.s20,
                                  phone ? IcSpace.s12 : IcSpace.s20,
                                  phone ? IcSpace.s12 : IcSpace.s20,
                                ),
                                child: panel,
                              ),
                              Positioned(
                                top: IcSpace.s4,
                                right: IcSpace.s4,
                                child: IconButton(
                                  tooltip: l10n.closePanel,
                                  onPressed: onClose,
                                  icon: const IcIconView(IcIcon.fechar, size: 20, color: IcColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Body with a right-hand panel docked **beside** it (D26, 2 Nov 2026).
///
/// Used by the Dashboard's B4 "Editar grelha": there the panel stays open
/// while positions are picked, merged and split, and [OverlayPanelLayout]
/// covered the right-hand positions so they couldn't be reached. Here the
/// panel takes its own column and the grid (which always fits the width it
/// is given) shrinks into the rest, as in the Figma B4 frame and Material
/// 3's "supporting pane" layout: nothing scrolls sideways and no position is
/// covered. The App (A6/A7) keeps [OverlayPanelLayout].
///
/// Width: at most [panelWidth] and 40 % of the width (Material 3 gives a
/// supporting pane about 30 % of an expanded window); on a phone-sized
/// window at most 300 px and 50 %.
class SidePanelLayout extends StatelessWidget {
  const SidePanelLayout({
    super.key,
    required this.body,
    required this.panel,
    required this.onClose,
    this.panelWidth = 360,
  });

  /// Key of the open panel, for tests.
  static const panelKey = ValueKey('side-panel');

  final Widget body;

  /// Null hides the panel and gives the body the full width.
  final Widget? panel;
  final VoidCallback onClose;
  final double panelWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phone = allowsScroll(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = phone ? min(min(panelWidth, 300.0), constraints.maxWidth * 0.5) : min(panelWidth, constraints.maxWidth * 0.4);
        final gap = phone ? IcSpace.s12 : IcSpace.s20;
        final pad = phone ? IcSpace.s12 : IcSpace.s20;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: body),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              // Opening/closing only: the panel grows from 0 to its width and
              // the grid reflows with it. Changing the selection keeps it open.
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                axis: Axis.horizontal,
                alignment: Alignment.centerLeft,
                child: child,
              ),
              // Passthrough: the Row gives this column the full height.
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.passthrough,
                alignment: Alignment.centerLeft,
                children: [...previous, ?current],
              ),
              child: panel == null
                  ? const SizedBox.shrink(key: ValueKey('no-panel'))
                  : Padding(
                      key: const ValueKey('panel'),
                      padding: EdgeInsets.only(left: gap),
                      child: SizedBox(
                        key: panelKey,
                        width: width,
                        height: double.infinity,
                        child: Material(
                          color: IcColors.bgSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(IcRadius.lg),
                            side: const BorderSide(color: IcColors.borderDefault),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Padding(padding: EdgeInsets.all(pad), child: panel),
                              Positioned(
                                top: IcSpace.s4,
                                right: IcSpace.s4,
                                child: IconButton(
                                  tooltip: l10n.closePanel,
                                  onPressed: onClose,
                                  icon: const IcIconView(IcIcon.fechar, size: 20, color: IcColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
