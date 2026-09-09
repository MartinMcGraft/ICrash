import 'package:flutter/material.dart';

class NewDrawerInput {
  const NewDrawerInput({required this.name, required this.rows, required this.columns});

  final String name;
  final int rows;
  final int columns;
}

const _gridSizeOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

/// Collects a name and the base grid size (spec section 36) for a new
/// drawer. Individual slots start as one cell each; merging into bigger
/// slots happens afterwards in the slot editor.
Future<NewDrawerInput?> showCreateDrawerDialog(BuildContext context) {
  final nameController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var rows = 5;
  var columns = 7;

  return showDialog<NewDrawerInput>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Nova gaveta'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome da gaveta'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Indique um nome' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: rows,
                      decoration: const InputDecoration(labelText: 'Linhas'),
                      items: [for (final n in _gridSizeOptions) DropdownMenuItem(value: n, child: Text('$n'))],
                      onChanged: (value) => setState(() => rows = value ?? rows),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: columns,
                      decoration: const InputDecoration(labelText: 'Colunas'),
                      items: [for (final n in _gridSizeOptions) DropdownMenuItem(value: n, child: Text('$n'))],
                      onChanged: (value) => setState(() => columns = value ?? columns),
                    ),
                  ),
                ],
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
                Navigator.of(context).pop(NewDrawerInput(name: nameController.text.trim(), rows: rows, columns: columns));
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    ),
  );
}
