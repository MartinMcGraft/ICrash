import 'package:flutter/material.dart';

import '../../common/app_services.dart';
import '../../common/l10n/app_localizations.dart';
import '../../common/locale_scope.dart';
import '../../common/repository_failure.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_product_assignment.dart';
import '../../domain/entities/institution.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/role.dart';
import '../../domain/entities/usage_event.dart';
import '../../domain/inventory_rules.dart';
import '../../services/scanner_platform_support.dart';
import '../cart/assignment_status_label.dart';
import '../cart/cart_detail_screen.dart';
import '../cart/cart_status_label.dart';
import '../cart/create_cart_dialog.dart';
import '../cart/edit_cart_dialog.dart';
import '../members/members_screen.dart';
import '../products/products_screen.dart';
import '../reports/history_screen.dart';
import '../scanning/cart_qr_scan_screen.dart';

/// Per-institution home (spec section 49): a small dashboard — cross-cart
/// alerts (manager+ only, see `docs/FIREBASE_MODEL.md`'s "Why the cross-cart
/// alerts query is manager+ only") and recent activity — above the
/// accessible-cart list, with a name filter for fast access when there are
/// many carts.
class InstitutionHomeScreen extends StatefulWidget {
  const InstitutionHomeScreen({super.key, required this.institution});

  final Institution institution;

  @override
  State<InstitutionHomeScreen> createState() => _InstitutionHomeScreenState();
}

class _InstitutionHomeScreenState extends State<InstitutionHomeScreen> {
  late final Future<Membership?> _myMembership = AppServicesScope.of(context)
      .institutions
      .getMyMembership(widget.institution.id);
  late final Future<List<Product>> _products = AppServicesScope.of(context)
      .products
      .watchProducts(widget.institution.id)
      .first;

  // Cached once rather than created inline in `build()`: the search field
  // and the type-ahead filter below both call `setState` on every keystroke,
  // and a fresh `watchX(...)` call returns a new Stream each time, which
  // would otherwise tear down and re-subscribe every Firestore listener on
  // this screen on every keystroke instead of just re-filtering already-
  // received data.
  late final Stream<List<Cart>> _cartsStream = AppServicesScope.of(context)
      .carts
      .watchAccessibleCarts(widget.institution.id);
  late final Stream<List<CartProductAssignment>> _allAssignmentsStream =
      AppServicesScope.of(context).inventory
          .watchAllAssignments(widget.institution.id);
  late final Stream<List<UsageEvent>> _recentEventsStream = AppServicesScope.of(
    context,
  ).usage.watchRecentEvents(widget.institution.id, limit: 5);

  String _searchQuery = '';

  bool _canManageCarts(Membership? membership) {
    if (membership == null || !membership.isActive) return false;
    return membership.role == Role.institutionAdmin ||
        membership.role == Role.manager ||
        membership.role == Role.platformSuperAdmin;
  }

  bool _isInstitutionAdmin(Membership? membership) {
    if (membership == null || !membership.isActive) return false;
    return membership.role == Role.institutionAdmin ||
        membership.role == Role.platformSuperAdmin;
  }

  /// Spec section 33: scanning only resolves an id, it never grants access
  /// by itself — `CartRepository.getCart` still goes through the same
  /// Firestore Rules as any other cart read, so a scanned code for a cart
  /// this user cannot access simply fails here instead of opening it.
  Future<void> _scanCartQr(BuildContext context) async {
    final services = AppServicesScope.of(context);
    final target = await showCartQrScanScreen(
      context,
      createScanner: services.createInternalQrScanner,
    );
    if (target == null || !context.mounted) return;
    try {
      final cart = await services.carts.getCart(
        target.institutionId,
        target.cartId,
      );
      if (!context.mounted) return;
      if (cart == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).dashboardOpenCartError)),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CartDetailScreen(
            cart: cart,
            expiryWarningDays: widget.institution.expiryWarningDays,
          ),
        ),
      );
    } on RepositoryFailure catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).dashboardOpenCartError)),
      );
    }
  }

  Future<void> _createCart(BuildContext context) async {
    final services = AppServicesScope.of(context);
    // A fresh call, not a reused reference to `_cartsStream`: that field's
    // underlying broadcast stream already delivered its one relevant
    // snapshot to the list's own StreamBuilder, so listening to it again
    // here would wait indefinitely for a next emission that may never come.
    final existingCarts = await services.carts
        .watchAccessibleCarts(widget.institution.id)
        .first;
    if (!context.mounted) return;
    final name = await showCreateCartDialog(
      context,
      existingNames: existingCarts.map((c) => c.name).toList(),
    );
    if (name == null || !context.mounted) return;
    try {
      await services.carts.createCart(
        widget.institution.id,
        Cart(id: '', institutionId: widget.institution.id, name: name),
      );
    } on RepositoryFailure catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).dashboardCreateCartError)),
      );
    }
  }

  /// Renames a cart (or toggles it out of service) straight from the
  /// dashboard list, without navigating into [CartDetailScreen] first.
  Future<void> _editCartFromList(BuildContext context, Cart cart) async {
    final input = await showEditCartDialog(context, cart);
    if (input == null || !context.mounted) return;
    final services = AppServicesScope.of(context);
    try {
      await services.carts.updateCart(
        widget.institution.id,
        Cart(
          id: cart.id,
          institutionId: cart.institutionId,
          name: input.name,
          status: input.status,
          layoutVersion: cart.layoutVersion,
          templateId: cart.templateId,
        ),
      );
    } on RepositoryFailure catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).cartDetailUpdateError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServicesScope.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.institution.name),
        actions: [
          if (isCameraScanningSupported)
            IconButton(
              tooltip: l10n.cartQrScanTitle,
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => _scanCartQr(context),
            ),
          IconButton(
            tooltip: l10n.historyScreenTitle,
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    HistoryScreen(institutionId: widget.institution.id),
              ),
            ),
          ),
          FutureBuilder<Membership?>(
            future: _myMembership,
            builder: (context, snapshot) {
              if (!_canManageCarts(snapshot.data)) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: l10n.productsScreenTitle,
                icon: const Icon(Icons.medication_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductsScreen(
                      institutionId: widget.institution.id,
                      canManage: true,
                    ),
                  ),
                ),
              );
            },
          ),
          FutureBuilder<Membership?>(
            future: _myMembership,
            builder: (context, snapshot) {
              if (!_isInstitutionAdmin(snapshot.data)) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: l10n.membersScreenTitle,
                icon: const Icon(Icons.group_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        MembersScreen(institution: widget.institution),
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<Locale>(
            tooltip: l10n.languageSwitcherTooltip,
            icon: const Icon(Icons.language),
            onSelected: (locale) => LocaleScope.of(context).setLocale(locale),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: const Locale('pt'),
                child: Text(l10n.languagePortuguese),
              ),
              PopupMenuItem(
                value: const Locale('en'),
                child: Text(l10n.languageEnglish),
              ),
            ],
          ),
          IconButton(
            tooltip: l10n.actionSignOut,
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Pop back to `_AuthGate` (the root route) first: it is the
              // only widget listening to authStateChanges(), so any screen
              // still pushed on top of it (this one, or a cart/drawer pushed
              // above it) would otherwise keep showing its now-unauthenticated
              // Firestore stream's permission-denied error instead of
              // redirecting to the login screen.
              Navigator.of(context).popUntil((route) => route.isFirst);
              services.auth.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Cart>>(
        stream: _cartsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.dashboardLoadCartsError(snapshot.error!)),
              ),
            );
          }
          final carts = snapshot.data ?? const <Cart>[];
          if (carts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.dashboardCartsEmpty, textAlign: TextAlign.center),
              ),
            );
          }
          final query = _searchQuery.trim().toLowerCase();
          final filtered = query.isEmpty
              ? carts
              : carts
                    .where((c) => c.name.toLowerCase().contains(query))
                    .toList();
          // A single subscription to `_allAssignmentsStream`, shared by the
          // alerts panel and the cart list's status/edit column below: two
          // independent `StreamBuilder`s off the same broadcast stream can
          // end up subscribing a frame apart (e.g. each gated behind its own
          // `FutureBuilder<Membership?>`, which — unlike a Future — a
          // Stream does not replay past events to a late subscriber), so the
          // second one can silently miss the one-shot emission and stay
          // empty forever.
          return StreamBuilder<List<CartProductAssignment>>(
            stream: _allAssignmentsStream,
            builder: (context, assignmentsSnapshot) {
              final allAssignments =
                  assignmentsSnapshot.data ?? const <CartProductAssignment>[];
              final now = DateTime.now();
              return Column(
                children: [
                  FutureBuilder<Membership?>(
                    future: _myMembership,
                    builder: (context, membershipSnapshot) {
                      if (!_canManageCarts(membershipSnapshot.data)) {
                        return const SizedBox.shrink();
                      }
                      if (assignmentsSnapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Text(
                            l10n.dashboardLoadAlertsError(assignmentsSnapshot.error!),
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        );
                      }
                      return _CrossCartAlerts(
                        assignments: allAssignments,
                        expiryWarningDays: widget.institution.expiryWarningDays,
                        carts: carts,
                        products: _products,
                      );
                    },
                  ),
                  _RecentActivity(
                    eventsStream: _recentEventsStream,
                    products: _products,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        labelText: l10n.dashboardSearchCartLabel,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                l10n.dashboardNoCartMatches,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : FutureBuilder<Membership?>(
                            future: _myMembership,
                            builder: (context, membershipSnapshot) {
                              final canManage = _canManageCarts(membershipSnapshot.data);
                              return ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final cart = filtered[index];
                                  final effectiveStatus = InventoryRules.computeEffectiveCartStatus(
                                    manualStatus: cart.status,
                                    cartAssignments: allAssignments
                                        .where((a) => a.cartId == cart.id)
                                        .toList(),
                                    expiryWarningDays: widget.institution.expiryWarningDays,
                                    now: now,
                                  );
                                  return Card(
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.medical_services_outlined,
                                      ),
                                      title: Text(cart.name),
                                      subtitle: Text(
                                        cartStatusLabel(context, effectiveStatus),
                                      ),
                                      trailing: canManage
                                          ? IconButton(
                                              tooltip: l10n.actionEdit,
                                              icon: const Icon(Icons.edit_outlined),
                                              onPressed: () => _editCartFromList(context, cart),
                                            )
                                          : const Icon(Icons.chevron_right),
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => CartDetailScreen(
                                            cart: cart,
                                            expiryWarningDays: widget.institution.expiryWarningDays,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<Membership?>(
        future: _myMembership,
        builder: (context, snapshot) {
          if (!_canManageCarts(snapshot.data)) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _createCart(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.createCartTitle),
          );
        },
      ),
    );
  }
}

/// Cross-cart dashboard alerts (spec section 49): expiring/expired products
/// and stock below its minimum, across every cart in the institution at
/// once — manager+ only, since the underlying `collectionGroup('assignments')`
/// Rules can only safely check role, not per-cart responsibility (see
/// `docs/FIREBASE_MODEL.md`). Cart/product names are resolved from data the
/// screen already has (the same `carts` stream the list below uses, and the
/// same one-shot `products` future `_RecentActivity` uses) rather than
/// fetched again.
class _CrossCartAlerts extends StatelessWidget {
  const _CrossCartAlerts({
    required this.assignments,
    required this.expiryWarningDays,
    required this.carts,
    required this.products,
  });

  final List<CartProductAssignment> assignments;
  final int expiryWarningDays;
  final List<Cart> carts;
  final Future<List<Product>> products;

  String _cartName(AppLocalizations l10n, String cartId) {
    for (final cart in carts) {
      if (cart.id == cartId) return cart.name;
    }
    return l10n.cartRemoved;
  }

  String _productName(AppLocalizations l10n, List<Product> products, String productId) {
    for (final product in products) {
      if (product.id == productId) return product.name;
    }
    return l10n.productRemoved;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final alerts = <(CartProductAssignment, AssignmentAlert)>[
      for (final assignment in assignments)
        if (InventoryRules.computeAlert(
              assignment,
              expiryWarningDays: expiryWarningDays,
              now: now,
            )
            case final alert?)
          (assignment, alert),
    ];
    if (alerts.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<Product>>(
      future: products,
      builder: (context, productsSnapshot) {
        final productList = productsSnapshot.data ?? const <Product>[];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dashboardAlertsTitle,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              for (final (assignment, alert) in alerts)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${_assignmentAlertLabel(l10n, alert)} · ${_productName(l10n, productList, assignment.productId)}'
                    ' · ${_cartName(l10n, assignment.cartId)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

String _assignmentAlertLabel(AppLocalizations l10n, AssignmentAlert alert) => switch (alert) {
  AssignmentAlert.expired => l10n.assignmentStatusExpired,
  AssignmentAlert.expiringSoon => l10n.assignmentStatusExpiringSoon,
  AssignmentAlert.belowMinimum => l10n.alertBelowMinimum,
};

/// Institution-wide recent stock activity (spec section 49's "recent
/// relevant activity"), one of the few dashboard signals that does not need
/// a per-cart or cross-cart query: [UsageRepository.watchRecentEvents] is
/// already scoped to the whole institution.
class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.eventsStream, required this.products});

  final Stream<List<UsageEvent>> eventsStream;
  final Future<List<Product>> products;

  String _productName(AppLocalizations l10n, List<Product> products, String productId) {
    for (final product in products) {
      if (product.id == productId) return product.name;
    }
    return l10n.productRemoved;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<List<UsageEvent>>(
      stream: eventsStream,
      builder: (context, eventsSnapshot) {
        if (eventsSnapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              l10n.dashboardLoadActivityError(eventsSnapshot.error!),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }
        final events = eventsSnapshot.data ?? const <UsageEvent>[];
        if (events.isEmpty) return const SizedBox.shrink();
        return FutureBuilder<List<Product>>(
          future: products,
          builder: (context, productsSnapshot) {
            final productList = productsSnapshot.data ?? const <Product>[];
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dashboardRecentActivityTitle,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  for (final event in events)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${usageEventTypeLabel(context, event.type)} · ${_productName(l10n, productList, event.productId)} '
                        '(${event.amount > 0 ? '+' : ''}${event.amount})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
