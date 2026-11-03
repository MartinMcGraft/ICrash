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

/// The session saved on this device, and the PIN check that unlocks it
/// (A2) and signs reports (A9).
///
/// DB3 (28 Oct): the PIN is set by the administration only. The device
/// keeps a copy of the user's PIN *hash* (fetched from the membership's
/// credentials after each sign-in), so A2 still works offline. Users can't
/// set or change their PIN here.
abstract class DeviceSessionRepository {
  Future<RememberedUser?> rememberedUser();
  Future<void> remember(RememberedUser user);
  Future<void> forget();

  /// Whether this device holds a PIN hash for [uid].
  Future<bool> hasPin(String uid);

  /// Stores (or, with null, removes) the cached PIN hash for [uid].
  Future<void> cachePinHash(String uid, String? pinHash);

  /// Checks [pin] against the cached hash. False when there is none.
  Future<bool> verifyPin(String uid, String pin);
}
