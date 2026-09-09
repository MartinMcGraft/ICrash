import 'package:flutter/material.dart';

class NewProductInput {
  const NewProductInput({required this.name, this.description, this.unitDescription, this.gtin});

  final String name;
  final String? description;
  final String? unitDescription;
  final String? gtin;
}

/// Collects the minimal product fields the prototype needs (spec section
/// 21): a name, plus optional description/unit/GTIN. Product images and
/// richer metadata are explicitly deferred.
Future<NewProductInput?> showCreateProductDialog(BuildContext context) {
  final nameController = TextEditingController();
  final unitController = TextEditingController();
  final gtinController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  return showDialog<NewProductInput>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Novo produto'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Indique um nome' : null,
            ),
            TextFormField(
              controller: unitController,
              decoration: const InputDecoration(labelText: 'Unidade (opcional)', hintText: 'ex.: 1 mg/mL, ampola 1 mL'),
            ),
            TextFormField(
              controller: gtinController,
              decoration: const InputDecoration(labelText: 'GTIN (opcional)'),
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
              Navigator.of(context).pop(NewProductInput(
                name: nameController.text.trim(),
                unitDescription: unitController.text.trim().isEmpty ? null : unitController.text.trim(),
                gtin: gtinController.text.trim().isEmpty ? null : gtinController.text.trim(),
              ));
            }
          },
          child: const Text('Criar'),
        ),
      ],
    ),
  );
}
