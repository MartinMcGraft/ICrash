/// D18 (30 Oct 2026): a window, opened by an institution's own Admin, during
/// which Super (the I-Crash team) may work in that institution as an Admin.
/// Firestore: `institutions/{i}/support/current` (the window in force) and
/// `supportGrants/{grantId}` (every window, as history).
class SupportWindow {
  const SupportWindow({
    required this.grantId,
    required this.institutionId,
    required this.reason,
    required this.grantedBy,
    this.grantedByName,
    this.startsAt,
    required this.endsAt,
    this.closedAt,
  });

  final String grantId;
  final String institutionId;

  /// Why the institution asked for help (required, ≤ 500 characters).
  final String reason;
  final String grantedBy;
  final String? grantedByName;
  final DateTime? startsAt;
  final DateTime endsAt;
  final DateTime? closedAt;

  /// The lengths an Admin can choose; 7 days at most (Martim, 30 Oct).
  static const durations = [Duration(hours: 4), Duration(hours: 24), Duration(days: 7)];

  bool isOpenAt(DateTime now) => closedAt == null && endsAt.isAfter(now);

  factory SupportWindow.fromMap(String institutionId, Map<String, Object?> map) => SupportWindow(
        grantId: map['grantId'] as String? ?? '',
        institutionId: institutionId,
        reason: map['reason'] as String? ?? '',
        grantedBy: map['grantedBy'] as String? ?? '',
        grantedByName: map['grantedByName'] as String?,
        startsAt: map['startsAt'] as DateTime?,
        endsAt: map['endsAt'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0),
        closedAt: map['closedAt'] as DateTime?,
      );
}

/// One entry of what Super did inside a window (append-only; the Admin
/// reads it). Written by Super's app: `enter` when it opens the
/// institution, `leave` when it goes back to the list or signs out.
class SupportLogEntry {
  const SupportLogEntry({
    required this.id,
    required this.superUid,
    this.superEmail,
    required this.grantId,
    required this.action,
    this.at,
  });

  final String id;
  final String superUid;
  final String? superEmail;
  final String grantId;

  /// `enter` or `leave`.
  final String action;
  final DateTime? at;

  factory SupportLogEntry.fromMap(String id, Map<String, Object?> map) => SupportLogEntry(
        id: id,
        superUid: map['superUid'] as String? ?? '',
        superEmail: map['superEmail'] as String?,
        grantId: map['grantId'] as String? ?? '',
        action: map['action'] as String? ?? '',
        at: map['at'] as DateTime?,
      );
}
