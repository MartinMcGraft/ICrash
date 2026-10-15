import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
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
import '../carts/cart_card.dart' show drawerSummaryLine;
import '../drawer/drawer_screen.dart';
import '../emergency/emergency_screen.dart';
import '../monthly_check/monthly_check_screen.dart';
import '../reports/reports_list_screen.dart';
import 'cart_dialogs.dart';
import 'cart_view_model.dart';
import 'product_search_dialog.dart';

/// A5 · Carrinho — drawers on the left, "Menu do carro" on the right.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.cartId, this.isRoot = false});

  final String cartId;

  /// Root of a cart-scoped session (A3): no back button.
  final bool isRoot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.read(context);
    return ViewModelBuilder<CartViewModel>(
      create: (services) => CartViewModel(services, session, cartId),
      builder: (context, vm) {
        final cart = vm.cart;
        if (vm.notFound) return StateView.message(message: l10n.cartLoginNotFound, icon: IcIcon.carro);
        if (cart == null) return const StateView.loading();
        final compact = isCompactHeight(context);
        final responsible = vm.responsibleOnShift;
        final subtitle = [
          if (cart.placeLabel != null) cart.placeLabel!,
          if (responsible != null && !compact) l10n.responsibleOnShift(responsible),
        ].join(' · ');
        return Padding(
          padding: contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: cart.name,
                subtitle: subtitle.isEmpty ? null : subtitle,
                onBack: isRoot ? null : () => Navigator.of(context).maybePop(),
                trailing: [CartStateChip(status: cart.status, emergencyActive: vm.emergencyActive)],
              ),
              SizedBox(height: compact ? IcSpace.s12 : IcSpace.s20),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _Drawers(vm: vm)),
                    SizedBox(width: compact ? IcSpace.s12 : IcSpace.s20),
                    SidePanel(width: 340, child: _CartMenu(vm: vm)),
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

class _Drawers extends StatelessWidget {
  const _Drawers({required this.vm});
  final CartViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = isCompactHeight(context);
    if (!vm.ready) return const StateView.loading();
    final drawers = vm.drawers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[SectionTitle(l10n.drawersTitle), const SizedBox(height: IcSpace.s12)],
        Expanded(
          child: drawers.isEmpty
              ? StateView.message(message: l10n.cartDetailDrawersEmpty, icon: IcIcon.gaveta)
              : FitList(
                  itemCount: drawers.length,
                  itemExtent: compact ? 60 : 76,
                  spacing: compact ? IcSpace.s8 : IcSpace.s12,
                  itemBuilder: (context, index) {
                    final row = drawers[index];
                    final (tone, icon, text) = drawerSummaryLine(l10n, row.health.counts);
                    return SurfaceCard(
                      elevated: false,
                      padding: EdgeInsets.fromLTRB(IcSpace.s16, compact ? IcSpace.s8 : IcSpace.s12, IcSpace.s12, compact ? IcSpace.s8 : IcSpace.s12),
                      onTap: () => Navigator.of(context).push(
                        sectionRoute((_) => DrawerScreen(cartId: vm.cartId, drawerId: row.drawer.id)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: IcColors.navy50, borderRadius: BorderRadius.circular(IcRadius.md)),
                            child: Text('${row.number}', style: IcText.titleS.copyWith(color: IcColors.textLink)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(row.drawer.name, style: IcText.labelL, maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(
                                  compact
                                      ? l10n.drawerGridShort(row.drawer.rows, row.drawer.columns, row.health.positions)
                                      : l10n.drawerGridLong(row.drawer.rows, row.drawer.columns, row.health.positions, row.health.withProduct),
                                  style: IcText.bodyS.copyWith(color: IcColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: IcSpace.s12),
                          Flexible(child: ToneLine(tone: tone, icon: icon, text: text)),
                          const SizedBox(width: IcSpace.s8),
                          const IcIconView(IcIcon.seguinte, color: IcColors.textSecondary),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CartMenu extends StatelessWidget {
  const _CartMenu({required this.vm});
  final CartViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.of(context);
    final compact = isCompactHeight(context);
    final gap = SizedBox(height: compact ? IcSpace.s8 : IcSpace.s12);
    final cart = vm.cart!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[Text(l10n.cartMenuTitle, style: IcText.titleS), const SizedBox(height: IcSpace.s16)],
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (session.canMonthlyCheck) ...[
                  IcButton(
                    label: l10n.monthlyCheckTitle,
                    icon: IcIcon.calendario,
                    expand: true,
                    onPressed: () => Navigator.of(context).push(sectionRoute((_) => MonthlyCheckScreen(cartId: vm.cartId))),
                  ),
                  gap,
                ],
                IcButton(
                  label: l10n.actionSearchProduct,
                  icon: IcIcon.pesquisar,
                  style: IcButtonStyle.secondary,
                  expand: true,
                  onPressed: () => showProductSearch(context, vm.data),
                ),
                gap,
                IcButton(
                  label: compact ? l10n.qrCodeShort : l10n.actionShowQrCode,
                  icon: IcIcon.qr,
                  style: IcButtonStyle.secondary,
                  expand: true,
                  onPressed: () => showCartQrDialog(context, cart),
                ),
                if (!compact && session.canChangeCartState) ...[
                  gap,
                  IcButton(
                    label: l10n.changeStateAction,
                    icon: IcIcon.editar,
                    style: IcButtonStyle.secondary,
                    expand: true,
                    onPressed: () async {
                      final status = await showChangeStatusDialog(context, cart.status);
                      if (status == null || !context.mounted) return;
                      final result = await vm.changeStatus(status);
                      if (!context.mounted) return;
                      showResult(context, result, success: l10n.cartUpdatedMessage);
                    },
                  ),
                ],
                if (!compact) ...[
                  gap,
                  IcButton(
                    label: l10n.cartReportsAction,
                    icon: IcIcon.relatorio,
                    style: IcButtonStyle.secondary,
                    expand: true,
                    onPressed: () => Navigator.of(context).push(sectionRoute((_) => ReportsListScreen(cartId: vm.cartId))),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (session.canUseEmergency) ...[
          if (!compact) ...[
            Text(l10n.emergencyHint, style: IcText.bodyS.copyWith(color: IcColors.textSecondary)),
            const SizedBox(height: IcSpace.s12),
          ],
          IcButton(
            label: vm.emergencyActive ? l10n.emergencyResume : (compact ? l10n.emergencyShort : l10n.emergencyModeTitle),
            icon: IcIcon.emergencia,
            style: IcButtonStyle.danger,
            size: compact ? IcButtonSize.m : IcButtonSize.l,
            expand: true,
            busy: vm.busy,
            onPressed: () async {
              final result = await vm.startEmergency();
              if (!context.mounted) return;
              if (!result.isOk) return showResult(context, result);
              Navigator.of(context).push(sectionRoute((_) => EmergencyScreen(cartId: vm.cartId)));
            },
          ),
        ],
      ],
    );
  }
}
