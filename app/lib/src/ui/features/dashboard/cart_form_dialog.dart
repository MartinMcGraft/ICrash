import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/cart_template.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/layout.dart';

class CartFormResult {
  const CartFormResult({required this.name, this.service, this.location, this.template});
  final String name;
  final String? service;
  final String? location;
  final CartTemplate? template;
}

/// "Novo carrinho" / "Criar a partir de modelo".
Future<CartFormResult?> showCartFormDialog(
  BuildContext context, {
  required String title,
  List<CartTemplate>? templates,
  CartTemplate? initialTemplate,
}) {
  final l10n = AppLocalizations.of(context);
  final name = TextEditingController();
  final service = TextEditingController();
  final location = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var template = initialTemplate ?? templates?.firstOrNull;
  String? clean(String v) => v.trim().isEmpty ? null : v.trim();
  return showDialog<CartFormResult>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (templates != null) ...[
                    Text(l10n.templateLabel, style: IcText.labelS.copyWith(color: IcColors.textSecondary)),
                    const SizedBox(height: 6),
                    if (templates.isEmpty)
                      Text(l10n.templatesEmpty, style: IcText.bodyM.copyWith(color: IcColors.textSecondary))
                    else
                      DropdownButtonFormField<CartTemplate>(
                        initialValue: template,
                        items: [for (final t in templates) DropdownMenuItem(value: t, child: Text(t.name))],
                        onChanged: (v) => setState(() => template = v),
                      ),
                    const SizedBox(height: IcSpace.s12),
                  ],
                  LabeledField(
                    label: l10n.fieldName,
                    controller: name,
                    autofocus: true,
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.validationEnterName : null,
                  ),
                  const SizedBox(height: IcSpace.s12),
                  LabeledField(label: l10n.fieldService, controller: service, hint: l10n.fieldServiceHint),
                  const SizedBox(height: IcSpace.s12),
                  LabeledField(label: l10n.fieldLocation, controller: location, hint: l10n.fieldLocationHint),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
          IcButton(
            label: l10n.actionCreate,
            onPressed: templates != null && template == null
                ? null
                : () {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.of(context).pop(CartFormResult(
                      name: name.text.trim(),
                      service: clean(service.text),
                      location: clean(location.text),
                      template: template,
                    ));
                  },
          ),
        ],
      ),
    ),
  );
}
