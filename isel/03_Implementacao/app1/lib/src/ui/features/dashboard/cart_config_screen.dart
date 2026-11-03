import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/fit.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/status.dart';
import '../../shells/shell_navigation.dart';
import '../cart/cart_dialogs.dart';
import 'cart_config_view_model.dart';
import 'drawer_form_dialog.dart';
import 'grid_editor_screen.dart';

/// B3 · Carrinho — configuração.
class CartConfigScreen extends StatefulWidget {
  const CartConfigScreen({super.key, required this.cartId});
  final String cartId;

  @override
  State<CartConfigScreen> createState() => _CartConfigScreenState();
}

class _CartConfigScreenState extends State<CartConfigScreen> {
  final _name = TextEditingController();
  final _service = TextEditingController();
  final _location = TextEditingController();
  bool _filled = false;

  @override
  void dispose() {
    _name.dispose();
    _service.dispose();
    _location.dispose();
    super.dispose();
  }

  String? _clean(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.read(context);
    return ViewModelBuilder<CartConfigViewModel>(
      create: (services) => CartConfigViewModel(services, session, widget.cartId),
      builder: (context, vm) {
        final cart = vm.cart;
        if (vm.data.cartMissing) return StateView.message(message: l10n.cartLoginNotFound, icon: IcIcon.carro);
        if (cart == null) return const StateView.loading();
        if (!_filled) {
          _name.text = cart.name;
          _service.text = cart.service ?? '';
          _location.text = cart.location ?? '';
          _filled = true;
        }
        final canEdit = SessionScope.of(context).canEditStructure;
        return Padding(
          padding: contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: cart.name,
                subtitle: l10n.cartConfigSubtitle,
                onBack: () => Navigator.of(context).maybePop(),
                trailing: [
                  if (canEdit) ...[
                    IcButton(
                      label: l10n.archiveCart,
                      icon: IcIcon.arquivar,
                      style: IcButtonStyle.ghost,
                      onPressed: () async {
                        final ok = await confirmAction(
                          context,
                          title: l10n.archiveCart,
                          message: l10n.archiveCartConfirm,
                          confirmLabel: l10n.archiveCart,
                          destructive: true,
                        );
                        if (!ok || !context.mounted) return;
                        final result = await vm.archive();
                        if (!context.mounted) return;
                        showResult(context, result, success: l10n.cartArchived);
                        if (result.isOk) Navigator.of(context).maybePop();
                      },
                    ),
                    IcButton(
                      label: l10n.saveChanges,
                      icon: IcIcon.confirmar,
                      busy: vm.busy,
                      onPressed: () async {
                        if (_name.text.trim().isEmpty) return showMessage(context, l10n.validationEnterName);
                        final result = await vm.save(name: _name.text.trim(), service: _clean(_service), location: _clean(_location));
                        if (context.mounted) showResult(context, result, success: l10n.cartUpdatedMessage);
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: IcSpace.s20),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 400,
                      child: SurfaceCard(
                        elevated: false,
                        padding: const EdgeInsets.all(IcSpace.s20),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(l10n.cartInfoTitle, style: IcText.titleS),
                              const SizedBox(height: IcSpace.s16),
                              LabeledField(label: l10n.fieldName, controller: _name, readOnly: !canEdit),
                              const SizedBox(height: IcSpace.s16),
                              LabeledField(label: l10n.fieldService, controller: _service, readOnly: !canEdit),
                              const SizedBox(height: IcSpace.s16),
                              LabeledField(label: l10n.fieldLocation, controller: _location, readOnly: !canEdit),
                              const SizedBox(height: IcSpace.s16),
                              LabeledField(
                                key: ValueKey(vm.templateName),
                                label: l10n.originTemplate,
                                initialValue: vm.templateName ?? '—',
                                readOnly: true,
                              ),
                              const SizedBox(height: IcSpace.s16),
                              Row(
                                children: [
                                  Text(l10n.columnState, style: IcText.labelS.copyWith(color: IcColors.textSecondary)),
                                  const SizedBox(width: IcSpace.s12),
                                  CartStateChip(status: cart.status, compact: true),
                                  const Spacer(),
                                  if (SessionScope.of(context).canChangeCartState)
                                    TextButton(
                                      onPressed: () async {
                                        final status = await showChangeStatusDialog(context, cart.status);
                                        if (status == null || !context.mounted) return;
                                        final result = await vm.setStatus(status);
                                        if (!context.mounted) return;
                                        showResult(context, result, success: l10n.cartUpdatedMessage);
                                      },
                                      child: Text(l10n.changeStateAction),
                                    ),
                                ],
                              ),
                              const SizedBox(height: IcSpace.s8),
                              CheckRow(
                                label: l10n.autoStateLabel,
                                value: vm.autoStatus,
                                onChanged: canEdit ? (v) => vm.setAutoStatus(v) : null,
                              ),
                              const SizedBox(height: IcSpace.s8),
                              Text(l10n.autoStateRule, style: IcText.bodyS.copyWith(color: IcColors.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: IcSpace.s20),
                    Expanded(child: _Drawers(vm: vm, canEdit: canEdit)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Drawers extends StatelessWidget {
  const _Drawers({required this.vm, required this.canEdit});
  final CartConfigViewModel vm;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final drawers = vm.drawers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          l10n.drawersCount(drawers.length),
          trailing: canEdit
              ? IcButton(
                  label: l10n.addDrawer,
                  icon: IcIcon.mais,
                  style: IcButtonStyle.secondary,
                  onPressed: () async {
                    final input = await showDrawerFormDialog(context);
                    if (input == null || !context.mounted) return;
                    final result = await vm.addDrawer(name: input.name, rows: input.rows, columns: input.columns);
                    if (!context.mounted) return;
                    showResult(context, result);
                  },
                )
              : null,
        ),
        const SizedBox(height: IcSpace.s12),
        Expanded(
          child: FitDataTable(
            columns: [
              TableColumnSpec(l10n.columnNumber, width: 40),
              TableColumnSpec(l10n.fieldName, flex: 4),
              TableColumnSpec(l10n.columnSize, flex: 2),
              TableColumnSpec(l10n.columnPositions, flex: 2),
              TableColumnSpec(l10n.columnWithProduct, flex: 2),
              TableColumnSpec('', width: 150, alignEnd: true),
            ],
            emptyText: l10n.cartDetailDrawersEmpty,
            rows: [
              for (final (number, drawer, health) in drawers)
                [
                  CellText('$number', primary: true),
                  CellText(drawer.name),
                  CellText('${drawer.rows} × ${drawer.columns}'),
                  CellText('${health.positions}'),
                  CellText('${health.withProduct}'),
                  IcButton(
                    label: l10n.editGrid,
                    icon: IcIcon.grelha,
                    style: IcButtonStyle.secondary,
                    onPressed: () => Navigator.of(context).push(
                      sectionRoute((_) => GridEditorScreen(cartId: vm.cartId, drawerId: drawer.id)),
                    ),
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}
