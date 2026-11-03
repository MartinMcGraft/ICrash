import '../../../common/app_services.dart';
import '../../../domain/entities/cart_report.dart';
import '../../core/mvvm/view_model.dart';
import '../../core/session/session.dart';

/// A9 · Relatório — view and sign (proposal D6: name + PIN + date; a signed
/// report can no longer change).
class ReportViewModel extends ViewModel {
  ReportViewModel(this.services, this.session, this.reportId) {
    listen(services.reports.watchReports(session.institution.id), (reports) {
      report = reports.where((r) => r.id == reportId).firstOrNull;
      state = report == null ? LoadState.error : LoadState.ready;
      notify();
    });
  }

  final AppServices services;
  final SessionController session;
  final String reportId;

  CartReport? report;
  LoadState state = LoadState.loading;
  bool confirmed = false;

  void setConfirmed(bool value) {
    confirmed = value;
    notify();
  }

  /// DB4 (28 Oct): the person who performed the check signs it; there is no
  /// separate signer. Anyone else sees the report but can't sign it.
  bool get canSign => report != null && !report!.isSigned && report!.createdByUid == session.user.uid;

  /// Error codes: `notAuthor`, `notConfirmed`, `noPin`, `wrongPin`.
  Future<ActionResult<void>> sign(String pin) => run(() async {
        final current = report;
        if (current == null) return;
        if (current.createdByUid != session.user.uid) throw const ActionError('notAuthor');
        if (!confirmed) throw const ActionError('notConfirmed');
        final uid = session.user.uid;
        if (!await services.deviceSession.hasPin(uid)) throw const ActionError('noPin');
        if (!await services.deviceSession.verifyPin(uid, pin)) throw const ActionError('wrongPin');
        await services.reports.signReport(session.institution.id, reportId, uid: uid, name: session.myName);
      });
}
