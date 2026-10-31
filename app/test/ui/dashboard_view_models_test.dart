import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/batch.dart';
import 'package:icrash_app/src/domain/entities/cart.dart';
import 'package:icrash_app/src/domain/entities/cart_drawer.dart';
import 'package:icrash_app/src/domain/entities/cart_product_assignment.dart';
import 'package:icrash_app/src/domain/entities/cart_report.dart';
import 'package:icrash_app/src/domain/entities/institution.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
import 'package:icrash_app/src/domain/entities/product.dart';
import 'package:icrash_app/src/domain/entities/registered_device.dart';
import 'package:icrash_app/src/domain/entities/role.dart';
import 'package:icrash_app/src/domain/entities/shift.dart';
import 'package:icrash_app/src/domain/entities/slot.dart';
import 'package:icrash_app/src/domain/entities/usage_event.dart';
import 'package:icrash_app/src/domain/repositories/auth_repository.dart';
import 'package:icrash_app/src/ui/core/session/session.dart';
import 'package:icrash_app/src/ui/features/dashboard/cart_config_view_model.dart';
import 'package:icrash_app/src/ui/features/dashboard/catalog_view_model.dart';
import 'package:icrash_app/src/ui/features/drawer/drawer_view_model.dart';
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
      drawers = FakeDrawerRepository(drawers: [const CartDrawer(id: 'd1', cartId: 'c1', number: 2, rows: 2, columns: 3)]);
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
      expect(vm.drawerNumber, 2, reason: 'the stored number, not the position');
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
      final result = await vm.apply(product: product, target: 6);
      expect(result.isOk, isTrue);
      expect(inventory.assignments.single.targetQuantity, 6);
    });

    test('apply refuses a target below the current stock (Q6)', () async {
      vm.selectOnly('r0c1');
      final product = const Product(id: 'p1', institutionId: 'inst', name: 'Adrenalina');
      final result = await vm.apply(product: product, target: 1);
      expect(result.isOk, isFalse);
      expect(result.code, 'targetBelowCurrent');
      expect(inventory.assignments.single.targetQuantity, 4);
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

    test('skips the "Consumível" header and the old "Produto" one (D19)', () {
      for (final header in ['Consumível;Apresentação;GTIN', 'Produto;Apresentação;GTIN', 'Consumable,Presentation,GTIN']) {
        final lines = CatalogViewModel.parseCsv('$header\nAdrenalina 1 mg/ml;Ampola 1 ml;05601234567890\n');
        expect(lines.single.name, 'Adrenalina 1 mg/ml', reason: header);
      }
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

    test('a typed EAN-13 is saved padded to 14 digits, so it matches its own scan (P16)', () async {
      final products = FakeProductRepository();
      final services = buildTestServices(products: products);
      final vm = CatalogViewModel(services, _session(services));
      await _settle();
      final result = await vm.save(const Product(id: '', institutionId: 'inst', name: 'Adrenalina', gtin: '5601234567890'));
      expect(result.isOk, isTrue);
      expect(products.products.single.gtin, '05601234567890');
      expect((await products.findByGtin('inst', '05601234567890'))?.name, 'Adrenalina');
      vm.dispose();
    });

    test('an old unpadded GTIN still counts as taken and is still found by a scan', () async {
      final products = FakeProductRepository(products: [
        const Product(id: 'p1', institutionId: 'inst', name: 'A', gtin: '5601234567890'),
      ]);
      final services = buildTestServices(products: products);
      final vm = CatalogViewModel(services, _session(services));
      await _settle();
      expect(vm.gtinTaken('05601234567890'), isTrue);
      expect((await products.findByGtin('inst', '05601234567890'))?.id, 'p1');
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
    test('D17: the nº mecanográfico is stored and must be unique', () async {
      final institutions = FakeInstitutionRepository();
      final services = buildTestServices(institutions: institutions);
      final vm = UsersViewModel(services, _session(services));
      await _settle();
      expect(
        (await vm.createUser(name: 'Ana', email: 'ana@h.pt', role: Role.manager, password: 'segura-123', pin: '2468', userNumber: ' 2002 '))
            .isOk,
        isTrue,
      );
      expect(institutions.members.single.userNumber, '2002');
      await _settle();
      expect(
        (await vm.createUser(name: 'Rui', email: 'rui@h.pt', role: Role.manager, password: 'segura-123', pin: '2468', userNumber: '2002'))
            .code,
        'numberTaken',
      );
      vm.dispose();
    });

    test("D17: tablets aren't people; the Dispositivos tab lists them, changes and revokes them", () async {
      final devices = FakeDeviceRepository(devices: [
        const RegisteredDevice(id: 'd1', institutionId: 'inst', name: 'Tablet UCI', cartIds: ['c1'], authUid: 'auth-d1'),
      ]);
      final services = buildTestServices(
        institutions: FakeInstitutionRepository(members: [
          const Membership(uid: 'ana', institutionId: 'inst', role: Role.manager, status: MembershipStatus.active, displayName: 'Ana'),
          const Membership(uid: 'auth-d1', institutionId: 'inst', role: Role.device, status: MembershipStatus.active, displayName: 'Tablet UCI'),
        ]),
        carts: FakeCartRepository(carts: [
          const Cart(id: 'c1', institutionId: 'inst', name: 'Carro 1'),
          const Cart(id: 'c2', institutionId: 'inst', name: 'Carro 2'),
        ]),
        devices: devices,
      );
      final vm = UsersViewModel(services, _session(services));
      await _settle();
      expect(vm.total, 1);
      expect(vm.deviceCount, 1);
      expect(vm.cartNames(vm.devices.single), 'Carro 1');
      expect((await vm.updateDevice(vm.devices.single, name: 'Tablet UCI', cartIds: const [])).code, 'noCarts');
      expect((await vm.updateDevice(vm.devices.single, name: ' Tablet UCI 2 ', cartIds: const ['c1', 'c2'])).isOk, isTrue);
      expect(devices.devices.single.name, 'Tablet UCI 2');
      expect(devices.devices.single.cartIds, ['c1', 'c2']);
      expect((await vm.revokeDevice(devices.devices.single)).isOk, isTrue);
      await _settle();
      expect(vm.devices.single.revoked, isTrue);
      expect(vm.deviceCount, 0);
      vm.dispose();
    });

    test('the administrator creates a user with the password and PIN they chose (DB3)', () async {
      final institutions = FakeInstitutionRepository();
      final services = buildTestServices(institutions: institutions);
      final vm = UsersViewModel(services, _session(services));
      await _settle();
      final result =
          await vm.createUser(name: 'Ana Silva', email: 'Ana.Silva@H.pt', role: Role.manager, password: 'segura-123', pin: '2468');
      expect(result.isOk, isTrue);
      final member = institutions.members.single;
      expect(member.displayName, 'Ana Silva');
      expect(member.status, MembershipStatus.active, reason: 'no invitation: the person gets the credentials by hand');
      expect(institutions.passwords[member.uid], 'segura-123');
      final hash = institutions.pinHashes[member.uid]!;
      expect(hash, isNot(contains('2468')));
      expect(await services.pinHasher.verify('2468', hash), isTrue);
      await _settle();
      final again = await vm.createUser(name: 'Ana', email: 'ana.silva@h.pt', role: Role.manager, password: 'segura-123', pin: '2468');
      expect(again.code, 'emailTaken');
      vm.dispose();
    });

    test('a short password or a PIN that isn\'t 4 digits is refused', () async {
      final institutions = FakeInstitutionRepository();
      final services = buildTestServices(institutions: institutions);
      final vm = UsersViewModel(services, _session(services));
      await _settle();
      expect((await vm.createUser(name: 'A', email: 'a@h.pt', role: Role.manager, password: 'curta', pin: '1234')).code,
          'passwordTooShort');
      expect((await vm.createUser(name: 'A', email: 'a@h.pt', role: Role.manager, password: 'segura-123', pin: '12')).code,
          'pinInvalid');
      expect(institutions.members, isEmpty);
      vm.dispose();
    });

    test('an administrator sets a new PIN for someone else, never for themselves', () async {
      const me = Membership(uid: 'me', institutionId: 'inst', role: Role.institutionAdmin, status: MembershipStatus.active);
      const ana = Membership(uid: 'ana', institutionId: 'inst', role: Role.manager, status: MembershipStatus.active);
      final credentials = FakeCredentialRepository();
      final services = buildTestServices(institutions: FakeInstitutionRepository(members: [me, ana]), credentials: credentials);
      final vm = UsersViewModel(services, _session(services));
      await _settle();
      expect((await vm.setMemberPin(ana, '1357')).isOk, isTrue);
      expect(await services.pinHasher.verify('1357', credentials.pinHashes['inst/ana']!), isTrue);
      expect((await vm.setMemberPin(me, '1357')).code, 'self');
      expect(credentials.pinHashes.containsKey('inst/me'), isFalse);
      vm.dispose();
    });

    test('cannot change your own role', () async {
      final me = const Membership(uid: 'me', institutionId: 'inst', role: Role.institutionAdmin, status: MembershipStatus.active);
      final services = buildTestServices(institutions: FakeInstitutionRepository(members: [me]));
      final vm = UsersViewModel(services, _session(services));
      await _settle();
      final result = await vm.changeRole(me, Role.manager);
      expect(result.code, 'self');
      vm.dispose();
    });

    test('filters by role and status', () async {
      final services = buildTestServices(
        institutions: FakeInstitutionRepository(members: const [
          Membership(uid: 'a', institutionId: 'inst', role: Role.manager, status: MembershipStatus.active, displayName: 'Ana'),
          Membership(uid: 'b', institutionId: 'inst', role: Role.institutionAdmin, status: MembershipStatus.active, displayName: 'Bruno'),
          Membership(uid: 'c', institutionId: 'inst', role: Role.manager, status: MembershipStatus.invited, displayName: 'Carla'),
        ]),
      );
      final vm = UsersViewModel(services, _session(services));
      await _settle();
      expect(vm.adminCount, 1);
      expect(vm.managerCount, 2);
      vm.setFilter(UsersFilter.admins);
      expect(vm.visible.single.uid, 'b');
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
      final drawers = FakeDrawerRepository(drawers: [const CartDrawer(id: 'd1', cartId: 'c1', number: 1, rows: 2, columns: 2)]);
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

    test('templates are archived and restored, never deleted (P3)', () async {
      final drawers = FakeDrawerRepository(drawers: [const CartDrawer(id: 'd1', cartId: 'c1', number: 1, rows: 1, columns: 1)]);
      final carts = FakeCartRepository(carts: [const Cart(id: 'c1', institutionId: 'inst', name: 'Carro 1')]);
      final services = buildTestServices(drawers: drawers, carts: carts);
      final vm = TemplatesViewModel(services, _session(services));
      await _settle();
      await vm.createFromCart(cartId: 'c1', name: 'Adulto');
      await _settle();
      final template = vm.templates.single;

      expect((await vm.archive(template)).isOk, isTrue);
      await _settle();
      expect(vm.templates, isEmpty, reason: 'the active tab no longer lists it');
      expect(vm.activeTemplates, isEmpty);
      vm.setShowArchived(true);
      expect(vm.templates.single.archived, isTrue);
      expect((await vm.createCart(vm.templates.single, name: 'Carro 2')).code, 'templateArchived');

      expect((await vm.restore(vm.templates.single)).isOk, isTrue);
      await _settle();
      vm.setShowArchived(false);
      expect(vm.templates.single.id, template.id);
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

  group('B3 CartConfigViewModel: drawer numbers (P17)', () {
    late FakeDrawerRepository drawers;
    late CartConfigViewModel vm;

    setUp(() async {
      drawers = FakeDrawerRepository(drawers: [
        const CartDrawer(id: 'd1', cartId: 'c1', number: 1, rows: 2, columns: 2),
        const CartDrawer(id: 'd3', cartId: 'c1', number: 3, rows: 1, columns: 1),
      ]);
      final carts = FakeCartRepository(carts: [const Cart(id: 'c1', institutionId: 'inst', name: 'Carro 1')]);
      final services = buildTestServices(drawers: drawers, carts: carts);
      vm = CartConfigViewModel(services, _session(services), 'c1');
      await _settle();
    });

    tearDown(() => vm.dispose());

    test('drawers are listed by their stored number; the default is the lowest free one', () {
      expect(vm.drawers.map((d) => d.$1), [1, 3]);
      expect(vm.nextDrawerNumber, 2);
    });

    test('a new drawer stores its number and gets one slot per cell', () async {
      final result = await vm.addDrawer(number: 2, rows: 2, columns: 3);
      expect(result.isOk, isTrue);
      final created = drawers.lastCreatedDrawer!;
      expect(created.number, 2);
      expect(drawers.slotsByDrawer[created.id], hasLength(6));
    });

    test('a number already used in the cart is refused', () async {
      final result = await vm.addDrawer(number: 3, rows: 1, columns: 1);
      expect(result.code, 'drawerNumberTaken');
      expect(drawers.drawers, hasLength(2));
    });

    test('a drawer number can be changed to a free one, not to a taken one', () async {
      final d3 = drawers.drawers.last;
      expect((await vm.setDrawerNumber(d3, 1)).code, 'drawerNumberTaken');
      expect((await vm.setDrawerNumber(d3, 4)).isOk, isTrue);
      expect(drawers.drawers.last.number, 4);
    });

    test('a new drawer may have a name, trimmed; an empty one is no name (D20)', () async {
      expect((await vm.addDrawer(number: 2, name: '  Via aérea ', rows: 1, columns: 1)).isOk, isTrue);
      expect(drawers.lastCreatedDrawer!.name, 'Via aérea');
      expect((await vm.addDrawer(number: 4, name: '   ', rows: 1, columns: 1)).isOk, isTrue);
      expect(drawers.lastCreatedDrawer!.name, isNull);
      expect((await vm.addDrawer(number: 5, name: 'x' * 51, rows: 1, columns: 1)).code, 'drawerNameTooLong');
    });

    test('"Editar gaveta" renames, and an empty name removes it (D20)', () async {
      final d1 = drawers.drawers.first;
      expect((await vm.editDrawer(d1, number: 1, name: 'Circulação')).isOk, isTrue);
      expect(drawers.drawers.first.name, 'Circulação');
      expect(drawers.drawers.first.number, 1);
      expect((await vm.editDrawer(drawers.drawers.first, number: 1, name: '')).isOk, isTrue);
      expect(drawers.drawers.first.name, isNull);
    });
  });

  group('A6 DrawerViewModel: placement and stock bounds', () {
    late FakeInventoryRepository inventory;
    late DrawerViewModel vm;

    setUp(() async {
      final drawers = FakeDrawerRepository(drawers: [
        const CartDrawer(id: 'd1', cartId: 'c1', number: 1, rows: 1, columns: 2),
        const CartDrawer(id: 'd2', cartId: 'c1', number: 2, rows: 1, columns: 2),
      ]);
      final carts = FakeCartRepository(carts: [const Cart(id: 'c1', institutionId: 'inst', name: 'Carro 1')]);
      inventory = FakeInventoryRepository(assignments: [
        const CartProductAssignment(
            id: 'a1', cartId: 'c1', drawerId: 'd1', slotId: 'r0c0', productId: 'p1', currentQuantity: 3, targetQuantity: 4),
      ]);
      final products = FakeProductRepository(products: [
        const Product(id: 'p1', institutionId: 'inst', name: 'Adrenalina'),
        const Product(id: 'p2', institutionId: 'inst', name: 'Atropina'),
      ]);
      final services = buildTestServices(drawers: drawers, carts: carts, inventory: inventory, products: products);
      vm = DrawerViewModel(services, _session(services), cartId: 'c1', drawerId: 'd2');
      await _settle();
    });

    tearDown(() => vm.dispose());

    test('the same slot id in another drawer is a different, free slot', () async {
      vm.select('r0c0');
      expect(vm.selectedAssignment, isNull);
      final result = await vm.assign(const Product(id: 'p2', institutionId: 'inst', name: 'Atropina'), target: 2, initial: 1);
      expect(result.isOk, isTrue);
      expect(inventory.lastCreated!.drawerId, 'd2');
      expect(inventory.lastCreated!.slotId, 'r0c0');
    });

    test('the initial quantity can\'t exceed the target (P5)', () async {
      vm.select('r0c1');
      final result = await vm.assign(const Product(id: 'p2', institutionId: 'inst', name: 'Atropina'), target: 2, initial: 3);
      expect(result.code, 'exceedsTarget');
      expect(inventory.assignments, hasLength(1));
    });
  });

  group('A6/A7 DrawerViewModel: stock history (DB1, P9)', () {
    late FakeInventoryRepository inventory;
    late DrawerViewModel vm;

    setUp(() async {
      final drawers = FakeDrawerRepository(drawers: [const CartDrawer(id: 'd1', cartId: 'c1', number: 1, rows: 1, columns: 2)]);
      final carts = FakeCartRepository(carts: [const Cart(id: 'c1', institutionId: 'inst', name: 'Carro 1')]);
      inventory = FakeInventoryRepository(assignments: [
        const CartProductAssignment(
            id: 'a1', cartId: 'c1', drawerId: 'd1', slotId: 'r0c0', productId: 'p1', currentQuantity: 3, targetQuantity: 4),
      ]);
      inventory.batchesByAssignment['a1'] = [
        Batch(id: 'b1', assignmentId: 'a1', lotNumber: 'L1', expiryDate: DateTime(2027, 1, 31), quantity: 2),
        Batch(id: 'b2', assignmentId: 'a1', expiryDate: DateTime(2027, 3, 31), quantity: 1),
      ];
      final services = buildTestServices(drawers: drawers, carts: carts, inventory: inventory);
      vm = DrawerViewModel(services, _session(services), cartId: 'c1', drawerId: 'd1', initialSlotId: 'r0c0');
      await _settle();
    });

    tearDown(() => vm.dispose());

    test('replenishment accepts an empty lot but needs an expiry date', () async {
      vm.showPanel(DrawerPanel.replenish);
      expect(vm.amount, 1, reason: 'prefilled up to the target, never above it');
      expect((await vm.replenish()).code, 'expiryRequired');
      vm.setExpiry(DateTime(2027, 6, 30));
      final result = await vm.replenish();
      expect(result.isOk, isTrue);
      expect(inventory.batchesByAssignment['a1']!.last.lotNumber, isNull);
      expect(inventory.assignments.single.currentQuantity, 4);
    });

    test('a full slot can\'t be replenished (P5)', () async {
      vm.showPanel(DrawerPanel.replenish);
      vm.setExpiry(DateTime(2027, 6, 30));
      vm.setAmount(2);
      expect((await vm.replenish()).code, 'exceedsTarget');
    });

    test('confirming a consumption closes the panel (RV-23)', () async {
      vm.showPanel(DrawerPanel.consume);
      final result = await vm.consume(1);
      expect(result.isOk, isTrue);
      expect(inventory.assignments.single.currentQuantity, 2);
      expect(vm.selectedSlotId, isNull);
      expect(vm.panel, DrawerPanel.detail);
    });
  });

  group('P1/P2: a cart\'s structure is fixed once used', () {
    const event = UsageEvent(
      id: 'e1', institutionId: 'inst', actorUid: 'me', cartId: 'c1', assignmentId: 'a1', productId: 'p1',
      type: UsageEventType.consumption, amount: -1,
    );
    late FakeDrawerRepository drawers;
    late FakeInventoryRepository inventory;
    late AppServices services;

    setUp(() {
      drawers = FakeDrawerRepository(drawers: [
        const CartDrawer(id: 'd1', cartId: 'c1', number: 1, rows: 1, columns: 3),
        const CartDrawer(id: 'd2', cartId: 'c1', number: 2, rows: 1, columns: 2),
      ]);
      inventory = FakeInventoryRepository(assignments: [
        // a1 has History (an event); a2 was placed but never used.
        const CartProductAssignment(
            id: 'a1', cartId: 'c1', drawerId: 'd1', slotId: 'r0c0', productId: 'p1', currentQuantity: 3, targetQuantity: 4),
        const CartProductAssignment(
            id: 'a2', cartId: 'c1', drawerId: 'd1', slotId: 'r0c1', productId: 'p2', currentQuantity: 0, targetQuantity: 2),
      ]);
      services = buildTestServices(
        drawers: drawers,
        carts: FakeCartRepository(carts: [const Cart(id: 'c1', institutionId: 'inst', name: 'Carro 1', layoutVersion: 1)]),
        inventory: inventory,
        usage: FakeUsageRepository(events: [event]),
        products: FakeProductRepository(products: [
          const Product(id: 'p1', institutionId: 'inst', name: 'Adrenalina'),
          const Product(id: 'p2', institutionId: 'inst', name: 'Atropina'),
          const Product(id: 'p3', institutionId: 'inst', name: 'Amiodarona'),
        ]),
      );
    });

    test('B4: a used drawer can\'t be resized, merged or split, or saved', () async {
      final vm = GridEditorViewModel(services, _session(services), cartId: 'c1', drawerId: 'd1');
      await _settle();
      expect(vm.layoutLocked, isTrue);
      vm.resize(newColumns: 4);
      vm.toggle('r0c1');
      vm.toggle('r0c2');
      vm.merge();
      expect(vm.slots, hasLength(3));
      expect(vm.dirty, isFalse);
      vm.dispose();
    });

    test('B4: an unused drawer can still be edited', () async {
      final vm = GridEditorViewModel(services, _session(services), cartId: 'c1', drawerId: 'd2');
      await _settle();
      expect(vm.layoutLocked, isFalse);
      vm.resize(newColumns: 3);
      expect(vm.slots, hasLength(3));
      vm.dispose();
    });

    test('B4: a used slot keeps its product and can\'t be cleared; its target can change', () async {
      final vm = GridEditorViewModel(services, _session(services), cartId: 'c1', drawerId: 'd1');
      await _settle();
      vm.selectOnly('r0c0');
      expect(vm.selectedInUse, isTrue);
      expect((await vm.clearPosition()).code, 'slotInUse');
      final swap = await vm.apply(product: const Product(id: 'p3', institutionId: 'inst', name: 'Amiodarona'), target: 4);
      expect(swap.code, 'slotInUse');
      final target = await vm.apply(product: const Product(id: 'p1', institutionId: 'inst', name: 'Adrenalina'), target: 6);
      expect(target.isOk, isTrue);
      expect(inventory.assignments.where((a) => a.id == 'a1').single.targetQuantity, 6);
      vm.dispose();
    });

    test('B4: an unused slot can still be cleared', () async {
      final vm = GridEditorViewModel(services, _session(services), cartId: 'c1', drawerId: 'd1');
      await _settle();
      vm.selectOnly('r0c1');
      expect(vm.selectedInUse, isFalse);
      expect((await vm.clearPosition()).isOk, isTrue);
      expect(inventory.assignments.map((a) => a.id), ['a1']);
      vm.dispose();
    });

    test('B4: an orphan with History can be reassigned but not removed (Q7)', () async {
      drawers.slotsByDrawer['d1'] = [const Slot(id: 'r0c1', drawerId: 'd1', row: 0, column: 1, columnSpan: 2)];
      final vm = GridEditorViewModel(services, _session(services), cartId: 'c1', drawerId: 'd1');
      await _settle();
      final orphan = vm.orphans.singleWhere((a) => a.id == 'a1');
      expect((await vm.removeOrphan(orphan)).code, 'slotInUse');
      vm.dispose();
    });

    test('A6: "trocar produto" is refused on a used slot', () async {
      final vm = DrawerViewModel(services, _session(services), cartId: 'c1', drawerId: 'd1', initialSlotId: 'r0c0');
      await _settle();
      expect(vm.selectedInUse, isTrue);
      final result = await vm.assign(const Product(id: 'p3', institutionId: 'inst', name: 'Amiodarona'), target: 2, initial: 0);
      expect(result.code, 'slotInUse');
      expect(inventory.assignments.where((a) => a.id == 'a1'), hasLength(1));
      vm.dispose();
    });

    test('B3: a used drawer keeps its number; an unused one can be renumbered (Q8)', () async {
      final vm = CartConfigViewModel(services, _session(services), 'c1');
      await _settle();
      expect(vm.canEditNumber(drawers.drawers.first), isFalse);
      expect((await vm.setDrawerNumber(drawers.drawers.first, 5)).code, 'drawerInUse');
      expect((await vm.setDrawerNumber(drawers.drawers.last, 5)).isOk, isTrue);
      vm.dispose();
    });

    test('B3: a used drawer can still be renamed, not renumbered (D20, Q8)', () async {
      final vm = CartConfigViewModel(services, _session(services), 'c1');
      await _settle();
      final used = drawers.drawers.first;
      expect((await vm.editDrawer(used, number: used.number!, name: 'Via aérea')).isOk, isTrue);
      expect(drawers.drawers.first.name, 'Via aérea');
      expect((await vm.editDrawer(drawers.drawers.first, number: 7, name: 'Via aérea')).code, 'drawerInUse');
      vm.dispose();
    });
  });
}
