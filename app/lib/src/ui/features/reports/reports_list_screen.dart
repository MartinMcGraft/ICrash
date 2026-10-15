import 'package:flutter/material.dart';

import '../../../common/app_services.dart';
import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/cart_report.dart';
import '../../core/format.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fit.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/status.dart';
import '../../shells/shell_navigation.dart';
import 'report_screen.dart';

enum ReportsFilter { pending, all }

/// The App's "Relatórios": reports to sign first, then the rest.
class ReportsListViewModel extends ViewModel {
  ReportsListViewModel(AppServices services, this.session, {this.cartId}) {
    listen(services.reports.watchReports(session.institution.id), (reports) {
      _reports = cartId == null ? reports : reports.where((r) => r.cartId == cartId).toList();
      state = LoadState.ready;
      notify();
    });
  }

  final SessionController session;
  final String? cartId;
  List<CartReport> _reports = const [];
  LoadState state = LoadState.loading;
  ReportsFilter filter = ReportsFilter.pending;

  int get pendingCount => _reports.where((r) => !r.isSigned).length;
  int get total => _reports.length;

  List<CartReport> get visible =>
      filter == ReportsFilter.pending ? _reports.where((r) => !r.isSigned).toList() : _reports;

  void setFilter(ReportsFilter value) {
    filter = value;
    notify();
  }
}

class ReportsListScreen extends StatelessWidget {
  const ReportsListScreen({super.key, this.cartId});

  /// Limits the list to one cart ("Relatórios do carro").
  final String? cartId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.read(context);
    return ViewModelBuilder<ReportsListViewModel>(
      create: (services) => ReportsListViewModel(services, session, cartId: cartId),
      builder: (context, vm) {
        final format = IcFormat.of(context);
        final reports = vm.visible;
        return Padding(
          padding: contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: l10n.navReports,
                subtitle: session.institution.name,
                onBack: cartId == null ? null : () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: IcSpace.s20),
              SegmentedTabs<ReportsFilter>(
                selected: vm.filter,
                onChanged: vm.setFilter,
                items: [
                  TabItem(ReportsFilter.pending, l10n.reportsFilterPending(vm.pendingCount)),
                  TabItem(ReportsFilter.all, l10n.cartsFilterAll(vm.total)),
                ],
              ),
              const SizedBox(height: IcSpace.s20),
              Expanded(
                child: vm.state == LoadState.loading
                    ? const StateView.loading()
                    : reports.isEmpty
                        ? StateView.message(message: l10n.reportsEmpty, icon: IcIcon.relatorio)
                        : FitList(
                            itemCount: reports.length,
                            itemExtent: 72,
                            itemBuilder: (context, index) {
                              final r = reports[index];
                              return SurfaceCard(
                                elevated: false,
                                padding: const EdgeInsets.symmetric(horizontal: IcSpace.s16, vertical: 14),
                                onTap: () => Navigator.of(context).push(sectionRoute((_) => ReportScreen(reportId: r.id))),
                                child: Row(
                                  children: [
                                    IcIconView(
                                      r.kind == ReportKind.monthlyCheck ? IcIcon.calendario : IcIcon.emergencia,
                                      color: r.kind == ReportKind.monthlyCheck ? IcColors.textLink : IcColors.dangerFg,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(reportTitle(l10n, r), style: IcText.labelL),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${r.cartName} · ${format.dateTime(r.createdAt)} · ${r.createdByName}',
                                            style: IcText.bodyS.copyWith(color: IcColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    StatusPill(
                                      text: r.isSigned ? l10n.reportSigned : l10n.reportPendingSignature,
                                      tone: r.isSigned ? PillTone.ok : PillTone.warning,
                                    ),
                                    const SizedBox(width: IcSpace.s8),
                                    const IcIconView(IcIcon.seguinte, color: IcColors.textSecondary),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
