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

/// Width of the App rail: 96 px on tablet, 72 px on phone, plus the left
/// safe-area inset (the notch side of a landscape iPhone), so the rail's own
/// content keeps its full width (RV-14).
double appRailWidth(BuildContext context) =>
    (isCompactHeight(context) ? IcSize.railPhone : IcSize.railTablet) + MediaQuery.paddingOf(context).left;

/// The App shell's layout without its state: the rail on the left and the
/// section content on the right, inside the safe area. Used by [AppShell] and
/// by the layout tests, so the tests measure what a device really shows.
class AppShellFrame extends StatelessWidget {
  const AppShellFrame({super.key, required this.rail, required this.child});

  final Widget rail;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: appRailWidth(context), child: rail),
        Expanded(child: SafeArea(left: false, child: child)),
      ],
    );
  }
}

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

  /// Cart screens open in the Carrinhos tab (a drawer may sit on top of one).
  final List<String> _openCarts = [];

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
  void showReports({String? cartId}) {
    if (cartId == null) return _select(AppTab.reports);
    setState(() => _tab = AppTab.reports);
    final nav = _keys[AppTab.reports]!.currentState;
    nav?.popUntil((route) => route.isFirst);
    nav?.push(sectionRoute((_) => ReportsListScreen(
          cartId: cartId,
          // Back returns to the cart in the Carrinhos tab.
          onBack: () {
            _keys[AppTab.reports]!.currentState?.popUntil((route) => route.isFirst);
            setState(() => _tab = AppTab.carts);
          },
        )));
  }

  @override
  void cartOpened(String cartId) => _openCarts.add(cartId);

  @override
  void cartClosed(String cartId) => _openCarts.remove(cartId);

  /// The cart the person is in: the cart-limited session (A3) or the cart
  /// screen open in the Carrinhos tab.
  String? get _currentCartId => SessionScope.read(context).scopedCartId ?? _openCarts.lastOrNull;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final emergency = session.activeEmergencies.isNotEmpty;
    return ShellNavigationScope(
      navigation: this,
      child: Scaffold(
        body: AppShellFrame(
          rail: _AppRail(tab: _tab, emergency: emergency, onSelect: _select),
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
                SectionNavigator(navigatorKey: _keys[AppTab.scan]!, root: (_) => ScannerScreen(cartId: _currentCartId))
              else
                const SizedBox.shrink(),
            ],
          ),
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
