import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/common/repository_failure.dart';
import 'package:icrash_app/src/data/local/device_credential_store.dart';
import 'package:icrash_app/src/domain/entities/cart.dart';
import 'package:icrash_app/src/domain/entities/cart_responsible_user.dart';
import 'package:icrash_app/src/domain/entities/institution.dart';
import 'package:icrash_app/src/domain/entities/membership.dart';
import 'package:icrash_app/src/domain/entities/registered_device.dart';
import 'package:icrash_app/src/domain/entities/role.dart';
import 'package:icrash_app/src/domain/repositories/auth_repository.dart';
import 'package:icrash_app/src/services/internal_qr_payload.dart';
import 'package:icrash_app/src/services/pin_hasher.dart';
import 'package:icrash_app/src/ui/app/app_root_view_model.dart';
import 'package:icrash_app/src/ui/features/device/device_setup_view_model.dart';
import 'package:icrash_app/src/ui/features/device/device_sign_in_view_model.dart';

import '../fakes/fake_repositories.dart';

Future<void> _settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

const _institution = Institution(id: 'inst', name: 'Hospital da Ribeira');
const _admin = Membership(
  uid: 'rita',
  institutionId: 'inst',
  role: Role.institutionAdmin,
  status: MembershipStatus.active,
  displayName: 'Rita Lopes',
  email: 'rita@h.pt',
  userNumber: '1001',
);
const _ana = Membership(
  uid: 'ana',
  institutionId: 'inst',
  role: Role.manager,
  status: MembershipStatus.active,
  displayName: 'Ana Silva',
  email: 'ana@h.pt',
  userNumber: '2002',
);
const _tablet = Membership(uid: 'auth-dev1', institutionId: 'inst', role: Role.device, status: MembershipStatus.active, displayName: 'Tablet');

const _credentials = DeviceCredentials(
  institutionId: 'inst',
  institutionName: 'Hospital da Ribeira',
  deviceId: 'dev1',
  deviceName: 'Tablet Carro 1 · UCI',
  email: 'device-dev1@inst.devices.icrash.invalid',
  password: 'secret',
);

RegisteredDevice _device({List<String> carts = const ['c1', 'c2'], DateTime? revokedAt}) => RegisteredDevice(
      id: 'dev1',
      institutionId: 'inst',
      name: 'Tablet Carro 1 · UCI',
      cartIds: carts,
      authUid: 'auth-dev1',
      revokedAt: revokedAt,
    );

void main() {
  late PinHasher hasher;
  late FakeCredentialRepository pins;

  setUp(() async {
    hasher = PinHasher(iterations: 1000);
    pins = FakeCredentialRepository(pinHashes: {
      'inst/rita': await hasher.hash('1111'),
      'inst/ana': await hasher.hash('2468'),
    });
  });

  group('DeviceSignInViewModel: nº mecanográfico or e-mail + PIN (D17)', () {
    DeviceSignInViewModel build({Future<String?> Function(Membership)? onIdentified, Future<void> Function()? onTooMany}) {
      final services = buildTestServices(
        institutions: FakeInstitutionRepository(members: [_admin, _ana, _tablet]),
        credentials: pins,
        pinHasher: hasher,
      );
      return DeviceSignInViewModel(
        services: services,
        institutionId: 'inst',
        onIdentified: onIdentified ?? (_) async => null,
        onTooManyAttempts: onTooMany ?? () async {},
      );
    }

    Future<void> typePin(DeviceSignInViewModel vm, String pin) async {
      for (final d in pin.split('')) {
        vm.addDigit(int.parse(d));
      }
      await _settle();
    }

    test('the nº mecanográfico and the right PIN identify the person', () async {
      Membership? who;
      final vm = build(onIdentified: (m) async {
        who = m;
        return null;
      });
      vm.setIdentifier('2002');
      await typePin(vm, '2468');
      expect(who?.uid, 'ana');
      expect(vm.error, isNull);
      vm.dispose();
    });

    test('the e-mail works too, in any case', () async {
      Membership? who;
      final vm = build(onIdentified: (m) async {
        who = m;
        return null;
      });
      vm.setIdentifier('ANA@h.pt');
      await typePin(vm, '2468');
      expect(who?.uid, 'ana');
      vm.dispose();
    });

    test('a wrong PIN and an unknown number give the same message and count as attempts', () async {
      final vm = build();
      vm.setIdentifier('2002');
      await typePin(vm, '0000');
      expect(vm.error, DeviceSignInError.wrongCredentials);
      expect(vm.attemptsLeft, DeviceSignInViewModel.maxAttempts - 1);
      vm.setIdentifier('9999');
      await typePin(vm, '2468');
      expect(vm.error, DeviceSignInError.wrongCredentials);
      expect(vm.attemptsLeft, DeviceSignInViewModel.maxAttempts - 2);
      expect(vm.entered, 0);
      vm.dispose();
    });

    test('the tablet account itself can never sign in as a person', () async {
      final vm = build();
      vm.setIdentifier('Tablet');
      await typePin(vm, '1111');
      expect(vm.error, DeviceSignInError.wrongCredentials);
      vm.dispose();
    });

    test('five failures send the tablet back to its A1', () async {
      var backHome = false;
      final vm = build(onTooMany: () async => backHome = true);
      vm.setIdentifier('2002');
      for (var i = 0; i < DeviceSignInViewModel.maxAttempts; i++) {
        await typePin(vm, '0000');
      }
      expect(backHome, isTrue);
      vm.dispose();
    });

    test('the PIN before the number asks for the number first', () async {
      final vm = build();
      await typePin(vm, '2468');
      expect(vm.error, DeviceSignInError.enterIdentifier);
      expect(vm.attemptsLeft, DeviceSignInViewModel.maxAttempts);
      vm.dispose();
    });

    test("the root's refusal is shown (not registered to the cart)", () async {
      final vm = build(onIdentified: (_) async => 'notOnCart');
      vm.setIdentifier('2002');
      await typePin(vm, '2468');
      expect(vm.error, DeviceSignInError.notOnCart);
      expect(vm.attemptsLeft, DeviceSignInViewModel.maxAttempts);
      vm.dispose();
    });
  });

  group('DeviceSetupViewModel: an Admin registers the tablet once (A0, D17)', () {
    test('an Admin signs in, names the tablet, picks carts; the credentials are saved', () async {
      final devices = FakeDeviceRepository();
      final store = InMemoryDeviceCredentialStore();
      DeviceCredentials? registered;
      final services = buildTestServices(
        auth: FakeAuthRepository(signInResult: const AuthUser(uid: 'rita', email: 'rita@h.pt')),
        institutions: FakeInstitutionRepository(institutions: const [_institution], myMembership: _admin),
        carts: FakeCartRepository(carts: [
          const Cart(id: 'c2', institutionId: 'inst', name: 'Carro 2'),
          const Cart(id: 'c1', institutionId: 'inst', name: 'Carro 1'),
        ]),
        devices: devices,
        deviceCredentials: store,
      );
      final vm = DeviceSetupViewModel(services, onRegistered: (c) async => registered = c);
      expect((await vm.signIn('rita@h.pt', 'password')).isOk, isTrue);
      expect(vm.step, DeviceSetupStep.details);
      expect(vm.carts.map((c) => c.id), ['c1', 'c2']);
      expect(vm.canRegister, isFalse);
      vm.setName('Tablet Carro 1 · UCI');
      expect((await vm.register()).code, 'noCarts');
      vm.toggleCart('c1');
      expect((await vm.register()).isOk, isTrue);
      expect(devices.devices.single.cartIds, ['c1']);
      expect(devices.devices.single.registeredBy, 'rita');
      expect(store.value?.deviceName, 'Tablet Carro 1 · UCI');
      expect(registered?.deviceId, devices.devices.single.id);
      vm.dispose();
    });

    test('a Manager cannot register a tablet and is signed out again', () async {
      final auth = FakeAuthRepository(signInResult: const AuthUser(uid: 'ana', email: 'ana@h.pt'));
      final services = buildTestServices(
        auth: auth,
        institutions: FakeInstitutionRepository(institutions: const [_institution], myMembership: _ana),
      );
      final vm = DeviceSetupViewModel(services, onRegistered: (_) async {});
      final result = await vm.signIn('ana@h.pt', 'password');
      expect(result.code, 'notAdmin');
      expect(auth.signOutCallCount, 1);
      expect(vm.step, DeviceSetupStep.signIn);
      vm.dispose();
    });
  });

  group('AppRootViewModel on a registered tablet (D17)', () {
    ({AppRootViewModel vm, FakeAuthRepository auth, InMemoryDeviceCredentialStore store}) build({
      RegisteredDevice? device,
      List<CartResponsibleUser> registered = const [],
      Duration idleTimeout = AppRootViewModel.deviceIdleTimeout,
    }) {
      final auth = FakeAuthRepository(signInResult: const AuthUser(uid: 'auth-dev1', email: 'device-dev1@inst.devices.icrash.invalid'));
      final store = InMemoryDeviceCredentialStore()..value = _credentials;
      final carts = FakeCartRepository(carts: [
        const Cart(id: 'c1', institutionId: 'inst', name: 'Carro 1'),
        const Cart(id: 'c2', institutionId: 'inst', name: 'Carro 2'),
        const Cart(id: 'c3', institutionId: 'inst', name: 'Carro 3'),
      ]);
      carts.responsibleUsers.addAll(registered);
      final services = buildTestServices(
        auth: auth,
        institutions: FakeInstitutionRepository(institutions: const [_institution], members: [_admin, _ana, _tablet]),
        carts: carts,
        credentials: pins,
        pinHasher: hasher,
        devices: FakeDeviceRepository(devices: [device ?? _device()]),
        deviceCredentials: store,
      );
      return (vm: AppRootViewModel(services, idleTimeout: idleTimeout), auth: auth, store: store);
    }

    test('on start the tablet signs itself in and shows its A1, without a password', () async {
      final (:vm, :auth, store: _) = build();
      await _settle();
      expect(auth.lastEmail, _credentials.email);
      expect(vm.stage, RootStage.deviceHome);
      expect(vm.deviceCartIds, ['c1', 'c2']);
      vm.dispose();
    });

    test('a revoked tablet says so', () async {
      final (:vm, auth: _, store: _) = build(device: _device(revokedAt: DateTime(2026, 10, 30)));
      await _settle();
      expect(vm.stage, RootStage.deviceRevoked);
      vm.dispose();
    });

    test("a Manager's session runs as the person, limited to their carts on this tablet", () async {
      final (:vm, auth: _, store: _) = build(registered: const [
        CartResponsibleUser(uid: 'ana', cartId: 'c2'),
        CartResponsibleUser(uid: 'ana', cartId: 'c3'), // not on this tablet
      ]);
      await _settle();
      vm.showDeviceIdentify();
      expect(await vm.onDevicePersonIdentified(_ana), isNull);
      expect(vm.stage, RootStage.ready);
      final session = vm.session!;
      expect(session.user.uid, 'ana');
      expect(session.allowedCartIds, {'c2'});
      expect(session.mayOpenCart('c1'), isFalse);
      expect(session.onDevice, isTrue);
      // Structure stays on the Dashboard / a personal sign-in.
      expect(session.canEditStructure, isFalse);
      vm.dispose();
    });

    test('an Admin gets every cart of the tablet; someone on none of them is refused', () async {
      final (:vm, auth: _, store: _) = build();
      await _settle();
      vm.showDeviceIdentify();
      expect(await vm.onDevicePersonIdentified(_ana), 'noCarts');
      expect(await vm.onDevicePersonIdentified(_admin), isNull);
      expect(vm.session!.allowedCartIds, {'c1', 'c2'});
      expect(vm.session!.isInstitutionAdmin, isFalse);
      vm.dispose();
    });

    test("cart login: only the tablet's carts, then the person must be on that cart", () async {
      final (:vm, auth: _, store: _) = build(registered: const [CartResponsibleUser(uid: 'ana', cartId: 'c1')]);
      await _settle();
      final other = await vm.enterCartOnDevice(const CartQrTarget(institutionId: 'inst', cartId: 'c3'));
      expect(other.failure, RepositoryFailureReason.permissionDenied);
      expect((await vm.enterCartOnDevice(const CartQrTarget(institutionId: 'inst', cartId: 'c2'))).isOk, isTrue);
      expect(vm.stage, RootStage.deviceIdentify);
      expect(await vm.onDevicePersonIdentified(_ana), 'notOnCart');
      vm.showDeviceHome();
      await vm.enterCartOnDevice(const CartQrTarget(institutionId: 'inst', cartId: 'c1'));
      expect(await vm.onDevicePersonIdentified(_ana), isNull);
      expect(vm.session!.scopedCartId, 'c1');
      vm.dispose();
    });

    test('"Terminar sessão" goes back to the tablet\'s A1; the tablet stays signed in', () async {
      final (:vm, :auth, store: _) = build(registered: const [CartResponsibleUser(uid: 'ana', cartId: 'c1')]);
      await _settle();
      await vm.onDevicePersonIdentified(_ana);
      await vm.signOut();
      expect(vm.stage, RootStage.deviceHome);
      expect(vm.session, isNull);
      expect(auth.signOutCallCount, 0);
      vm.dispose();
    });

    test('without a touch the session ends (5 minutes; shorter here)', () async {
      final (:vm, auth: _, store: _) = build(
        registered: const [CartResponsibleUser(uid: 'ana', cartId: 'c1')],
        idleTimeout: const Duration(milliseconds: 80),
      );
      await _settle();
      await vm.onDevicePersonIdentified(_ana);
      expect(vm.stage, RootStage.ready);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      vm.touch();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(vm.stage, RootStage.ready);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(vm.stage, RootStage.deviceHome);
      expect(vm.deviceNotice, DeviceNotice.idle);
      vm.dispose();
    });

    test('"Remover registo" needs an Admin and forgets the tablet\'s sign-in', () async {
      final (:vm, :auth, :store) = build();
      await _settle();
      vm.showDeviceIdentify(purpose: DeviceIdentifyPurpose.removeRegistration);
      expect(await vm.onDevicePersonIdentified(_ana), 'notAdmin');
      expect(store.value, isNotNull);
      expect(await vm.onDevicePersonIdentified(_admin), isNull);
      expect(store.value, isNull);
      expect(vm.isRegisteredDevice, isFalse);
      expect(auth.signOutCallCount, greaterThan(0));
      vm.dispose();
    });
  });
}
