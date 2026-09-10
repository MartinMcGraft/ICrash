import 'package:flutter/material.dart';

import '../../common/l10n/app_localizations.dart';
import '../../domain/entities/role.dart';
import 'membership_labels.dart';

class NewMemberInput {
  const NewMemberInput({
    required this.email,
    required this.password,
    required this.role,
  });

  final String email;
  final String password;
  final Role role;
}

/// Collects an e-mail, a temporary password and a role for a brand-new
/// member. There is no Cloud Function yet to invite an existing user by
/// e-mail alone (spec Phase 1 has none), so this always provisions a fresh
/// Auth account — the admin is expected to pass the temporary password to
/// the new member out of band.
Future<NewMemberInput?> showAddMemberDialog(BuildContext context) {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var role = Role.user;

  return showDialog<NewMemberInput>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.addMemberTitle),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailController,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.loginEmailLabel),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.addMemberEmailRequired
                      : null,
                ),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.addMemberPasswordLabel,
                  ),
                  validator: (value) => (value == null || value.length < 6)
                      ? l10n.addMemberPasswordMinLength
                      : null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Role>(
                  initialValue: role,
                  decoration: InputDecoration(labelText: l10n.addMemberRoleLabel),
                  items: [
                    for (final r in assignableRoles)
                      DropdownMenuItem(
                        value: r,
                        child: Text(roleLabel(context, r)),
                      ),
                  ],
                  onChanged: (value) => setState(() => role = value ?? role),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(
                    NewMemberInput(
                      email: emailController.text.trim(),
                      password: passwordController.text,
                      role: role,
                    ),
                  );
                }
              },
              child: Text(l10n.actionCreate),
            ),
          ],
        );
      },
    ),
  );
}
