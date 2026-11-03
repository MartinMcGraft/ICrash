
import 'package:flutter/material.dart';

import '../../../common/app_services.dart';
import '../../../common/l10n/app_localizations.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fit.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/status.dart';
import '../../shells/shell_navigation.dart';
import '../cart/cart_screen.dart';
import 'cart_card.dart';
import 'carts_view_model.dart';

/// A4 · Carrinhos — and A12 when offline (banner + offline sync state).
class CartsScreen extends StatelessWidget {
  const CartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.read(context);
    final sync = AppServicesScope.of(context).sync;
    return ViewModelBuilder<CartsViewModel>(
      create: (services) => CartsViewModel(services, session),
      builder: (context, vm) {
        final compact = isCompactHeight(context);
        return ListenableBuilder(
          listenable: sync,
          builder: (context, _) => Padding(
            padding: contentPadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: l10n.navCarts,
                  subtitle: compact
                      ? '${session.institution.name} · ${vm.total}'
                      : l10n.cartsSubtitle(session.institution.name, vm.total),
                  trailing: [
                    SyncIndicator(online: sync.online, pendingWrites: sync.pendingWrites),
                    if (!compact) SearchField(hint: l10n.cartsSearchHint, onChanged: vm.setQuery),
                  ],
                ),
                if (!sync.online) ...[
                  SizedBox(height: compact ? IcSpace.s12 : IcSpace.s20),
                  Notice(
                    kind: NoticeKind.offline,
                    title: l10n.offlineTitle,
                    message: l10n.offlineMessage(sync.pendingWrites),
                  ),
                ],
                SizedBox(height: compact ? IcSpace.s12 : IcSpace.s20),
                SegmentedTabs<CartsFilter>(
                  selected: vm.filter,
                  onChanged: vm.setFilter,
                  items: [
                    TabItem(CartsFilter.all, l10n.cartsFilterAll(vm.total)),
                    TabItem(CartsFilter.attention, compact ? l10n.cartsFilterAttentionShort(vm.attentionCount) : l10n.cartsFilterAttention(vm.attentionCount)),
                    TabItem(CartsFilter.mine, l10n.cartsFilterMine(vm.mineCount)),
                  ],
                ),
                SizedBox(height: compact ? IcSpace.s12 : IcSpace.s20),
                Expanded(child: _body(context, vm, l10n)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, CartsViewModel vm, AppLocalizations l10n) {
    switch (vm.state) {
      case LoadState.loading:
        return const StateView.loading();
      case LoadState.error:
        return StateView.message(message: l10n.stateLoadError, icon: IcIcon.alerta);
      case LoadState.ready:
        final items = vm.visible;
        if (items.isEmpty) {
          return StateView.message(
            message: vm.total == 0 ? l10n.dashboardCartsEmpty : l10n.dashboardNoCartMatches,
            icon: IcIcon.carro,
          );
        }
        // Equal-height cards; pages instead of scrolling on tablets.
        return FitList(
          itemCount: items.length,
          itemExtent: CartCard.height,
          spacing: IcSpace.s20,
          minColumnWidth: 360,
          itemBuilder: (context, index) => CartCard(
            summary: items[index],
            onTap: () => Navigator.of(context).push(sectionRoute((_) => CartScreen(cartId: items[index].cart.id))),
          ),
        );
    }
  }
}
