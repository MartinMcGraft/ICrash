import '../../domain/entities/cart_product_assignment.dart';
import '../../domain/entities/usage_event.dart';

String assignmentStatusLabel(AssignmentStatus status) {
  switch (status) {
    case AssignmentStatus.ok:
      return 'OK';
    case AssignmentStatus.replenishmentRequired:
      return 'Reposição necessária';
    case AssignmentStatus.expiringSoon:
      return 'A expirar em breve';
    case AssignmentStatus.expired:
      return 'Expirado';
  }
}

String usageEventTypeLabel(UsageEventType type) {
  switch (type) {
    case UsageEventType.consumption:
      return 'Consumo';
    case UsageEventType.replenishment:
      return 'Reposição';
    case UsageEventType.correction:
      return 'Correção';
    case UsageEventType.auditReconciliation:
      return 'Reconciliação';
  }
}
