import 'package:flutter/material.dart';

import '../../common/app_services.dart';
import '../../common/repository_failure.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_drawer.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/role.dart';
import 'bump_layout_version.dart';
import 'cart_status_label.dart';
import 'create_drawer_dialog.dart';
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
  late final Future<Membership?> _myMembership =
      AppServicesScope.of(context).institutions.getMyMembership(widget.cart.institutionId);

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
        CartDrawer(id: '', cartId: widget.cart.id, name: input.name, rows: input.rows, columns: input.columns),
      );
      await bumpCartLayoutVersion(services, widget.cart);
    } on RepositoryFailure catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível criar a gaveta. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cart.name),
        actions: [
          FutureBuilder<Membership?>(
            future: _myMembership,
            builder: (context, snapshot) {
              if (!_canManageDrawers(snapshot.data)) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Responsáveis',
                icon: const Icon(Icons.badge_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ResponsibleUsersScreen(institutionId: widget.cart.institutionId, cartId: widget.cart.id),
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
            child: Chip(label: Text(cartStatusLabel(widget.cart.status))),
          ),
        ),
      ),
      body: StreamBuilder<List<CartDrawer>>(
        stream: services.drawers.watchDrawers(widget.cart.institutionId, widget.cart.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Não foi possível carregar as gavetas: ${snapshot.error}'),
              ),
            );
          }
          final drawers = snapshot.data ?? const <CartDrawer>[];
          if (drawers.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Ainda não existem gavetas neste carro.', textAlign: TextAlign.center),
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
                  subtitle: Text('${drawer.rows} linhas × ${drawer.columns} colunas'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SlotEditorScreen(cart: widget.cart, drawer: drawer)),
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
            label: const Text('Nova gaveta'),
          );
        },
      ),
    );
  }
}
