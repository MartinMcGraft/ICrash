import '../entities/shift.dart';

/// Shifts (design v2 B8, proposal D8).
abstract class ShiftRepository {
  Stream<List<ShiftAssignment>> watchShifts(String institutionId);
  Future<void> setShift(String institutionId, ShiftAssignment shift);
  Future<void> clearShift(String institutionId, ShiftAssignment shift);
}
