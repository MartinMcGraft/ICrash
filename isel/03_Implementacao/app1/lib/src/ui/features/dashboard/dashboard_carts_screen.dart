import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../core/format.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/fit.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/status.dart';
import '../../shells/shell_navigation.dart';
import '../carts/cart_card.dart';
import 'cart_config_screen.dart';
import 'cart_form_dialog.dart';
import 'dashboard_carts_view_model.dart';

/// B2 · Carrinhos.
class DashboardCartsScreen extends StatelessWidget {
  const DashboardCartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.read(context);
    return ViewModelBuilder<DashboardCartsViewModel>(
      create: (services) => DashboardCartsViewModel(services, session),
      builder: (context, vm) {
        final format = IcFormat.of(context);
        final rows = vm.visible;
        return Padding(
          padding: contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: l10n.navCarts,
                subtitle: l10n.cartsServicesSubtitle(vm.total, vm.serviceCount),
                trailing: [
                  if (SessionScope.of(context).isManager) ...[
                    IcButton(
                      label: l10n.createFromTemplate,
                      icon: IcIcon.modelo,
                      style: IcButtonStyle.secondary,
                      onPressed: () => _create(context, vm, fromTemplate: true),
                    ),
                    IcButton(label: l10n.newCart, icon: IcIcon.mais, onPressed: () => _create(context, vm, fromTemplate: false)),
                  ],
                ],
              ),
              const SizedBox(height: IcSpace.s20),
              Row(
                children: [
                  SearchField(hint: l10n.cartsSearchHintLong, onChanged: vm.setQuery),
                  const SizedBox(width: IcSpace.s12),
                  SegmentedTabs<DashboardCartsFilter>(
                    selected: vm.filter,
                    onChanged: vm.setFilter,
                    items: [
                      TabItem(DashboardCartsFilter.all, l10n.cartsFilterAll(vm.total)),
                      TabItem(DashboardCartsFilter.attention, l10n.cartsFilterAttention(vm.attentionCount)),
                      TabItem(DashboardCartsFilter.outOfService, l10n.cartsFilterOutOfService(vm.outOfServiceCount)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: IcSpace.s20),
              Expanded(
                child: vm.state == LoadState.loading
                    ? const StateView.loading()
                    : FitDataTable(
                        columns: [
                          TableColumnSpec(l10n.columnCart, flex: 5),
                          TableColumnSpec(l10n.columnServiceLocation, flex: 4),
                          TableColumnSpec(l10n.columnState, flex: 5),
                          TableColumnSpec(l10n.drawersTitle, flex: 2),
                          TableColumnSpec(l10n.columnAlerts, flex: 4),
                          TableColumnSpec(l10n.columnLastCheck, flex: 3),
                          TableColumnSpec(l10n.columnOnShift, flex: 3),
                        ],
                        emptyText: vm.total == 0 ? l10n.dashboardCartsEmpty : l10n.dashboardNoCartMatches,
                        onRowTap: (i) => Navigator.of(context).push(sectionRoute((_) => CartConfigScreen(cartId: rows[i].cart.id))),
                        rows: [
                          for (final s in rows)
                            [
                              CellText(s.cart.name, primary: true),
                              CellText(s.cart.placeLabel ?? '—'),
                              CartStateChip(status: s.cart.status, emergencyActive: s.emergencyActive, compact: true),
                              CellText('${vm.drawerCount(s.cart.id) ?? '—'}'),
                              CellText(s.counts.allOk && s.checkOverdueDays == null ? '—' : cartAlertLine(l10n, s).$3),
                              CellText(s.lastCheck == null ? '—' : format.date(s.lastCheck!.createdAt)),
                              CellText(vm.responsibleNow(s.cart.id) ?? '—'),
                            ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _create(BuildContext context, DashboardCartsViewModel vm, {required bool fromTemplate}) async {
    final l10n = AppLocalizations.of(context);
    final result = await showCartFormDialog(
      context,
      title: fromTemplate ? l10n.createFromTemplate : l10n.newCart,
      templates: fromTemplate ? vm.templates : null,
    );
    if (result == null || !context.mounted) return;
    final created = result.template != null
        ? await vm.createFromTemplate(result.template!, name: result.name, service: result.service, location: result.location)
        : await vm.createCart(name: result.name, service: result.service, location: result.location);
    if (!context.mounted) return;
    showResult(context, created, success: l10n.cartCreated(result.name));
    final cart = created.value;
    if (cart != null) Navigator.of(context).push(sectionRoute((_) => CartConfigScreen(cartId: cart.id)));
  }
}
