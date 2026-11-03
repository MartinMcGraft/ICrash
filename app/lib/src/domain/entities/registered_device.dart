/// D17 (30 Oct 2026): a tablet set up once by an Admin, bound to some carts.
/// Firestore: `institutions/{i}/devices/{id}`; the tablet has its own
/// account ([authUid], membership role `device`), registered to each bound
/// cart like a person, so it reads and works only on those carts.
class RegisteredDevice {
  const RegisteredDevice({
    required this.id,
    required this.institutionId,
    required this.name,
    required this.cartIds,
    required this.authUid,
    this.registeredBy,
    this.registeredByName,
    this.registeredAt,
    this.revokedAt,
  });

  final String id;
  final String institutionId;

  /// "Tablet Carro 3 · UCI".
  final String name;

  /// The carts it serves (at least one, Martim 30 Oct).
  final List<String> cartIds;
  final String authUid;
  final String? registeredBy;
  final String? registeredByName;
  final DateTime? registeredAt;
  final DateTime? revokedAt;

  bool get revoked => revokedAt != null;

  factory RegisteredDevice.fromMap(String id, String institutionId, Map<String, Object?> map) => RegisteredDevice(
        id: id,
        institutionId: institutionId,
        name: map['name'] as String? ?? '',
        cartIds: [for (final c in (map['cartIds'] as List? ?? const [])) '$c'],
        authUid: map['authUid'] as String? ?? '',
        registeredBy: map['registeredBy'] as String?,
        registeredByName: map['registeredByName'] as String?,
        registeredAt: map['registeredAt'] as DateTime?,
        revokedAt: map['revokedAt'] as DateTime?,
      );
}

/// What a registered tablet keeps to sign itself in (secure storage on
/// Android/iOS).
class DeviceCredentials {
  const DeviceCredentials({
    required this.institutionId,
    required this.institutionName,
    required this.deviceId,
    required this.deviceName,
    required this.email,
    required this.password,
  });

  final String institutionId;
  final String institutionName;
  final String deviceId;
  final String deviceName;
  final String email;
  final String password;

  Map<String, String> toJson() => {
        'institutionId': institutionId,
        'institutionName': institutionName,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'email': email,
        'password': password,
      };

  static DeviceCredentials? fromJson(Map<String, Object?> json) {
    String? v(String k) => json[k] is String && (json[k] as String).isNotEmpty ? json[k] as String : null;
    final institutionId = v('institutionId'), deviceId = v('deviceId'), email = v('email'), password = v('password');
    if (institutionId == null || deviceId == null || email == null || password == null) return null;
    return DeviceCredentials(
      institutionId: institutionId,
      institutionName: v('institutionName') ?? '',
      deviceId: deviceId,
      deviceName: v('deviceName') ?? '',
      email: email,
      password: password,
    );
  }
}
