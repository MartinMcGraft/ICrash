import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../common/app_services.dart';
import '../../../common/l10n/app_localizations.dart';
import '../../core/format.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/fit.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/status.dart';
import '../../shells/shell_navigation.dart';
import '../carts/cart_card.dart';
import 'activity_list.dart';
import 'overview_pdf.dart';
import 'overview_view_model.dart';

/// B1 · Visão geral.
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.read(context);
    final sync = AppServicesScope.of(context).sync;
    return ViewModelBuilder<OverviewViewModel>(
      create: (services) => OverviewViewModel(services, session),
      builder: (context, vm) {
        final format = IcFormat.of(context);
        if (vm.state == LoadState.loading) return const StateView.loading();
        if (vm.state == LoadState.error) return StateView.message(message: l10n.stateLoadError, icon: IcIcon.alerta);
        final total = vm.summaries.length;
        final (expiring, expiringCarts) = vm.expiringSoon;
        final overdue = vm.overdueChecks;
        final (emergencies, emergencyUnits) = vm.emergenciesThisMonth;
        final attention = vm.needingAttention;
        return Padding(
          padding: contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: l10n.navOverview,
                subtitle: '${session.institution.name} · ${format.longDate(DateTime.now())}',
                trailing: [
                  ListenableBuilder(
                    listenable: sync,
                    builder: (context, _) => SyncIndicator(online: sync.online, pendingWrites: sync.pendingWrites),
                  ),
                  IcButton(
                    label: l10n.exportReport,
                    icon: IcIcon.descarregar,
                    style: IcButtonStyle.secondary,
                    onPressed: () => Printing.layoutPdf(
                      name: l10n.navOverview,
                      onLayout: (_) => buildOverviewPdf(context, vm),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: IcSpace.s20),
              Row(
                children: [
                  Expanded(
                    child: MetricTile(
                      label: l10n.metricOperational,
                      value: '${vm.operational} / $total',
                      caption: l10n.metricNeedReplenishment(vm.needReplenishment),
                      tone: vm.operational == total ? MetricTone.ok : MetricTone.warning,
                    ),
                  ),
                  const SizedBox(width: IcSpace.s16),
                  Expanded(
                    child: MetricTile(
                      label: l10n.metricExpiring30,
                      value: '$expiring',
                      caption: l10n.metricInCarts(expiringCarts),
                      tone: expiring == 0 ? MetricTone.ok : MetricTone.warning,
                    ),
                  ),
                  const SizedBox(width: IcSpace.s16),
                  Expanded(
                    child: MetricTile(
                      label: l10n.metricChecksOverdue,
                      value: '${overdue.length}',
                      caption: overdue.isEmpty ? l10n.allCompliant : overdue.map((s) => s.cart.name).join(', '),
                      tone: overdue.isEmpty ? MetricTone.ok : MetricTone.danger,
                    ),
                  ),
                  const SizedBox(width: IcSpace.s16),
                  Expanded(
                    child: MetricTile(
                      label: l10n.metricEmergencies,
                      value: '$emergencies',
                      caption: l10n.metricUnitsRecorded(emergencyUnits),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: IcSpace.s20),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionTitle(l10n.cartsNeedingAttention),
                          const SizedBox(height: IcSpace.s12),
                          Expanded(
                            child: FitDataTable(
                              columns: [
                                TableColumnSpec(l10n.columnCart, flex: 4),
                                TableColumnSpec(l10n.columnState, flex: 5),
                                TableColumnSpec(l10n.columnAlerts, flex: 5),
                              ],
                              emptyText: l10n.allCompliant,
                              onRowTap: (i) => ShellNavigationScope.of(context).openCart(attention[i].cart.id),
                              rows: [
                                for (final s in attention)
                                  [
                                    CellText(s.cart.name, primary: true),
                                    CartStateChip(status: s.cart.status, emergencyActive: s.emergencyActive, compact: true),
                                    CellText(cartAlertLine(l10n, s).$3),
                                  ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: IcSpace.s20),
                    Expanded(
                      flex: 4,
                      child: SurfaceCard(
                        elevated: false,
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(IcSpace.s16),
                              child: Text(l10n.dashboardRecentActivityTitle, style: IcText.titleS),
                            ),
                            Expanded(
                              child: vm.activity.isEmpty
                                  ? StateView.message(message: l10n.historyEmpty, icon: IcIcon.historico)
                                  : FitList(
                                      itemCount: vm.activity.length,
                                      itemExtent: 64,
                                      spacing: 0,
                                      itemBuilder: (context, i) => buildActivity(context, vm.activity[i], vm),
                                    ),
                            ),
                          ],
                        ),
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
}
