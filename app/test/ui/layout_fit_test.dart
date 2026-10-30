// Validates the layout rule (design change, 14 Oct 2026):
// - tablet (1280 × 800) and desktop (1440 × 900): no screen scrolls, in any
//   direction; long lists/tables are paged; the slot panel sits over the
//   drawer grid;
// - phone (844 × 390): vertical scrolling is allowed, horizontal is not.
//
// Each test renders a screen with deliberately large data (dense 12-row
// drawers, dozens of carts/products) and fails on any RenderFlex overflow or
// any Scrollable that could actually scroll.
//
// Real devices (30 Oct 2026 review, docs/REVIEW_2026-10-30.md §5.1): the
// sizes above have no safe-area insets and no App rail, so screens that
// passed here overflowed on an iPhone 16 and an iPad mini. The "real devices"
// group renders inside the App shell frame with each device's insets.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/common/l10n/app_localizations.dart';
import 'package:icrash_app/src/common/locale_scope.dart';
import 'package:icrash_app/src/domain/entities/cart.dart';
import 'package:icrash_app/src/domain/entities/cart_report.dart';
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
import 'package:icrash_app/src/ui/core/theme/tokens.dart';
import 'package:icrash_app/src/ui/core/widgets/fit.dart';
import 'package:icrash_app/src/ui/core/widgets/ic_button.dart';
import 'package:icrash_app/src/ui/core/widgets/slot_grid.dart';
import 'package:icrash_app/src/ui/features/auth/login_screen.dart';
import 'package:icrash_app/src/ui/features/cart/cart_screen.dart';
import 'package:icrash_app/src/ui/features/carts/carts_screen.dart';
import 'package:icrash_app/src/ui/features/dashboard/cart_config_screen.dart';
import 'package:icrash_app/src/ui/features/dashboard/catalog_screen.dart';
import 'package:icrash_app/src/ui/features/dashboard/grid_editor_screen.dart';
import 'package:icrash_app/src/ui/features/dashboard/shifts_screen.dart';
import 'package:icrash_app/src/ui/features/dashboard/templates_screen.dart';
import 'package:icrash_app/src/ui/features/dashboard/users_screen.dart';
import 'package:icrash_app/src/ui/features/drawer/drawer_screen.dart';
import 'package:icrash_app/src/ui/features/monthly_check/monthly_check_screen.dart';
import 'package:icrash_app/src/ui/features/reports/report_screen.dart';
import 'package:icrash_app/src/ui/shells/app_shell.dart';
import 'package:icrash_app/src/ui/shells/shell_navigation.dart';

import '../fakes/fake_repositories.dart';

const phone = Size(844, 390);
const tablet = Size(1280, 800);
const desktop = Size(1440, 900);

/// A real device in landscape: logical size and safe-area insets.
typedef _Device = ({String name, Size size, EdgeInsets padding});

/// iPhone 16: notch side 59 px on both sides in landscape, home indicator 21 px.
const iphone16 = (name: 'iPhone 16', size: Size(852, 393), padding: EdgeInsets.only(left: 59, right: 59, bottom: 21));

/// iPad mini (6th gen): status bar 24 px, home indicator 20 px.
const ipadMini = (name: 'iPad mini', size: Size(1133, 744), padding: EdgeInsets.only(top: 24, bottom: 20));

const _devices = <_Device>[iphone16, ipadMini];

const _institution = Institution(id: 'inst', name: 'Hospital da Ribeira');

class _NoNavigation implements ShellNavigation {
  @override
  void openCart(String cartId) {}
  @override
  void openDrawer(String cartId, String drawerId, {String? slotId}) {}
  @override
  void openReport(String reportId) {}
  @override
  void showReports({String? cartId}) {}
  @override
  void cartOpened(String cartId) {}
  @override
  void cartClosed(String cartId) {}
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
  // Products are spread over the drawers in order (one product per cart):
  // drawer 0 gets the first rows × columns products, and so on.
  final assignments = <CartProductAssignment>[
    for (var d = 0; d < drawers; d++)
      for (var r = 0; r < rows; r++)
        for (var c = 0; c < columns; c++)
          if ((r * columns + c) % 5 != 4 && d * rows * columns + r * columns + c < products)
            CartProductAssignment(
              id: d == 0 ? 'a${r}_$c' : 'a${d}_${r}_$c',
              cartId: 'c0',
              drawerId: 'd$d',
              slotId: 'r${r}c$c',
              productId: 'p${d * rows * columns + r * columns + c}',
              currentQuantity: (r + c) % 4,
              targetQuantity: 4,
              earliestKnownExpiry: now.add(Duration(days: (r * 7 + c * 3 + d * 11) % 90 - 10)),
            ),
  ];
  return buildTestServices(
    carts: FakeCartRepository(carts: [
      for (var i = 0; i < carts; i++)
        Cart(id: 'c$i', institutionId: 'inst', name: 'Carro de Urgência $i', service: 'Urgência', location: 'Piso 0 · Sala $i'),
    ]),
    drawers: FakeDrawerRepository(drawers: [
      for (var d = 0; d < drawers; d++) CartDrawer(id: 'd$d', cartId: 'c0', number: d + 1, rows: rows, columns: columns),
    ]),
    inventory: FakeInventoryRepository(assignments: assignments),
    products: FakeProductRepository(products: productList),
    institutions: FakeInstitutionRepository(members: const [
      Membership(uid: 'me', institutionId: 'inst', role: Role.institutionAdmin, status: MembershipStatus.active, displayName: 'Rui Costa'),
      Membership(uid: 'u1', institutionId: 'inst', role: Role.user, status: MembershipStatus.active, displayName: 'Ana Silva'),
    ]),
  );
}

/// Renders [screen]. With [padding] the view gets those safe-area insets; with
/// [appShell] the screen sits inside the App shell frame (rail + safe area),
/// as it does on a phone or tablet.
Future<void> _pump(
  WidgetTester tester,
  Size size,
  AppServices services,
  Widget screen, {
  EdgeInsets padding = EdgeInsets.zero,
  bool appShell = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  final insets = FakeViewPadding(left: padding.left, top: padding.top, right: padding.right, bottom: padding.bottom);
  tester.view.padding = insets;
  tester.view.viewPadding = insets;
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
    LocaleScope(
      locale: const Locale('pt'),
      setLocale: (_) {},
      child: MaterialApp(
        theme: buildAppTheme(),
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppServicesScope(
          services: services,
          child: SessionScope(
            session: session,
            child: ShellNavigationScope(
              navigation: _NoNavigation(),
              child: Scaffold(
                body: appShell
                    ? AppShellFrame(rail: const ColoredBox(color: IcColors.bgSidebar), child: screen)
                    : screen,
              ),
            ),
          ),
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

/// Fails when a button label is cut with an ellipsis (RV-6).
void _expectButtonLabelsFit(WidgetTester tester) {
  final labels = find.descendant(of: find.byType(IcButton), matching: find.byType(RichText));
  for (final element in labels.evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: 'Button label "${paragraph.text.toPlainText()}" is cut on this screen',
    );
  }
}

/// Fails when any text inside [within] is cut (RV-13: "# com produto" cut
/// at "com" on an iPad mini).
void _expectTextsNotCut(WidgetTester tester, Finder within) {
  for (final element in find.descendant(of: within, matching: find.byType(RichText)).evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    expect(paragraph.didExceedMaxLines, isFalse, reason: 'Text "${paragraph.text.toPlainText()}" is cut on this screen');
  }
}

/// Phones may scroll vertically (except A1, RV-5); tablets never scroll.
void _expectFits(WidgetTester tester, _Device device, {bool strict = false}) {
  final phone = device.size.height < 500;
  _expectNoScroll(tester, axes: phone && !strict ? {Axis.horizontal} : {Axis.vertical, Axis.horizontal});
  _expectButtonLabelsFit(tester);
}

/// A finished monthly check by "me" with problems found, optionally signed.
Future<String> _monthlyReport(AppServices services, {required bool signed}) async {
  final report = await services.reports.createReport(CartReport(
    id: '',
    institutionId: 'inst',
    cartId: 'c0',
    cartName: 'Carro de Urgência 0',
    kind: ReportKind.monthlyCheck,
    status: ReportStatus.pendingSignature,
    createdAt: DateTime.now(),
    createdByUid: 'me',
    createdByName: 'Rui Costa',
    drawersChecked: 6,
    drawersTotal: 6,
    positionsChecked: 120,
    positionsTotal: 120,
    findings: [
      for (var i = 0; i < 6; i++)
        ReportFinding(
          productName: 'Produto de teste com nome longo $i',
          position: 'B${i + 1}',
          issue: FindingIssue.values[i % FindingIssue.values.length],
          detail: '1/4 · 28/11/2026',
        ),
    ],
    notes: 'Faltam duas ampolas de adrenalina; reposição pedida à farmácia.',
  ));
  if (signed) await services.reports.signReport('inst', report.id, uid: 'me', name: 'Rui Costa');
  return report.id;
}

void main() {
  setUpAll(_loadFonts);

  // 30 Oct 2026 review: what the devices showed (RV-5–RV-9, RV-13, RV-14).
  group('real devices: App screens inside the shell, with safe-area insets', () {
    for (final device in _devices) {
      final name = device.name;

      testWidgets('A1 sign-in ($name): fits with no scrolling, PIN button not cut', (tester) async {
        await _pump(
          tester,
          device.size,
          _services(),
          LoginScreen(onSignedIn: () async {}, onUsePin: () {}, onCartLogin: () {}, savedSessionAvailable: true),
          padding: device.padding,
        );
        _expectFits(tester, device, strict: true);
      });

      testWidgets('A4 carts in the real App shell ($name): the rail fits beside the notch', (tester) async {
        await _pump(tester, device.size, _services(carts: 20), const AppShell(), padding: device.padding);
        _expectFits(tester, device);
      });

      testWidgets('A5 cart ($name): 10 drawers, drawer rows not cut', (tester) async {
        await _pump(tester, device.size, _services(drawers: 10, products: 120), const CartScreen(cartId: 'c0'),
            padding: device.padding, appShell: true);
        _expectFits(tester, device);
        _expectTextsNotCut(tester, find.byType(FitList));
      });

      testWidgets('A6 drawer ($name): 8 × 10 grid, panel open', (tester) async {
        await _pump(tester, device.size, _services(rows: 8, columns: 10, products: 80),
            const DrawerScreen(cartId: 'c0', drawerId: 'd0'),
            padding: device.padding, appShell: true);
        _expectFits(tester, device);
        await tester.tap(find.byType(SlotCell).first);
        await _settle(tester);
        expect(find.byTooltip('Fechar painel'), findsOneWidget);
        _expectFits(tester, device);
      });

      for (final (step, index) in [('middle drawer', 1), ('last drawer', 2)]) {
        testWidgets('A8 monthly check ($name): $step', (tester) async {
          final services = _services(drawers: 3, products: 90);
          await services.reports.saveCheckDraft('inst', 'c0', {'drawerIndex': index, 'notes': '', 'states': <String, Object?>{}});
          await _pump(tester, device.size, services, const MonthlyCheckScreen(cartId: 'c0'),
              padding: device.padding, appShell: true);
          _expectFits(tester, device);
        });
      }

      for (final signed in [false, true]) {
        testWidgets('A9 monthly report ($name): ${signed ? 'signed' : 'unsigned, PIN field shown'}', (tester) async {
          final services = _services();
          final id = await _monthlyReport(services, signed: signed);
          await _pump(tester, device.size, services, ReportScreen(reportId: id), padding: device.padding, appShell: true);
          _expectFits(tester, device);
        });
      }
    }
  });

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

  // Screens changed by the 28 Oct database decisions (29 Oct 2026).
  group('screens changed on 29 Oct fit without scrolling', () {
    for (final (name, size) in [('tablet', tablet), ('desktop', desktop)]) {
      testWidgets('A1 sign-in ($name): no "forgot password", credentials note', (tester) async {
        await _pump(
          tester,
          size,
          _services(),
          LoginScreen(onSignedIn: () async {}, onUsePin: () {}, onCartLogin: () {}, savedSessionAvailable: true),
        );
        _expectNoScroll(tester);
      });

      testWidgets('B3 cart configuration ($name): 10 numbered drawers', (tester) async {
        await _pump(tester, size, _services(drawers: 10), const CartConfigScreen(cartId: 'c0'));
        _expectNoScroll(tester);
      });

      testWidgets('B6 templates ($name): active/archived tabs', (tester) async {
        await _pump(tester, size, _services(), const TemplatesScreen());
        _expectNoScroll(tester);
      });

      testWidgets('B7 users ($name): "Criar utilizador"', (tester) async {
        await _pump(tester, size, _services(), const UsersScreen());
        _expectNoScroll(tester);
      });
    }

    testWidgets('A1 sign-in on a phone may scroll vertically but not sideways', (tester) async {
      await _pump(
        tester,
        phone,
        _services(),
        LoginScreen(onSignedIn: () async {}, onUsePin: () {}, onCartLogin: () {}, savedSessionAvailable: true),
      );
      _expectNoScroll(tester, axes: {Axis.horizontal});
    });
  });
}
