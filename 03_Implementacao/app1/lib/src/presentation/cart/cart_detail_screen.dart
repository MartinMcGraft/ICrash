import 'package:flutter/material.dart';

import '../../common/app_services.dart';
import '../../common/l10n/app_localizations.dart';
import '../../common/repository_failure.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_drawer.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/role.dart';
import 'bump_layout_version.dart';
import 'cart_status_label.dart';
import '../scanning/cart_qr_code_screen.dart';
import 'create_drawer_dialog.dart';
import 'duplicate_cart_dialog.dart';
import 'edit_cart_dialog.dart';
import 'product_search_screen.dart';
import 'responsible_users_screen.dart';
import 'slot_editor_screen.dart';

/// Cart detail: status plus its drawers (spec section 36). Slot layout for
/// each drawer is edited in [SlotEditorScreen]; stock/assignments
/// (workstreams C/E/F) are still future work.
class CartDetailScreen extends StatefulWidget {
  const CartDetailScreen({super.key, required this.cart});

  final Cart cart;

  @override
  State<CartDetailScreen> createState() => _CartDetailScreenState();
}

class _CartDetailScreenState extends State<CartDetailScreen> {
  late final Future<Membership?> _myMembership = AppServicesScope.of(context)
      .institutions
      .getMyMembership(widget.cart.institutionId);

  bool _canManageDrawers(Membership? membership) {
    if (membership == null || !membership.isActive) return false;
    return membership.role == Role.institutionAdmin ||
        membership.role == Role.manager ||
        membership.role == Role.platformSuperAdmin;
  }

  Future<void> _createDrawer(BuildContext context) async {
    final input = await showCreateDrawerDialog(context);
    if (input == null || !context.mounted) return;
    final services = AppServicesScope.of(context);
    try {
      await services.drawers.createDrawer(
        widget.cart.institutionId,
        widget.cart.id,
        CartDrawer(
          id: '',
          cartId: widget.cart.id,
          name: input.name,
          rows: input.rows,
          columns: input.columns,
        ),
      );
      await bumpCartLayoutVersion(services, widget.cart);
    } on RepositoryFailure catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).cartDetailCreateDrawerError)),
      );
    }
  }

  Future<void> _editCart(BuildContext context) async {
    final input = await showEditCartDialog(context, widget.cart);
    if (input == null || !context.mounted) return;
    final services = AppServicesScope.of(context);
    try {
      await services.carts.updateCart(
        widget.cart.institutionId,
        Cart(
          id: widget.cart.id,
          institutionId: widget.cart.institutionId,
          name: input.name,
          status: input.status,
          layoutVersion: widget.cart.layoutVersion,
          templateId: widget.cart.templateId,
        ),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).cartUpdatedMessage)));
      Navigator.of(context).pop();
    } on RepositoryFailure catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).cartDetailUpdateError)),
      );
    }
  }

  Future<void> _duplicateCart(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final newName = await showDuplicateCartDialog(
      context,
      defaultName: l10n.duplicateCartDefaultName(widget.cart.name),
    );
    if (newName == null || !context.mounted) return;
    final services = AppServicesScope.of(context);
    try {
      final newCart = await services.carts.createCart(
        widget.cart.institutionId,
        Cart(id: '', institutionId: widget.cart.institutionId, name: newName),
      );
      final drawers = await services.drawers
          .watchDrawers(widget.cart.institutionId, widget.cart.id)
          .first;
      for (final drawer in drawers) {
        final newDrawer = await services.drawers.createDrawer(
          widget.cart.institutionId,
          newCart.id,
          CartDrawer(
            id: '',
            cartId: newCart.id,
            name: drawer.name,
            rows: drawer.rows,
            columns: drawer.columns,
          ),
        );
        final slots = await services.drawers
            .watchSlots(widget.cart.institutionId, widget.cart.id, drawer.id)
            .first;
        if (slots.isNotEmpty) {
          await services.drawers.replaceSlots(
            widget.cart.institutionId,
            newCart.id,
            newDrawer.id,
            slots,
          );
        }
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cartDuplicatedMessage(newCart.name))),
      );
      Navigator.of(context).pop();
    } on RepositoryFailure catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cartDetailDuplicateError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cart.name),
        actions: [
          IconButton(
            tooltip: l10n.actionShowQrCode,
            icon: const Icon(Icons.qr_code_2),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CartQrCodeScreen(cart: widget.cart),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.actionSearchProduct,
            icon: const Icon(Icons.search),
            onPressed: () async {
              final membership = await _myMembership;
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductSearchScreen(
                    cart: widget.cart,
                    canManage: _canManageDrawers(membership),
                  ),
                ),
              );
            },
          ),
          FutureBuilder<Membership?>(
            future: _myMembership,
            builder: (context, snapshot) {
              if (!_canManageDrawers(snapshot.data)) {
                return const SizedBox.shrink();
              }
              return PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'edit') _editCart(context);
                  if (action == 'duplicate') _duplicateCart(context);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text(l10n.actionEdit)),
                  PopupMenuItem(
                    value: 'duplicate',
                    child: Text(l10n.actionDuplicate),
                  ),
                ],
              );
            },
          ),
          FutureBuilder<Membership?>(
            future: _myMembership,
            builder: (context, snapshot) {
              if (!_canManageDrawers(snapshot.data)) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: l10n.actionResponsible,
                icon: const Icon(Icons.badge_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ResponsibleUsersScreen(
                      institutionId: widget.cart.institutionId,
                      cartId: widget.cart.id,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Chip(
              label: Text(cartStatusLabel(context, widget.cart.status)),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<CartDrawer>>(
        stream: services.drawers.watchDrawers(
          widget.cart.institutionId,
          widget.cart.id,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.cartDetailLoadDrawersError(snapshot.error!)),
              ),
            );
          }
          final drawers = snapshot.data ?? const <CartDrawer>[];
          if (drawers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.cartDetailDrawersEmpty, textAlign: TextAlign.center),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: drawers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final drawer = drawers[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.grid_view_outlined),
                  title: Text(drawer.name),
                  subtitle: Text(l10n.drawerGridSize(drawer.rows, drawer.columns)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          SlotEditorScreen(cart: widget.cart, drawer: drawer),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<Membership?>(
        future: _myMembership,
        builder: (context, snapshot) {
          if (!_canManageDrawers(snapshot.data)) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _createDrawer(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.createDrawerTitle),
          );
        },
      ),
    );
  }
}
