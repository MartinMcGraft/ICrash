import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../common/repository_failure.dart';
import '../../../domain/entities/registered_device.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/status.dart';
import '../auth/login_screen.dart';
import 'device_setup_view_model.dart';

/// A0 · Configurar dispositivo (D17): step 1 an Admin signs in, step 2 the
/// tablet's name and carts.
class DeviceSetupScreen extends StatefulWidget {
  const DeviceSetupScreen({super.key, required this.onRegistered, required this.onCancel});

  final Future<void> Function(DeviceCredentials credentials) onRegistered;
  final Future<void> Function() onCancel;

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  ActionResult<void>? _last;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _error(AppLocalizations l10n) {
    final last = _last;
    if (last == null || last.isOk) return null;
    return switch ((last.code, last.failure)) {
      ('notAdmin', _) => l10n.deviceSetupNotAdmin,
      ('nameRequired', _) => l10n.validationEnterName,
      ('noCarts', _) => l10n.deviceSetupPickCart,
      (_, RepositoryFailureReason.unauthenticated || RepositoryFailureReason.invalidInput) => l10n.loginErrorInvalidCredentials,
      (_, RepositoryFailureReason.offline) => l10n.loginErrorOffline,
      _ => l10n.loginErrorGeneric,
    };
  }

  Future<void> _signIn(DeviceSetupViewModel vm) async {
    if (vm.busy || !_formKey.currentState!.validate()) return;
    final result = await vm.signIn(_email.text, _password.text);
    if (mounted) setState(() => _last = result);
  }

  Future<void> _register(DeviceSetupViewModel vm) async {
    if (!vm.canRegister) return;
    final result = await vm.register();
    if (mounted) setState(() => _last = result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ViewModelBuilder<DeviceSetupViewModel>(
      create: (services) => DeviceSetupViewModel(services, onRegistered: widget.onRegistered),
      builder: (context, vm) {
        final width = MediaQuery.sizeOf(context).width;
        final compact = isCompactHeight(context);
        final brandWidth = compact ? 280.0 : (width * 0.4).clamp(220.0, 520.0);
        final gap = SizedBox(height: compact ? IcSpace.s8 : IcSpace.s16);
        final error = _error(l10n);
        final cancel = IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: widget.onCancel);
        final body = switch (vm.step) {
          DeviceSetupStep.signIn => Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.deviceSetupAdminNote, style: IcText.bodyM.copyWith(color: IcColors.textSecondary)),
                  gap,
                  LabeledField(
                    label: l10n.loginEmailLabel,
                    controller: _email,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.loginEmailRequired : null,
                  ),
                  gap,
                  LabeledField(
                    label: l10n.loginPasswordLabel,
                    controller: _password,
                    obscure: true,
                    validator: (v) => (v == null || v.isEmpty) ? l10n.loginPasswordRequired : null,
                    onSubmitted: (_) => _signIn(vm),
                  ),
                  if (error != null) ...[gap, Notice(kind: NoticeKind.critical, title: error)],
                  gap,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      cancel,
                      const SizedBox(width: IcSpace.s12),
                      IcButton(label: l10n.actionContinue, busy: vm.busy, onPressed: () => _signIn(vm)),
                    ],
                  ),
                ],
              ),
            ),
          DeviceSetupStep.details => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.deviceSetupInstitution(vm.institution?.name ?? ''), style: IcText.bodyM.copyWith(color: IcColors.textSecondary)),
                gap,
                LabeledField(
                  label: l10n.deviceNameLabel,
                  hint: l10n.deviceNameHint,
                  autofocus: true,
                  onChanged: vm.setName,
                  inputFormatters: [LengthLimitingTextInputFormatter(DeviceSetupViewModel.maxNameLength)],
                ),
                gap,
                Text(l10n.deviceCartsLabel, style: IcText.labelS.copyWith(color: IcColors.textSecondary)),
                const SizedBox(height: IcSpace.s4),
                if (vm.carts.isEmpty)
                  Text(l10n.deviceSetupNoCarts, style: IcText.bodyS.copyWith(color: IcColors.textMuted))
                else
                  for (final cart in vm.carts)
                    InkWell(
                      onTap: () => vm.toggleCart(cart.id),
                      child: Row(
                        children: [
                          Checkbox(value: vm.selected.contains(cart.id), onChanged: (_) => vm.toggleCart(cart.id)),
                          Expanded(
                            child: Text(
                              [cart.name, ?cart.placeLabel].join(' · '),
                              style: IcText.bodyM,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                if (error != null) ...[gap, Notice(kind: NoticeKind.critical, title: error)],
                gap,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    cancel,
                    const SizedBox(width: IcSpace.s12),
                    IcButton(
                      label: l10n.deviceRegister,
                      busy: vm.busy,
                      onPressed: vm.canRegister ? () => _register(vm) : null,
                    ),
                  ],
                ),
              ],
            ),
        };
        return Scaffold(
          body: Row(
            children: [
              LoginBrandPanel(width: brandWidth, compact: compact),
              Expanded(
                child: SafeArea(
                  left: false,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(compact ? IcSpace.s16 : IcSpace.s24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(l10n.deviceSetUp, style: compact ? IcText.titleM : IcText.titleL),
                            ),
                            gap,
                            body,
                          ],
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
}
