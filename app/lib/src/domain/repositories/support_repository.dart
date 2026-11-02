import '../entities/institution.dart';
import '../entities/support_access.dart';

/// D18 support access (see docs/DESIGN_D17_D18.md §2).
abstract class SupportRepository {
  /// Whether the signed-in account is Super (a `platformAdmins/{uid}` marker).
  Future<bool> isPlatformAdmin();

  /// Super's own PIN hash (on its `platformAdmins/{uid}` marker, set by
  /// I-Crash), so A2 and signing work for Super too. Null when none is set.
  Future<String?> myPinHash();

  /// The window in force for [institutionId] (open, closed or expired), or
  /// `null` when none was ever opened.
  Stream<SupportWindow?> watchWindow(String institutionId);

  /// Opens a window from now for [duration] (≤ 7 days) with a [reason].
  /// Only the institution's own Admin may (the rules refuse anyone else).
  Future<SupportWindow> openWindow(
    String institutionId, {
    required String reason,
    required Duration duration,
    required String byUid,
    String? byName,
  });

  /// Closes the window in force now.
  Future<void> closeWindow(String institutionId, {required String byUid});

  /// What Super did, newest first (Admin only).
  Stream<List<SupportLogEntry>> watchLog(String institutionId);

  /// Super's app records entering or leaving an institution.
  Future<void> log(String institutionId, {required String grantId, required String action, required String superUid, String? superEmail});

  /// Super: the institutions with an open window, with that window.
  Future<List<(Institution, SupportWindow)>> openInstitutions();
}

/// For builds and tests without a backend: nobody is Super, no windows.
class NoSupportRepository implements SupportRepository {
  const NoSupportRepository();

  @override
  Future<bool> isPlatformAdmin() async => false;

  @override
  Future<String?> myPinHash() async => null;

  @override
  Stream<SupportWindow?> watchWindow(String institutionId) => Stream.value(null);

  @override
  Future<SupportWindow> openWindow(String institutionId,
          {required String reason, required Duration duration, required String byUid, String? byName}) =>
      throw UnsupportedError('No support backend');

  @override
  Future<void> closeWindow(String institutionId, {required String byUid}) async {}

  @override
  Stream<List<SupportLogEntry>> watchLog(String institutionId) => Stream.value(const []);

  @override
  Future<void> log(String institutionId, {required String grantId, required String action, required String superUid, String? superEmail}) async {}

  @override
  Future<List<(Institution, SupportWindow)>> openInstitutions() async => const [];
}
