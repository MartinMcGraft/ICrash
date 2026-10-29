import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/repository_failure.dart';
import 'package:icrash_app/src/domain/entities/institution.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
import 'package:icrash_app/src/domain/entities/role.dart';
import 'package:icrash_app/src/domain/repositories/auth_repository.dart';
import 'package:icrash_app/src/services/pin_hasher.dart';
import 'package:icrash_app/src/ui/app/app_root_view_model.dart';

import '../fakes/fake_repositories.dart';

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('AppRootViewModel: the administrator-set PIN is copied to the device (DB3)', () {
    const institution = Institution(id: 'inst', name: 'Hospital da Ribeira');
    const membership = Membership(uid: 'ana', institutionId: 'inst', role: Role.user, status: MembershipStatus.active);

    test('after sign-in the device holds the PIN hash and can check the PIN offline', () async {
      final hasher = PinHasher(iterations: 1000);
      final credentials = FakeCredentialRepository(pinHashes: {'inst/ana': await hasher.hash('2468')});
      final services = buildTestServices(
        auth: FakeAuthRepository(signedInUser: const AuthUser(uid: 'ana', email: 'ana@h.pt')),
        institutions: FakeInstitutionRepository(institutions: const [institution], myMembership: membership),
        credentials: credentials,
        pinHasher: hasher,
      );
      final vm = AppRootViewModel(services);
      await _settle();
      expect(vm.stage, RootStage.ready);
      expect(vm.hasPin, isTrue);
      expect(await services.deviceSession.verifyPin('ana', '2468'), isTrue);
      vm.dispose();
    });

    test('without a PIN from the administration there is nothing to unlock with', () async {
      final services = buildTestServices(
        auth: FakeAuthRepository(signedInUser: const AuthUser(uid: 'ana', email: 'ana@h.pt')),
        institutions: FakeInstitutionRepository(institutions: const [institution], myMembership: membership),
      );
      final vm = AppRootViewModel(services);
      await _settle();
      expect(vm.hasPin, isFalse);
      vm.dispose();
    });

    test('offline, the copy already on the device is kept', () async {
      final hasher = PinHasher(iterations: 1000);
      final credentials = FakeCredentialRepository()..fetchError = const RepositoryFailure(RepositoryFailureReason.offline);
      final services = buildTestServices(
        auth: FakeAuthRepository(signedInUser: const AuthUser(uid: 'ana', email: 'ana@h.pt')),
        institutions: FakeInstitutionRepository(institutions: const [institution], myMembership: membership),
        credentials: credentials,
        pinHasher: hasher,
      );
      await services.deviceSession.cachePinHash('ana', await hasher.hash('2468'));
      final vm = AppRootViewModel(services);
      await _settle();
      expect(vm.hasPin, isTrue);
      vm.dispose();
    });
  });
}
