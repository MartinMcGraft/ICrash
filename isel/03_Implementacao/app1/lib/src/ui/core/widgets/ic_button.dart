import 'package:flutter/material.dart';

import '../icons/ic_icons.dart';
import '../theme/tokens.dart';

enum IcButtonStyle { primary, secondary, danger, ghost }

enum IcButtonSize { m, l }

/// Figma component "Botão" (Estilo × Tamanho, optional icon).
class IcButton extends StatelessWidget {
  const IcButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = IcButtonStyle.primary,
    this.size = IcButtonSize.m,
    this.icon,
    this.expand = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IcButtonStyle style;
  final IcButtonSize size;
  final IcIcon? icon;

  /// Fill the available width (side-panel buttons).
  final bool expand;

  /// Shows a spinner and disables the button.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (style) {
      IcButtonStyle.primary => (IcColors.actionPrimary, IcColors.textOnDark, null),
      IcButtonStyle.secondary => (IcColors.actionSecondary, IcColors.textLink, null),
      IcButtonStyle.danger => (IcColors.actionDanger, IcColors.textOnDark, null),
      IcButtonStyle.ghost => (Colors.transparent, IcColors.textPrimary, IcColors.borderStrong),
    };
    final large = size == IcButtonSize.l;
    final enabled = onPressed != null && !busy;
    final textStyle = (large ? IcText.labelL : IcText.labelM).copyWith(color: fg);
    final iconSize = large ? 22.0 : 20.0;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox.square(dimension: iconSize - 4, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        else if (icon != null)
          IcIconView(icon!, size: iconSize, color: fg),
        if (busy || icon != null) const SizedBox(width: IcSpace.s8),
        Flexible(child: Text(label, style: textStyle, overflow: TextOverflow.ellipsis, maxLines: 1)),
      ],
    );

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IcRadius.md),
          side: border == null ? BorderSide.none : BorderSide(color: border, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: large ? 56 : IcSize.touchMin),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: large ? IcSpace.s24 : IcSpace.s20, vertical: IcSpace.s12),
              child: Center(widthFactor: expand ? null : 1, child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square icon button (e.g. the 48 px "Voltar" in the page header, or the
/// scan button beside a field).
class IcIconButton extends StatelessWidget {
  const IcIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.background = IcColors.bgSurface,
    this.foreground = IcColors.textPrimary,
    this.bordered = true,
    this.size = IcSize.touchMin,
  });

  final IcIcon icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color background;
  final Color foreground;
  final bool bordered;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IcRadius.md),
          side: bordered ? const BorderSide(color: IcColors.borderDefault) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Center(child: IcIconView(icon, size: 22, color: foreground, semanticLabel: tooltip)),
          ),
        ),
      ),
    );
  }
}
