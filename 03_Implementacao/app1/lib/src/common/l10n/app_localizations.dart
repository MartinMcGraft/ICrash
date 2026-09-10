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

  /// No description provided for @loginTagline.
  ///
  /// In pt, this message translates to:
  /// **'Gestão de carros de emergência'**
  String get loginTagline;

  /// No description provided for @loginEmailLabel.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get loginEmailLabel;

  /// No description provided for @loginEmailRequired.
  ///
  /// In pt, this message translates to:
  /// **'Indique o e-mail'**
  String get loginEmailRequired;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Palavra-passe'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordRequired.
  ///
  /// In pt, this message translates to:
  /// **'Indique a palavra-passe'**
  String get loginPasswordRequired;

  /// No description provided for @loginSubmit.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get loginSubmit;

  /// No description provided for @loginErrorInvalidCredentials.
  ///
  /// In pt, this message translates to:
  /// **'Credenciais inválidas. Verifique o e-mail e a palavra-passe.'**
  String get loginErrorInvalidCredentials;

  /// No description provided for @loginErrorOffline.
  ///
  /// In pt, this message translates to:
  /// **'Sem ligação. Verifique a rede e tente novamente.'**
  String get loginErrorOffline;

  /// No description provided for @loginErrorGeneric.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível iniciar sessão. Tente novamente.'**
  String get loginErrorGeneric;

  /// No description provided for @actionCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar'**
  String get actionCreate;

  /// No description provided for @actionDuplicate.
  ///
  /// In pt, this message translates to:
  /// **'Duplicar'**
  String get actionDuplicate;

  /// No description provided for @validationEnterName.
  ///
  /// In pt, this message translates to:
  /// **'Indique um nome'**
  String get validationEnterName;

  /// No description provided for @createCartTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo carro'**
  String get createCartTitle;

  /// No description provided for @createCartNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do carro'**
  String get createCartNameLabel;

  /// No description provided for @createDrawerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova gaveta'**
  String get createDrawerTitle;

  /// No description provided for @createDrawerNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome da gaveta'**
  String get createDrawerNameLabel;

  /// No description provided for @createDrawerRowsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Linhas'**
  String get createDrawerRowsLabel;

  /// No description provided for @createDrawerColumnsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Colunas'**
  String get createDrawerColumnsLabel;

  /// No description provided for @duplicateCartTitle.
  ///
  /// In pt, this message translates to:
  /// **'Duplicar carro'**
  String get duplicateCartTitle;

  /// No description provided for @duplicateCartDescription.
  ///
  /// In pt, this message translates to:
  /// **'Cria um novo carro com as mesmas gavetas e slots. Não copia produtos, stock nem histórico.'**
  String get duplicateCartDescription;

  /// No description provided for @duplicateCartNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do novo carro'**
  String get duplicateCartNameLabel;

  /// No description provided for @editCartTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar carro'**
  String get editCartTitle;

  /// No description provided for @editCartStatusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Estado'**
  String get editCartStatusLabel;

  /// No description provided for @createProductTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo produto'**
  String get createProductTitle;

  /// No description provided for @createProductNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get createProductNameLabel;

  /// No description provided for @createProductUnitLabel.
  ///
  /// In pt, this message translates to:
  /// **'Unidade (opcional)'**
  String get createProductUnitLabel;

  /// No description provided for @createProductUnitHint.
  ///
  /// In pt, this message translates to:
  /// **'ex.: 1 mg/mL, ampola 1 mL'**
  String get createProductUnitHint;

  /// No description provided for @createProductGtinLabel.
  ///
  /// In pt, this message translates to:
  /// **'GTIN (opcional)'**
  String get createProductGtinLabel;

  /// No description provided for @addMemberTitle.
  ///
  /// In pt, this message translates to:
  /// **'Novo membro'**
  String get addMemberTitle;

  /// No description provided for @addMemberEmailRequired.
  ///
  /// In pt, this message translates to:
  /// **'Indique um e-mail'**
  String get addMemberEmailRequired;

  /// No description provided for @addMemberPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Palavra-passe temporária'**
  String get addMemberPasswordLabel;

  /// No description provided for @addMemberPasswordMinLength.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo de 6 caracteres'**
  String get addMemberPasswordMinLength;

  /// No description provided for @addMemberRoleLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cargo'**
  String get addMemberRoleLabel;

  /// No description provided for @cartQrScreenTitle.
  ///
  /// In pt, this message translates to:
  /// **'Código do carro'**
  String get cartQrScreenTitle;

  /// No description provided for @cartQrSemanticLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código QR do carro {cartName}'**
  String cartQrSemanticLabel(String cartName);

  /// No description provided for @cartQrInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Digitalize este código para abrir diretamente este carro.'**
  String get cartQrInstruction;

  /// No description provided for @cartQrScanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ler código do carro'**
  String get cartQrScanTitle;

  /// No description provided for @cartQrScanError.
  ///
  /// In pt, this message translates to:
  /// **'Código lido mas não é um código de carro reconhecido. Tente novamente.'**
  String get cartQrScanError;

  /// No description provided for @cartQrScanInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Aponte a câmara ao código do carro.'**
  String get cartQrScanInstruction;

  /// No description provided for @scannerPreviewUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Pré-visualização da câmara indisponível.'**
  String get scannerPreviewUnavailable;

  /// No description provided for @gs1ScanTitle.
  ///
  /// In pt, this message translates to:
  /// **'Digitalizar código GS1'**
  String get gs1ScanTitle;

  /// No description provided for @gs1ScanError.
  ///
  /// In pt, this message translates to:
  /// **'Código lido mas sem GTIN, lote ou validade reconhecidos. Tente novamente.'**
  String get gs1ScanError;

  /// No description provided for @gs1ScanInstructionHid.
  ///
  /// In pt, this message translates to:
  /// **'Digitalize o código com o leitor de códigos de barras ligado a este computador.'**
  String get gs1ScanInstructionHid;

  /// No description provided for @gs1ScanInstructionCamera.
  ///
  /// In pt, this message translates to:
  /// **'Aponte a câmara ao código GS1 Data Matrix da embalagem.'**
  String get gs1ScanInstructionCamera;

  /// No description provided for @actionCancelManualEntry.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar e inserir manualmente'**
  String get actionCancelManualEntry;

  /// No description provided for @gs1HidWaitingLabel.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando leitura...'**
  String get gs1HidWaitingLabel;

  /// No description provided for @actionSignOut.
  ///
  /// In pt, this message translates to:
  /// **'Terminar sessão'**
  String get actionSignOut;

  /// No description provided for @institutionSelectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolher instituição'**
  String get institutionSelectionTitle;

  /// No description provided for @institutionSelectionLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as instituições: {error}'**
  String institutionSelectionLoadError(Object error);

  /// No description provided for @institutionSelectionEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não tem acesso a nenhuma instituição.\nContacte o administrador da sua instituição.'**
  String get institutionSelectionEmpty;

  /// No description provided for @connectivityOfflineMessage.
  ///
  /// In pt, this message translates to:
  /// **'Sem ligação à internet — a mostrar dados guardados localmente.'**
  String get connectivityOfflineMessage;

  /// No description provided for @productsScreenTitle.
  ///
  /// In pt, this message translates to:
  /// **'Produtos'**
  String get productsScreenTitle;

  /// No description provided for @productsCreateError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível criar o produto. Tente novamente.'**
  String get productsCreateError;

  /// No description provided for @productsLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os produtos: {error}'**
  String productsLoadError(Object error);

  /// No description provided for @productsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não existem produtos nesta instituição.'**
  String get productsEmpty;

  /// No description provided for @membersScreenTitle.
  ///
  /// In pt, this message translates to:
  /// **'Membros'**
  String get membersScreenTitle;

  /// No description provided for @membersLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os membros: {error}'**
  String membersLoadError(Object error);

  /// No description provided for @membersEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não existem membros nesta instituição.'**
  String get membersEmpty;

  /// No description provided for @membersCreateErrorConflict.
  ///
  /// In pt, this message translates to:
  /// **'Já existe uma conta com este e-mail.'**
  String get membersCreateErrorConflict;

  /// No description provided for @membersCreateErrorInvalidInput.
  ///
  /// In pt, this message translates to:
  /// **'E-mail ou palavra-passe inválidos.'**
  String get membersCreateErrorInvalidInput;

  /// No description provided for @membersCreateErrorGeneric.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível criar o membro. Tente novamente.'**
  String get membersCreateErrorGeneric;

  /// No description provided for @membersChangeRoleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Mudar cargo'**
  String get membersChangeRoleTitle;

  /// No description provided for @membersChangeRoleError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível mudar o cargo. Tente novamente.'**
  String get membersChangeRoleError;

  /// No description provided for @membersToggleStatusError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível alterar o estado do membro. Tente novamente.'**
  String get membersToggleStatusError;

  /// No description provided for @membersDeactivate.
  ///
  /// In pt, this message translates to:
  /// **'Desativar'**
  String get membersDeactivate;

  /// No description provided for @membersReactivate.
  ///
  /// In pt, this message translates to:
  /// **'Reativar'**
  String get membersReactivate;

  /// No description provided for @responsibleUsersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Responsáveis pelo carro'**
  String get responsibleUsersTitle;

  /// No description provided for @productSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar produto neste carro...'**
  String get productSearchHint;

  /// No description provided for @productSearchPrompt.
  ///
  /// In pt, this message translates to:
  /// **'Escreva o nome de um produto para o encontrar neste carro.'**
  String get productSearchPrompt;

  /// No description provided for @productSearchEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum produto encontrado neste carro.'**
  String get productSearchEmpty;

  /// No description provided for @actionEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get actionEdit;

  /// No description provided for @actionShowQrCode.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar código QR'**
  String get actionShowQrCode;

  /// No description provided for @actionSearchProduct.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar produto'**
  String get actionSearchProduct;

  /// No description provided for @actionResponsible.
  ///
  /// In pt, this message translates to:
  /// **'Responsáveis'**
  String get actionResponsible;

  /// No description provided for @cartDetailCreateDrawerError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível criar a gaveta. Tente novamente.'**
  String get cartDetailCreateDrawerError;

  /// No description provided for @cartUpdatedMessage.
  ///
  /// In pt, this message translates to:
  /// **'Carro atualizado.'**
  String get cartUpdatedMessage;

  /// No description provided for @cartDetailUpdateError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atualizar o carro. Tente novamente.'**
  String get cartDetailUpdateError;

  /// No description provided for @duplicateCartDefaultName.
  ///
  /// In pt, this message translates to:
  /// **'{name} (cópia)'**
  String duplicateCartDefaultName(String name);

  /// No description provided for @cartDuplicatedMessage.
  ///
  /// In pt, this message translates to:
  /// **'Carro duplicado como \"{name}\".'**
  String cartDuplicatedMessage(String name);

  /// No description provided for @cartDetailDuplicateError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível duplicar o carro. Tente novamente.'**
  String get cartDetailDuplicateError;

  /// No description provided for @cartDetailLoadDrawersError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as gavetas: {error}'**
  String cartDetailLoadDrawersError(Object error);

  /// No description provided for @cartDetailDrawersEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não existem gavetas neste carro.'**
  String get cartDetailDrawersEmpty;

  /// No description provided for @drawerGridSize.
  ///
  /// In pt, this message translates to:
  /// **'{rows} linhas × {columns} colunas'**
  String drawerGridSize(int rows, int columns);
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
