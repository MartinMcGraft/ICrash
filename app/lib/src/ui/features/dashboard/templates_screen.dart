import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/cart.dart';
import '../../../domain/entities/cart_template.dart';
import '../../core/format.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/fit.dart';
import '../../core/widgets/layout.dart';
import '../../shells/shell_navigation.dart';
import 'cart_config_screen.dart';
import 'cart_form_dialog.dart';
import 'templates_view_model.dart';

/// B6 · Modelos.
class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.read(context);
    return ViewModelBuilder<TemplatesViewModel>(
      create: (services) => TemplatesViewModel(services, session),
      builder: (context, vm) {
        final canEdit = SessionScope.of(context).canEditStructure;
        final selected = vm.selected;
        return Padding(
          padding: contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: l10n.templatesTitle,
                subtitle: l10n.templatesSubtitle,
                trailing: [
                  if (canEdit)
                    IcButton(
                      label: l10n.newTemplate,
                      icon: IcIcon.mais,
                      onPressed: vm.carts.isEmpty ? null : () => _create(context, vm),
                    ),
                ],
              ),
              const SizedBox(height: IcSpace.s20),
              Expanded(
                child: switch (vm.state) {
                  LoadState.loading => const StateView.loading(),
                  LoadState.error => StateView.message(message: l10n.stateLoadError),
                  LoadState.ready when vm.templates.isEmpty =>
                    StateView.message(message: l10n.templatesEmptyDashboard, icon: IcIcon.modelo),
                  LoadState.ready => Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: FitList(
                            itemCount: vm.templates.length,
                            itemExtent: 80,
                            spacing: IcSpace.s12,
                            itemBuilder: (context, i) => _TemplateCard(
                              template: vm.templates[i],
                              usage: vm.usageOf(vm.templates[i].id),
                              selected: vm.templates[i].id == vm.selectedId,
                              onTap: () => vm.select(vm.templates[i].id),
                              onDuplicate: canEdit ? () => _duplicate(context, vm, vm.templates[i]) : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: IcSpace.s20),
                        if (selected != null)
                          SidePanel(width: 460, child: _Preview(vm: vm, template: selected, canEdit: canEdit)),
                      ],
                    ),
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _create(BuildContext context, TemplatesViewModel vm) async {
    final l10n = AppLocalizations.of(context);
    final input = await _showTemplateDialog(context, title: l10n.newTemplate, carts: vm.carts, requireCart: true);
    if (input == null || !context.mounted) return;
    final result = await vm.createFromCart(cartId: input.cartId!, name: input.name);
    if (!context.mounted) return;
    showResult(context, result, success: l10n.templateSaved);
  }

  Future<void> _duplicate(BuildContext context, TemplatesViewModel vm, CartTemplate template) async {
    final l10n = AppLocalizations.of(context);
    final input = await _showTemplateDialog(
      context,
      title: l10n.actionDuplicate,
      carts: const [],
      initialName: l10n.templateCopyName(template.name),
    );
    if (input == null || !context.mounted) return;
    final result = await vm.duplicate(template, name: input.name);
    if (!context.mounted) return;
    showResult(context, result, success: l10n.templateSaved);
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.usage, required this.selected, required this.onTap, this.onDuplicate});
  final CartTemplate template;
  final int usage;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDuplicate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SurfaceCard(
      onTap: onTap,
      borderColor: selected ? IcColors.borderFocus : IcColors.borderDefault,
      borderWidth: selected ? 2 : 1,
      padding: const EdgeInsets.all(IcSpace.s16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(template.name, style: IcText.titleS, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  l10n.templateSummary(template.drawers.length, template.positionCount, usage),
                  style: IcText.bodyS.copyWith(color: IcColors.textSecondary),
                ),
              ],
            ),
          ),
          if (onDuplicate != null) IcButton(label: l10n.actionDuplicate, style: IcButtonStyle.secondary, onPressed: onDuplicate),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.vm, required this.template, required this.canEdit});
  final TemplatesViewModel vm;
  final CartTemplate template;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final format = IcFormat.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(template.name, style: IcText.titleM),
        const SizedBox(height: 2),
        Text(
          l10n.templateUpdatedBy(format.date(template.updatedAt), template.updatedByName),
          style: IcText.bodyS.copyWith(color: IcColors.textSecondary),
        ),
        const SizedBox(height: IcSpace.s16),
        Expanded(
          child: FitList(
            itemCount: template.drawers.length,
            itemExtent: 46,
            itemBuilder: (context, i) {
              final drawer = template.drawers[i];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: IcSpace.s12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: IcColors.bgSurfaceMuted,
                  borderRadius: BorderRadius.circular(IcRadius.md),
                  border: Border.all(color: IcColors.borderDefault),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text('${i + 1} · ${drawer.name}', style: IcText.labelM, overflow: TextOverflow.ellipsis)),
                    Text(
                      l10n.templateDrawerSize(drawer.rows, drawer.columns, drawer.positionCount),
                      style: IcText.bodyS.copyWith(color: IcColors.textSecondary),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: IcSpace.s8),
        Text(l10n.templateCopyNote, style: IcText.bodyS.copyWith(color: IcColors.textMuted)),
        const SizedBox(height: IcSpace.s16),
        if (SessionScope.of(context).isManager)
          IcButton(
            label: l10n.createCartFromThisTemplate,
            icon: IcIcon.mais,
            expand: true,
            busy: vm.busy,
            onPressed: () => _createCart(context),
          ),
        if (canEdit) ...[
          const SizedBox(height: IcSpace.s8),
          Row(
            children: [
              Expanded(
                child: IcButton(
                  label: l10n.editTemplate,
                  icon: IcIcon.editar,
                  style: IcButtonStyle.secondary,
                  expand: true,
                  onPressed: () => _edit(context),
                ),
              ),
              const SizedBox(width: IcSpace.s8),
              IcIconButton(icon: IcIcon.apagar, tooltip: l10n.deleteTemplate, onPressed: () => _delete(context)),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _createCart(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final input = await showCartFormDialog(context, title: l10n.createFromTemplate, templates: vm.templates, initialTemplate: template);
    if (input == null || !context.mounted) return;
    final result = await vm.createCart(input.template ?? template, name: input.name, service: input.service, location: input.location);
    if (!context.mounted) return;
    showResult(context, result, success: l10n.cartCreated(input.name));
    final cart = result.value;
    if (cart != null) Navigator.of(context).push(sectionRoute((_) => CartConfigScreen(cartId: cart.id)));
  }

  Future<void> _edit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final input = await _showTemplateDialog(context, title: l10n.editTemplate, carts: vm.carts, initialName: template.name);
    if (input == null || !context.mounted) return;
    final result = await vm.update(template, name: input.name, refreshFromCartId: input.cartId);
    if (!context.mounted) return;
    showResult(context, result, success: l10n.templateSaved);
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirmAction(
      context,
      title: l10n.deleteTemplate,
      message: l10n.deleteTemplateConfirm(template.name),
      confirmLabel: l10n.deleteTemplate,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final result = await vm.delete(template);
    if (!context.mounted) return;
    showResult(context, result, success: l10n.templateDeleted);
  }
}

class _TemplateInput {
  const _TemplateInput(this.name, this.cartId);
  final String name;
  final String? cartId;
}

/// Name + source cart. For "Novo modelo" the cart is required; when editing
/// it is optional ("Atualizar a partir de um carrinho").
Future<_TemplateInput?> _showTemplateDialog(
  BuildContext context, {
  required String title,
  required List<Cart> carts,
  String? initialName,
  bool requireCart = false,
}) {
  final l10n = AppLocalizations.of(context);
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: initialName ?? '');
  String? cartId;
  return showDialog<_TemplateInput>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
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
                if (carts.isNotEmpty) ...[
                  const SizedBox(height: IcSpace.s16),
                  Text(
                    requireCart ? l10n.templateSourceCart : l10n.templateRefreshFromCart,
                    style: IcText.labelS.copyWith(color: IcColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    initialValue: cartId,
                    isExpanded: true,
                    items: [
                      if (!requireCart) DropdownMenuItem<String?>(value: null, child: Text(l10n.templateKeepStructure)),
                      for (final c in carts) DropdownMenuItem<String?>(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) => setState(() => cartId = v),
                    validator: (v) => requireCart && v == null ? l10n.templateChooseCart : null,
                  ),
                  if (requireCart) ...[
                    const SizedBox(height: IcSpace.s8),
                    Text(l10n.templateCopyNote, style: IcText.bodyS.copyWith(color: IcColors.textMuted)),
                  ],
                ],
              ],
            ),
          ),
        ),
        actions: [
          IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
          IcButton(
            label: l10n.actionSave,
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.of(context).pop(_TemplateInput(name.text.trim(), cartId));
            },
          ),
        ],
      ),
    ),
  );
}
