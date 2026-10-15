import '../entities/usage_event.dart';

abstract class UsageRepository {
  Stream<List<UsageEvent>> watchRecentEvents(String institutionId, {int limit = 50});

  Stream<List<UsageEvent>> watchEventsForAssignment(String institutionId, String assignmentId);
}
