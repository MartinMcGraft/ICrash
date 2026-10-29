import 'package:flutter_test/flutter_test.dart';
import 'package:icrash_app/src/data/local/local_repositories.dart';
import 'package:icrash_app/src/data/local/local_store.dart';
import 'package:icrash_app/src/services/pin_hasher.dart';

void main() {
  group('LocalDeviceSessionRepository: cached administrator-set PIN (DB3)', () {
    final hasher = PinHasher(iterations: 1000);

    test('verifies against the cached hash, offline', () async {
      final repo = LocalDeviceSessionRepository(InMemoryLocalStore(), hasher: hasher);
      expect(await repo.hasPin('ana'), isFalse);
      expect(await repo.verifyPin('ana', '1234'), isFalse);
      await repo.cachePinHash('ana', await hasher.hash('1234'));
      expect(await repo.hasPin('ana'), isTrue);
      expect(await repo.verifyPin('ana', '1234'), isTrue);
      expect(await repo.verifyPin('ana', '9999'), isFalse);
    });

    test('a cleared hash (no PIN set by the administration) can\'t unlock', () async {
      final repo = LocalDeviceSessionRepository(InMemoryLocalStore(), hasher: hasher);
      await repo.cachePinHash('ana', await hasher.hash('1234'));
      await repo.cachePinHash('ana', null);
      expect(await repo.hasPin('ana'), isFalse);
      expect(await repo.verifyPin('ana', '1234'), isFalse);
    });

    test('the old self-set device PIN is ignored', () async {
      final store = InMemoryLocalStore();
      await store.write('device.pin.ana', {'salt': 'x', 'hash': 'y'});
      final repo = LocalDeviceSessionRepository(store, hasher: hasher);
      expect(await repo.hasPin('ana'), isFalse);
    });
  });
}
