/// The person remembered on this device, so the PIN screen (design v2 A2)
/// can greet them and unlock the saved session without a network.
class RememberedUser {
  const RememberedUser({required this.uid, required this.displayName, this.roleId, this.service, this.institutionName});

  final String uid;
  final String displayName;

  /// `Role.id` of the last membership used on this device.
  final String? roleId;

  /// Hospital service, e.g. "Urgência".
  final String? service;

  /// Last institution used on this device (shown on the login screen).
  final String? institutionName;

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Map<String, Object?> toJson() => {'uid': uid, 'displayName': displayName, 'roleId': roleId, 'service': service, 'institutionName': institutionName};

  factory RememberedUser.fromJson(Map<String, Object?> json) => RememberedUser(
        uid: json['uid'] as String,
        displayName: json['displayName'] as String? ?? '',
        roleId: json['roleId'] as String?,
        service: json['service'] as String?,
        institutionName: json['institutionName'] as String?,
      );
}

/// Device-local unlock (proposal D3 option a: "o PIN desbloqueia a sessão
/// guardada neste dispositivo. Funciona sem rede."). The PIN never leaves
/// the device and is stored hashed.
abstract class DeviceSessionRepository {
  Future<RememberedUser?> rememberedUser();
  Future<void> remember(RememberedUser user);
  Future<void> forget();

  Future<bool> hasPin(String uid);
  Future<void> setPin(String uid, String pin);
  Future<bool> verifyPin(String uid, String pin);
}
