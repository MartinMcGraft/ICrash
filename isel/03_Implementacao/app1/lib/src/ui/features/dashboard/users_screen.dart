import 'package:flutter/material.dart';

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
                    IcButton(label: l10n.inviteUser, icon: IcIcon.mais, onPressed: () => _invite(context, vm)),
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

  Future<void> _invite(BuildContext context, UsersViewModel vm) async {
    final l10n = AppLocalizations.of(context);
    final input = await _showInviteDialog(context);
    if (input == null || !context.mounted) return;
    final result = await vm.invite(name: input.$1, email: input.$2, role: input.$3);
    if (!context.mounted) return;
    showResult(
      context,
      result,
      success: l10n.inviteSent(input.$2),
      failure: result.code == 'emailTaken' ? l10n.emailTaken : null,
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

enum _MemberAction { role, toggle, resend }

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
        if (member.email != null) PopupMenuItem(value: _MemberAction.resend, child: Text(l10n.resendInvite)),
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
      case _MemberAction.resend:
        final sent = await vm.resendInvite(member);
        if (!context.mounted) return;
        showResult(context, sent, success: l10n.inviteSent(member.email ?? ''));
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

Future<(String, String, Role)?> _showInviteDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  var role = Role.user;
  return showDialog<(String, String, Role)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.inviteUser),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
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
                const SizedBox(height: IcSpace.s16),
                LabeledField(
                  label: l10n.fieldEmail,
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) ? l10n.emailInvalid : null,
                ),
                const SizedBox(height: IcSpace.s16),
                Text(l10n.columnUserType, style: IcText.labelS.copyWith(color: IcColors.textSecondary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<Role>(
                  initialValue: role,
                  isExpanded: true,
                  items: [for (final r in assignableRoles) DropdownMenuItem(value: r, child: Text(roleText(l10n, r)))],
                  onChanged: (v) => setState(() => role = v ?? role),
                ),
                const SizedBox(height: IcSpace.s12),
                Text(l10n.inviteNote, style: IcText.bodyS.copyWith(color: IcColors.textMuted)),
              ],
            ),
          ),
        ),
        actions: [
          IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
          IcButton(
            label: l10n.sendInvite,
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.of(context).pop((name.text.trim(), email.text.trim(), role));
            },
          ),
        ],
      ),
    ),
  );
}
