import 'package:flutter/widgets.dart';

import '../../common/l10n/app_localizations.dart';
import '../../domain/entities/cart_status.dart';

/// Localized (spec section 13) display label for [CartStatus] (spec section
/// 40). Centralized here so every screen that lists carts describes status
/// the same way.
String cartStatusLabel(BuildContext context, CartStatus status) {
  final l10n = AppLocalizations.of(context);
  switch (status) {
    case CartStatus.operational:
      return l10n.cartStatusOperational;
    case CartStatus.replenishmentRequired:
      return l10n.cartStatusReplenishmentRequired;
    case CartStatus.auditRequired:
      return l10n.cartStatusAuditRequired;
    case CartStatus.outOfService:
      return l10n.cartStatusOutOfService;
  }
}
