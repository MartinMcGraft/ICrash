import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/repository_failure.dart';
import 'package:icrash_app/src/domain/entities/institution.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
import 'package:icrash_app/src/domain/entities/role.dart';
import 'package:icrash_app/src/domain/entities/support_access.dart';
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
    const membership = Membership(uid: 'ana', institutionId: 'inst', role: Role.manager, status: MembershipStatus.active);

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

  group('AppRootViewModel: Super only through an open support window (D18)', () {
    const hospital = Institution(id: 'inst', name: 'Hospital da Ribeira');
    const other = Institution(id: 'other', name: 'Hospital B');

    SupportWindow window(String id, {Duration left = const Duration(hours: 4)}) => SupportWindow(
          grantId: 'g-$id',
          institutionId: id,
          reason: 'Erro ao sincronizar',
          grantedBy: 'admin',
          endsAt: DateTime.now().add(left),
        );

    test('Super sees only institutions with an open window, enters one, and the entry is logged', () async {
      final support = FakeSupportRepository(isSuper: true, institutions: const [hospital, other], windows: {'inst': window('inst')});
      final services = buildTestServices(
        auth: FakeAuthRepository(signedInUser: const AuthUser(uid: 'sup', email: 'sup@icrash.pt')),
        support: support,
      );
      final vm = AppRootViewModel(services);
      await _settle();
      expect(vm.stage, RootStage.pickingInstitution, reason: 'Super always picks, even with one window');
      expect(vm.institutions.map((i) => i.id), ['inst']);
      await vm.selectInstitution(hospital);
      expect(vm.stage, RootStage.ready);
      expect(vm.session!.role, Role.platformSuperAdmin);
      expect(vm.session!.supportWindow!.grantId, 'g-inst');
      expect(support.logged, [('inst', 'enter')]);
      vm.dispose();
    });

    test("Super's own PIN (on its platformAdmins marker) is copied to the device", () async {
      final hasher = PinHasher(iterations: 1000);
      final support = FakeSupportRepository(isSuper: true, institutions: const [hospital], windows: {'inst': window('inst')})
        ..pinHash = await hasher.hash('0001');
      final services = buildTestServices(
        auth: FakeAuthRepository(signedInUser: const AuthUser(uid: 'sup', email: 'sup@icrash.pt')),
        support: support,
        pinHasher: hasher,
      );
      final vm = AppRootViewModel(services);
      await _settle();
      await vm.selectInstitution(hospital);
      expect(vm.hasPin, isTrue);
      expect(await services.deviceSession.verifyPin('sup', '0001'), isTrue);
      vm.dispose();
    });

    test('when the Admin closes the window, Super is sent back to the list', () async {
      final support = FakeSupportRepository(isSuper: true, institutions: const [hospital], windows: {'inst': window('inst')});
      final services = buildTestServices(
        auth: FakeAuthRepository(signedInUser: const AuthUser(uid: 'sup', email: 'sup@icrash.pt')),
        support: support,
      );
      final vm = AppRootViewModel(services);
      await _settle();
      await vm.selectInstitution(hospital);
      await _settle();
      await support.closeWindow('inst', byUid: 'admin');
      await _settle();
      expect(vm.session, isNull);
      expect(vm.supportEnded, isTrue);
      expect(vm.stage, RootStage.pickingInstitution);
      expect(vm.institutions, isEmpty);
      vm.dispose();
    });

    test('a user with several old memberships gets no picker: the first institution by name opens', () async {
      const membership = Membership(uid: 'ana', institutionId: 'inst', role: Role.manager, status: MembershipStatus.active);
      final services = buildTestServices(
        auth: FakeAuthRepository(signedInUser: const AuthUser(uid: 'ana', email: 'ana@h.pt')),
        institutions: FakeInstitutionRepository(institutions: const [other, hospital], myMembership: membership),
      );
      final vm = AppRootViewModel(services);
      await _settle();
      expect(vm.stage, RootStage.ready);
      expect(vm.session!.institution.id, 'other', reason: '"Hospital B" sorts before "Hospital da Ribeira"');
      vm.dispose();
    });
  });
}
