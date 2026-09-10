import 'package:flutter/material.dart';

/// Collects a name for a cart duplicate (spec section 39). Duplication
/// copies drawer/slot configuration only — never product assignments, stock,
/// batches, or usage/audit history — so the new cart starts empty and ready
/// to be stocked from scratch.
Future<String?> showDuplicateCartDialog(BuildContext context, {required String defaultName}) {
  final nameController = TextEditingController(text: defaultName);
  final formKey = GlobalKey<FormState>();

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Duplicar carro'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Cria um novo carro com as mesmas gavetas e slots. Não copia produtos, stock nem histórico.'),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome do novo carro'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Indique um nome' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.of(context).pop(nameController.text.trim());
            }
          },
          child: const Text('Duplicar'),
        ),
      ],
    ),
  );
}
