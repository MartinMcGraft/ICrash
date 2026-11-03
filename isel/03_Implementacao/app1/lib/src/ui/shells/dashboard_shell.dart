import 'package:flutter/material.dart';

import '../../common/l10n/app_localizations.dart';
import '../core/icons/ic_icons.dart';
import '../core/labels.dart';
import '../core/session/session.dart';
import '../core/theme/tokens.dart';
import '../core/widgets/brand.dart';
import '../features/dashboard/cart_config_screen.dart';
import '../features/dashboard/catalog_screen.dart';
import '../features/dashboard/dashboard_carts_screen.dart';
import '../features/dashboard/grid_editor_screen.dart';
import '../features/dashboard/overview_screen.dart';
import '../features/dashboard/reports_history_screen.dart';
import '../features/dashboard/shifts_screen.dart';
import '../features/dashboard/templates_screen.dart';
import '../features/dashboard/users_screen.dart';
import '../features/reports/report_screen.dart';
import 'profile_menu.dart';
import 'shell_navigation.dart';

enum DashboardSection { overview, carts, catalog, templates, users, shifts, reports, history }

/// The management Dashboard (web, Windows, Linux, macOS): permanent 240 px
/// sidebar (Figma "Barra lateral · Dashboard"), one stack per section.
/// Sections the role cannot use are hidden rather than labelled (audit F7).
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> implements ShellNavigation {
  final _keys = {for (final s in DashboardSection.values) s: GlobalKey<NavigatorState>()};
  DashboardSection _section = DashboardSection.overview;

  List<DashboardSection> _visible(SessionController session) => [
        DashboardSection.overview,
        DashboardSection.carts,
        if (session.isManager) DashboardSection.catalog,
        if (session.isManager) DashboardSection.templates,
        if (session.isInstitutionAdmin) DashboardSection.users,
        if (session.isManager) DashboardSection.shifts,
        DashboardSection.reports,
        DashboardSection.history,
      ];

  void _select(DashboardSection section) {
    if (section == _section) {
      _keys[section]!.currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _section = section);
    }
  }

  @override
  void openCart(String cartId) {
    setState(() => _section = DashboardSection.carts);
    final nav = _keys[DashboardSection.carts]!.currentState;
    nav?.popUntil((route) => route.isFirst);
    nav?.push(sectionRoute((_) => CartConfigScreen(cartId: cartId)));
  }

  @override
  void openDrawer(String cartId, String drawerId, {String? slotId}) {
    openCart(cartId);
    _keys[DashboardSection.carts]!.currentState?.push(
      sectionRoute((_) => GridEditorScreen(cartId: cartId, drawerId: drawerId, initialSlotId: slotId)),
    );
  }

  @override
  void openReport(String reportId) {
    setState(() => _section = DashboardSection.reports);
    final nav = _keys[DashboardSection.reports]!.currentState;
    nav?.popUntil((route) => route.isFirst);
    nav?.push(sectionRoute((_) => ReportScreen(reportId: reportId)));
  }

  @override
  void showReports() => _select(DashboardSection.reports);

  Widget _root(DashboardSection section) => switch (section) {
        DashboardSection.overview => const OverviewScreen(),
        DashboardSection.carts => const DashboardCartsScreen(),
        DashboardSection.catalog => const CatalogScreen(),
        DashboardSection.templates => const TemplatesScreen(),
        DashboardSection.users => const UsersScreen(),
        DashboardSection.shifts => const ShiftsScreen(),
        DashboardSection.reports => const ReportsHistoryScreen(initialTab: ReportsHistoryTab.reports),
        DashboardSection.history => const ReportsHistoryScreen(initialTab: ReportsHistoryTab.events),
      };

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final visible = _visible(session);
    if (!visible.contains(_section)) _section = DashboardSection.overview;
    return ShellNavigationScope(
      navigation: this,
      child: Scaffold(
        body: Row(
          children: [
            _Sidebar(sections: visible, active: _section, onSelect: _select),
            Expanded(
              child: IndexedStack(
                index: DashboardSection.values.indexOf(_section),
                children: [
                  for (final section in DashboardSection.values)
                    visible.contains(section)
                        ? SectionNavigator(navigatorKey: _keys[section]!, root: (_) => _root(section))
                        : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.sections, required this.active, required this.onSelect});

  final List<DashboardSection> sections;
  final DashboardSection active;
  final ValueChanged<DashboardSection> onSelect;

  (IcIcon, String) _item(AppLocalizations l10n, DashboardSection section) => switch (section) {
        DashboardSection.overview => (IcIcon.painel, l10n.navOverview),
        DashboardSection.carts => (IcIcon.carro, l10n.navCarts),
        DashboardSection.catalog => (IcIcon.catalogo, l10n.navCatalog),
        DashboardSection.templates => (IcIcon.modelo, l10n.navTemplates),
        DashboardSection.users => (IcIcon.utilizadores, l10n.navUsers),
        DashboardSection.shifts => (IcIcon.turnos, l10n.navShifts),
        DashboardSection.reports => (IcIcon.relatorio, l10n.navReports),
        DashboardSection.history => (IcIcon.historico, l10n.navHistory),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.of(context);
    final initials = _initials(session.myName);
    return Container(
      width: IcSize.sidebar,
      color: IcColors.bgSidebar,
      padding: const EdgeInsets.symmetric(horizontal: IcSpace.s16, vertical: IcSpace.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: IcSpace.s8, bottom: IcSpace.s20),
            child: Row(
              children: [
                const Monogram(size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.appTitle, style: IcText.titleS.copyWith(color: IcColors.textOnDark)),
                      Text(
                        l10n.dashboardBrandSubtitle(session.institution.name),
                        style: IcText.bodyS.copyWith(color: IcColors.textOnDarkMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final section in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: IcSpace.s4),
              child: _SidebarItem(
                icon: _item(l10n, section).$1,
                label: _item(l10n, section).$2,
                active: section == active,
                onTap: () => onSelect(section),
              ),
            ),
          const Spacer(),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(IcRadius.md),
              onTap: () => showProfileMenu(context),
              child: Padding(
                padding: const EdgeInsets.all(IcSpace.s8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: IcColors.bgSidebarActive, shape: BoxShape.circle),
                      child: Text(initials, style: IcText.labelS.copyWith(color: IcColors.textOnDark)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(session.myName, style: IcText.labelM.copyWith(color: IcColors.textOnDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(roleText(l10n, session.role), style: IcText.bodyS.copyWith(color: IcColors.textOnDarkMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'[\s@.]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

/// Figma "Item de navegação" variant "Lista" (208×44).
class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.icon, required this.label, required this.active, required this.onTap});

  final IcIcon icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? IcColors.textOnDark : IcColors.textOnDarkMuted;
    return Semantics(
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
          child: Padding(
            padding: const EdgeInsets.all(IcSpace.s12),
            child: Row(
              children: [
                IcIconView(icon, color: color),
                const SizedBox(width: IcSpace.s12),
                Expanded(child: Text(label, style: IcText.labelM.copyWith(color: color))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
