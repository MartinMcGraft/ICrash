// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'I-Crash';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClose => 'Close';

  @override
  String get actionSave => 'Save';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionBack => 'Back';

  @override
  String get assignmentStatusOk => 'OK';

  @override
  String get assignmentStatusReplenishmentRequired => 'Replenishment required';

  @override
  String get assignmentStatusExpiringSoon => 'Expiring soon';

  @override
  String get assignmentStatusExpired => 'Expired';

  @override
  String get usageEventConsumption => 'Consumption';

  @override
  String get usageEventReplenishment => 'Replenishment';

  @override
  String get usageEventCorrection => 'Correction';

  @override
  String get usageEventAuditReconciliation => 'Reconciliation';

  @override
  String get cartStatusOperational => 'Operational';

  @override
  String get cartStatusReplenishmentRequired => 'Replenishment required';

  @override
  String get cartStatusAuditRequired => 'Audit required';

  @override
  String get cartStatusOutOfService => 'Out of service';

  @override
  String get roleSuperAdmin => 'Super administrator';

  @override
  String get roleInstitutionAdmin => 'Institution administrator';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleUser => 'User';

  @override
  String get membershipStatusActive => 'Active';

  @override
  String get membershipStatusInvited => 'Invited';

  @override
  String get membershipStatusDisabled => 'Disabled';

  @override
  String get loginTagline => 'Emergency cart management';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginEmailRequired => 'Enter your email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordRequired => 'Enter your password';

  @override
  String get loginSubmit => 'Sign in';

  @override
  String get loginErrorInvalidCredentials =>
      'Invalid credentials. Check your email and password.';

  @override
  String get loginErrorOffline =>
      'No connection. Check your network and try again.';

  @override
  String get loginErrorGeneric => 'Couldn\'t sign in. Try again.';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionDuplicate => 'Duplicate';

  @override
  String get validationEnterName => 'Enter a name';

  @override
  String get createCartTitle => 'New cart';

  @override
  String get createCartNameLabel => 'Cart name';

  @override
  String get createDrawerTitle => 'New drawer';

  @override
  String get createDrawerNameLabel => 'Drawer name';

  @override
  String get createDrawerRowsLabel => 'Rows';

  @override
  String get createDrawerColumnsLabel => 'Columns';

  @override
  String get duplicateCartTitle => 'Duplicate cart';

  @override
  String get duplicateCartDescription =>
      'Creates a new cart with the same drawers and slots. Does not copy products, stock, or history.';

  @override
  String get duplicateCartNameLabel => 'New cart\'s name';

  @override
  String get editCartTitle => 'Edit cart';

  @override
  String get editCartStatusLabel => 'Status';

  @override
  String get createProductTitle => 'New product';

  @override
  String get createProductNameLabel => 'Name';

  @override
  String get createProductUnitLabel => 'Unit (optional)';

  @override
  String get createProductUnitHint => 'e.g.: 1 mg/mL, 1 mL ampoule';

  @override
  String get createProductGtinLabel => 'GTIN (optional)';

  @override
  String get addMemberTitle => 'New member';

  @override
  String get addMemberEmailRequired => 'Enter an email';

  @override
  String get addMemberPasswordLabel => 'Temporary password';

  @override
  String get addMemberPasswordMinLength => 'Minimum 6 characters';

  @override
  String get addMemberRoleLabel => 'Role';

  @override
  String get cartQrScreenTitle => 'Cart code';

  @override
  String cartQrSemanticLabel(String cartName) {
    return 'QR code for cart $cartName';
  }

  @override
  String get cartQrInstruction => 'Scan this code to open this cart directly.';

  @override
  String get cartQrScanTitle => 'Scan cart code';

  @override
  String get cartQrScanError =>
      'Code read but it isn\'t a recognized cart code. Try again.';

  @override
  String get cartQrScanInstruction => 'Point the camera at the cart\'s code.';

  @override
  String get scannerPreviewUnavailable => 'Camera preview unavailable.';

  @override
  String get gs1ScanTitle => 'Scan GS1 code';

  @override
  String get gs1ScanError =>
      'Code read but no GTIN, lot, or expiry recognized. Try again.';

  @override
  String get gs1ScanInstructionHid =>
      'Scan the code with the barcode reader connected to this computer.';

  @override
  String get gs1ScanInstructionCamera =>
      'Point the camera at the package\'s GS1 Data Matrix code.';

  @override
  String get actionCancelManualEntry => 'Cancel and enter manually';

  @override
  String get gs1HidWaitingLabel => 'Waiting for scan...';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get institutionSelectionTitle => 'Choose institution';

  @override
  String institutionSelectionLoadError(Object error) {
    return 'Couldn\'t load institutions: $error';
  }

  @override
  String get institutionSelectionEmpty =>
      'You don\'t have access to any institution yet.\nContact your institution\'s administrator.';

  @override
  String get connectivityOfflineMessage =>
      'No internet connection — showing locally saved data.';

  @override
  String get productsScreenTitle => 'Products';

  @override
  String get productsCreateError => 'Couldn\'t create the product. Try again.';

  @override
  String productsLoadError(Object error) {
    return 'Couldn\'t load products: $error';
  }

  @override
  String get productsEmpty => 'There are no products in this institution yet.';

  @override
  String get membersScreenTitle => 'Members';

  @override
  String membersLoadError(Object error) {
    return 'Couldn\'t load members: $error';
  }

  @override
  String get membersEmpty => 'There are no members in this institution yet.';

  @override
  String get membersCreateErrorConflict =>
      'An account with this email already exists.';

  @override
  String get membersCreateErrorInvalidInput => 'Invalid email or password.';

  @override
  String get membersCreateErrorGeneric =>
      'Couldn\'t create the member. Try again.';

  @override
  String get membersChangeRoleTitle => 'Change role';

  @override
  String get membersChangeRoleError => 'Couldn\'t change the role. Try again.';

  @override
  String get membersToggleStatusError =>
      'Couldn\'t change the member\'s status. Try again.';

  @override
  String get membersDeactivate => 'Deactivate';

  @override
  String get membersReactivate => 'Reactivate';

  @override
  String get responsibleUsersTitle => 'Cart\'s responsible users';

  @override
  String get productSearchHint => 'Search for a product in this cart...';

  @override
  String get productSearchPrompt =>
      'Type a product\'s name to find it in this cart.';

  @override
  String get productSearchEmpty => 'No product found in this cart.';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionShowQrCode => 'Show QR code';

  @override
  String get actionSearchProduct => 'Search product';

  @override
  String get actionResponsible => 'Responsible users';

  @override
  String get cartDetailCreateDrawerError =>
      'Couldn\'t create the drawer. Try again.';

  @override
  String get cartUpdatedMessage => 'Cart updated.';

  @override
  String get cartDetailUpdateError => 'Couldn\'t update the cart. Try again.';

  @override
  String duplicateCartDefaultName(String name) {
    return '$name (copy)';
  }

  @override
  String cartDuplicatedMessage(String name) {
    return 'Cart duplicated as \"$name\".';
  }

  @override
  String get cartDetailDuplicateError =>
      'Couldn\'t duplicate the cart. Try again.';

  @override
  String cartDetailLoadDrawersError(Object error) {
    return 'Couldn\'t load drawers: $error';
  }

  @override
  String get cartDetailDrawersEmpty => 'There are no drawers in this cart yet.';

  @override
  String drawerGridSize(int rows, int columns) {
    return '$rows rows × $columns columns';
  }

  @override
  String get historyScreenTitle => 'History';

  @override
  String get historyFilterAll => 'All';

  @override
  String historyLoadError(Object error) {
    return 'Couldn\'t load the history: $error';
  }

  @override
  String get historyEmpty => 'No events to show.';

  @override
  String get exportCsvButton => 'Export CSV';

  @override
  String get actionCopy => 'Copy';

  @override
  String get csvCopiedMessage => 'CSV copied.';

  @override
  String get exportPdfButton => 'Export PDF';

  @override
  String get historyPdfDocumentTitle => 'Activity history';

  @override
  String get summaryViewButton => 'View summary';

  @override
  String get summaryDialogTitle => 'Summary';

  @override
  String get summaryGroupProduct => 'Product';

  @override
  String get summaryGroupCart => 'Cart';

  @override
  String get summaryGroupPeriod => 'Period';

  @override
  String get periodUnitDay => 'Day';

  @override
  String get periodUnitWeek => 'Week';

  @override
  String get periodUnitMonth => 'Month';

  @override
  String get summaryEmpty => 'No data to summarize.';

  @override
  String summaryConsumedReplenished(int consumed, int replenished) {
    return 'Consumed: $consumed   Replenished: $replenished';
  }

  @override
  String summaryOtherAdjustments(String value) {
    return '   Other adjustments: $value';
  }

  @override
  String get productRemoved => 'Removed product';

  @override
  String get cartRemoved => 'Removed cart';

  @override
  String get dashboardLegacyAppTooltip => 'Previous application (reference)';

  @override
  String get dashboardOpenCartError => 'Couldn\'t open this cart.';

  @override
  String get dashboardCreateCartError =>
      'Couldn\'t create the cart. Try again.';

  @override
  String dashboardLoadCartsError(Object error) {
    return 'Couldn\'t load carts: $error';
  }

  @override
  String get dashboardCartsEmpty =>
      'There are no emergency carts in this institution yet.';

  @override
  String get dashboardSearchCartLabel => 'Search cart';

  @override
  String get dashboardNoCartMatches => 'No cart matches the search.';

  @override
  String get dashboardAlertsTitle => 'Alerts';

  @override
  String get alertBelowMinimum => 'Stock below minimum';

  @override
  String get dashboardRecentActivityTitle => 'Recent activity';

  @override
  String get assignConflictError =>
      'This product is already assigned to another slot in this cart.';

  @override
  String get assignGenericError => 'Couldn\'t assign the product. Try again.';

  @override
  String get consumeExceedsError =>
      'You can\'t consume more than the current quantity.';

  @override
  String get consumeGenericError =>
      'Couldn\'t record the consumption. Try again.';

  @override
  String get replenishMissingExpiry => 'Enter the batch\'s expiry date.';

  @override
  String get replenishGenericError =>
      'Couldn\'t replenish the stock. Try again.';

  @override
  String get gs1UnknownGtin =>
      'GTIN not recognized in the catalogue — it wasn\'t linked to any product.';

  @override
  String gs1WrongProductWarning(String productName) {
    return 'Warning: this code matches \"$productName\", not this slot\'s product.';
  }

  @override
  String get reconcileGenericError => 'Couldn\'t reconcile. Try again.';

  @override
  String get correctGenericError => 'Couldn\'t correct. Try again.';

  @override
  String get emptySlotTitle => 'Empty slot';

  @override
  String get emptySlotMessage =>
      'This slot doesn\'t have a product assigned yet.';

  @override
  String get assignDialogTitle => 'Assign product';

  @override
  String get noProductsMessage =>
      'First create a product in the institution\'s catalogue.';

  @override
  String get productLabel => 'Product';

  @override
  String get initialQuantityLabel => 'Initial quantity';

  @override
  String get targetQuantityLabel => 'Target quantity';

  @override
  String get chooseProductValidation => 'Choose a product';

  @override
  String get actionAssign => 'Assign';

  @override
  String get recordConsumptionTitle => 'Record consumption';

  @override
  String get consumedQuantityLabel => 'Consumed quantity';

  @override
  String get validatePositiveInt => 'Enter a positive number';

  @override
  String get replenishStockTitle => 'Replenish stock';

  @override
  String get receivedQuantityLabel => 'Received quantity';

  @override
  String get lotNumberLabel => 'Lot number';

  @override
  String get lotRequiredValidation => 'Enter the lot';

  @override
  String get chooseExpiryLabel => 'Choose expiry date';

  @override
  String expiryDateLabel(String date) {
    return 'Expiry: $date';
  }

  @override
  String get reconcileDialogTitle => 'Reconcile (audit)';

  @override
  String get confirmedQuantityLabel => 'Physically confirmed quantity';

  @override
  String get validateNonNegativeInt => 'Enter a valid number';

  @override
  String get noBatchesMessage =>
      'No batches recorded; the reconciliation ends up with no confirmed batches.';

  @override
  String get confirmedBatchesLabel =>
      'Batches confirmed as physically present:';

  @override
  String batchLotLabel(String lotNumber) {
    return 'Lot $lotNumber';
  }

  @override
  String get correctEventDialogTitle => 'Correct event';

  @override
  String get noEventsToCorrect => 'There are no events to correct yet.';

  @override
  String get eventToCorrectLabel => 'Event to correct';

  @override
  String get chooseEventValidation => 'Choose an event';

  @override
  String get adjustmentLabel => 'Adjustment (positive or negative)';

  @override
  String get validateNonZeroInt => 'Enter an adjustment other than zero';

  @override
  String currentTargetLabel(int current, int target) {
    return 'Current: $current   Target: $target';
  }

  @override
  String get actionCorrect => 'Correct';

  @override
  String get actionReconcile => 'Reconcile';

  @override
  String get slotSelectionNotRectangle =>
      'The selection must form a rectangle with no gaps.';

  @override
  String get drawerSavedMessage => 'Drawer saved.';

  @override
  String get drawerSaveError => 'Couldn\'t save the drawer. Try again.';

  @override
  String get reassignSlotError => 'Couldn\'t reassign the slot. Try again.';

  @override
  String get removeAssignmentTitle => 'Remove assignment';

  @override
  String get removeAssignmentMessage =>
      'This assignment points to a slot that no longer exists in this drawer. Removing the assignment also removes its recorded batches; the event history is kept. This action cannot be undone.';

  @override
  String get actionRemove => 'Remove';

  @override
  String get deleteAssignmentError =>
      'Couldn\'t remove the assignment. Try again.';

  @override
  String loadSlotsError(Object error) {
    return 'Couldn\'t load the slots: $error';
  }

  @override
  String get actionMerge => 'Merge';

  @override
  String get actionSplit => 'Split';

  @override
  String get orphanedAssignmentsHeader =>
      'Assignments with no valid slot (from a past merge/split):';

  @override
  String get actionReassign => 'Reassign';

  @override
  String get reassignTooltip => 'Reassign to a free slot';

  @override
  String slotPositionTooltip(int row, int column) {
    return 'Row $row, column $column';
  }

  @override
  String get languageSwitcherTooltip => 'Language';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';
}
