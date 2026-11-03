import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/institution.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
import 'package:icrash_app/src/domain/entities/role.dart';
import 'package:icrash_app/src/domain/repositories/auth_repository.dart';
import 'package:icrash_app/src/services/code_scanner_service.dart';
import 'package:icrash_app/src/services/internal_qr_payload.dart';
import 'package:icrash_app/src/ui/core/session/session.dart';
import 'package:icrash_app/src/ui/features/scanner/scanner_view_model.dart';

import '../fakes/fake_repositories.dart';

const _institution = Institution(id: 'inst', name: 'Hospital da Ribeira');

SessionController _session(AppServices services) => SessionController(
      services: services,
      user: const AuthUser(uid: 'me', email: 'me@h.pt'),
      institution: _institution,
      membership: const Membership(uid: 'me', institutionId: 'inst', role: Role.manager, status: MembershipStatus.active),
      institutionCount: 1,
    );

void main() {
  group('A11 ScannerViewModel inside a cart (RV-26)', () {
    test('only consumables: a cart code is refused and the mode stays on consumables', () async {
      final services = buildTestServices();
      final opened = <String>[];
      final vm = ScannerViewModel(services, _session(services), onCart: opened.add, consumablesOnly: true);
      vm.setMode(ScanMode.cart);
      expect(vm.mode, ScanMode.product);
      await vm.handle(ScannedCode(encodeCartQrPayload('inst', 'c1'), CodeFormat.qr));
      expect(opened, isEmpty);
      expect(vm.error, ScanError.onlyConsumables);
      vm.dispose();
    });

    test('outside a cart a cart code still opens the cart', () async {
      final services = buildTestServices();
      final opened = <String>[];
      final vm = ScannerViewModel(services, _session(services), onCart: opened.add);
      await vm.handle(ScannedCode(encodeCartQrPayload('inst', 'c1'), CodeFormat.qr));
      expect(opened, ['c1']);
      expect(vm.error, isNull);
      vm.dispose();
    });
  });
}
