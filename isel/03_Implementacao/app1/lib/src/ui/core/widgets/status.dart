import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/cart_status.dart';
import '../../../domain/inventory_health.dart';
import '../icons/ic_icons.dart';
import '../theme/tokens.dart';

/// What the "Estado do carro" chip shows. [emergencyActive] is not a stored
/// cart status: it is shown while an emergency session is open on the cart.
enum CartDisplayState { operational, replenishmentRequired, checkOverdue, outOfService, emergencyActive }

CartDisplayState cartDisplayState(CartStatus status, {bool emergencyActive = false}) {
  if (emergencyActive) return CartDisplayState.emergencyActive;
  return switch (status) {
    CartStatus.operational => CartDisplayState.operational,
    CartStatus.replenishmentRequired => CartDisplayState.replenishmentRequired,
    CartStatus.auditRequired => CartDisplayState.checkOverdue,
    CartStatus.outOfService => CartDisplayState.outOfService,
  };
}

String cartStatusText(AppLocalizations l10n, CartStatus status) => switch (status) {
      CartStatus.operational => l10n.cartStatusOperational,
      CartStatus.replenishmentRequired => l10n.cartStatusReplenishmentRequired,
      CartStatus.auditRequired => l10n.cartStatusAuditRequired,
      CartStatus.outOfService => l10n.cartStatusOutOfService,
    };

class IcTone {
  const IcTone(this.fg, this.bg, this.icon);
  final Color fg;
  final Color bg;
  final IcIcon icon;
}

IcTone _cartTone(CartDisplayState state) => switch (state) {
      CartDisplayState.operational => const IcTone(IcColors.okFg, IcColors.okBg, IcIcon.okCirculo),
      CartDisplayState.replenishmentRequired => const IcTone(IcColors.warningFg, IcColors.warningBg, IcIcon.alerta),
      CartDisplayState.checkOverdue => const IcTone(IcColors.infoFg, IcColors.infoBg, IcIcon.relogio),
      CartDisplayState.outOfService => const IcTone(IcColors.neutralFg, IcColors.neutralBg, IcIcon.cadeado),
      CartDisplayState.emergencyActive => const IcTone(IcColors.dangerFg, IcColors.dangerBg, IcIcon.emergencia),
    };

/// Figma "Estado do carro": colour + icon + label, never colour alone.
class CartStateChip extends StatelessWidget {
  const CartStateChip({super.key, required this.status, this.emergencyActive = false, this.compact = false});

  final CartStatus status;
  final bool emergencyActive;

  /// Table variant (smaller padding).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = cartDisplayState(status, emergencyActive: emergencyActive);
    final tone = _cartTone(state);
    final label = state == CartDisplayState.emergencyActive ? l10n.cartStateEmergencyActive : cartStatusText(l10n, status);
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 28 : 32),
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : IcSpace.s12, vertical: IcSpace.s4),
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(IcRadius.full)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IcIconView(tone.icon, size: 16, color: tone.fg),
          const SizedBox(width: IcSpace.s8),
          Flexible(
            child: Text(label, style: IcText.labelM.copyWith(color: tone.fg), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

IcTone slotTone(SlotHealth health) => switch (health) {
      SlotHealth.ok => const IcTone(IcColors.okFg, IcColors.okBg, IcIcon.okCirculo),
      SlotHealth.expiring => const IcTone(IcColors.warningFg, IcColors.warningBg, IcIcon.relogio),
      SlotHealth.expired => const IcTone(IcColors.dangerFg, IcColors.dangerBg, IcIcon.alerta),
      SlotHealth.lowStock => const IcTone(IcColors.warningFg, IcColors.warningBg, IcIcon.menos),
      SlotHealth.missing => const IcTone(IcColors.dangerFg, IcColors.dangerBg, IcIcon.fechar),
      SlotHealth.free => const IcTone(IcColors.neutralFg, IcColors.neutralBg, IcIcon.info),
    };

IcIcon slotHealthIcon(SlotHealth health) => slotTone(health).icon;
Color slotHealthFg(SlotHealth health) => slotTone(health).fg;

String slotHealthText(AppLocalizations l10n, SlotHealth health) => switch (health) {
      SlotHealth.ok => l10n.slotHealthOk,
      SlotHealth.expiring => l10n.slotHealthExpiring,
      SlotHealth.expired => l10n.slotHealthExpired,
      SlotHealth.lowStock => l10n.slotHealthLowStock,
      SlotHealth.missing => l10n.slotHealthMissing,
      SlotHealth.free => l10n.slotHealthFree,
    };

/// Figma "Estado da posição" (small badge, radius 6).
class SlotHealthBadge extends StatelessWidget {
  const SlotHealthBadge({super.key, required this.health});
  final SlotHealth health;

  @override
  Widget build(BuildContext context) {
    final tone = slotTone(health);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: IcSpace.s8, vertical: IcSpace.s2),
      decoration: BoxDecoration(color: tone.bg, borderRadius: BorderRadius.circular(IcRadius.sm)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IcIconView(tone.icon, size: 14, color: tone.fg),
          const SizedBox(width: IcSpace.s4),
          Text(slotHealthText(AppLocalizations.of(context), health), style: IcText.labelS.copyWith(color: tone.fg)),
        ],
      ),
    );
  }
}

Color toneColor(HealthTone tone) => switch (tone) {
      HealthTone.ok => IcColors.okFg,
      HealthTone.warning => IcColors.warningFg,
      HealthTone.danger => IcColors.dangerFg,
    };

IcIcon toneIcon(HealthTone tone, {bool clockForWarning = true}) => switch (tone) {
      HealthTone.ok => IcIcon.okCirculo,
      HealthTone.warning => clockForWarning ? IcIcon.relogio : IcIcon.alerta,
      HealthTone.danger => IcIcon.alerta,
    };

/// Icon + coloured text line ("1 expirado · 2 em falta", "Tudo conforme").
class ToneLine extends StatelessWidget {
  const ToneLine({super.key, required this.tone, required this.text, this.iconSize = 18, this.icon, this.style});

  final HealthTone tone;
  final String text;
  final double iconSize;
  final IcIcon? icon;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final color = toneColor(tone);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IcIconView(icon ?? toneIcon(tone), size: iconSize, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text, style: (style ?? IcText.labelM).copyWith(color: color), maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

enum NoticeKind { info, warning, critical, offline }

/// Figma "Aviso".
class Notice extends StatelessWidget {
  const Notice({super.key, required this.kind, required this.title, this.message});

  final NoticeKind kind;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (kind) {
      NoticeKind.info => (IcColors.infoBg, IcColors.infoFg, IcIcon.info),
      NoticeKind.warning => (IcColors.warningBg, IcColors.warningFg, IcIcon.alerta),
      NoticeKind.critical => (IcColors.dangerBg, IcColors.dangerFg, IcIcon.alerta),
      NoticeKind.offline => (IcColors.neutralBg, IcColors.neutralFg, IcIcon.semRede),
    };
    return Semantics(
      container: true,
      liveRegion: kind == NoticeKind.critical,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: IcSpace.s16, vertical: IcSpace.s12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(IcRadius.md)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 2), child: IcIconView(icon, size: 20, color: fg)),
            const SizedBox(width: IcSpace.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: IcText.titleS.copyWith(color: fg)),
                  if (message != null) ...[
                    const SizedBox(height: 2),
                    Text(message!, style: IcText.bodyM),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma "Sincronização".
class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key, required this.online, required this.pendingWrites});

  final bool online;
  final int pendingWrites;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, color, text) = !online
        ? (IcIcon.semRede, IcColors.neutralFg, l10n.syncOffline)
        : pendingWrites > 0
            ? (IcIcon.relogio, IcColors.warningFg, l10n.syncPending(pendingWrites))
            : (IcIcon.sincronizar, IcColors.okFg, l10n.syncSynced);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: IcSpace.s8, vertical: IcSpace.s4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IcIconView(icon, size: 16, color: color),
            const SizedBox(width: IcSpace.s8),
            Flexible(child: Text(text, style: IcText.bodyS.copyWith(color: color), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

enum PillTone { ok, warning, danger, info, neutral }

/// Small rounded label used in tables ("Ativo", "Por assinar", "Assinado").
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text, required this.tone});
  final String text;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      PillTone.ok => (IcColors.okBg, IcColors.okFg),
      PillTone.warning => (IcColors.warningBg, IcColors.warningFg),
      PillTone.danger => (IcColors.dangerBg, IcColors.dangerFg),
      PillTone.info => (IcColors.infoBg, IcColors.infoFg),
      PillTone.neutral => (IcColors.neutralBg, IcColors.neutralFg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(IcRadius.full)),
      child: Text(text, style: IcText.labelS.copyWith(color: fg)),
    );
  }
}
