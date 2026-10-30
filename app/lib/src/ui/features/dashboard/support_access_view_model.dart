import '../../../common/app_services.dart';
import '../../../domain/entities/support_access.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';

/// D18 · "Acesso do suporte" (Admin only): open a time-limited window for the
/// I-Crash team, close it, and see what they did.
class SupportAccessViewModel extends ViewModel {
  SupportAccessViewModel(this.services, this.session) {
    final id = session.institution.id;
    listen(services.support.watchWindow(id), (window) {
      this.window = window;
      state = LoadState.ready;
      notify();
    }, onError: (_) {
      state = LoadState.ready;
      notify();
    });
    listen(services.support.watchLog(id), (entries) {
      log = entries;
      notify();
    }, onError: (_) {});
  }

  final AppServices services;
  final SessionController session;

  LoadState state = LoadState.loading;
  SupportWindow? window;
  List<SupportLogEntry> log = const [];

  /// The window in force right now, if any.
  SupportWindow? get openWindow {
    final w = window;
    return w != null && w.isOpenAt(DateTime.now()) ? w : null;
  }

  Duration duration = SupportWindow.durations.first;

  void setDuration(Duration value) {
    duration = value;
    notify();
  }

  /// Codes `reasonRequired`, `reasonTooLong`, `durationTooLong`.
  Future<ActionResult<void>> open(String reason) => run(() async {
        final text = reason.trim();
        if (text.isEmpty) throw const ActionError('reasonRequired');
        if (text.length > 500) throw const ActionError('reasonTooLong');
        if (duration > SupportWindow.durations.last) throw const ActionError('durationTooLong');
        await services.support.openWindow(
          session.institution.id,
          reason: text,
          duration: duration,
          byUid: session.user.uid,
          byName: session.myName,
        );
      });

  Future<ActionResult<void>> close() => run(() => services.support.closeWindow(session.institution.id, byUid: session.user.uid));
}
