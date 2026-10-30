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
import 'package:icrash_app/src/domain/entities/role.dart';
import 'package:icrash_app/src/domain/monthly_check.dart';
import 'package:icrash_app/src/domain/repositories/auth_repository.dart';
import 'package:icrash_app/src/ui/core/session/session.dart';
import 'package:icrash_app/src/ui/features/monthly_check/monthly_check_view_model.dart';

import '../fakes/fake_repositories.dart';

const _institution = Institution(id: 'inst', name: 'Hospital da Ribeira');

SessionController _session(AppServices services) => SessionController(
      services: services,
      user: const AuthUser(uid: 'ana', email: 'ana@h.pt'),
      institution: _institution,
      membership: const Membership(uid: 'ana', institutionId: 'inst', role: Role.manager, status: MembershipStatus.active, displayName: 'Ana Silva'),
      institutionCount: 1,
    );

Future<void> _settle() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('A8 "Gestão mensal" (D22, D23)', () {
    late FakeInventoryRepository inventory;
    late AppServices services;
    final now = DateTime.now();
    final expired = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 3));
    final expiring = DateTime(now.year, now.month, now.day).add(const Duration(days: 10));

    setUp(() {
      inventory = FakeInventoryRepository(assignments: [
        // Drawer 1: an expired lot. Drawer 2: an expiring lot.
        const CartProductAssignment(id: 'a1', cartId: 'c1', drawerId: 'd1', slotId: 'r0c0', productId: 'p1', currentQuantity: 4, targetQuantity: 4),
        const CartProductAssignment(id: 'a2', cartId: 'c1', drawerId: 'd2', slotId: 'r0c0', productId: 'p2', currentQuantity: 2, targetQuantity: 2),
      ]);
      inventory.batchesByAssignment['a1'] = [
        Batch(id: 'old', assignmentId: 'a1', lotNumber: 'L1', expiryDate: expired, quantity: 2),
        Batch(id: 'good', assignmentId: 'a1', lotNumber: 'L9', expiryDate: DateTime(now.year + 2, 1, 31), quantity: 2),
      ];
      inventory.batchesByAssignment['a2'] = [Batch(id: 'soon', assignmentId: 'a2', expiryDate: expiring, quantity: 2)];
      services = buildTestServices(
        carts: FakeCartRepository(carts: [const Cart(id: 'c1', institutionId: 'inst', name: 'Carro 1')]),
        drawers: FakeDrawerRepository(drawers: [
          const CartDrawer(id: 'd1', cartId: 'c1', number: 1, name: 'Via aérea', rows: 1, columns: 2),
          const CartDrawer(id: 'd2', cartId: 'c1', number: 2, rows: 1, columns: 2),
        ]),
        products: FakeProductRepository(products: [
          const Product(id: 'p1', institutionId: 'inst', name: 'Adrenalina'),
          const Product(id: 'p2', institutionId: 'inst', name: 'Atropina'),
        ]),
        inventory: inventory,
      );
    });

    test('lists only the expired and expiring lots, one drawer per step', () async {
      final vm = MonthlyCheckViewModel(services, _session(services), 'c1');
      await _settle();
      expect(vm.ready, isTrue);
      expect(vm.items.map((i) => i.batchId), ['old', 'soon']);
      expect(vm.steps.map((d) => d.id), ['d1', 'd2']);
      expect(vm.stepItems.single.batchId, 'old');
      expect(vm.canFinish, isFalse);
      vm.dispose();
    });

    test('"Substituído" swaps the lot: old one removed, new one added, same quantity', () async {
      final vm = MonthlyCheckViewModel(services, _session(services), 'c1');
      await _settle();
      final item = vm.stepItems.single;
      expect((await vm.replace(item, units: 2, newExpiry: null)).code, 'newExpiryRequired');
      expect((await vm.replace(item, units: 2, newExpiry: expired)).code, 'newExpiryNotLater');
      final newExpiry = DateTime(now.year + 1, 6, 30);
      final result = await vm.replace(item, units: 2, newExpiry: newExpiry, newLot: 'L2');
      expect(result.isOk, isTrue);
      final batches = inventory.batchesByAssignment['a1']!;
      expect(batches.singleWhere((b) => b.id == 'old').isActive, isFalse);
      expect(batches.where((b) => b.isActive).map((b) => b.lotNumber), containsAll(['L9', 'L2']));
      expect(inventory.assignments.firstWhere((a) => a.id == 'a1').currentQuantity, 4);
      expect(vm.stepItems.single.locked, isTrue);
      vm.dispose();
    });

    test('"Retirado sem reposição" lowers the stock', () async {
      final vm = MonthlyCheckViewModel(services, _session(services), 'c1');
      await _settle();
      expect((await vm.remove(vm.stepItems.single, units: 2)).isOk, isTrue);
      expect(inventory.assignments.firstWhere((a) => a.id == 'a1').currentQuantity, 2);
      vm.dispose();
    });

    test('every answer is saved: leaving and coming back resumes at the same step', () async {
      final vm = MonthlyCheckViewModel(services, _session(services), 'c1');
      await _settle();
      await vm.remove(vm.stepItems.single, units: 1);
      await vm.next();
      await vm.setKept(vm.stepItems.single, true);
      await vm.setNotes('Pedido à farmácia');
      vm.dispose();

      final again = MonthlyCheckViewModel(services, _session(services), 'c1');
      await _settle();
      expect(again.step, 1);
      expect(again.notes, 'Pedido à farmácia');
      expect(again.items.map((i) => i.outcome), [CheckOutcome.removed, CheckOutcome.kept]);
      expect(again.canFinish, isTrue);
      again.dispose();
    });

    test('back goes to the previous step, and is false on the first one', () async {
      final vm = MonthlyCheckViewModel(services, _session(services), 'c1');
      await _settle();
      expect(await vm.back(), isFalse);
      await vm.next();
      expect(vm.step, 1);
      expect(await vm.back(), isTrue);
      expect(vm.step, 0);
      vm.dispose();
    });

    test('finishing needs every lot handled, then creates the report and clears the draft', () async {
      final vm = MonthlyCheckViewModel(services, _session(services), 'c1');
      await _settle();
      expect((await vm.finish()).code, 'checkIncomplete');
      await vm.remove(vm.items.first, units: 2);
      await vm.setKept(vm.items.last, true);
      final result = await vm.finish();
      expect(result.isOk, isTrue);
      final report = (await services.reports.watchReports('inst').first).single;
      expect(report.status, ReportStatus.pendingSignature);
      expect(report.findings.map((f) => f.outcome), ['removed', 'kept']);
      expect(report.findings.first.drawerName, 'Via aérea');
      expect(await services.reports.loadCheckDraft('inst', 'c1'), isNull);
      vm.dispose();
    });
  });
}
