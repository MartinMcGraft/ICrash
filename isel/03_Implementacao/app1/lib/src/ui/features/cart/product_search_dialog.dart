import 'package:flutter/material.dart';

import '../../../common/l10n/app_localizations.dart';
import '../../../domain/entities/cart_drawer.dart';
import '../../../domain/entities/cart_product_assignment.dart';
import '../../../domain/inventory_health.dart';
import '../../core/cart_live_data.dart';
import '../../core/icons/ic_icons.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/status.dart';
import '../../shells/shell_navigation.dart';
import '../drawer/drawer_screen.dart';

class ProductHit {
  const ProductHit({
    required this.productName,
    required this.assignment,
    required this.drawer,
    required this.drawerNumber,
    required this.position,
    required this.health,
  });
  final String productName;
  final CartProductAssignment assignment;
  final CartDrawer drawer;
  final int drawerNumber;
  final String position;
  final SlotHealth health;
}

/// "Pesquisar produto" inside a cart.
class ProductSearchViewModel extends ViewModel {
  ProductSearchViewModel(this.data, this.expiryWarningDays);

  final CartLiveData data;
  final int expiryWarningDays;
  String query = '';

  void setQuery(String value) {
    query = value;
    notify();
  }

  List<ProductHit> get hits {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final now = DateTime.now();
    final result = <ProductHit>[];
    for (final assignment in data.assignments) {
      final name = data.productName(assignment.productId);
      final gtin = data.products[assignment.productId]?.gtin ?? '';
      if (!name.toLowerCase().contains(q) && !gtin.contains(q)) continue;
      final located = data.locate(assignment.slotId);
      if (located == null) continue;
      final (drawer, slot) = located;
      result.add(ProductHit(
        productName: name,
        assignment: assignment,
        drawer: drawer,
        drawerNumber: data.drawers.indexOf(drawer) + 1,
        position: slotPositionLabel(slot),
        health: InventoryHealth.slotHealth(assignment, expiryWarningDays: expiryWarningDays, now: now),
      ));
    }
    result.sort((a, b) => a.productName.compareTo(b.productName));
    return result;
  }
}

Future<void> showProductSearch(BuildContext context, CartLiveData data) async {
  final session = SessionScope.read(context);
  final navigator = Navigator.of(context);
  final hit = await showDialog<ProductHit>(
    context: context,
    builder: (context) => _ProductSearchDialog(
      viewModel: ProductSearchViewModel(data, session.institution.expiryWarningDays),
    ),
  );
  if (hit == null) return;
  navigator.push(sectionRoute((_) => DrawerScreen(cartId: data.cartId, drawerId: hit.drawer.id, initialSlotId: hit.assignment.slotId)));
}

class _ProductSearchDialog extends StatefulWidget {
  const _ProductSearchDialog({required this.viewModel});
  final ProductSearchViewModel viewModel;

  @override
  State<_ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<_ProductSearchDialog> {
  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = widget.viewModel;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(IcSpace.s20),
          child: ListenableBuilder(
            listenable: vm,
            builder: (context, _) {
              final hits = vm.hits;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.actionSearchProduct, style: IcText.titleM),
                  const SizedBox(height: IcSpace.s16),
                  SearchField(hint: l10n.productSearchHint, onChanged: vm.setQuery, width: null, autofocus: true),
                  const SizedBox(height: IcSpace.s12),
                  Expanded(
                    child: vm.query.trim().isEmpty
                        ? StateView.message(message: l10n.productSearchPrompt, icon: IcIcon.pesquisar)
                        : hits.isEmpty
                            ? StateView.message(message: l10n.productSearchEmpty, icon: IcIcon.pesquisar)
                            : ListView.separated(
                                itemCount: hits.length,
                                separatorBuilder: (_, _) => const Divider(),
                                itemBuilder: (context, index) {
                                  final hit = hits[index];
                                  return InkWell(
                                    onTap: () => Navigator.of(context).pop(hit),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: IcSpace.s12, horizontal: IcSpace.s4),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(hit.productName, style: IcText.labelM),
                                                const SizedBox(height: 2),
                                                Text(
                                                  l10n.productLocation(hit.drawerNumber, hit.drawer.name, hit.position),
                                                  style: IcText.bodyS.copyWith(color: IcColors.textSecondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text('${hit.assignment.currentQuantity} / ${hit.assignment.targetQuantity}', style: IcText.labelM),
                                          const SizedBox(width: IcSpace.s12),
                                          SlotHealthBadge(health: hit.health),
                                          const SizedBox(width: IcSpace.s8),
                                          const IcIconView(IcIcon.seguinte, size: 20, color: IcColors.textSecondary),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
