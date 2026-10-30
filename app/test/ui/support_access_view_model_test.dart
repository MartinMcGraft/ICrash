import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/app_services.dart';
import 'package:icrash_app/src/domain/entities/institution.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
import 'package:icrash_app/src/domain/entities/role.dart';
import 'package:icrash_app/src/domain/entities/support_access.dart';
import 'package:icrash_app/src/domain/repositories/auth_repository.dart';
import 'package:icrash_app/src/ui/core/session/session.dart';
import 'package:icrash_app/src/ui/features/dashboard/support_access_view_model.dart';

import '../fakes/fake_repositories.dart';

const _institution = Institution(id: 'inst', name: 'Hospital da Ribeira');

SessionController _admin(AppServices services) => SessionController(
      services: services,
      user: const AuthUser(uid: 'rita', email: 'rita@h.pt'),
      institution: _institution,
      membership: const Membership(uid: 'rita', institutionId: 'inst', role: Role.institutionAdmin, status: MembershipStatus.active, displayName: 'Rita Lopes'),
      institutionCount: 1,
    );

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('Dashboard "Acesso do suporte" (D18)', () {
    test('opening needs a reason; the window lasts the chosen time (7 days at most)', () async {
      final support = FakeSupportRepository();
      final services = buildTestServices(support: support);
      final vm = SupportAccessViewModel(services, _admin(services));
      await _settle();
      expect(vm.openWindow, isNull);
      expect((await vm.open('  ')).code, 'reasonRequired');
      vm.setDuration(const Duration(days: 8));
      expect((await vm.open('Ajuda')).code, 'durationTooLong');
      vm.setDuration(SupportWindow.durations[1]);
      expect((await vm.open('Carro 3 não sincroniza')).isOk, isTrue);
      await _settle();
      final window = vm.openWindow!;
      expect(window.reason, 'Carro 3 não sincroniza');
      expect(window.grantedByName, 'Rita Lopes');
      expect(window.endsAt.difference(DateTime.now()).inHours, inInclusiveRange(23, 24));
      vm.dispose();
    });

    test('closing ends the window at once', () async {
      final support = FakeSupportRepository();
      final services = buildTestServices(support: support);
      final vm = SupportAccessViewModel(services, _admin(services));
      await _settle();
      await vm.open('Ajuda');
      await _settle();
      expect((await vm.close()).isOk, isTrue);
      await _settle();
      expect(vm.openWindow, isNull);
      vm.dispose();
    });

    test('only the institution\'s own Admin sees the section, not Super', () {
      final services = buildTestServices();
      expect(_admin(services).isOwnAdmin, isTrue);
      final superSession = SessionController(
        services: services,
        user: const AuthUser(uid: 'sup'),
        institution: _institution,
        membership: const Membership(uid: 'sup', institutionId: 'inst', role: Role.platformSuperAdmin, status: MembershipStatus.active),
        institutionCount: 1,
      );
      expect(superSession.isOwnAdmin, isFalse);
      expect(superSession.isInstitutionAdmin, isTrue);
    });
  });
}
