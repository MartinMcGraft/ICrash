import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/cart_status.dart';
import '../../../domain/inventory_health.dart';
import '../../core/format.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/status.dart';
import 'carts_view_model.dart';

/// The single alert line of a cart (audit F5: one line, not six metrics).
(HealthTone tone, IcIcon icon, String text) cartAlertLine(AppLocalizations l10n, CartSummary s) {
  final c = s.counts;
  if (c.expired > 0 || c.missing > 0) {
    final parts = [
      if (c.expired > 0) l10n.countExpired(c.expired),
      if (c.missing > 0) l10n.countMissing(c.missing),
    ];
    return (HealthTone.danger, IcIcon.alerta, parts.join(' · '));
  }
  if (c.expiring > 0) return (HealthTone.warning, IcIcon.relogio, l10n.countExpiring(c.expiring));
  if (s.checkOverdueDays != null) return (HealthTone.warning, IcIcon.relogio, l10n.checkOverdueDays(s.checkOverdueDays!));
  if (c.lowStock > 0) return (HealthTone.warning, IcIcon.menos, l10n.countLowStock(c.lowStock));
  if (s.cart.status == CartStatus.outOfService) return (HealthTone.ok, IcIcon.okCirculo, l10n.noStockAlerts);
  return (HealthTone.ok, IcIcon.okCirculo, l10n.allCompliant);
}

/// Drawer row summary (A5): "Conforme", "1 expirado · 2 em falta", "2 a expirar".
(HealthTone tone, IcIcon icon, String text) drawerSummaryLine(AppLocalizations l10n, HealthCounts c) {
  if (c.expired > 0 || c.missing > 0) {
    return (
      HealthTone.danger,
      IcIcon.alerta,
      [if (c.expired > 0) l10n.countExpired(c.expired), if (c.missing > 0) l10n.countMissing(c.missing)].join(' · '),
    );
  }
  if (c.expiring > 0) return (HealthTone.warning, IcIcon.relogio, l10n.countExpiring(c.expiring));
  if (c.lowStock > 0) return (HealthTone.warning, IcIcon.menos, l10n.countLowStock(c.lowStock));
  return (HealthTone.ok, IcIcon.okCirculo, l10n.compliant);
}

/// "Verificação mensal: 02 out · Ana Silva".
String lastCheckLine(AppLocalizations l10n, IcFormat format, CartSummary s) {
  final check = s.lastCheck;
  if (check == null) return l10n.lastCheckNever;
  return l10n.lastCheckLine(format.dayMonth(check.createdAt), check.createdByName);
}

/// Figma "Cartão de carro".
class CartCard extends StatelessWidget {
  const CartCard({super.key, required this.summary, required this.onTap});

  /// Fixed height so cards line up and lists can be paged (no scrolling
  /// on tablets).
  static const height = 192.0;

  final CartSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = IcFormat.of(context);
    final (tone, icon, text) = cartAlertLine(l10n, summary);
    final place = summary.cart.placeLabel;
    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: IcSpace.s20, vertical: IcSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary.cart.name, style: IcText.titleS, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (place != null) ...[
                      const SizedBox(height: 2),
                      Text(place, style: IcText.bodyS.copyWith(color: IcColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: IcSpace.s8),
              Flexible(child: CartStateChip(status: summary.cart.status, emergencyActive: summary.emergencyActive)),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),
          ToneLine(tone: tone, icon: icon, text: text),
          const SizedBox(height: 10),
          Text(lastCheckLine(l10n, format, summary), style: IcText.bodyS.copyWith(color: IcColors.textMuted)),
        ],
      ),
    );
  }
}
