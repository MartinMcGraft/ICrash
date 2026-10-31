import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../common/l10n/app_localizations.dart';
import '../core/mvvm/view_model.dart';
import '../core/session/session.dart';
import '../core/widgets/layout.dart';
import '../core/widgets/support_banner.dart';
import '../features/auth/cart_login_screen.dart';
import '../features/auth/institution_picker_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/pin_unlock_screen.dart';
import '../features/device/device_home_screen.dart';
import '../features/device/device_setup_screen.dart';
import '../features/device/device_sign_in_screen.dart';
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
              // D17: only the App (tablets) is registered as a device.
              onSetUpDevice: shell == ShellKind.app ? vm.beginDeviceSetup : null,
            );
          case RootStage.pin:
            return PinUnlockScreen(user: vm.remembered!, onUnlocked: vm.onPinUnlocked, onNotMe: vm.signOut);
          case RootStage.cartLogin:
            return vm.isRegisteredDevice
                ? CartLoginScreen(enterCart: vm.enterCartOnDevice, onBack: vm.showDeviceHome)
                : CartLoginScreen(enterCart: vm.enterCart, onBack: vm.showLogin);
          case RootStage.deviceSetup:
            return DeviceSetupScreen(onRegistered: vm.finishDeviceSetup, onCancel: vm.cancelDeviceSetup);
          case RootStage.deviceHome:
          case RootStage.deviceRevoked:
            return DeviceHomeScreen(
              key: const ValueKey('deviceHome'),
              institutionName: vm.device?.institutionName ?? '',
              deviceName: vm.deviceName ?? vm.device?.deviceName ?? '',
              revoked: vm.stage == RootStage.deviceRevoked,
              notice: switch (vm.deviceNotice) {
                DeviceNotice.idle => l10n.deviceNoticeIdle,
                DeviceNotice.tooManyAttempts => l10n.deviceNoticeTooManyAttempts,
                DeviceNotice.signInFailed => l10n.deviceNoticeSignInFailed,
                DeviceNotice.registrationRemoved || null => null,
              },
              onUsePin: vm.showDeviceIdentify,
              onCartLogin: vm.showCartLogin,
              onRemoveRegistration: () => vm.showDeviceIdentify(purpose: DeviceIdentifyPurpose.removeRegistration),
              onSetUpAgain: vm.beginDeviceSetup,
            );
          case RootStage.deviceIdentify:
            final device = vm.device;
            if (device == null) return const Scaffold(body: StateView.loading());
            final removing = vm.identifyPurpose == DeviceIdentifyPurpose.removeRegistration;
            return DeviceSignInScreen(
              key: ValueKey(vm.identifyPurpose),
              institutionId: device.institutionId,
              title: removing ? l10n.deviceRemoveRegistration : l10n.deviceIdentifyTitle,
              subtitle: removing ? l10n.deviceRemoveNote : (vm.deviceName ?? device.deviceName),
              onIdentified: vm.onDevicePersonIdentified,
              onCancel: vm.showDeviceHome,
              onTooManyAttempts: () async => vm.showDeviceHome(notice: DeviceNotice.tooManyAttempts),
            );
          case RootStage.pickingInstitution:
          case RootStage.noInstitution:
            return InstitutionPickerScreen(
              institutions: vm.institutions,
              supportWindows: vm.isSuper ? vm.supportWindows : null,
              supportEnded: vm.supportEnded,
              onRefresh: vm.isSuper ? vm.loadInstitutions : null,
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
            final shellChild = AppActionsScope(
              actions: AppActions(
                signOut: vm.signOut,
                lock: vm.lock,
                // A user belongs to one institution; only Super moves between
                // them, back through the list of open windows (D16, D18).
                switchInstitution: vm.isSuper ? vm.switchInstitution : null,
                hasPin: vm.hasPin,
                showingDashboard: shell == ShellKind.dashboard,
                switchShell: kDebugMode
                    ? () => setState(() => _switched = shell == ShellKind.app ? ShellKind.dashboard : ShellKind.app)
                    : null,
              ),
              child: SessionScope(
                key: ObjectKey(session),
                session: session,
                // D18: while Super works through a support window, a banner
                // stays on every screen.
                child: session.supportWindow == null
                    ? (shell == ShellKind.app ? const AppShell() : const DashboardShell())
                    : SupportBannerFrame(
                        institutionName: session.institution.name,
                        window: session.supportWindow!,
                        child: shell == ShellKind.app ? const AppShell() : const DashboardShell(),
                      ),
              ),
            );
            // D17: on a registered tablet any touch restarts the 5-minute
            // inactivity timer.
            return vm.isRegisteredDevice
                ? Listener(behavior: HitTestBehavior.translucent, onPointerDown: (_) => vm.touch(), child: shellChild)
                : shellChild;
        }
      },
    );
  }
}
