import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/membership.dart';
import '../../../domain/entities/role.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/labels.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/fit.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/status.dart';
import 'users_view_model.dart';

String permissionText(AppLocalizations l10n, AppPermission p) => switch (p) {
      AppPermission.viewCarts => l10n.permViewCarts,
      AppPermission.recordConsumption => l10n.permRecordConsumption,
      AppPermission.replenish => l10n.permReplenish,
      AppPermission.monthlyCheck => l10n.permMonthlyCheck,
      AppPermission.signReports => l10n.permSignReports,
      AppPermission.emergencyMode => l10n.permEmergencyMode,
      AppPermission.changeCartState => l10n.permChangeCartState,
      AppPermission.editDrawers => l10n.permEditDrawers,
      AppPermission.manageUsersAndShifts => l10n.permManageUsersAndShifts,
    };

/// B7 · Utilizadores e permissões.
class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.read(context);
    return ViewModelBuilder<UsersViewModel>(
      create: (services) => UsersViewModel(services, session),
      builder: (context, vm) {
        final rows = vm.visible;
        return Padding(
          padding: contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: l10n.usersTitle,
                subtitle: l10n.usersCount(vm.total),
                trailing: [
                  if (vm.canManage)
                    IcButton(label: l10n.createUser, icon: IcIcon.mais, onPressed: () => _create(context, vm)),
                ],
              ),
              const SizedBox(height: IcSpace.s20),
              Row(
                children: [
                  SearchField(hint: l10n.usersSearchHint, onChanged: vm.setQuery),
                  const SizedBox(width: IcSpace.s12),
                  Flexible(
                    child: SegmentedTabs<UsersFilter>(
                      selected: vm.filter,
                      onChanged: vm.setFilter,
                      items: [
                        TabItem(UsersFilter.all, l10n.cartsFilterAll(vm.total)),
                        TabItem(UsersFilter.managers, l10n.usersFilterManagers(vm.managerCount)),
                        TabItem(UsersFilter.professionals, l10n.usersFilterProfessionals(vm.professionalCount)),
                        TabItem(UsersFilter.invited, l10n.usersFilterInvited(vm.invitedCount)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: IcSpace.s20),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: switch (vm.state) {
                        LoadState.loading => const StateView.loading(),
                        LoadState.error => StateView.message(message: l10n.stateLoadError),
                        LoadState.ready => FitDataTable(
                            columns: [
                              TableColumnSpec(l10n.fieldName, flex: 4),
                              TableColumnSpec(l10n.fieldEmail, flex: 5),
                              TableColumnSpec(l10n.columnUserType, flex: 4),
                              TableColumnSpec(l10n.fieldService, flex: 3),
                              TableColumnSpec(l10n.columnState, flex: 3),
                              if (vm.canManage) const TableColumnSpec('', width: 56, alignEnd: true),
                            ],
                            emptyText: l10n.usersNoMatches,
                            rows: [
                              for (final m in rows)
                                [
                                  CellText(m.label, primary: true),
                                  CellText(m.email ?? '—'),
                                  CellText(roleText(l10n, m.role)),
                                  CellText(m.service ?? (m.role == Role.user ? '—' : l10n.allServices)),
                                  _MemberStatus(status: m.status),
                                  if (vm.canManage) _MemberMenu(vm: vm, member: m),
                                ],
                            ],
                          ),
                      },
                    ),
                    const SizedBox(width: IcSpace.s20),
                    SidePanel(width: 320, child: _PermissionsPanel(vm: vm)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _create(BuildContext context, UsersViewModel vm) async {
    final l10n = AppLocalizations.of(context);
    final input = await _showCreateUserDialog(context);
    if (input == null || !context.mounted) return;
    final result = await vm.createUser(
      name: input.name,
      email: input.email,
      role: input.role,
      password: input.password,
      pin: input.pin,
    );
    if (!context.mounted) return;
    showResult(
      context,
      result,
      success: l10n.userCreated(input.email),
      failure: switch (result.code) {
        'emailTaken' => l10n.emailTaken,
        'passwordTooShort' => l10n.passwordTooShort(UsersViewModel.minPasswordLength),
        'pinInvalid' => l10n.pinFourDigits,
        _ => null,
      },
    );
  }
}

class _MemberStatus extends StatelessWidget {
  const _MemberStatus({required this.status});
  final MembershipStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tone = switch (status) {
      MembershipStatus.active => PillTone.ok,
      MembershipStatus.invited => PillTone.warning,
      MembershipStatus.disabled => PillTone.neutral,
    };
    return Align(alignment: Alignment.centerLeft, child: StatusPill(text: membershipStatusText(l10n, status), tone: tone));
  }
}

enum _MemberAction { role, toggle, pin, password }

class _MemberMenu extends StatelessWidget {
  const _MemberMenu({required this.vm, required this.member});
  final UsersViewModel vm;
  final Membership member;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (vm.isMe(member)) {
      return Tooltip(
        message: l10n.cannotEditSelf,
        child: const Padding(
          padding: EdgeInsets.all(IcSpace.s8),
          child: IcIconView(IcIcon.opcoes, size: 20, color: IcColors.textMuted),
        ),
      );
    }
    final active = member.status != MembershipStatus.disabled;
    return PopupMenuButton<_MemberAction>(
      tooltip: l10n.moreActions,
      icon: const IcIconView(IcIcon.opcoes, size: 20, color: IcColors.textSecondary),
      onSelected: (action) => _run(context, action),
      itemBuilder: (_) => [
        PopupMenuItem(value: _MemberAction.role, child: Text(l10n.changeUserType)),
        PopupMenuItem(value: _MemberAction.toggle, child: Text(active ? l10n.deactivateUser : l10n.reactivateUser)),
        // DB3: only the administration sets credentials.
        PopupMenuItem(value: _MemberAction.pin, child: Text(l10n.setNewPin)),
        PopupMenuItem(value: _MemberAction.password, child: Text(l10n.resetPasswordAction)),
      ],
    );
  }

  Future<void> _run(BuildContext context, _MemberAction action) async {
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case _MemberAction.role:
        final role = await _showRoleDialog(context, member.role);
        if (role == null || role == member.role || !context.mounted) return;
        final changed = await vm.changeRole(member, role);
        if (!context.mounted) return;
        showResult(context, changed, success: l10n.userUpdated);
      case _MemberAction.toggle:
        final activate = member.status == MembershipStatus.disabled;
        final ok = await confirmAction(
          context,
          title: activate ? l10n.reactivateUser : l10n.deactivateUser,
          message: activate ? l10n.reactivateUserConfirm(member.label) : l10n.deactivateUserConfirm(member.label),
          confirmLabel: activate ? l10n.reactivateUser : l10n.deactivateUser,
          destructive: !activate,
        );
        if (!ok || !context.mounted) return;
        final toggled = await vm.setActive(member, activate);
        if (!context.mounted) return;
        showResult(context, toggled, success: l10n.userUpdated);
      case _MemberAction.pin:
        final pin = await _showPinDialog(context, title: l10n.setNewPinFor(member.label));
        if (pin == null || !context.mounted) return;
        final set = await vm.setMemberPin(member, pin);
        if (!context.mounted) return;
        showResult(context, set, success: l10n.pinSetFor(member.label));
      case _MemberAction.password:
        // Q4: a client can't change another user's Firebase password without
        // Cloud Functions (Spark plan). IT resets it with
        // firebase/tools/set_password.mjs; see docs/FIREBASE.md §9.
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.resetPasswordAction),
            content: SizedBox(width: 420, child: Text(l10n.resetPasswordSupport, style: IcText.bodyM)),
            actions: [IcButton(label: l10n.actionClose, onPressed: () => Navigator.of(context).pop())],
          ),
        );
    }
  }
}

class _PermissionsPanel extends StatelessWidget {
  const _PermissionsPanel({required this.vm});
  final UsersViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final granted = vm.permissionsOf(vm.permissionRole);
    final editable = vm.canManage;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.permissionsTitle, style: IcText.titleS),
          const SizedBox(height: IcSpace.s12),
          SegmentedTabs<Role>(
            selected: vm.permissionRole,
            onChanged: vm.setPermissionRole,
            items: [
              TabItem(Role.user, l10n.roleUser),
              TabItem(Role.manager, l10n.roleManager),
            ],
          ),
          const SizedBox(height: IcSpace.s12),
          for (final p in AppPermission.values)
            CheckRow(
              label: permissionText(l10n, p),
              value: granted.contains(p),
              onChanged: editable ? (v) => vm.togglePermission(p, v) : null,
            ),
          const SizedBox(height: IcSpace.s12),
          Text(l10n.permissionsNote, style: IcText.bodyS.copyWith(color: IcColors.textMuted)),
        ],
      ),
    );
  }
}

Future<Role?> _showRoleDialog(BuildContext context, Role current) {
  final l10n = AppLocalizations.of(context);
  return showDialog<Role>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.changeUserType),
      children: [
        for (final role in assignableRoles)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(role),
            child: Row(
              children: [
                Expanded(child: Text(roleText(l10n, role), style: IcText.bodyM)),
                if (role == current) const IcIconView(IcIcon.confirmar, size: 18, color: IcColors.actionPrimary),
              ],
            ),
          ),
      ],
    ),
  );
}

class _NewUser {
  const _NewUser({required this.name, required this.email, required this.role, required this.password, required this.pin});
  final String name;
  final String email;
  final Role role;
  final String password;
  final String pin;
}

/// "Criar utilizador" (DB3): the administrator sets the password and PIN
/// and hands them over.
Future<_NewUser?> _showCreateUserDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final password2 = TextEditingController();
  final pin = TextEditingController();
  final pin2 = TextEditingController();
  var role = Role.user;
  final pinFormatters = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)];
  return showDialog<_NewUser>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.createUser),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LabeledField(
                    label: l10n.fieldName,
                    controller: name,
                    autofocus: true,
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.validationEnterName : null,
                  ),
                  const SizedBox(height: IcSpace.s12),
                  LabeledField(
                    label: l10n.fieldEmail,
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) ? l10n.emailInvalid : null,
                  ),
                  const SizedBox(height: IcSpace.s12),
                  Text(l10n.columnUserType, style: IcText.labelS.copyWith(color: IcColors.textSecondary)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Role>(
                    initialValue: role,
                    isExpanded: true,
                    items: [for (final r in assignableRoles) DropdownMenuItem(value: r, child: Text(roleText(l10n, r)))],
                    onChanged: (v) => setState(() => role = v ?? role),
                  ),
                  const SizedBox(height: IcSpace.s12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabeledField(
                          label: l10n.loginPasswordLabel,
                          controller: password,
                          obscure: true,
                          validator: (v) => (v == null || v.length < UsersViewModel.minPasswordLength)
                              ? l10n.passwordTooShort(UsersViewModel.minPasswordLength)
                              : null,
                        ),
                      ),
                      const SizedBox(width: IcSpace.s12),
                      Expanded(
                        child: LabeledField(
                          label: l10n.passwordRepeatLabel,
                          controller: password2,
                          obscure: true,
                          validator: (v) => v != password.text ? l10n.passwordMismatch : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: IcSpace.s12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabeledField(
                          label: l10n.pinLabel,
                          controller: pin,
                          obscure: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: pinFormatters,
                          validator: (v) => (v == null || v.length != 4) ? l10n.pinFourDigits : null,
                        ),
                      ),
                      const SizedBox(width: IcSpace.s12),
                      Expanded(
                        child: LabeledField(
                          label: l10n.pinRepeatLabel,
                          controller: pin2,
                          obscure: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: pinFormatters,
                          validator: (v) => v != pin.text ? l10n.pinMismatch : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: IcSpace.s12),
                  Text(l10n.createUserNote, style: IcText.bodyS.copyWith(color: IcColors.textMuted)),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
          IcButton(
            label: l10n.createUser,
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(context).pop(_NewUser(
                name: name.text.trim(),
                email: email.text.trim(),
                role: role,
                password: password.text,
                pin: pin.text,
              ));
            },
          ),
        ],
      ),
    ),
  );
}

/// "Definir novo PIN" (DB3): the administrator types the new PIN twice.
Future<String?> _showPinDialog(BuildContext context, {required String title}) {
  final l10n = AppLocalizations.of(context);
  final formKey = GlobalKey<FormState>();
  final pin = TextEditingController();
  final pin2 = TextEditingController();
  final pinFormatters = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)];
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 380,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledField(
                label: l10n.pinNewLabel,
                controller: pin,
                obscure: true,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: pinFormatters,
                validator: (v) => (v == null || v.length != 4) ? l10n.pinFourDigits : null,
              ),
              const SizedBox(height: IcSpace.s12),
              LabeledField(
                label: l10n.pinRepeatLabel,
                controller: pin2,
                obscure: true,
                keyboardType: TextInputType.number,
                inputFormatters: pinFormatters,
                validator: (v) => v != pin.text ? l10n.pinMismatch : null,
              ),
              const SizedBox(height: IcSpace.s12),
              Text(l10n.setPinNote, style: IcText.bodyS.copyWith(color: IcColors.textMuted)),
            ],
          ),
        ),
      ),
      actions: [
        IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
        IcButton(
          label: l10n.actionSave,
          onPressed: () {
            if (formKey.currentState!.validate()) Navigator.of(context).pop(pin.text);
          },
        ),
      ],
    ),
  );
}
