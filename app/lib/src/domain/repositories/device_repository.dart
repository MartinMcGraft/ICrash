import '../entities/registered_device.dart';

/// D17 registered tablets (see docs/DESIGN_D17_D18.md §1).
abstract class DeviceRepository {
  Stream<List<RegisteredDevice>> watchDevices(String institutionId);

  Future<RegisteredDevice?> getDevice(String institutionId, String deviceId);

  /// Admin: creates the tablet's account (role `device`), its device
  /// document, and registers it to [cartIds]. Returns what the tablet keeps
  /// to sign itself in.
  Future<DeviceCredentials> registerDevice(
    String institutionId, {
    required String institutionName,
    required String name,
    required List<String> cartIds,
    required String byUid,
    String? byName,
  });

  /// Admin: renames the tablet and changes its carts.
  Future<void> updateDevice(String institutionId, RegisteredDevice device, {required String name, required List<String> cartIds});

  /// Admin: the tablet stops working at its next request (its account is
  /// disabled and removed from its carts).
  Future<void> revokeDevice(String institutionId, RegisteredDevice device);
}

/// Where a registered tablet keeps its own credentials.
abstract class DeviceCredentialStore {
  Future<DeviceCredentials?> load();
  Future<void> save(DeviceCredentials credentials);
  Future<void> clear();
}

/// For builds and tests without a backend: no tablets.
class NoDeviceRepository implements DeviceRepository {
  const NoDeviceRepository();

  @override
  Stream<List<RegisteredDevice>> watchDevices(String institutionId) => Stream.value(const []);

  @override
  Future<RegisteredDevice?> getDevice(String institutionId, String deviceId) async => null;

  @override
  Future<DeviceCredentials> registerDevice(String institutionId,
          {required String institutionName, required String name, required List<String> cartIds, required String byUid, String? byName}) =>
      throw UnsupportedError('No device backend');

  @override
  Future<void> updateDevice(String institutionId, RegisteredDevice device, {required String name, required List<String> cartIds}) async {}

  @override
  Future<void> revokeDevice(String institutionId, RegisteredDevice device) async {}
}
