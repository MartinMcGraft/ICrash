import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../common/repository_failure.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/status.dart';
import 'login_view_model.dart';

/// A1 · Iniciar sessão — brand panel on the left, form on the right.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onSignedIn,
    required this.onUsePin,
    required this.onCartLogin,
    required this.savedSessionAvailable,
    this.institutionName,
  });

  final Future<void> Function() onSignedIn;
  final VoidCallback onUsePin;
  final VoidCallback onCartLogin;

  /// PIN unlock and cart login need a session saved on this device.
  final bool savedSessionAvailable;
  final String? institutionName;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _errorText(AppLocalizations l10n, RepositoryFailureReason reason) => switch (reason) {
        RepositoryFailureReason.unauthenticated || RepositoryFailureReason.invalidInput => l10n.loginErrorInvalidCredentials,
        RepositoryFailureReason.offline => l10n.loginErrorOffline,
        _ => l10n.loginErrorGeneric,
      };

  void _needsSavedSession(AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.loginNeedsSavedSession)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<LoginViewModel>(
      create: (services) => LoginViewModel(auth: services.auth, onSignedIn: widget.onSignedIn),
      builder: (context, vm) {
        final width = MediaQuery.sizeOf(context).width;
        final brandWidth = (width * 0.4).clamp(220.0, 520.0);
        final compact = isCompactHeight(context);
        return Scaffold(
          body: Row(
            children: [
              _BrandPanel(width: brandWidth, compact: compact, institutionName: widget.institutionName),
              Expanded(
                child: SafeArea(
                  left: false,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(IcSpace.s24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: AutofillGroup(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Semantics(header: true, child: Text(l10n.loginTitle, style: IcText.titleL)),
                                const SizedBox(height: IcSpace.s16),
                                LabeledField(
                                  label: l10n.loginEmailLabel,
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
                                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.loginEmailRequired : null,
                                ),
                                const SizedBox(height: IcSpace.s16),
                                LabeledField(
                                  label: l10n.loginPasswordLabel,
                                  controller: _password,
                                  obscure: true,
                                  autofillHints: const [AutofillHints.password],
                                  validator: (v) => (v == null || v.isEmpty) ? l10n.loginPasswordRequired : null,
                                  onSubmitted: (_) => _submit(vm),
                                ),
                                if (vm.error != null) ...[
                                  const SizedBox(height: IcSpace.s12),
                                  Notice(kind: NoticeKind.critical, title: _errorText(l10n, vm.error!)),
                                ],
                                if (vm.resetSent) ...[
                                  const SizedBox(height: IcSpace.s12),
                                  Notice(kind: NoticeKind.info, title: l10n.loginResetSent),
                                ],
                                const SizedBox(height: IcSpace.s16),
                                IcButton(
                                  label: l10n.loginSubmit,
                                  size: IcButtonSize.l,
                                  expand: true,
                                  busy: vm.busy,
                                  onPressed: () => _submit(vm),
                                ),
                                const SizedBox(height: IcSpace.s4),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                    onPressed: vm.busy ? null : () => _resetPassword(vm, l10n),
                                    child: Text(l10n.loginForgotPassword),
                                  ),
                                ),
                                const SizedBox(height: IcSpace.s4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: IcButton(
                                        label: l10n.loginUsePin,
                                        icon: IcIcon.cadeado,
                                        style: IcButtonStyle.secondary,
                                        expand: true,
                                        onPressed: widget.savedSessionAvailable ? widget.onUsePin : () => _needsSavedSession(l10n),
                                      ),
                                    ),
                                    const SizedBox(width: IcSpace.s12),
                                    Expanded(
                                      child: IcButton(
                                        label: l10n.loginCartLogin,
                                        icon: IcIcon.qr,
                                        style: IcButtonStyle.secondary,
                                        expand: true,
                                        onPressed: widget.savedSessionAvailable ? widget.onCartLogin : () => _needsSavedSession(l10n),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submit(LoginViewModel vm) {
    if (vm.busy || !_formKey.currentState!.validate()) return;
    vm.signIn(_email.text, _password.text);
  }

  Future<void> _resetPassword(LoginViewModel vm, AppLocalizations l10n) async {
    if (_email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.loginResetNeedsEmail)));
      return;
    }
    final result = await vm.resetPassword(_email.text);
    if (!mounted || result.isOk) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.actionGenericError)));
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.width, required this.compact, this.institutionName});
  final double width;
  final bool compact;
  final String? institutionName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: width,
      color: IcColors.bgSidebar,
      padding: EdgeInsets.all(compact ? IcSpace.s24 : 56),
      child: SafeArea(
        right: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Monogram(size: compact ? 48 : 72),
            SizedBox(height: compact ? IcSpace.s12 : IcSpace.s16),
            Text(l10n.appTitle, style: (compact ? IcText.titleL : IcText.display).copyWith(color: IcColors.textOnDark)),
            const SizedBox(height: IcSpace.s16),
            Text(l10n.loginTagline, style: IcText.bodyL.copyWith(color: IcColors.textOnDarkMuted)),
            if (institutionName != null) ...[
              const SizedBox(height: IcSpace.s16),
              Text(institutionName!, style: IcText.bodyM.copyWith(color: IcColors.textOnDarkMuted)),
            ],
          ],
        ),
      ),
    );
  }
}
