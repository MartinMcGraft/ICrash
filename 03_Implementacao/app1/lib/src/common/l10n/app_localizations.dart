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

  /// No description provided for @historyScreenTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get historyScreenTitle;

  /// No description provided for @historyFilterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get historyFilterAll;

  /// No description provided for @historyLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o histórico: {error}'**
  String historyLoadError(Object error);

  /// No description provided for @historyEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Sem eventos para mostrar.'**
  String get historyEmpty;

  /// No description provided for @exportCsvButton.
  ///
  /// In pt, this message translates to:
  /// **'Exportar CSV'**
  String get exportCsvButton;

  /// No description provided for @actionCopy.
  ///
  /// In pt, this message translates to:
  /// **'Copiar'**
  String get actionCopy;

  /// No description provided for @csvCopiedMessage.
  ///
  /// In pt, this message translates to:
  /// **'CSV copiado.'**
  String get csvCopiedMessage;

  /// No description provided for @exportPdfButton.
  ///
  /// In pt, this message translates to:
  /// **'Exportar PDF'**
  String get exportPdfButton;

  /// No description provided for @historyPdfDocumentTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de atividade'**
  String get historyPdfDocumentTitle;

  /// No description provided for @summaryViewButton.
  ///
  /// In pt, this message translates to:
  /// **'Ver resumo'**
  String get summaryViewButton;

  /// No description provided for @summaryDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resumo'**
  String get summaryDialogTitle;

  /// No description provided for @summaryGroupProduct.
  ///
  /// In pt, this message translates to:
  /// **'Produto'**
  String get summaryGroupProduct;

  /// No description provided for @summaryGroupCart.
  ///
  /// In pt, this message translates to:
  /// **'Carro'**
  String get summaryGroupCart;

  /// No description provided for @summaryGroupPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Período'**
  String get summaryGroupPeriod;

  /// No description provided for @periodUnitDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia'**
  String get periodUnitDay;

  /// No description provided for @periodUnitWeek.
  ///
  /// In pt, this message translates to:
  /// **'Semana'**
  String get periodUnitWeek;

  /// No description provided for @periodUnitMonth.
  ///
  /// In pt, this message translates to:
  /// **'Mês'**
  String get periodUnitMonth;

  /// No description provided for @summaryEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Sem dados para resumir.'**
  String get summaryEmpty;

  /// No description provided for @summaryConsumedReplenished.
  ///
  /// In pt, this message translates to:
  /// **'Consumido: {consumed}   Reposto: {replenished}'**
  String summaryConsumedReplenished(int consumed, int replenished);

  /// No description provided for @summaryOtherAdjustments.
  ///
  /// In pt, this message translates to:
  /// **'   Outros ajustes: {value}'**
  String summaryOtherAdjustments(String value);

  /// No description provided for @productRemoved.
  ///
  /// In pt, this message translates to:
  /// **'Produto removido'**
  String get productRemoved;

  /// No description provided for @cartRemoved.
  ///
  /// In pt, this message translates to:
  /// **'Carro removido'**
  String get cartRemoved;

  /// No description provided for @dashboardLegacyAppTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Aplicação anterior (referência)'**
  String get dashboardLegacyAppTooltip;

  /// No description provided for @dashboardOpenCartError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir este carro.'**
  String get dashboardOpenCartError;

  /// No description provided for @dashboardCreateCartError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível criar o carro. Tente novamente.'**
  String get dashboardCreateCartError;

  /// No description provided for @dashboardLoadCartsError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os carros: {error}'**
  String dashboardLoadCartsError(Object error);

  /// No description provided for @dashboardCartsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não existem carros de emergência nesta instituição.'**
  String get dashboardCartsEmpty;

  /// No description provided for @dashboardSearchCartLabel.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar carro'**
  String get dashboardSearchCartLabel;

  /// No description provided for @dashboardNoCartMatches.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum carro corresponde à pesquisa.'**
  String get dashboardNoCartMatches;

  /// No description provided for @dashboardAlertsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alertas'**
  String get dashboardAlertsTitle;

  /// No description provided for @alertBelowMinimum.
  ///
  /// In pt, this message translates to:
  /// **'Stock abaixo do mínimo'**
  String get alertBelowMinimum;

  /// No description provided for @dashboardRecentActivityTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atividade recente'**
  String get dashboardRecentActivityTitle;

  /// No description provided for @assignConflictError.
  ///
  /// In pt, this message translates to:
  /// **'Este produto já está atribuído a outro slot deste carro.'**
  String get assignConflictError;

  /// No description provided for @assignGenericError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível atribuir o produto. Tente novamente.'**
  String get assignGenericError;

  /// No description provided for @consumeExceedsError.
  ///
  /// In pt, this message translates to:
  /// **'Não pode consumir mais do que a quantidade atual.'**
  String get consumeExceedsError;

  /// No description provided for @consumeGenericError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível registar o consumo. Tente novamente.'**
  String get consumeGenericError;

  /// No description provided for @replenishMissingExpiry.
  ///
  /// In pt, this message translates to:
  /// **'Indique a validade do lote.'**
  String get replenishMissingExpiry;

  /// No description provided for @replenishGenericError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível repor o stock. Tente novamente.'**
  String get replenishGenericError;

  /// No description provided for @gs1UnknownGtin.
  ///
  /// In pt, this message translates to:
  /// **'GTIN não reconhecido no catálogo — não foi associado a nenhum produto.'**
  String get gs1UnknownGtin;

  /// No description provided for @gs1WrongProductWarning.
  ///
  /// In pt, this message translates to:
  /// **'Atenção: este código corresponde a \"{productName}\", não ao produto deste slot.'**
  String gs1WrongProductWarning(String productName);

  /// No description provided for @reconcileGenericError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível reconciliar. Tente novamente.'**
  String get reconcileGenericError;

  /// No description provided for @correctGenericError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível corrigir. Tente novamente.'**
  String get correctGenericError;

  /// No description provided for @emptySlotTitle.
  ///
  /// In pt, this message translates to:
  /// **'Slot vazio'**
  String get emptySlotTitle;

  /// No description provided for @emptySlotMessage.
  ///
  /// In pt, this message translates to:
  /// **'Este slot ainda não tem produto atribuído.'**
  String get emptySlotMessage;

  /// No description provided for @assignDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atribuir produto'**
  String get assignDialogTitle;

  /// No description provided for @noProductsMessage.
  ///
  /// In pt, this message translates to:
  /// **'Crie primeiro um produto no catálogo da instituição.'**
  String get noProductsMessage;

  /// No description provided for @productLabel.
  ///
  /// In pt, this message translates to:
  /// **'Produto'**
  String get productLabel;

  /// No description provided for @initialQuantityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade inicial'**
  String get initialQuantityLabel;

  /// No description provided for @targetQuantityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade alvo'**
  String get targetQuantityLabel;

  /// No description provided for @chooseProductValidation.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um produto'**
  String get chooseProductValidation;

  /// No description provided for @actionAssign.
  ///
  /// In pt, this message translates to:
  /// **'Atribuir'**
  String get actionAssign;

  /// No description provided for @recordConsumptionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Registar consumo'**
  String get recordConsumptionTitle;

  /// No description provided for @consumedQuantityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade consumida'**
  String get consumedQuantityLabel;

  /// No description provided for @validatePositiveInt.
  ///
  /// In pt, this message translates to:
  /// **'Indique um número positivo'**
  String get validatePositiveInt;

  /// No description provided for @replenishStockTitle.
  ///
  /// In pt, this message translates to:
  /// **'Repor stock'**
  String get replenishStockTitle;

  /// No description provided for @receivedQuantityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade recebida'**
  String get receivedQuantityLabel;

  /// No description provided for @lotNumberLabel.
  ///
  /// In pt, this message translates to:
  /// **'Número de lote'**
  String get lotNumberLabel;

  /// No description provided for @lotRequiredValidation.
  ///
  /// In pt, this message translates to:
  /// **'Indique o lote'**
  String get lotRequiredValidation;

  /// No description provided for @chooseExpiryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Escolher validade'**
  String get chooseExpiryLabel;

  /// No description provided for @expiryDateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Validade: {date}'**
  String expiryDateLabel(String date);

  /// No description provided for @reconcileDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Reconciliar (auditoria)'**
  String get reconcileDialogTitle;

  /// No description provided for @confirmedQuantityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade confirmada fisicamente'**
  String get confirmedQuantityLabel;

  /// No description provided for @validateNonNegativeInt.
  ///
  /// In pt, this message translates to:
  /// **'Indique um número válido'**
  String get validateNonNegativeInt;

  /// No description provided for @noBatchesMessage.
  ///
  /// In pt, this message translates to:
  /// **'Sem lotes registados; a reconciliação fica sem lotes confirmados.'**
  String get noBatchesMessage;

  /// No description provided for @confirmedBatchesLabel.
  ///
  /// In pt, this message translates to:
  /// **'Lotes confirmados como fisicamente presentes:'**
  String get confirmedBatchesLabel;

  /// No description provided for @batchLotLabel.
  ///
  /// In pt, this message translates to:
  /// **'Lote {lotNumber}'**
  String batchLotLabel(String lotNumber);

  /// No description provided for @correctEventDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Corrigir evento'**
  String get correctEventDialogTitle;

  /// No description provided for @noEventsToCorrect.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não existem eventos para corrigir.'**
  String get noEventsToCorrect;

  /// No description provided for @eventToCorrectLabel.
  ///
  /// In pt, this message translates to:
  /// **'Evento a corrigir'**
  String get eventToCorrectLabel;

  /// No description provided for @chooseEventValidation.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um evento'**
  String get chooseEventValidation;

  /// No description provided for @adjustmentLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ajuste (positivo ou negativo)'**
  String get adjustmentLabel;

  /// No description provided for @validateNonZeroInt.
  ///
  /// In pt, this message translates to:
  /// **'Indique um ajuste diferente de zero'**
  String get validateNonZeroInt;

  /// No description provided for @currentTargetLabel.
  ///
  /// In pt, this message translates to:
  /// **'Atual: {current}   Alvo: {target}'**
  String currentTargetLabel(int current, int target);

  /// No description provided for @actionCorrect.
  ///
  /// In pt, this message translates to:
  /// **'Corrigir'**
  String get actionCorrect;

  /// No description provided for @actionReconcile.
  ///
  /// In pt, this message translates to:
  /// **'Reconciliar'**
  String get actionReconcile;

  /// No description provided for @slotSelectionNotRectangle.
  ///
  /// In pt, this message translates to:
  /// **'A seleção tem de formar um retângulo sem espaços.'**
  String get slotSelectionNotRectangle;

  /// No description provided for @drawerSavedMessage.
  ///
  /// In pt, this message translates to:
  /// **'Gaveta guardada.'**
  String get drawerSavedMessage;

  /// No description provided for @drawerSaveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível guardar a gaveta. Tente novamente.'**
  String get drawerSaveError;

  /// No description provided for @reassignSlotError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível reatribuir o slot. Tente novamente.'**
  String get reassignSlotError;

  /// No description provided for @removeAssignmentTitle.
  ///
  /// In pt, this message translates to:
  /// **'Remover atribuição'**
  String get removeAssignmentTitle;

  /// No description provided for @removeAssignmentMessage.
  ///
  /// In pt, this message translates to:
  /// **'Esta atribuição aponta para um slot que já não existe nesta gaveta. Remover a atribuição também remove os lotes registados; o histórico de eventos mantém-se. Esta ação não pode ser desfeita.'**
  String get removeAssignmentMessage;

  /// No description provided for @actionRemove.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get actionRemove;

  /// No description provided for @deleteAssignmentError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível remover a atribuição. Tente novamente.'**
  String get deleteAssignmentError;

  /// No description provided for @loadSlotsError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os slots: {error}'**
  String loadSlotsError(Object error);

  /// No description provided for @actionMerge.
  ///
  /// In pt, this message translates to:
  /// **'Juntar'**
  String get actionMerge;

  /// No description provided for @actionSplit.
  ///
  /// In pt, this message translates to:
  /// **'Dividir'**
  String get actionSplit;

  /// No description provided for @orphanedAssignmentsHeader.
  ///
  /// In pt, this message translates to:
  /// **'Atribuições sem slot válido (de uma junção/divisão anterior):'**
  String get orphanedAssignmentsHeader;

  /// No description provided for @actionReassign.
  ///
  /// In pt, this message translates to:
  /// **'Reatribuir'**
  String get actionReassign;

  /// No description provided for @reassignTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Reatribuir a um slot livre'**
  String get reassignTooltip;

  /// No description provided for @slotPositionTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Linha {row}, coluna {column}'**
  String slotPositionTooltip(int row, int column);

  /// No description provided for @languageSwitcherTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get languageSwitcherTooltip;

  /// No description provided for @languagePortuguese.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// No description provided for @languageEnglish.
  ///
  /// In pt, this message translates to:
  /// **'English'**
  String get languageEnglish;
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
