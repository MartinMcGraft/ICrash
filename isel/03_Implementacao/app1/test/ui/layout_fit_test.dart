// Validates the layout rule (design change, 14 Oct 2026):
// - tablet (1280 × 800) and desktop (1440 × 900): no screen scrolls, in any
//   direction; long lists/tables are paged; the slot panel sits over the
//   drawer grid;
// - phone (844 × 390): vertical scrolling is allowed, horizontal is not.
//
// Each test renders a screen with deliberately large data (dense 12-row
// drawers, dozens of carts/products) and fails on any RenderFlex overflow or
// any Scrollable that could actually scroll.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/common/l10n/app_localizations.dart';
import 'package:icrash_app/src/domain/entities/cart.dart';
import 'package:icrash_app/src/domain/entities/cart_drawer.dart';
import 'package:icrash_app/src/domain/entities/cart_product_assignment.dart';
import 'package:icrash_app/src/domain/entities/institution.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
import 'package:icrash_app/src/domain/entities/product.dart';
import 'package:icrash_app/src/domain/entities/role.dart';
import 'package:icrash_app/src/domain/entities/shift.dart';
import 'package:icrash_app/src/domain/repositories/auth_repository.dart';
import 'package:icrash_app/src/ui/core/session/session.dart';
import 'package:icrash_app/src/ui/core/theme/app_theme.dart';
import 'package:icrash_app/src/ui/core/widgets/slot_grid.dart';
import 'package:icrash_app/src/ui/features/cart/cart_screen.dart';
import 'package:icrash_app/src/ui/features/carts/carts_screen.dart';
import 'package:icrash_app/src/ui/features/dashboard/catalog_screen.dart';
import 'package:icrash_app/src/ui/features/dashboard/grid_editor_screen.dart';
import 'package:icrash_app/src/ui/features/dashboard/shifts_screen.dart';
import 'package:icrash_app/src/ui/features/drawer/drawer_screen.dart';
import 'package:icrash_app/src/ui/shells/shell_navigation.dart';

import '../fakes/fake_repositories.dart';

const phone = Size(844, 390);
const tablet = Size(1280, 800);
const desktop = Size(1440, 900);

const _institution = Institution(id: 'inst', name: 'Hospital da Ribeira');

class _NoNavigation implements ShellNavigation {
  @override
  void openCart(String cartId) {}
  @override
  void openDrawer(String cartId, String drawerId, {String? slotId}) {}
  @override
  void openReport(String reportId) {}
  @override
  void showReports() {}
}

Future<void> _loadFonts() async {
  final sans = FontLoader('IBMPlexSans');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    sans.addFont(rootBundle.load('assets/fonts/IBMPlexSans-$w.ttf'));
  }
  await sans.load();
  final mono = FontLoader('IBMPlexMono')
    ..addFont(rootBundle.load('assets/fonts/IBMPlexMono-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/IBMPlexMono-Medium.ttf'));
  await mono.load();
}

/// Realistic data: [carts] carts, a [rows] × [columns] drawer in cart c0
/// with a product in most positions, [products] products.
AppServices _services({int carts = 1, int rows = 5, int columns = 6, int products = 30, int drawers = 1}) {
  final productList = [
    for (var i = 0; i < products; i++)
      Product(
        id: 'p$i',
        institutionId: 'inst',
        name: 'Produto de teste com nome longo $i',
        unitDescription: 'Ampola 1 ml',
        gtin: '0560123456${i.toString().padLeft(4, '0')}',
        category: ProductCategory.values[i % 3],
        expiryWarningDays: 30,
      ),
  ];
  final now = DateTime.now();
  final assignments = <CartProductAssignment>[
    for (var r = 0; r < rows; r++)
      for (var c = 0; c < columns; c++)
        if ((r * columns + c) % 5 != 4 && r * columns + c < products)
          CartProductAssignment(
            id: 'a${r}_$c',
            cartId: 'c0',
            slotId: 'r${r}c$c',
            productId: 'p${r * columns + c}',
            currentQuantity: (r + c) % 4,
            targetQuantity: 4,
            minimumQuantity: 2,
            earliestKnownExpiry: now.add(Duration(days: (r * 7 + c * 3) % 90 - 10)),
          ),
  ];
  return buildTestServices(
    carts: FakeCartRepository(carts: [
      for (var i = 0; i < carts; i++)
        Cart(id: 'c$i', institutionId: 'inst', name: 'Carro de Urgência $i', service: 'Urgência', location: 'Piso 0 · Sala $i'),
    ]),
    drawers: FakeDrawerRepository(drawers: [
      for (var d = 0; d < drawers; d++) CartDrawer(id: 'd$d', cartId: 'c0', name: 'Gaveta de fármacos $d', rows: rows, columns: columns),
    ]),
    inventory: FakeInventoryRepository(assignments: assignments),
    products: FakeProductRepository(products: productList),
    institutions: FakeInstitutionRepository(members: const [
      Membership(uid: 'me', institutionId: 'inst', role: Role.institutionAdmin, status: MembershipStatus.active, displayName: 'Rui Costa'),
      Membership(uid: 'u1', institutionId: 'inst', role: Role.user, status: MembershipStatus.active, displayName: 'Ana Silva'),
    ]),
  );
}

Future<void> _pump(WidgetTester tester, Size size, AppServices services, Widget screen) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final session = SessionController(
    services: services,
    user: const AuthUser(uid: 'me', email: 'rui@h.pt'),
    institution: _institution,
    membership: const Membership(
      uid: 'me',
      institutionId: 'inst',
      role: Role.institutionAdmin,
      status: MembershipStatus.active,
      displayName: 'Rui Costa',
    ),
    institutionCount: 1,
  );
  addTearDown(session.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AppServicesScope(
        services: services,
        child: SessionScope(
          session: session,
          child: ShellNavigationScope(navigation: _NoNavigation(), child: Scaffold(body: screen)),
        ),
      ),
    ),
  );
  await _settle(tester);
}

/// Lets streams deliver and animations finish (no pumpAndSettle: a loading
/// spinner would never settle).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Fails when any scroll view on screen can actually scroll in [axes].
void _expectNoScroll(WidgetTester tester, {Set<Axis> axes = const {Axis.vertical, Axis.horizontal}}) {
  for (final state in tester.stateList<ScrollableState>(find.byType(Scrollable))) {
    final position = state.position;
    if (!axes.contains(position.axis)) continue;
    expect(
      position.maxScrollExtent,
      lessThanOrEqualTo(0.5),
      reason: 'A ${position.axis.name} scroll view can scroll by ${position.maxScrollExtent.toStringAsFixed(1)} px '
          '(${state.widget.runtimeType} in ${state.context.widget.runtimeType})',
    );
  }
}

void main() {
  setUpAll(_loadFonts);

  group('A6 drawer (slot grid + panel over it)', () {
    testWidgets('tablet: dense 12 × 10 drawer fits with no scrolling, panel opens over the grid', (tester) async {
      final services = _services(rows: 12, columns: 10, products: 120);
      await _pump(tester, tablet, services, const DrawerScreen(cartId: 'c0', drawerId: 'd0'));
      expect(find.byType(SlotGrid), findsOneWidget);
      expect(tester.getRect(find.byType(SlotGrid)).right, lessThanOrEqualTo(tablet.width));
      _expectNoScroll(tester);

      await tester.tap(find.byType(SlotCell).first);
      await _settle(tester);
      expect(find.byTooltip('Fechar painel'), findsOneWidget);
      // The grid keeps its full width: the panel is drawn over it.
      expect(tester.getRect(find.byType(SlotGrid)).width, greaterThan(tablet.width * 0.8));
      _expectNoScroll(tester);

      await tester.tap(find.byTooltip('Fechar painel'));
      await _settle(tester);
      expect(find.byTooltip('Fechar painel'), findsNothing);
    });

    testWidgets('desktop: 12 × 12 drawer fits with no scrolling', (tester) async {
      final services = _services(rows: 12, columns: 12, products: 144);
      await _pump(tester, desktop, services, const DrawerScreen(cartId: 'c0', drawerId: 'd0'));
      _expectNoScroll(tester);
    });

    testWidgets('phone: never scrolls sideways (vertical is allowed)', (tester) async {
      final services = _services(rows: 12, columns: 10, products: 120);
      await _pump(tester, phone, services, const DrawerScreen(cartId: 'c0', drawerId: 'd0'));
      _expectNoScroll(tester, axes: {Axis.horizontal});
      await tester.tap(find.byType(SlotCell).first);
      await _settle(tester);
      _expectNoScroll(tester, axes: {Axis.horizontal});
    });
  });

  group('B4 grid editor', () {
    testWidgets('desktop: 12 × 12 grid fits, position panel opens over it', (tester) async {
      final services = _services(rows: 12, columns: 12, products: 144);
      await _pump(tester, desktop, services, const GridEditorScreen(cartId: 'c0', drawerId: 'd0'));
      _expectNoScroll(tester);
      await tester.tap(find.byType(SlotCell).first);
      await _settle(tester);
      expect(find.byTooltip('Fechar painel'), findsOneWidget);
      _expectNoScroll(tester);
    });

    testWidgets('tablet size: grid editor fits', (tester) async {
      final services = _services(rows: 8, columns: 10, products: 80);
      await _pump(tester, tablet, services, const GridEditorScreen(cartId: 'c0', drawerId: 'd0'));
      _expectNoScroll(tester);
    });
  });

  group('lists and tables are paged instead of scrolling', () {
    testWidgets('A4 carts: 20 carts on a tablet', (tester) async {
      await _pump(tester, tablet, _services(carts: 20), const CartsScreen());
      _expectNoScroll(tester);
      expect(find.textContaining(' de 20'), findsOneWidget);
    });

    testWidgets('A5 cart: 10 drawers on a tablet', (tester) async {
      await _pump(tester, tablet, _services(drawers: 10), const CartScreen(cartId: 'c0'));
      _expectNoScroll(tester);
    });

    testWidgets('B5 catalogue: 60 products on desktop', (tester) async {
      await _pump(tester, desktop, _services(products: 60), const CatalogScreen());
      _expectNoScroll(tester);
      expect(find.textContaining(' de 60'), findsOneWidget);
    });

    testWidgets('B8 shifts: 15 carts with a full week on desktop', (tester) async {
      final services = _services(carts: 15);
      final monday = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      for (var c = 0; c < 15; c++) {
        for (var d = 0; d < 7; d++) {
          for (final p in ShiftPeriod.values) {
            await services.shifts.setShift(
              'inst',
              ShiftAssignment(cartId: 'c$c', day: DateTime(monday.year, monday.month, monday.day + d), period: p, uid: 'u1'),
            );
          }
        }
      }
      await _pump(tester, desktop, services, const ShiftsScreen());
      _expectNoScroll(tester);
    });

    testWidgets('A4 carts on a phone may scroll vertically but not sideways', (tester) async {
      await _pump(tester, phone, _services(carts: 20), const CartsScreen());
      _expectNoScroll(tester, axes: {Axis.horizontal});
    });
  });
}
