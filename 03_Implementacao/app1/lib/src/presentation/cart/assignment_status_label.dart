import '../../domain/entities/cart_product_assignment.dart';

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
