import 'package:flutter/material.dart';

/// Shows a minimal name-only dialog and returns the trimmed name, or `null`
/// if cancelled. Cart creation only needs a name up front (spec section 21
/// keeps the model simple); drawers/slots are configured later.
Future<String?> showCreateCartDialog(BuildContext context) {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Novo carro'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome do carro'),
          validator: (value) => (value == null || value.trim().isEmpty) ? 'Indique um nome' : null,
          onFieldSubmitted: (_) {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop(controller.text.trim());
            }
          },
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
              Navigator.of(context).pop(controller.text.trim());
            }
          },
          child: const Text('Criar'),
        ),
      ],
    ),
  );
}
