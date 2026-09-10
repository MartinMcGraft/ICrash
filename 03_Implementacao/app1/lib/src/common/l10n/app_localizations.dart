import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'I-Crash'**
  String get appTitle;

  /// No description provided for @actionCancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get actionCancel;

  /// No description provided for @actionClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get actionClose;

  /// No description provided for @actionSave.
  ///
  /// In pt, this message translates to:
  /// **'Guardar'**
  String get actionSave;

  /// No description provided for @actionConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get actionConfirm;

  /// No description provided for @actionBack.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get actionBack;

  /// No description provided for @assignmentStatusOk.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get assignmentStatusOk;

  /// No description provided for @assignmentStatusReplenishmentRequired.
  ///
  /// In pt, this message translates to:
  /// **'Reposição necessária'**
  String get assignmentStatusReplenishmentRequired;

  /// No description provided for @assignmentStatusExpiringSoon.
  ///
  /// In pt, this message translates to:
  /// **'A expirar em breve'**
  String get assignmentStatusExpiringSoon;

  /// No description provided for @assignmentStatusExpired.
  ///
  /// In pt, this message translates to:
  /// **'Expirado'**
  String get assignmentStatusExpired;

  /// No description provided for @usageEventConsumption.
  ///
  /// In pt, this message translates to:
  /// **'Consumo'**
  String get usageEventConsumption;

  /// No description provided for @usageEventReplenishment.
  ///
  /// In pt, this message translates to:
  /// **'Reposição'**
  String get usageEventReplenishment;

  /// No description provided for @usageEventCorrection.
  ///
  /// In pt, this message translates to:
  /// **'Correção'**
  String get usageEventCorrection;

  /// No description provided for @usageEventAuditReconciliation.
  ///
  /// In pt, this message translates to:
  /// **'Reconciliação'**
  String get usageEventAuditReconciliation;

  /// No description provided for @cartStatusOperational.
  ///
  /// In pt, this message translates to:
  /// **'Operacional'**
  String get cartStatusOperational;

  /// No description provided for @cartStatusReplenishmentRequired.
  ///
  /// In pt, this message translates to:
  /// **'Reposição necessária'**
  String get cartStatusReplenishmentRequired;

  /// No description provided for @cartStatusAuditRequired.
  ///
  /// In pt, this message translates to:
  /// **'Auditoria necessária'**
  String get cartStatusAuditRequired;

  /// No description provided for @cartStatusOutOfService.
  ///
  /// In pt, this message translates to:
  /// **'Fora de serviço'**
  String get cartStatusOutOfService;

  /// No description provided for @roleSuperAdmin.
  ///
  /// In pt, this message translates to:
  /// **'Super administrador'**
  String get roleSuperAdmin;

  /// No description provided for @roleInstitutionAdmin.
  ///
  /// In pt, this message translates to:
  /// **'Administrador da instituição'**
  String get roleInstitutionAdmin;

  /// No description provided for @roleManager.
  ///
  /// In pt, this message translates to:
  /// **'Gestor'**
  String get roleManager;

  /// No description provided for @roleUser.
  ///
  /// In pt, this message translates to:
  /// **'Utilizador'**
  String get roleUser;

  /// No description provided for @membershipStatusActive.
  ///
  /// In pt, this message translates to:
  /// **'Ativo'**
  String get membershipStatusActive;

  /// No description provided for @membershipStatusInvited.
  ///
  /// In pt, this message translates to:
  /// **'Convidado'**
  String get membershipStatusInvited;

  /// No description provided for @membershipStatusDisabled.
  ///
  /// In pt, this message translates to:
  /// **'Desativado'**
  String get membershipStatusDisabled;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
