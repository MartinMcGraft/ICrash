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
}
