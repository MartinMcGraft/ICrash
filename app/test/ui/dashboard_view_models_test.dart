import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/cart.dart';
import 'package:icrash_app/src/domain/entities/cart_drawer.dart';
import 'package:icrash_app/src/domain/entities/cart_product_assignment.dart';
import 'package:icrash_app/src/domain/entities/cart_report.dart';
import 'package:icrash_app/src/domain/entities/institution.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
import 'package:icrash_app/src/domain/entities/product.dart';
import 'package:icrash_app/src/domain/entities/role.dart';
import 'package:icrash_app/src/domain/entities/shift.dart';
import 'package:icrash_app/src/domain/entities/slot.dart';
import 'package:icrash_app/src/domain/repositories/auth_repository.dart';
import 'package:icrash_app/src/ui/core/session/session.dart';
import 'package:icrash_app/src/ui/features/dashboard/catalog_view_model.dart';
import 'package:icrash_app/src/ui/features/dashboard/grid_editor_view_model.dart';
import 'package:icrash_app/src/ui/features/dashboard/reports_history_view_model.dart';
import 'package:icrash_app/src/ui/features/dashboard/shifts_view_model.dart';
import 'package:icrash_app/src/ui/features/dashboard/templates_view_model.dart';
import 'package:icrash_app/src/ui/features/dashboard/users_view_model.dart';

import '../fakes/fake_repositories.dart';

const _institution = Institution(id: 'inst', name: 'Hospital da Ribeira');

SessionController _session(AppServices services, {Role role = Role.institutionAdmin, String uid = 'me'}) => SessionController(
      services: services,
      user: AuthUser(uid: uid, email: '$uid@h.pt'),
      institution: _institution,
      membership: Membership(uid: uid, institutionId: 'inst', role: role, status: MembershipStatus.active, displayName: 'Rui Costa'),
      institutionCount: 1,
    );

/// Lets stream subscriptions deliver their first values.
Future<void> _settle() => Future<void>.delayed(Duration.zero).then((_) => Future<void>.delayed(Duration.zero));

void main() {
  group('B4 GridEditorViewModel', () {
    late FakeDrawerRepository drawers;
    late FakeCartRepository carts;
    late FakeInventoryRepository inventory;
    late GridEditorViewModel vm;

    setUp(() async {
      drawers = FakeDrawerRepository(drawers: [const CartDrawer(id: 'd1', cartId: 'c1', name: 'Fármacos', rows: 2, columns: 3)]);
      carts = FakeCartRepository(carts: [const Cart(id: 'c1', institutionId: 'inst', name: 'Carro 1', layoutVersion: 4)]);
      inventory = FakeInventoryRepository(assignments: [
        const CartProductAssignment(id: 'a1', cartId: 'c1', slotId: 'r0c1', productId: 'p1', currentQuantity: 2, targetQuantity: 4),
      ]);
      final services = buildTestServices(drawers: drawers, carts: carts, inventory: inventory);
      vm = GridEditorViewModel(services, _session(services), cartId: 'c1', drawerId: 'd1');
      await _settle();
    });

    tearDown(() => vm.dispose());

    test('starts from the unit grid when no layout was saved', () {
      expect(vm.ready, isTrue);
      expect(vm.slots, hasLength(6));
      expect(vm.drawerNumber, 1);
    });

    test('merges a rectangular selection and keeps the top-left id', () {
      vm.toggle('r0c0');
      vm.toggle('r0c1');
      expect(vm.canMerge, isTrue);
      vm.merge();
      expect(vm.slots, hasLength(5));
      final merged = vm.slots.singleWhere((s) => s.id == 'r0c0');
      expect(merged.columnSpan, 2);
      expect(vm.dirty, isTrue);
    });

    test('refuses an L-shaped selection', () {
      vm.toggle('r0c0');
      vm.toggle('r0c1');
      vm.toggle('r1c0');
      expect(vm.canMerge, isFalse);
    });

    test('split restores the unit cells', () {
      vm.toggle('r0c0');
      vm.toggle('r1c0');
      vm.merge();
      vm.selectOnly('r0c0');
      expect(vm.canSplit, isTrue);
      vm.split();
      expect(vm.slots, hasLength(6));
      expect(vm.slots.every((s) => s.rowSpan == 1 && s.columnSpan == 1), isTrue);
    });

    test('resize drops cells outside the grid and adds new ones', () {
      vm.resize(newColumns: 2);
      expect(vm.slots, hasLength(4));
      vm.resize(newRows: 3);
      expect(vm.slots, hasLength(6));
      expect(vm.slots.map((s) => s.id).toSet(), hasLength(6));
    });

    test('save writes slots, size and bumps the layout version', () async {
      vm.resize(newRows: 3);
      final result = await vm.save();
      expect(result.isOk, isTrue);
      expect(drawers.lastSavedSlots, hasLength(9));
      expect(drawers.drawers.single.rows, 3);
      expect(carts.carts.single.layoutVersion, 5);
      expect(vm.dirty, isFalse);
    });

    test('apply updates the settings of the product already in the slot', () async {
      vm.selectOnly('r0c1');
      final product = const Product(id: 'p1', institutionId: 'inst', name: 'Adrenalina');
      final result = await vm.apply(product: product, target: 6, minimum: 2);
      expect(result.isOk, isTrue);
      expect(inventory.assignments.single.targetQuantity, 6);
      expect(inventory.assignments.single.minimumQuantity, 2);
    });

    test('apply places a new product in a free slot', () async {
      vm.selectOnly('r1c2');
      await vm.apply(product: const Product(id: 'p2', institutionId: 'inst', name: 'Atropina'), target: 3);
      expect(inventory.assignments.where((a) => a.slotId == 'r1c2').single.productId, 'p2');
    });

    test('orphans are assignments whose slot no longer exists', () async {
      drawers.slotsByDrawer['d1'] = [const Slot(id: 'r0c0', drawerId: 'd1', row: 0, column: 0, columnSpan: 3, rowSpan: 2)];
      await drawers.replaceSlots('inst', 'c1', 'd1', drawers.slotsByDrawer['d1']!);
      await _settle();
      expect(vm.orphans.single.id, 'a1');
    });
  });

  group('B5 CatalogViewModel', () {
    test('parses semicolon or comma CSV and skips the header', () {
      final lines = CatalogViewModel.parseCsv('nome;apresentação;gtin;categoria;aviso\n'
          'Adrenalina 1 mg/ml;Ampola 1 ml;05601234567890;Fármaco;30\n'
          'Seringa 10 ml,Unidade,,Material,\n');
      expect(lines, hasLength(2));
      expect(lines.first.category, ProductCategory.drug);
      expect(lines.first.expiryWarningDays, 30);
      expect(lines.last.gtin, isNull);
      expect(lines.last.category, ProductCategory.material);
    });

    test('import skips existing names and GTINs', () async {
      final products = FakeProductRepository(products: [
        const Product(id: 'p1', institutionId: 'inst', name: 'Adrenalina 1 mg/ml', gtin: '1'),
      ]);
      final services = buildTestServices(products: products);
      final vm = CatalogViewModel(services, _session(services));
      await _settle();
      final result = await vm.importCsv('Adrenalina 1 mg/ml;;;;\nOutro;;1;;\nAtropina 1 mg;Ampola;2;Fármaco;');
      expect(result.value!.created, 1);
      expect(result.value!.skipped, 2);
      expect(products.products.map((p) => p.name), contains('Atropina 1 mg'));
      vm.dispose();
    });

    test('rejects a duplicated GTIN', () async {
      final products = FakeProductRepository(products: [const Product(id: 'p1', institutionId: 'inst', name: 'A', gtin: '123')]);
      final services = buildTestServices(products: products);
      final vm = CatalogViewModel(services, _session(services));
      await _settle();
      final result = await vm.save(const Product(id: '', institutionId: 'inst', name: 'B', gtin: '123'));
      expect(result.isOk, isFalse);
      expect(result.code, 'gtinTaken');
      vm.dispose();
    });

    test('counts the carts where a product is used', () async {
      final inventory = FakeInventoryRepository(assignments: [
        const CartProductAssignment(id: 'a1', cartId: 'c1', slotId: 's', productId: 'p1', currentQuantity: 1, targetQuantity: 1),
        const CartProductAssignment(id: 'a2', cartId: 'c2', slotId: 's', productId: 'p1', currentQuantity: 1, targetQuantity: 1),
      ]);
      final services = buildTestServices(inventory: inventory);
      final vm = CatalogViewModel(services, _session(services));
      await _settle();
      expect(vm.usedIn('p1'), 2);
      expect(vm.cartsUsingCatalog, 2);
      vm.dispose();
    });
  });

  group('B7 UsersViewModel', () {
    test('invite creates the member and sends the access e-mail', () async {
      final auth = FakeAuthRepository();
      final institutions = FakeInstitutionRepository();
      final services = buildTestServices(auth: auth, institutions: institutions);
      final vm = UsersViewModel(services, _session(services));
      await _settle();
      final result = await vm.invite(name: 'Ana Silva', email: 'Ana.Silva@H.pt', role: Role.user);
      expect(result.isOk, isTrue);
      expect(institutions.members.single.displayName, 'Ana Silva');
      expect(auth.passwordResets, ['ana.silva@h.pt']);
      await _settle();
      final again = await vm.invite(name: 'Ana', email: 'ana.silva@h.pt', role: Role.user);
      expect(again.code, 'emailTaken');
      vm.dispose();
    });

    test('cannot change your own role', () async {
      final me = const Membership(uid: 'me', institutionId: 'inst', role: Role.institutionAdmin, status: MembershipStatus.active);
      final services = buildTestServices(institutions: FakeInstitutionRepository(members: [me]));
      final vm = UsersViewModel(services, _session(services));
      await _settle();
      final result = await vm.changeRole(me, Role.user);
      expect(result.code, 'self');
      vm.dispose();
    });

    test('filters by role and status', () async {
      final services = buildTestServices(
        institutions: FakeInstitutionRepository(members: const [
          Membership(uid: 'a', institutionId: 'inst', role: Role.user, status: MembershipStatus.active, displayName: 'Ana'),
          Membership(uid: 'b', institutionId: 'inst', role: Role.manager, status: MembershipStatus.active, displayName: 'Bruno'),
          Membership(uid: 'c', institutionId: 'inst', role: Role.user, status: MembershipStatus.invited, displayName: 'Carla'),
        ]),
      );
      final vm = UsersViewModel(services, _session(services));
      await _settle();
      expect(vm.managerCount, 1);
      expect(vm.professionalCount, 2);
      vm.setFilter(UsersFilter.invited);
      expect(vm.visible.single.uid, 'c');
      vm.setFilter(UsersFilter.all);
      vm.setQuery('bru');
      expect(vm.visible.single.uid, 'b');
      vm.dispose();
    });
  });

  group('B8 ShiftsViewModel', () {
    test('weeks start on Monday', () {
      expect(ShiftsViewModel.mondayOf(DateTime(2026, 10, 14)), DateTime(2026, 10, 12));
      expect(ShiftsViewModel.mondayOf(DateTime(2026, 10, 18)), DateTime(2026, 10, 12));
    });

    test('assign, clear and copy the previous week', () async {
      final services = buildTestServices(
        carts: FakeCartRepository(carts: [const Cart(id: 'c1', institutionId: 'inst', name: 'Carro 1')]),
      );
      final vm = ShiftsViewModel(services, _session(services), today: DateTime(2026, 10, 7));
      await _settle();
      await vm.assign(cartId: 'c1', day: DateTime(2026, 10, 7), period: ShiftPeriod.morning, uid: 'u1');
      await _settle();
      expect(vm.shiftAt('c1', DateTime(2026, 10, 7), ShiftPeriod.morning)?.uid, 'u1');

      vm.nextWeek();
      final copied = await vm.copyPreviousWeek();
      await _settle();
      expect(copied.value, 1);
      expect(vm.shiftAt('c1', DateTime(2026, 10, 14), ShiftPeriod.morning)?.uid, 'u1');

      await vm.assign(cartId: 'c1', day: DateTime(2026, 10, 14), period: ShiftPeriod.morning);
      await _settle();
      expect(vm.shiftAt('c1', DateTime(2026, 10, 14), ShiftPeriod.morning), isNull);
      vm.dispose();
    });
  });

  group('B6 TemplatesViewModel', () {
    test('creates a template from a cart and duplicates it', () async {
      final drawers = FakeDrawerRepository(drawers: [const CartDrawer(id: 'd1', cartId: 'c1', name: 'Via aérea', rows: 2, columns: 2)]);
      final carts = FakeCartRepository(carts: [const Cart(id: 'c1', institutionId: 'inst', name: 'Carro 1')]);
      final inventory = FakeInventoryRepository(assignments: [
        const CartProductAssignment(id: 'a1', cartId: 'c1', slotId: 'r0c0', productId: 'p1', currentQuantity: 1, targetQuantity: 5),
      ]);
      final services = buildTestServices(drawers: drawers, carts: carts, inventory: inventory);
      final vm = TemplatesViewModel(services, _session(services));
      await _settle();

      final created = await vm.createFromCart(cartId: 'c1', name: 'Adulto');
      await _settle();
      expect(created.isOk, isTrue);
      expect(vm.templates.single.positionCount, 4);
      expect(vm.templates.single.drawers.single.products.single.targetQuantity, 5);

      await vm.duplicate(vm.templates.single, name: 'Adulto (cópia)');
      await _settle();
      expect(vm.templates, hasLength(2));
      vm.dispose();
    });
  });

  group('B9 ReportsHistoryViewModel', () {
    test('filters reports by month and cart', () async {
      final services = buildTestServices(
        carts: FakeCartRepository(carts: [
          const Cart(id: 'c1', institutionId: 'inst', name: 'Carro 1'),
          const Cart(id: 'c2', institutionId: 'inst', name: 'Carro 2'),
        ]),
      );
      CartReport report(String id, String cartId, DateTime at) => CartReport(
            id: id,
            institutionId: 'inst',
            cartId: cartId,
            cartName: cartId,
            kind: ReportKind.monthlyCheck,
            status: ReportStatus.pendingSignature,
            createdAt: at,
            createdByUid: 'me',
            createdByName: 'Rui Costa',
          );
      await services.reports.createReport(report('r1', 'c1', DateTime(2026, 10, 3)));
      await services.reports.createReport(report('r2', 'c2', DateTime(2026, 10, 5)));
      await services.reports.createReport(report('r3', 'c1', DateTime(2026, 9, 20)));

      final vm = ReportsHistoryViewModel(services, _session(services), tab: ReportsHistoryTab.reports, now: DateTime(2026, 10, 14));
      await _settle();
      expect(vm.reports, hasLength(2));
      vm.setCart('c1');
      expect(vm.reports, hasLength(1));
      vm.setMonth(DateTime(2026, 9));
      expect(vm.reports.single.cartId, 'c1');
      expect(vm.pendingSignatures, 1);
      vm.dispose();
    });
  });
}
