import '../entities/emergency_session.dart';

/// Active emergency-mode sessions (design v2 A10).
abstract class EmergencyRepository {
  Stream<List<EmergencySession>> watchActive(String institutionId);
  Future<EmergencySession> start(EmergencySession session);
  Future<EmergencySession> addConsumption(String institutionId, String cartId, EmergencyConsumption consumption);

  /// Removes and returns the last consumption ("Desfazer último").
  Future<EmergencyConsumption?> removeLast(String institutionId, String cartId);

  /// Ends the session and returns its final state.
  Future<EmergencySession?> end(String institutionId, String cartId);
}
