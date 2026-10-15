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
  String get cartStatusAuditRequired => 'Check overdue';

  @override
  String get cartStatusOutOfService => 'Out of service';

  @override
  String get roleSuperAdmin => 'Engineer (support)';

  @override
  String get roleInstitutionAdmin => 'Institution manager';

  @override
  String get roleManager => 'Service manager';

  @override
  String get roleUser => 'Health professional';

  @override
  String get membershipStatusActive => 'Active';

  @override
  String get membershipStatusInvited => 'Invited';

  @override
  String get membershipStatusDisabled => 'Disabled';

  @override
  String get loginTagline => 'Emergency cart management';

  @override
  String get loginEmailLabel => 'Institutional e-mail';

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
  String get productSearchHint => 'Product name or GTIN';

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

  @override
  String get cartStateEmergencyActive => 'Emergency active';

  @override
  String get slotHealthOk => 'OK';

  @override
  String get slotHealthExpiring => 'Expiring';

  @override
  String get slotHealthExpired => 'Expired';

  @override
  String get slotHealthLowStock => 'Low stock';

  @override
  String get slotHealthMissing => 'Missing';

  @override
  String get slotHealthFree => 'Free';

  @override
  String get syncSynced => 'Synced';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes to send',
      one: '1 change to send',
    );
    return '$_temp0';
  }

  @override
  String get syncOffline => 'Offline · working offline';

  @override
  String get actionBackTooltip => 'Back';

  @override
  String get stateLoading => 'Loading…';

  @override
  String get stateLoadError => 'Could not load the data.';

  @override
  String get stateRetry => 'Try again';

  @override
  String get stateNoAccess => 'You don\'t have access to this area.';

  @override
  String get actionGenericError => 'Could not complete the action. Try again.';

  @override
  String get actionOfflineError =>
      'Offline. The change will be sent when the connection returns.';

  @override
  String get actionPermissionError =>
      'You don\'t have permission for this action.';

  @override
  String get stubNotice => 'Demo feature: data is stored on this device only.';

  @override
  String formatToday(String time) {
    return 'Today, $time';
  }

  @override
  String formatYesterday(String time) {
    return 'Yesterday, $time';
  }

  @override
  String slotQuantitySemantics(int current, int target) {
    return '$current of $target units';
  }

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginForgotPassword => 'I forgot my password';

  @override
  String get loginUsePin => 'Unlock with PIN';

  @override
  String get loginCartLogin => 'Open a cart';

  @override
  String get loginNeedsSavedSession =>
      'Sign in once on this device to use a PIN or open a cart.';

  @override
  String get loginResetSent => 'We sent you an e-mail to reset your password.';

  @override
  String get loginResetNeedsEmail => 'Type your e-mail first.';

  @override
  String get pinWorksOffline => 'Works offline';

  @override
  String pinWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wrong PIN. $count attempts left.',
      one: 'Wrong PIN. 1 attempt left.',
    );
    return '$_temp0';
  }

  @override
  String pinNotMe(String name) {
    return 'Not $name? Sign in';
  }

  @override
  String get pinDelete => 'Delete';

  @override
  String pinDigitsSemantics(int entered, int total) {
    return '$entered of $total digits';
  }

  @override
  String get scannerUsbHint =>
      'USB reader: scan the code or type it and press Enter';

  @override
  String get cartLoginCaption => 'Point at the cart\'s QR code';

  @override
  String get cartLoginHelp =>
      'Scan the QR code on the cart or hold the NFC badge to the reader. The session is limited to this cart.';

  @override
  String get cartLoginUseNfc => 'Use NFC';

  @override
  String get cartLoginNfcUnavailable =>
      'NFC is not available in this version yet.';

  @override
  String get scannerTorch => 'Torch';

  @override
  String get scannerTorchOff => 'Turn torch off';

  @override
  String get cartLoginEnterCode => 'Enter cart code';

  @override
  String get cartLoginCodeLabel => 'Cart code';

  @override
  String get cartLoginCodeHint => 'Code printed under the QR';

  @override
  String get cartLoginBackToLogin => 'Back to sign in';

  @override
  String get cartLoginNotFound => 'This cart does not exist or was archived.';

  @override
  String get cartLoginNoAccess => 'You don\'t have access to this cart.';

  @override
  String get profileSetPin => 'Set PIN';

  @override
  String get profileChangePin => 'Change PIN';

  @override
  String get profileLockNow => 'Lock now';

  @override
  String get profileSwitchInstitution => 'Switch institution';

  @override
  String get pinSetupHelp =>
      'The PIN unlocks the session saved on this device, even offline. It is not shared with other devices.';

  @override
  String get pinNewLabel => 'New PIN (4 digits)';

  @override
  String get pinRepeatLabel => 'Repeat PIN';

  @override
  String get pinFourDigits => 'The PIN has 4 digits';

  @override
  String get pinMismatch => 'The PINs don\'t match';

  @override
  String get pinSaved => 'PIN saved on this device.';

  @override
  String get navCarts => 'Carts';

  @override
  String get navReports => 'Reports';

  @override
  String get navScan => 'Scan';

  @override
  String get navProfile => 'Profile';

  @override
  String get navOverview => 'Overview';

  @override
  String get navCatalog => 'Catalogue';

  @override
  String get navTemplates => 'Templates';

  @override
  String get navUsers => 'Users';

  @override
  String get navShifts => 'Shifts';

  @override
  String get navHistory => 'History';

  @override
  String dashboardBrandSubtitle(String institution) {
    return 'Management · $institution';
  }

  @override
  String cartsSubtitle(String institution, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count carts',
      one: '1 cart',
    );
    return '$institution · $_temp0';
  }

  @override
  String get cartsSearchHint => 'Search cart';

  @override
  String cartsFilterAll(int count) {
    return 'All ($count)';
  }

  @override
  String cartsFilterAttention(int count) {
    return 'Need attention ($count)';
  }

  @override
  String cartsFilterAttentionShort(int count) {
    return 'Attention ($count)';
  }

  @override
  String cartsFilterMine(int count) {
    return 'Mine ($count)';
  }

  @override
  String get offlineTitle => 'No network connection';

  @override
  String offlineMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You can keep working. $count changes will be sent when the connection returns.',
      one: 'You can keep working. 1 change will be sent when the connection returns.',
      zero: 'You can keep working. Changes will be sent when the connection returns.',
    );
    return '$_temp0';
  }

  @override
  String countExpired(int count) {
    return '$count expired';
  }

  @override
  String countMissing(int count) {
    return '$count missing';
  }

  @override
  String countExpiring(int count) {
    return '$count expiring';
  }

  @override
  String countLowStock(int count) {
    return '$count low on stock';
  }

  @override
  String checkOverdueDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Monthly check overdue ($days days)',
      one: 'Monthly check overdue (1 day)',
    );
    return '$_temp0';
  }

  @override
  String get noStockAlerts => 'No stock alerts';

  @override
  String get allCompliant => 'All compliant';

  @override
  String lastCheckLine(String date, String name) {
    return 'Monthly check: $date · $name';
  }

  @override
  String get lastCheckNever => 'Monthly check: not done yet';

  @override
  String get compliant => 'Compliant';

  @override
  String responsibleOnShift(String name) {
    return 'On shift: $name';
  }

  @override
  String get drawersTitle => 'Drawers';

  @override
  String drawerGridLong(int rows, int columns, int positions, int withProduct) {
    return '$rows × $columns · $positions positions · $withProduct with product';
  }

  @override
  String drawerGridShort(int rows, int columns, int positions) {
    return '$rows × $columns · $positions positions';
  }

  @override
  String get cartMenuTitle => 'Cart menu';

  @override
  String get monthlyCheckTitle => 'Monthly check';

  @override
  String get qrCodeShort => 'QR code';

  @override
  String get changeStateAction => 'Change state';

  @override
  String get cartReportsAction => 'Cart reports';

  @override
  String get emergencyHint =>
      'To record quick consumption during or right after an emergency.';

  @override
  String get emergencyModeTitle => 'Emergency mode';

  @override
  String get emergencyShort => 'Emergency';

  @override
  String get emergencyResume => 'Back to emergency mode';

  @override
  String get autoStateRule =>
      'Automatic rule (when on): expired or missing product → Replenishment required; monthly check older than 31 days → Check overdue.';

  @override
  String get printLabel => 'Print label';

  @override
  String productLocation(int number, String drawer, String position) {
    return 'Drawer $number · $drawer · position $position';
  }

  @override
  String drawerTitle(int number, String name) {
    return 'Drawer $number · $name';
  }

  @override
  String drawerSubtitle(String cart, int rows, int columns, int positions) {
    return '$cart · $rows × $columns · $positions positions';
  }

  @override
  String drawerSubtitleShort(String cart, int rows, int columns) {
    return '$cart · $rows × $columns';
  }

  @override
  String get drawerSelectHint =>
      'Tap a position to see its product, quantity and expiry.';

  @override
  String slotPositionInDrawer(String position, int drawer) {
    return 'Position $position · Drawer $drawer';
  }

  @override
  String get slotFreeTitle => 'Free position';

  @override
  String unitsOf(int current, int target) {
    return '$current of $target units';
  }

  @override
  String ofTargetUnits(int target) {
    return 'of $target units';
  }

  @override
  String get expiryLabel => 'Expiry';

  @override
  String get lotLabel => 'Lot';

  @override
  String get minimumLabel => 'Minimum';

  @override
  String lotWithUnits(String lot, int units) {
    return '$lot · $units units';
  }

  @override
  String daysCount(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get changeProductAction => 'Change product';

  @override
  String get changeProductConfirm =>
      'The current product leaves this position together with its recorded lots. Consumption history is kept.';

  @override
  String panelSubtitle(
    String product,
    String position,
    int current,
    int target,
  ) {
    return '$product · $position · now $current of $target';
  }

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get confirmConsumption => 'Confirm consumption';

  @override
  String get consumptionRecorded => 'Consumption recorded.';

  @override
  String get confirmReplenishment => 'Confirm replenishment';

  @override
  String get replenishmentRecorded => 'Replenishment recorded.';

  @override
  String get replenishScanHelp =>
      'Scan the package Data Matrix to fill in lot and expiry.';

  @override
  String get correctionRecorded => 'Correction recorded.';

  @override
  String get reconcileRecorded => 'Reconciliation recorded.';

  @override
  String get catalogSearchHint => 'Search the catalogue';

  @override
  String monthlyCheckSubtitle(
    String cart,
    int index,
    int total,
    String drawer,
  ) {
    return '$cart · Drawer $index of $total · $drawer';
  }

  @override
  String get saveAndExit => 'Save and exit';

  @override
  String progressSemantics(int index, int total) {
    return 'Drawer $index of $total';
  }

  @override
  String get monthlyCheckEmptyDrawer => 'This drawer has no assigned products.';

  @override
  String expiresOn(String date) {
    return 'expires on $date';
  }

  @override
  String expectedUnits(int count) {
    return 'expected $count';
  }

  @override
  String expiryShort(String date) {
    return 'exp. $date';
  }

  @override
  String checkVerified(int count) {
    return '$count verified';
  }

  @override
  String checkProblems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count with problems',
      one: '1 with a problem',
    );
    return '$_temp0';
  }

  @override
  String checkPending(int count) {
    return '$count to check';
  }

  @override
  String get monthlyCheckHelp =>
      'Tap a row to confirm quantity and expiry. Tap again to flag a problem; long-press to clear. Problems are recorded in the report.';

  @override
  String get checkMarkAll => 'Mark the rest as verified';

  @override
  String get addNote => 'Add note';

  @override
  String get editNote => 'Edit note';

  @override
  String get noteHint => 'Notes for the report';

  @override
  String get nextDrawer => 'Next drawer';

  @override
  String get previousDrawer => 'Previous drawer';

  @override
  String get finishCheck => 'Finish and create report';

  @override
  String get reportKindMonthlyCheck => 'Monthly check';

  @override
  String get reportKindEmergency => 'Emergency summary';

  @override
  String get reportMonthlyTitle => 'Monthly check report';

  @override
  String get reportEmergencyTitle => 'Emergency summary';

  @override
  String get reportSigned => 'Signed';

  @override
  String get reportPendingSignature => 'To sign';

  @override
  String get reportDate => 'Date';

  @override
  String get reportCheckedBy => 'Checked by';

  @override
  String get reportStartedBy => 'Started by';

  @override
  String get reportPositionsChecked => 'Positions checked';

  @override
  String get reportPeriod => 'Period';

  @override
  String xOfY(int x, int y) {
    return '$x of $y';
  }

  @override
  String reportFindings(int count) {
    return 'Problems found ($count)';
  }

  @override
  String get reportNoFindings => 'No problems found.';

  @override
  String get findingOther => 'difference';

  @override
  String emergencyConsumptions(int count) {
    return 'Recorded consumption ($count)';
  }

  @override
  String get reportNotes => 'Notes';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String signedByOn(String name, String date) {
    return 'Signed by $name · $date';
  }

  @override
  String get reportLockedHelp =>
      'Once signed, the report can no longer be changed.';

  @override
  String get signReport => 'Sign report';

  @override
  String get signReportHelp =>
      'By signing you confirm you checked the cart and the data is correct. Once signed, the report can no longer be changed.';

  @override
  String get confirmCheck => 'I confirm the check';

  @override
  String get pinLabel => 'PIN';

  @override
  String get signNeedsPin => 'Set a PIN on this device first to sign.';

  @override
  String get signNeedsConfirmation => 'Tick “I confirm the check” to sign.';

  @override
  String get signWrongPin => 'Wrong PIN.';

  @override
  String get reportSignedMessage => 'Report signed.';

  @override
  String reportsFilterPending(int count) {
    return 'To sign ($count)';
  }

  @override
  String get reportsEmpty =>
      'No reports yet. They are created at the end of a monthly check or an emergency.';

  @override
  String get emergencyNotActive => 'Emergency mode on this cart has ended.';

  @override
  String emergencyHeader(String cart) {
    return 'Emergency mode · $cart';
  }

  @override
  String emergencyStarted(String time, int minutes, String name) {
    return 'Started at $time ($minutes min ago) · $name';
  }

  @override
  String get emergencyEnd => 'End emergency';

  @override
  String get emergencyEndConfirm =>
      'The cart becomes “Replenishment required” and a consumption summary is created for signing.';

  @override
  String drawerShort(int number) {
    return 'Drawer $number';
  }

  @override
  String get emergencyHelp =>
      'Tap a position to record 1 unit used. Long-press for another quantity.';

  @override
  String get emergencyNothingLeft => 'This position has no units left.';

  @override
  String emergencyNotSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count consumptions were not sent to the server; they stay in the summary.',
      one: '1 consumption was not sent to the server; it stays in the summary.',
    );
    return '$_temp0';
  }

  @override
  String get undoLast => 'Undo last';

  @override
  String get scanProductCaption => 'Point at the product code';

  @override
  String get scanModeProduct => 'Product';

  @override
  String get scanModeCart => 'Cart';

  @override
  String get scanHelp =>
      'QR, Data Matrix (GS1) or barcode. Also works with a USB reader.';

  @override
  String get scanLastRead => 'Last code read';

  @override
  String scanLot(String lot) {
    return 'Lot $lot';
  }

  @override
  String scanExpiry(String date) {
    return 'Exp. $date';
  }

  @override
  String get scanReplenishThis => 'Replenish this product';

  @override
  String get scanManual => 'Manual';

  @override
  String get scanManualProductLabel => 'GTIN or GS1 code';

  @override
  String get scanOtherInstitution =>
      'This cart belongs to another institution.';

  @override
  String get scanNotInAnyCart =>
      'This product is not assigned to any cart you can access.';

  @override
  String get exportReport => 'Export report';

  @override
  String get metricOperational => 'Operational carts';

  @override
  String metricNeedReplenishment(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count need replenishment',
      one: '1 needs replenishment',
      zero: 'None need replenishment',
    );
    return '$_temp0';
  }

  @override
  String get metricExpiring30 => 'Expiring within 30 days';

  @override
  String metricInCarts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count carts',
      one: 'in 1 cart',
    );
    return '$_temp0';
  }

  @override
  String get metricChecksOverdue => 'Overdue checks';

  @override
  String get metricEmergencies => 'Emergencies this month';

  @override
  String metricUnitsRecorded(int count) {
    return '$count units recorded';
  }

  @override
  String get cartsNeedingAttention => 'Carts that need attention';

  @override
  String get columnCart => 'Cart';

  @override
  String get columnState => 'State';

  @override
  String get columnAlerts => 'Alerts';

  @override
  String get columnServiceLocation => 'Service · location';

  @override
  String activityEmergency(int count) {
    return 'Emergency mode · $count units';
  }

  @override
  String get activityCheckSigned => 'Monthly check signed';

  @override
  String get activityCheckDone => 'Monthly check completed';

  @override
  String cartsServicesSubtitle(int carts, int services) {
    String _temp0 = intl.Intl.pluralLogic(
      carts,
      locale: localeName,
      other: '$carts carts',
      one: '1 cart',
    );
    String _temp1 = intl.Intl.pluralLogic(
      services,
      locale: localeName,
      other: '$services services',
      one: '1 service',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get createFromTemplate => 'Create from template';

  @override
  String get newCart => 'New cart';

  @override
  String get cartsSearchHintLong => 'Search cart or service';

  @override
  String cartsFilterOutOfService(int count) {
    return 'Out of service ($count)';
  }

  @override
  String get columnLastCheck => 'Last check';

  @override
  String get columnOnShift => 'On shift';

  @override
  String cartCreated(String name) {
    return 'Cart “$name” created.';
  }

  @override
  String get templateLabel => 'Template';

  @override
  String get templatesEmpty => 'No templates yet. Create one in Templates.';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldService => 'Service';

  @override
  String get fieldServiceHint => 'e.g. Emergency';

  @override
  String get fieldLocation => 'Location';

  @override
  String get fieldLocationHint => 'e.g. Floor 0 · Resuscitation room';

  @override
  String get cartConfigSubtitle => 'Cart configuration';

  @override
  String get archiveCart => 'Archive cart';

  @override
  String get archiveCartConfirm =>
      'The cart will no longer appear in lists. History and reports are kept.';

  @override
  String get cartArchived => 'Cart archived.';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get cartInfoTitle => 'Information';

  @override
  String get originTemplate => 'Source template';

  @override
  String get autoStateLabel => 'Update the state automatically';

  @override
  String drawersCount(int count) {
    return 'Drawers ($count)';
  }

  @override
  String get addDrawer => 'Add drawer';

  @override
  String get columnNumber => 'No.';

  @override
  String get columnSize => 'Size';

  @override
  String get columnPositions => 'Positions';

  @override
  String get columnWithProduct => 'With product';

  @override
  String get editGrid => 'Edit grid';

  @override
  String get drawerNameHint => 'e.g. Drugs';

  @override
  String gridEditorTitle(int number, String name) {
    return 'Drawer $number · $name';
  }

  @override
  String gridEditorSubtitle(String cart) {
    return '$cart · edit grid and positions';
  }

  @override
  String get saveGrid => 'Save grid';

  @override
  String get gridSaved => 'Grid saved.';

  @override
  String get mergePositions => 'Merge positions';

  @override
  String get clearPosition => 'Clear position';

  @override
  String clearPositionConfirm(String product, String position) {
    return 'Removes $product from position $position. Recorded lots are removed; the history is kept.';
  }

  @override
  String get gridSelectionHint =>
      'Tap a position to configure it. Tap several to merge them.';

  @override
  String mergeLosesAssignments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count positions lose their product, which stays “without position” until reassigned.',
      one: '1 position loses its product, which stays “without position” until reassigned.',
    );
    return '$_temp0';
  }

  @override
  String get unsavedGridTitle => 'Unsaved changes';

  @override
  String get unsavedGridMessage => 'Leave without saving the grid?';

  @override
  String get discardChanges => 'Discard';

  @override
  String orphansTitle(int count) {
    return 'Products without a position ($count)';
  }

  @override
  String get orphanReassignHint =>
      'Select a free position in the grid and tap Reassign.';

  @override
  String positionTitle(String position) {
    return 'Position $position';
  }

  @override
  String positionsSelected(int count) {
    return '$count positions selected';
  }

  @override
  String get positionSelectHint =>
      'Select a position to configure its product.';

  @override
  String get gridUnsavedHint => 'Save the grid before configuring positions.';

  @override
  String get chooseProduct => 'Choose product';

  @override
  String get catalogNoMatches => 'No product matches the search.';

  @override
  String get minimumQuantityLabel => 'Minimum quantity';

  @override
  String get expiryWarningDaysLabel => 'Expiry warning (days)';

  @override
  String get askLotOnReplenish => 'Ask for lot and expiry on replenishment';

  @override
  String get applyToPosition => 'Apply to position';

  @override
  String get positionApplied => 'Position updated.';

  @override
  String get catalogTitle => 'Consumables catalogue';

  @override
  String catalogSubtitle(int count, int carts) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
    );
    String _temp1 = intl.Intl.pluralLogic(
      carts,
      locale: localeName,
      other: '$carts carts',
      one: '1 cart',
    );
    return '$_temp0 · used in $_temp1';
  }

  @override
  String get importCsv => 'Import CSV';

  @override
  String get importCsvHelp =>
      'Paste one line per product: name; presentation; GTIN; category; expiry warning (days). Products whose name or GTIN already exists are skipped.';

  @override
  String get importCsvHint => 'Paste the CSV file content here';

  @override
  String get importAction => 'Import';

  @override
  String importResult(int created, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      created,
      locale: localeName,
      other: '$created products imported',
      one: '1 product imported',
    );
    return '$_temp0 · $skipped skipped.';
  }

  @override
  String get newProduct => 'New product';

  @override
  String get editProduct => 'Edit product';

  @override
  String get catalogSearchByNameOrGtin => 'Search by name or GTIN';

  @override
  String get filterAll => 'All';

  @override
  String get categoryDrug => 'Drug';

  @override
  String get categoryDrugs => 'Drugs';

  @override
  String get categoryMaterial => 'Supplies';

  @override
  String get categoryFluid => 'Fluid';

  @override
  String get categoryFluids => 'Fluids';

  @override
  String get columnPresentation => 'Presentation';

  @override
  String get columnGtin => 'GTIN';

  @override
  String get columnCategory => 'Category';

  @override
  String get columnInUse => 'In use';

  @override
  String get expiryWarningShort => 'Expiry warning';

  @override
  String inCartsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count carts',
      one: '1 cart',
      zero: '—',
    );
    return '$_temp0';
  }

  @override
  String productCreated(String name) {
    return 'Product “$name” created.';
  }

  @override
  String get productUpdated => 'Product updated.';

  @override
  String get gtinTaken => 'A product with this GTIN already exists.';

  @override
  String get gtinInvalid => 'A GTIN has 8, 12, 13 or 14 digits.';

  @override
  String get scanGtin => 'Scan GTIN from the box';

  @override
  String get expiryWarningDefaultHint => 'Empty = institution default';

  @override
  String get templatesTitle => 'Cart templates';

  @override
  String get templatesSubtitle => 'Create identical carts from a template';

  @override
  String get templatesEmptyDashboard =>
      'No templates yet. Create one from a configured cart.';

  @override
  String get newTemplate => 'New template';

  @override
  String get editTemplate => 'Edit template';

  @override
  String get deleteTemplate => 'Delete template';

  @override
  String deleteTemplateConfirm(String name) {
    return 'Delete the template “$name”? Carts already created from it are not changed.';
  }

  @override
  String get templateDeleted => 'Template deleted.';

  @override
  String get templateSaved => 'Template saved.';

  @override
  String templateSummary(int drawers, int positions, int carts) {
    String _temp0 = intl.Intl.pluralLogic(
      drawers,
      locale: localeName,
      other: '$drawers drawers',
      one: '1 drawer',
    );
    String _temp1 = intl.Intl.pluralLogic(
      carts,
      locale: localeName,
      other: '$carts carts',
      one: '1 cart',
    );
    return '$_temp0 · $positions positions · used in $_temp1';
  }

  @override
  String templateUpdatedBy(String date, String name) {
    return 'Updated on $date by $name';
  }

  @override
  String templateDrawerSize(int rows, int columns, int positions) {
    return '$rows × $columns · $positions positions';
  }

  @override
  String get templateCopyNote =>
      'Carts created from the template copy drawers, positions and target quantities. Stock and history are not copied.';

  @override
  String get createCartFromThisTemplate => 'Create cart from this template';

  @override
  String templateCopyName(String name) {
    return '$name (copy)';
  }

  @override
  String get templateSourceCart => 'Source cart';

  @override
  String get templateRefreshFromCart => 'Update from a cart';

  @override
  String get templateKeepStructure => 'Keep the current structure';

  @override
  String get templateChooseCart => 'Choose a cart';

  @override
  String get usersTitle => 'Users and permissions';

  @override
  String usersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count users',
      one: '1 user',
    );
    return '$_temp0';
  }

  @override
  String get inviteUser => 'Invite user';

  @override
  String get sendInvite => 'Send invitation';

  @override
  String get inviteNote =>
      'The person receives an e-mail to set their own password.';

  @override
  String inviteSent(String email) {
    return 'Invitation sent to $email.';
  }

  @override
  String get resendInvite => 'Resend access e-mail';

  @override
  String get emailTaken => 'A user with this e-mail already exists.';

  @override
  String get emailInvalid => 'Enter a valid e-mail.';

  @override
  String get fieldEmail => 'E-mail';

  @override
  String get usersSearchHint => 'Search by name or e-mail';

  @override
  String usersFilterManagers(int count) {
    return 'Managers ($count)';
  }

  @override
  String usersFilterProfessionals(int count) {
    return 'Health professionals ($count)';
  }

  @override
  String usersFilterInvited(int count) {
    return 'Pending invitations ($count)';
  }

  @override
  String get usersNoMatches => 'No user matches the search.';

  @override
  String get columnUserType => 'User type';

  @override
  String get allServices => 'All';

  @override
  String get moreActions => 'More actions';

  @override
  String get cannotEditSelf => 'You cannot change your own account.';

  @override
  String get changeUserType => 'Change user type';

  @override
  String get deactivateUser => 'Deactivate';

  @override
  String get reactivateUser => 'Reactivate';

  @override
  String deactivateUserConfirm(String name) {
    return '$name will no longer be able to sign in. The history is kept.';
  }

  @override
  String reactivateUserConfirm(String name) {
    return '$name will be able to sign in again.';
  }

  @override
  String get userUpdated => 'User updated.';

  @override
  String get permissionsTitle => 'Permissions';

  @override
  String get permissionsNote =>
      'Proposal (D2). Permissions are stored on this device until the server supports them.';

  @override
  String get permViewCarts => 'View carts and drawers';

  @override
  String get permRecordConsumption => 'Record consumption';

  @override
  String get permReplenish => 'Replenish stock (lot and expiry)';

  @override
  String get permMonthlyCheck => 'Do the monthly check';

  @override
  String get permSignReports => 'Sign reports';

  @override
  String get permEmergencyMode => 'Use emergency mode';

  @override
  String get permChangeCartState => 'Change the cart state';

  @override
  String get permEditDrawers => 'Edit drawers and grids';

  @override
  String get permManageUsersAndShifts => 'Manage users and shifts';

  @override
  String get shiftsTitle => 'Shifts';

  @override
  String shiftsWeekOf(String start, String end) {
    return 'Week of $start to $end';
  }

  @override
  String get previousWeek => 'Previous week';

  @override
  String get nextWeek => 'Next week';

  @override
  String get addShift => 'Add shift';

  @override
  String get copyPreviousWeek => 'Copy previous week';

  @override
  String shiftsCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shifts copied.',
      one: '1 shift copied.',
      zero: 'No shift copied.',
    );
    return '$_temp0';
  }

  @override
  String get shiftsByCart => 'By cart';

  @override
  String get shiftsByPerson => 'By person';

  @override
  String get columnPerson => 'Person';

  @override
  String get shiftsNoneThisWeek => 'No shifts this week.';

  @override
  String get shiftsLegend =>
      'M = morning (08–16) · A = afternoon (16–24) · N = night (00–08)';

  @override
  String get shiftMorningShort => 'M';

  @override
  String get shiftAfternoonShort => 'A';

  @override
  String get shiftNightShort => 'N';

  @override
  String get shiftMorning => 'Morning';

  @override
  String get shiftAfternoon => 'Afternoon';

  @override
  String get shiftNight => 'Night';

  @override
  String get shiftDay => 'Day';

  @override
  String get shiftResponsible => 'Responsible';

  @override
  String get shiftNobody => 'Nobody';

  @override
  String get shiftSaved => 'Shift saved.';

  @override
  String get reportsHistoryTitle => 'Reports and history';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String exportCsvHelp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events',
      one: '1 event',
    );
    return '$_temp0 for the chosen period and cart. Copy and paste into a spreadsheet.';
  }

  @override
  String get copyCsv => 'Copy';

  @override
  String get csvCopied => 'CSV copied.';

  @override
  String get tabReports => 'Reports';

  @override
  String get tabEvents => 'Event history';

  @override
  String get tabStatistics => 'Statistics';

  @override
  String filterCart(String name) {
    return 'Cart: $name';
  }

  @override
  String get filterAllCarts => 'all';

  @override
  String filterPeriod(String period) {
    return 'Period: $period';
  }

  @override
  String get columnReport => 'Report';

  @override
  String get columnDate => 'Date';

  @override
  String get columnSignedBy => 'Signed by';

  @override
  String get reportPendingSignatureShort => 'To sign';

  @override
  String get actionOpen => 'Open';

  @override
  String get reportsEmptyPeriod => 'No reports in this period.';

  @override
  String get eventsEmptyPeriod => 'No events in this period.';

  @override
  String eventsCapped(int count) {
    return 'Showing the institution\'s $count most recent events.';
  }

  @override
  String get statConsumed => 'Consumed';

  @override
  String get statReplenished => 'Replenished';

  @override
  String get statChecks => 'Checks';

  @override
  String get statEmergencies => 'Emergencies';

  @override
  String get statPendingSignatures => 'To sign';

  @override
  String get statTopProducts => 'Most consumed products';

  @override
  String get statByCart => 'By cart';

  @override
  String pagerRange(int from, int to, int total) {
    return '$from–$to of $total';
  }

  @override
  String get pagerPrevious => 'Previous page';

  @override
  String get pagerNext => 'Next page';

  @override
  String get closePanel => 'Close panel';

  @override
  String get viewAsApp => 'View as App (testing)';

  @override
  String get viewAsDashboard => 'View as Dashboard (testing)';
}
