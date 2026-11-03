import '../entities/audit_event.dart';

abstract class AuditRepository {
  Future<void> record(AuditEvent event);

  Stream<List<AuditEvent>> watchRecentEvents(String institutionId, {int limit = 100});
}
