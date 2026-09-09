import 'package:flutter/material.dart';

import '../../domain/entities/role.dart';
import 'membership_labels.dart';

class NewMemberInput {
  const NewMemberInput({required this.email, required this.password, required this.role});

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
      builder: (context, setState) => AlertDialog(
        title: const Text('Novo membro'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: emailController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Indique um e-mail' : null,
              ),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Palavra-passe temporária'),
                validator: (value) =>
                    (value == null || value.length < 6) ? 'Mínimo de 6 caracteres' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Role>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Cargo'),
                items: [
                  for (final r in assignableRoles) DropdownMenuItem(value: r, child: Text(roleLabel(r))),
                ],
                onChanged: (value) => setState(() => role = value ?? role),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(NewMemberInput(
                  email: emailController.text.trim(),
                  password: passwordController.text,
                  role: role,
                ));
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    ),
  );
}
