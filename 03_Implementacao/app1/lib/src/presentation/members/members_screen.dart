import 'package:flutter/material.dart';

import '../../common/app_services.dart';
import '../../common/repository_failure.dart';
import '../../domain/entities/institution.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/role.dart';
import 'add_member_dialog.dart';
import 'membership_labels.dart';

/// Institution-admin-only member management (spec section 16): list every
/// membership, add a brand-new member, change a member's role, enable or
/// disable them. `memberships`/`memberIndex` are always written together by
/// the repository, never directly here.
class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key, required this.institution});

  final Institution institution;

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  Future<void> _addMember(BuildContext context) async {
    final services = AppServicesScope.of(context);
    final input = await showAddMemberDialog(context);
    if (input == null || !context.mounted) return;
    try {
      await services.institutions.createMember(
        widget.institution.id,
        email: input.email,
        password: input.password,
        role: input.role,
      );
    } on RepositoryFailure catch (error) {
      if (!context.mounted) return;
      final message = switch (error.reason) {
        RepositoryFailureReason.conflict =>
          'Já existe uma conta com este e-mail.',
        RepositoryFailureReason.invalidInput =>
          'E-mail ou palavra-passe inválidos.',
        _ => 'Não foi possível criar o membro. Tente novamente.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _changeRole(BuildContext context, Membership membership) async {
    final services = AppServicesScope.of(context);
    final selected = await showDialog<Role>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Mudar cargo'),
        children: [
          for (final r in assignableRoles)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(r),
              child: Text(roleLabel(context, r)),
            ),
        ],
      ),
    );
    if (selected == null || selected == membership.role || !context.mounted) {
      return;
    }
    try {
      await services.institutions.updateMemberRole(
        widget.institution.id,
        membership.uid,
        selected,
      );
    } on RepositoryFailure catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível mudar o cargo. Tente novamente.'),
        ),
      );
    }
  }

  Future<void> _toggleStatus(
    BuildContext context,
    Membership membership,
  ) async {
    final services = AppServicesScope.of(context);
    final next = membership.isActive
        ? MembershipStatus.disabled
        : MembershipStatus.active;
    try {
      await services.institutions.setMembershipStatus(
        widget.institution.id,
        membership.uid,
        next,
      );
    } on RepositoryFailure catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível alterar o estado do membro. Tente novamente.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    final myUid = services.auth.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Membros')),
      body: StreamBuilder<List<Membership>>(
        stream: services.institutions.watchMembers(widget.institution.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não foi possível carregar os membros: ${snapshot.error}',
                ),
              ),
            );
          }
          final members = snapshot.data ?? const <Membership>[];
          if (members.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Ainda não existem membros nesta instituição.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final member = members[index];
              final isSelf = member.uid == myUid;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(member.uid, overflow: TextOverflow.ellipsis),
                  subtitle: Text(roleLabel(context, member.role)),
                  trailing: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        label: Text(
                          membershipStatusLabel(context, member.status),
                        ),
                      ),
                      if (!isSelf)
                        PopupMenuButton<String>(
                          onSelected: (action) {
                            if (action == 'role') _changeRole(context, member);
                            if (action == 'status') {
                              _toggleStatus(context, member);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'role',
                              child: Text('Mudar cargo'),
                            ),
                            PopupMenuItem(
                              value: 'status',
                              child: Text(
                                member.isActive ? 'Desativar' : 'Reativar',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMember(context),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Novo membro'),
      ),
    );
  }
}
