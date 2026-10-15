import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/product.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/dialogs.dart';
import '../../core/widgets/ic_button.dart';
import '../../core/widgets/fit.dart';
import '../../core/widgets/layout.dart';
import '../scanner/product_scan_sheet.dart';
import 'catalog_view_model.dart';

String productCategoryText(AppLocalizations l10n, ProductCategory? category) => switch (category) {
      ProductCategory.drug => l10n.categoryDrug,
      ProductCategory.material => l10n.categoryMaterial,
      ProductCategory.fluid => l10n.categoryFluid,
      null => '—',
    };

/// B5 · Catálogo.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = SessionScope.read(context);
    return ViewModelBuilder<CatalogViewModel>(
      create: (services) => CatalogViewModel(services, session),
      builder: (context, vm) {
        final canEdit = SessionScope.of(context).canEditStructure;
        final rows = vm.visible;
        return Padding(
          padding: contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: l10n.catalogTitle,
                subtitle: l10n.catalogSubtitle(vm.total, vm.cartsUsingCatalog),
                trailing: [
                  if (canEdit) ...[
                    IcButton(
                      label: l10n.importCsv,
                      icon: IcIcon.descarregar,
                      style: IcButtonStyle.secondary,
                      onPressed: () => _import(context, vm),
                    ),
                    IcButton(
                      label: l10n.newProduct,
                      icon: IcIcon.mais,
                      onPressed: () => _edit(context, vm, null),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: IcSpace.s20),
              Row(
                children: [
                  SearchField(hint: l10n.catalogSearchByNameOrGtin, onChanged: vm.setQuery),
                  const SizedBox(width: IcSpace.s12),
                  SegmentedTabs<ProductCategory?>(
                    selected: vm.filter,
                    onChanged: vm.setFilter,
                    items: [
                      TabItem(null, l10n.filterAll),
                      TabItem(ProductCategory.drug, l10n.categoryDrugs),
                      TabItem(ProductCategory.material, l10n.categoryMaterial),
                      TabItem(ProductCategory.fluid, l10n.categoryFluids),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: IcSpace.s20),
              Expanded(
                child: switch (vm.state) {
                  LoadState.loading => const StateView.loading(),
                  LoadState.error => StateView.message(message: l10n.stateLoadError),
                  LoadState.ready => FitDataTable(
                      columns: [
                        TableColumnSpec(l10n.productLabel, flex: 5),
                        TableColumnSpec(l10n.columnPresentation, flex: 3),
                        TableColumnSpec(l10n.columnGtin, flex: 3),
                        TableColumnSpec(l10n.columnCategory, flex: 2),
                        TableColumnSpec(l10n.columnInUse, flex: 2),
                        TableColumnSpec(l10n.expiryWarningShort, flex: 2),
                        if (canEdit) const TableColumnSpec('', width: 110, alignEnd: true),
                      ],
                      emptyText: vm.total == 0 ? l10n.productsEmpty : l10n.catalogNoMatches,
                      rows: [
                        for (final p in rows)
                          [
                            CellText(p.name, primary: true),
                            CellText(p.unitDescription ?? '—'),
                            CellText(p.gtin ?? '—'),
                            CellText(productCategoryText(l10n, p.category)),
                            CellText(l10n.inCartsCount(vm.usedIn(p.id))),
                            CellText(p.expiryWarningDays == null ? '—' : l10n.daysCount(p.expiryWarningDays!)),
                            if (canEdit)
                              IcButton(
                                label: l10n.actionEdit,
                                icon: IcIcon.editar,
                                style: IcButtonStyle.ghost,
                                onPressed: () => _edit(context, vm, p),
                              ),
                          ],
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

  Future<void> _edit(BuildContext context, CatalogViewModel vm, Product? product) async {
    final l10n = AppLocalizations.of(context);
    final result = await showProductFormDialog(context, institutionId: vm.session.institution.id, product: product);
    if (result == null || !context.mounted) return;
    final saved = await vm.save(result);
    if (!context.mounted) return;
    showResult(
      context,
      saved,
      success: product == null ? l10n.productCreated(result.name) : l10n.productUpdated,
      failure: saved.code == 'gtinTaken' ? l10n.gtinTaken : null,
    );
  }

  Future<void> _import(BuildContext context, CatalogViewModel vm) async {
    final l10n = AppLocalizations.of(context);
    final text = await _showImportDialog(context);
    if (text == null || !context.mounted) return;
    final result = await vm.importCsv(text);
    if (!context.mounted) return;
    final value = result.value;
    showResult(context, result, success: value == null ? null : l10n.importResult(value.created, value.skipped));
  }
}

/// "Novo produto" / "Editar produto".
Future<Product?> showProductFormDialog(BuildContext context, {required String institutionId, Product? product}) {
  final l10n = AppLocalizations.of(context);
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: product?.name ?? '');
  final unit = TextEditingController(text: product?.unitDescription ?? '');
  final gtin = TextEditingController(text: product?.gtin ?? '');
  final days = TextEditingController(text: product?.expiryWarningDays?.toString() ?? '');
  var category = product?.category;
  String? clean(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
  return showDialog<Product>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(product == null ? l10n.newProduct : l10n.editProduct),
        content: SizedBox(
          width: 460,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LabeledField(
                    label: l10n.fieldName,
                    controller: name,
                    autofocus: product == null,
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.validationEnterName : null,
                  ),
                  const SizedBox(height: IcSpace.s16),
                  LabeledField(label: l10n.columnPresentation, controller: unit, hint: l10n.createProductUnitHint),
                  const SizedBox(height: IcSpace.s16),
                  LabeledField(
                    label: l10n.columnGtin,
                    controller: gtin,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      return t.isEmpty || t.length == 8 || (t.length >= 12 && t.length <= 14) ? null : l10n.gtinInvalid;
                    },
                    trailing: IcIconButton(
                      icon: IcIcon.ler,
                      tooltip: l10n.scanGtin,
                      onPressed: () async {
                        final data = await showProductScanSheet(context);
                        if (data?.gtin != null) gtin.text = data!.gtin!;
                      },
                    ),
                  ),
                  const SizedBox(height: IcSpace.s16),
                  Text(l10n.columnCategory, style: IcText.labelS.copyWith(color: IcColors.textSecondary)),
                  const SizedBox(height: 6),
                  SegmentedTabs<ProductCategory?>(
                    selected: category,
                    onChanged: (v) => setState(() => category = v),
                    items: [
                      TabItem(ProductCategory.drug, l10n.categoryDrug),
                      TabItem(ProductCategory.material, l10n.categoryMaterial),
                      TabItem(ProductCategory.fluid, l10n.categoryFluid),
                    ],
                  ),
                  const SizedBox(height: IcSpace.s16),
                  LabeledField(
                    label: l10n.expiryWarningDaysLabel,
                    controller: days,
                    hint: l10n.expiryWarningDefaultHint,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
          IcButton(
            label: product == null ? l10n.actionCreate : l10n.actionSave,
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final base = product ?? Product(id: '', institutionId: institutionId, name: '');
              Navigator.of(context).pop(Product(
                id: base.id,
                institutionId: base.institutionId,
                name: name.text.trim(),
                description: base.description,
                unitDescription: clean(unit),
                gtin: clean(gtin),
                category: category,
                expiryWarningDays: int.tryParse(days.text.trim()),
                createdAt: base.createdAt,
              ));
            },
          ),
        ],
      ),
    ),
  );
}

Future<String?> _showImportDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final text = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.importCsv),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.importCsvHelp, style: IcText.bodyS.copyWith(color: IcColors.textSecondary)),
            const SizedBox(height: IcSpace.s8),
            Text('Adrenalina 1 mg/ml;Ampola 1 ml;05601234567890;Fármaco;30', style: IcText.mono),
            const SizedBox(height: IcSpace.s12),
            TextField(
              controller: text,
              maxLines: 10,
              minLines: 6,
              style: IcText.mono,
              decoration: InputDecoration(hintText: l10n.importCsvHint),
            ),
          ],
        ),
      ),
      actions: [
        IcButton(label: l10n.actionCancel, style: IcButtonStyle.ghost, onPressed: () => Navigator.of(context).pop()),
        IcButton(
          label: l10n.importAction,
          onPressed: () => Navigator.of(context).pop(text.text.trim().isEmpty ? null : text.text),
        ),
      ],
    ),
  );
}
