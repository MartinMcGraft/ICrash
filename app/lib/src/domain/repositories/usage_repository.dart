import '../entities/usage_event.dart';

abstract class UsageRepository {
  Stream<List<UsageEvent>> watchRecentEvents(String institutionId, {int limit = 50});

  Stream<List<UsageEvent>> watchEventsForAssignment(String institutionId, String assignmentId);

  /// Ids of the cart's placements that have at least one History event
  /// (P1/P2: their slot, product and drawer are then fixed). Covers old
  /// placements that have no `usedAt` marker.
  Stream<Set<String>> watchUsedAssignmentIds(String institutionId, String cartId);
}
