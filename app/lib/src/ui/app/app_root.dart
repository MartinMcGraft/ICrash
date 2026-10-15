import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../common/l10n/app_localizations.dart';
import '../core/mvvm/view_model.dart';
import '../core/session/session.dart';
import '../core/widgets/layout.dart';
import '../features/auth/cart_login_screen.dart';
import '../features/auth/institution_picker_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/pin_unlock_screen.dart';
import '../shells/app_shell.dart';
import '../shells/dashboard_shell.dart';
import 'app_root_view_model.dart';

enum ShellKind { app, dashboard }

/// Decision R1/D1: the platform picks the shell, the role decides what is
/// visible inside it. Override for development with
/// `--dart-define=ICRASH_SHELL=app` or `=dashboard`.
ShellKind resolveShellKind() {
  const override = String.fromEnvironment('ICRASH_SHELL');
  if (override == 'app') return ShellKind.app;
  if (override == 'dashboard') return ShellKind.dashboard;
  if (kIsWeb) return ShellKind.dashboard;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.fuchsia => ShellKind.app,
    TargetPlatform.macOS || TargetPlatform.windows || TargetPlatform.linux => ShellKind.dashboard,
  };
}

/// Root of the authenticated UI: login → PIN / cart login → institution →
/// App or Dashboard shell.
class AppRoot extends StatefulWidget {
  const AppRoot({super.key, this.shellKind});

  /// Defaults to [resolveShellKind].
  final ShellKind? shellKind;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  /// Set from the Profile menu in debug builds ("Ver como App").
  ShellKind? _switched;

  @override
  Widget build(BuildContext context) {
    final shell = _switched ?? widget.shellKind ?? resolveShellKind();
    return ViewModelBuilder<AppRootViewModel>(
      create: AppRootViewModel.new,
      builder: (context, vm) {
        final l10n = AppLocalizations.of(context);
        switch (vm.stage) {
          case RootStage.starting:
            return const Scaffold(body: StateView.loading());
          case RootStage.signedOut:
          case RootStage.locked:
            return LoginScreen(
              key: const ValueKey('login'),
              onSignedIn: vm.onPasswordSignIn,
              onUsePin: vm.showPin,
              onCartLogin: vm.showCartLogin,
              savedSessionAvailable: vm.stage == RootStage.locked,
              institutionName: vm.remembered?.institutionName,
            );
          case RootStage.pin:
            return PinUnlockScreen(user: vm.remembered!, onUnlocked: vm.onPinUnlocked, onNotMe: vm.signOut);
          case RootStage.cartLogin:
            return CartLoginScreen(enterCart: vm.enterCart, onBack: vm.showLogin);
          case RootStage.pickingInstitution:
          case RootStage.noInstitution:
            return InstitutionPickerScreen(
              institutions: vm.institutions,
              onSelect: vm.selectInstitution,
              onSignOut: vm.signOut,
              loadFailed: vm.loadError != null,
              onRetry: vm.loadInstitutions,
            );
          case RootStage.ready:
            final session = vm.session;
            if (session == null) {
              return Scaffold(
                body: StateView.message(message: l10n.stateLoadError, onRetry: vm.loadInstitutions),
              );
            }
            return AppActionsScope(
              actions: AppActions(
                signOut: vm.signOut,
                lock: vm.lock,
                switchInstitution: vm.institutions.length > 1 ? vm.switchInstitution : null,
                setPin: (pin) async => (await vm.setPin(pin)).isOk,
                hasPin: vm.hasPin,
                showingDashboard: shell == ShellKind.dashboard,
                switchShell: kDebugMode
                    ? () => setState(() => _switched = shell == ShellKind.app ? ShellKind.dashboard : ShellKind.app)
                    : null,
              ),
              child: SessionScope(
                key: ObjectKey(session),
                session: session,
                child: shell == ShellKind.app ? const AppShell() : const DashboardShell(),
              ),
            );
        }
      },
    );
  }
}
