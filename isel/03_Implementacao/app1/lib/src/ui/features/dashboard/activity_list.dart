import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/cart_report.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/usage_event.dart';
import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/session/session.dart';
import '../../core/widgets/layout.dart';
import 'overview_view_model.dart';

/// Renders stock events and reports as Figma "Linha de evento" rows.
EventRow buildEventRow(
  BuildContext context, {
  required UsageEvent event,
  required Map<String, Cart> carts,
  required Map<String, Product> products,
  required String position,
}) {
  final l10n = AppLocalizations.of(context);
  final format = IcFormat.of(context);
  final session = SessionScope.of(context);
  final kind = switch (event.type) {
    UsageEventType.consumption => EventKind.consumption,
    UsageEventType.replenishment => EventKind.replenishment,
    UsageEventType.correction => EventKind.correction,
    UsageEventType.auditReconciliation => EventKind.check,
  };
  final cart = carts[event.cartId]?.name ?? l10n.cartRemoved;
  final where = position.isEmpty ? cart : '$cart › $position';
  return EventRow(
    kind: kind,
    title: '${usageEventText(l10n, event.type)} · ${products[event.productId]?.name ?? l10n.productRemoved}',
    subtitle: '$where · ${session.nameOf(event.actorUid)}',
    amount: IcFormat.signed(event.amount),
    when: event.serverTimestamp == null ? '' : format.relative(event.serverTimestamp!),
  );
}

EventRow buildReportRow(BuildContext context, CartReport report) {
  final l10n = AppLocalizations.of(context);
  final format = IcFormat.of(context);
  final emergency = report.kind == ReportKind.emergencySummary;
  final units = report.lines.fold(0, (sum, l) => sum + l.amount);
  return EventRow(
    kind: emergency ? EventKind.emergency : EventKind.check,
    title: emergency
        ? l10n.activityEmergency(units)
        : (report.isSigned ? l10n.activityCheckSigned : l10n.activityCheckDone),
    subtitle: '${report.cartName} · ${report.signedByName ?? report.createdByName}',
    amount: emergency ? IcFormat.signed(-units) : '—',
    when: format.relative(report.signedAt ?? report.createdAt),
  );
}

Widget buildActivity(BuildContext context, ActivityItem item, OverviewViewModel vm) => item.event != null
    ? buildEventRow(context, event: item.event!, carts: vm.cartsById, products: vm.products, position: vm.positionOf(item.event!))
    : buildReportRow(context, item.report!);
