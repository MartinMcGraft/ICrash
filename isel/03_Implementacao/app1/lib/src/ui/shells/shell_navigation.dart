import 'package:flutter/widgets.dart';

/// Cross-section navigation offered by whichever shell is active, so a
/// screen can say "open this cart" without knowing whether it runs in the
/// App (rail + tabs) or the Dashboard (sidebar + sections).
abstract class ShellNavigation {
  /// App: Carrinhos tab › cart screen. Dashboard: Carrinhos › configuration.
  void openCart(String cartId);

  /// Opens a drawer (App: drawer grid; Dashboard: grid editor).
  void openDrawer(String cartId, String drawerId, {String? slotId});

  /// Opens a report for viewing/signing.
  void openReport(String reportId);

  /// Goes to the reports section.
  void showReports();
}

class ShellNavigationScope extends InheritedWidget {
  const ShellNavigationScope({super.key, required this.navigation, required super.child});
  final ShellNavigation navigation;

  static ShellNavigation of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ShellNavigationScope>()!.navigation;

  @override
  bool updateShouldNotify(ShellNavigationScope oldWidget) => navigation != oldWidget.navigation;
}

/// A tab/section with its own navigation stack.
class SectionNavigator extends StatelessWidget {
  const SectionNavigator({super.key, required this.navigatorKey, required this.root});

  final GlobalKey<NavigatorState> navigatorKey;
  final WidgetBuilder root;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        pageBuilder: (context, _, _) => root(context),
        transitionDuration: Duration.zero,
      ),
    );
  }
}

/// Default page route used inside sections (fast fade, no slide — the rail
/// or sidebar stays put).
Route<T> sectionRoute<T>(WidgetBuilder builder) => PageRouteBuilder<T>(
      pageBuilder: (context, _, _) => builder(context),
      transitionDuration: const Duration(milliseconds: 150),
      reverseTransitionDuration: const Duration(milliseconds: 120),
      transitionsBuilder: (context, animation, _, child) => FadeTransition(opacity: animation, child: child),
    );
