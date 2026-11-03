import 'package:flutter/material.dart';

import '../../common/app_services.dart';
import '../../common/l10n/app_localizations.dart';
import '../core/icons/ic_icons.dart';
import '../core/session/session.dart';
import '../core/theme/tokens.dart';
import '../core/widgets/brand.dart';
import '../core/widgets/layout.dart';
import '../features/cart/cart_screen.dart';
import '../features/carts/carts_screen.dart';
import '../features/drawer/drawer_screen.dart';
import '../features/reports/report_screen.dart';
import '../features/reports/reports_list_screen.dart';
import '../features/scanner/scanner_screen.dart';
import 'profile_menu.dart';
import 'shell_navigation.dart';

enum AppTab { carts, reports, scan }

/// The App (Android/iOS/iPadOS, landscape): permanent side rail — 96 px with
/// labels on tablet, 72 px icons on phone (Figma "Barra lateral · App") —
/// and one navigation stack per tab.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> implements ShellNavigation {
  final _keys = {for (final tab in AppTab.values) tab: GlobalKey<NavigatorState>()};
  AppTab _tab = AppTab.carts;

  void _select(AppTab tab) {
    if (tab == _tab) {
      _keys[tab]!.currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _tab = tab);
    }
  }

  @override
  void openCart(String cartId) {
    _select(AppTab.carts);
    final nav = _keys[AppTab.carts]!.currentState;
    if (nav == null) return;
    nav.popUntil((route) => route.isFirst);
    if (SessionScope.read(context).scopedCartId == cartId) return; // root already is that cart
    nav.push(sectionRoute((_) => CartScreen(cartId: cartId)));
  }

  @override
  void openDrawer(String cartId, String drawerId, {String? slotId}) {
    openCart(cartId);
    _keys[AppTab.carts]!.currentState?.push(
      sectionRoute((_) => DrawerScreen(cartId: cartId, drawerId: drawerId, initialSlotId: slotId)),
    );
  }

  @override
  void openReport(String reportId) {
    setState(() => _tab = AppTab.reports);
    final nav = _keys[AppTab.reports]!.currentState;
    nav?.popUntil((route) => route.isFirst);
    nav?.push(sectionRoute((_) => ReportScreen(reportId: reportId)));
  }

  @override
  void showReports() => _select(AppTab.reports);

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final emergency = session.activeEmergencies.isNotEmpty;
    return ShellNavigationScope(
      navigation: this,
      child: Scaffold(
        body: Row(
          children: [
            _AppRail(tab: _tab, emergency: emergency, onSelect: _select),
            Expanded(
              child: SafeArea(
                left: false,
                child: IndexedStack(
                  index: _tab.index,
                  children: [
                    SectionNavigator(
                      navigatorKey: _keys[AppTab.carts]!,
                      root: (_) => session.scopedCartId != null
                          ? CartScreen(cartId: session.scopedCartId!, isRoot: true)
                          : const CartsScreen(),
                    ),
                    SectionNavigator(navigatorKey: _keys[AppTab.reports]!, root: (_) => const ReportsListScreen()),
                    // Built only while visible: the scanner owns the camera.
                    if (_tab == AppTab.scan)
                      SectionNavigator(navigatorKey: _keys[AppTab.scan]!, root: (_) => const ScannerScreen())
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppRail extends StatelessWidget {
  const _AppRail({required this.tab, required this.emergency, required this.onSelect});

  final AppTab tab;

  /// Figma variant "Modo=Emergência": deep red rail while an emergency
  /// session is open, so nobody stays in it by accident.
  final bool emergency;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phone = isCompactHeight(context);
    final sync = AppServicesScope.of(context).sync;
    return Container(
      width: phone ? IcSize.railPhone : IcSize.railTablet,
      color: emergency ? IcColors.emergencyBgDeep : IcColors.bgSidebar,
      child: SafeArea(
        right: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: phone ? IcSpace.s8 : IcSpace.s16, horizontal: IcSpace.s8),
          child: Column(
            children: [
              Monogram(size: phone ? 36 : 40),
              SizedBox(height: phone ? IcSpace.s4 : IcSpace.s16),
              _RailItem(icon: IcIcon.carro, label: l10n.navCarts, active: tab == AppTab.carts, compact: phone, onTap: () => onSelect(AppTab.carts)),
              _RailItem(icon: IcIcon.relatorio, label: l10n.navReports, active: tab == AppTab.reports, compact: phone, onTap: () => onSelect(AppTab.reports)),
              _RailItem(icon: IcIcon.ler, label: l10n.navScan, active: tab == AppTab.scan, compact: phone, onTap: () => onSelect(AppTab.scan)),
              const Spacer(),
              ListenableBuilder(
                listenable: sync,
                builder: (context, _) {
                  final (color, text) = !sync.online
                      ? (IcColors.warm300, l10n.syncOffline)
                      : sync.pendingWrites > 0
                          ? (IcColors.amber500, l10n.syncPending(sync.pendingWrites))
                          : (IcColors.textOnDarkMuted, l10n.syncSynced);
                  return Tooltip(
                    message: text,
                    child: Semantics(
                      label: text,
                      child: Padding(
                        padding: const EdgeInsets.all(IcSpace.s8),
                        child: IcIconView(sync.online ? IcIcon.sincronizar : IcIcon.semRede, size: 20, color: color),
                      ),
                    ),
                  );
                },
              ),
              _RailItem(icon: IcIcon.utilizador, label: l10n.navProfile, active: false, compact: phone, onTap: () => showProfileMenu(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Figma "Item de navegação" (Rail 80×64 with label / Compacto 56×56).
class _RailItem extends StatelessWidget {
  const _RailItem({required this.icon, required this.label, required this.active, required this.compact, required this.onTap});

  final IcIcon icon;
  final String label;
  final bool active;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? IcColors.textOnDark : IcColors.textOnDarkMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: IcSpace.s4),
      child: Tooltip(
        message: compact ? label : '',
        child: Semantics(
          button: true,
          selected: active,
          label: label,
          excludeSemantics: true,
          child: Material(
            color: active ? IcColors.bgSidebarActive : Colors.transparent,
            borderRadius: BorderRadius.circular(IcRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(IcRadius.md),
              onTap: onTap,
              child: SizedBox(
                width: compact ? 56 : 80,
                height: compact ? 56 : 64,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IcIconView(icon, color: color),
                    if (!compact) ...[
                      const SizedBox(height: IcSpace.s4),
                      Text(label, style: IcText.labelS.copyWith(color: color), maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
