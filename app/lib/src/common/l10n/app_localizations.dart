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
  /// **'Verificação em atraso'**
  String get cartStatusAuditRequired;

  /// No description provided for @cartStatusOutOfService.
  ///
  /// In pt, this message translates to:
  /// **'Fora de serviço'**
  String get cartStatusOutOfService;

  /// No description provided for @roleSuperAdmin.
  ///
  /// In pt, this message translates to:
  /// **'Engenheiro (suporte)'**
  String get roleSuperAdmin;

  /// No description provided for @roleInstitutionAdmin.
  ///
  /// In pt, this message translates to:
  /// **'Gestor da instituição'**
  String get roleInstitutionAdmin;

  /// No description provided for @roleManager.
  ///
  /// In pt, this message translates to:
  /// **'Gestor de serviço'**
  String get roleManager;

  /// No description provided for @roleUser.
  ///
  /// In pt, this message translates to:
  /// **'Profissional de saúde'**
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
  /// **'E-mail institucional'**
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
  /// **'Nome do produto ou GTIN'**
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

  /// No description provided for @cartStateEmergencyActive.
  ///
  /// In pt, this message translates to:
  /// **'Emergência ativa'**
  String get cartStateEmergencyActive;

  /// No description provided for @slotHealthOk.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get slotHealthOk;

  /// No description provided for @slotHealthExpiring.
  ///
  /// In pt, this message translates to:
  /// **'A expirar'**
  String get slotHealthExpiring;

  /// No description provided for @slotHealthExpired.
  ///
  /// In pt, this message translates to:
  /// **'Expirado'**
  String get slotHealthExpired;

  /// No description provided for @slotHealthLowStock.
  ///
  /// In pt, this message translates to:
  /// **'Stock baixo'**
  String get slotHealthLowStock;

  /// No description provided for @slotHealthMissing.
  ///
  /// In pt, this message translates to:
  /// **'Em falta'**
  String get slotHealthMissing;

  /// No description provided for @slotHealthFree.
  ///
  /// In pt, this message translates to:
  /// **'Livre'**
  String get slotHealthFree;

  /// No description provided for @syncSynced.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizado'**
  String get syncSynced;

  /// No description provided for @syncPending.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 alteração por enviar} other{{count} alterações por enviar}}'**
  String syncPending(int count);

  /// No description provided for @syncOffline.
  ///
  /// In pt, this message translates to:
  /// **'Sem ligação · a trabalhar offline'**
  String get syncOffline;

  /// No description provided for @actionBackTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get actionBackTooltip;

  /// No description provided for @stateLoading.
  ///
  /// In pt, this message translates to:
  /// **'A carregar…'**
  String get stateLoading;

  /// No description provided for @stateLoadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os dados.'**
  String get stateLoadError;

  /// No description provided for @stateRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get stateRetry;

  /// No description provided for @stateNoAccess.
  ///
  /// In pt, this message translates to:
  /// **'Não tem acesso a esta área.'**
  String get stateNoAccess;

  /// No description provided for @actionGenericError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir a ação. Tente novamente.'**
  String get actionGenericError;

  /// No description provided for @actionOfflineError.
  ///
  /// In pt, this message translates to:
  /// **'Sem ligação. A alteração será enviada quando a ligação voltar.'**
  String get actionOfflineError;

  /// No description provided for @actionPermissionError.
  ///
  /// In pt, this message translates to:
  /// **'Não tem permissão para esta ação.'**
  String get actionPermissionError;

  /// No description provided for @stubNotice.
  ///
  /// In pt, this message translates to:
  /// **'Funcionalidade de demonstração: os dados ficam guardados só neste dispositivo.'**
  String get stubNotice;

  /// No description provided for @formatToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje, {time}'**
  String formatToday(String time);

  /// No description provided for @formatYesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem, {time}'**
  String formatYesterday(String time);

  /// No description provided for @slotQuantitySemantics.
  ///
  /// In pt, this message translates to:
  /// **'{current} de {target} unidades'**
  String slotQuantitySemantics(int current, int target);

  /// No description provided for @loginTitle.
  ///
  /// In pt, this message translates to:
  /// **'Iniciar sessão'**
  String get loginTitle;

  /// No description provided for @loginForgotPassword.
  ///
  /// In pt, this message translates to:
  /// **'Esqueci-me da palavra-passe'**
  String get loginForgotPassword;

  /// No description provided for @loginUsePin.
  ///
  /// In pt, this message translates to:
  /// **'Desbloquear com PIN'**
  String get loginUsePin;

  /// No description provided for @loginCartLogin.
  ///
  /// In pt, this message translates to:
  /// **'Entrar no carro'**
  String get loginCartLogin;

  /// No description provided for @loginNeedsSavedSession.
  ///
  /// In pt, this message translates to:
  /// **'Inicie sessão uma vez neste dispositivo para usar o PIN ou entrar num carro.'**
  String get loginNeedsSavedSession;

  /// No description provided for @loginResetSent.
  ///
  /// In pt, this message translates to:
  /// **'Enviámos um e-mail para redefinir a palavra-passe.'**
  String get loginResetSent;

  /// No description provided for @loginResetNeedsEmail.
  ///
  /// In pt, this message translates to:
  /// **'Escreva primeiro o seu e-mail.'**
  String get loginResetNeedsEmail;

  /// No description provided for @pinWorksOffline.
  ///
  /// In pt, this message translates to:
  /// **'Funciona sem rede'**
  String get pinWorksOffline;

  /// No description provided for @pinWrong.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{PIN errado. Resta 1 tentativa.} other{PIN errado. Restam {count} tentativas.}}'**
  String pinWrong(int count);

  /// No description provided for @pinNotMe.
  ///
  /// In pt, this message translates to:
  /// **'Não é {name}? Iniciar sessão'**
  String pinNotMe(String name);

  /// No description provided for @pinDelete.
  ///
  /// In pt, this message translates to:
  /// **'Apagar'**
  String get pinDelete;

  /// No description provided for @pinDigitsSemantics.
  ///
  /// In pt, this message translates to:
  /// **'{entered} de {total} dígitos'**
  String pinDigitsSemantics(int entered, int total);

  /// No description provided for @scannerUsbHint.
  ///
  /// In pt, this message translates to:
  /// **'Leitor USB: leia o código ou escreva-o e prima Enter'**
  String get scannerUsbHint;

  /// No description provided for @cartLoginCaption.
  ///
  /// In pt, this message translates to:
  /// **'Aponte para o código QR do carro'**
  String get cartLoginCaption;

  /// No description provided for @cartLoginHelp.
  ///
  /// In pt, this message translates to:
  /// **'Leia o código QR colado no carro ou aproxime o crachá NFC do leitor. A sessão fica limitada a este carro.'**
  String get cartLoginHelp;

  /// No description provided for @cartLoginUseNfc.
  ///
  /// In pt, this message translates to:
  /// **'Usar NFC'**
  String get cartLoginUseNfc;

  /// No description provided for @cartLoginNfcUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'NFC ainda não está disponível nesta versão.'**
  String get cartLoginNfcUnavailable;

  /// No description provided for @scannerTorch.
  ///
  /// In pt, this message translates to:
  /// **'Lanterna'**
  String get scannerTorch;

  /// No description provided for @scannerTorchOff.
  ///
  /// In pt, this message translates to:
  /// **'Desligar lanterna'**
  String get scannerTorchOff;

  /// No description provided for @cartLoginEnterCode.
  ///
  /// In pt, this message translates to:
  /// **'Introduzir código do carro'**
  String get cartLoginEnterCode;

  /// No description provided for @cartLoginCodeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código do carro'**
  String get cartLoginCodeLabel;

  /// No description provided for @cartLoginCodeHint.
  ///
  /// In pt, this message translates to:
  /// **'Código impresso por baixo do QR'**
  String get cartLoginCodeHint;

  /// No description provided for @cartLoginBackToLogin.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao início de sessão'**
  String get cartLoginBackToLogin;

  /// No description provided for @cartLoginNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Este carro não existe ou foi arquivado.'**
  String get cartLoginNotFound;

  /// No description provided for @cartLoginNoAccess.
  ///
  /// In pt, this message translates to:
  /// **'Não tem acesso a este carro.'**
  String get cartLoginNoAccess;

  /// No description provided for @profileSetPin.
  ///
  /// In pt, this message translates to:
  /// **'Definir PIN'**
  String get profileSetPin;

  /// No description provided for @profileChangePin.
  ///
  /// In pt, this message translates to:
  /// **'Alterar PIN'**
  String get profileChangePin;

  /// No description provided for @profileLockNow.
  ///
  /// In pt, this message translates to:
  /// **'Bloquear agora'**
  String get profileLockNow;

  /// No description provided for @profileSwitchInstitution.
  ///
  /// In pt, this message translates to:
  /// **'Mudar de instituição'**
  String get profileSwitchInstitution;

  /// No description provided for @pinSetupHelp.
  ///
  /// In pt, this message translates to:
  /// **'O PIN desbloqueia a sessão guardada neste dispositivo, mesmo sem rede. Não é partilhado com outros dispositivos.'**
  String get pinSetupHelp;

  /// No description provided for @pinNewLabel.
  ///
  /// In pt, this message translates to:
  /// **'Novo PIN (4 dígitos)'**
  String get pinNewLabel;

  /// No description provided for @pinRepeatLabel.
  ///
  /// In pt, this message translates to:
  /// **'Repetir PIN'**
  String get pinRepeatLabel;

  /// No description provided for @pinFourDigits.
  ///
  /// In pt, this message translates to:
  /// **'O PIN tem 4 dígitos'**
  String get pinFourDigits;

  /// No description provided for @pinMismatch.
  ///
  /// In pt, this message translates to:
  /// **'Os PIN não coincidem'**
  String get pinMismatch;

  /// No description provided for @pinSaved.
  ///
  /// In pt, this message translates to:
  /// **'PIN guardado neste dispositivo.'**
  String get pinSaved;

  /// No description provided for @navCarts.
  ///
  /// In pt, this message translates to:
  /// **'Carrinhos'**
  String get navCarts;

  /// No description provided for @navReports.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios'**
  String get navReports;

  /// No description provided for @navScan.
  ///
  /// In pt, this message translates to:
  /// **'Ler código'**
  String get navScan;

  /// No description provided for @navProfile.
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @navOverview.
  ///
  /// In pt, this message translates to:
  /// **'Visão geral'**
  String get navOverview;

  /// No description provided for @navCatalog.
  ///
  /// In pt, this message translates to:
  /// **'Catálogo'**
  String get navCatalog;

  /// No description provided for @navTemplates.
  ///
  /// In pt, this message translates to:
  /// **'Modelos'**
  String get navTemplates;

  /// No description provided for @navUsers.
  ///
  /// In pt, this message translates to:
  /// **'Utilizadores'**
  String get navUsers;

  /// No description provided for @navShifts.
  ///
  /// In pt, this message translates to:
  /// **'Turnos'**
  String get navShifts;

  /// No description provided for @navHistory.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get navHistory;

  /// No description provided for @dashboardBrandSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Gestão · {institution}'**
  String dashboardBrandSubtitle(String institution);

  /// No description provided for @cartsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{institution} · {count, plural, =1{1 carrinho} other{{count} carrinhos}}'**
  String cartsSubtitle(String institution, int count);

  /// No description provided for @cartsSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar carrinho'**
  String get cartsSearchHint;

  /// No description provided for @cartsFilterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos ({count})'**
  String cartsFilterAll(int count);

  /// No description provided for @cartsFilterAttention.
  ///
  /// In pt, this message translates to:
  /// **'Precisam de atenção ({count})'**
  String cartsFilterAttention(int count);

  /// No description provided for @cartsFilterAttentionShort.
  ///
  /// In pt, this message translates to:
  /// **'Atenção ({count})'**
  String cartsFilterAttentionShort(int count);

  /// No description provided for @cartsFilterMine.
  ///
  /// In pt, this message translates to:
  /// **'Os meus ({count})'**
  String cartsFilterMine(int count);

  /// No description provided for @offlineTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sem ligação à rede'**
  String get offlineTitle;

  /// No description provided for @offlineMessage.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Pode continuar a trabalhar. As alterações serão enviadas quando a ligação voltar.} =1{Pode continuar a trabalhar. 1 alteração será enviada quando a ligação voltar.} other{Pode continuar a trabalhar. {count} alterações serão enviadas quando a ligação voltar.}}'**
  String offlineMessage(int count);

  /// No description provided for @countExpired.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 expirado} other{{count} expirados}}'**
  String countExpired(int count);

  /// No description provided for @countMissing.
  ///
  /// In pt, this message translates to:
  /// **'{count} em falta'**
  String countMissing(int count);

  /// No description provided for @countExpiring.
  ///
  /// In pt, this message translates to:
  /// **'{count} a expirar'**
  String countExpiring(int count);

  /// No description provided for @countLowStock.
  ///
  /// In pt, this message translates to:
  /// **'{count} com stock baixo'**
  String countLowStock(int count);

  /// No description provided for @checkOverdueDays.
  ///
  /// In pt, this message translates to:
  /// **'{days, plural, =1{Verificação mensal em atraso (1 dia)} other{Verificação mensal em atraso ({days} dias)}}'**
  String checkOverdueDays(int days);

  /// No description provided for @noStockAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Sem alertas de stock'**
  String get noStockAlerts;

  /// No description provided for @allCompliant.
  ///
  /// In pt, this message translates to:
  /// **'Tudo conforme'**
  String get allCompliant;

  /// No description provided for @lastCheckLine.
  ///
  /// In pt, this message translates to:
  /// **'Verificação mensal: {date} · {name}'**
  String lastCheckLine(String date, String name);

  /// No description provided for @lastCheckNever.
  ///
  /// In pt, this message translates to:
  /// **'Verificação mensal: ainda não feita'**
  String get lastCheckNever;

  /// No description provided for @compliant.
  ///
  /// In pt, this message translates to:
  /// **'Conforme'**
  String get compliant;

  /// No description provided for @responsibleOnShift.
  ///
  /// In pt, this message translates to:
  /// **'Responsável no turno: {name}'**
  String responsibleOnShift(String name);

  /// No description provided for @drawersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gavetas'**
  String get drawersTitle;

  /// No description provided for @drawerGridLong.
  ///
  /// In pt, this message translates to:
  /// **'{rows} × {columns} · {positions} posições · {withProduct} com produto'**
  String drawerGridLong(int rows, int columns, int positions, int withProduct);

  /// No description provided for @drawerGridShort.
  ///
  /// In pt, this message translates to:
  /// **'{rows} × {columns} · {positions} posições'**
  String drawerGridShort(int rows, int columns, int positions);

  /// No description provided for @cartMenuTitle.
  ///
  /// In pt, this message translates to:
  /// **'Menu do carro'**
  String get cartMenuTitle;

  /// No description provided for @monthlyCheckTitle.
  ///
  /// In pt, this message translates to:
  /// **'Verificação mensal'**
  String get monthlyCheckTitle;

  /// No description provided for @qrCodeShort.
  ///
  /// In pt, this message translates to:
  /// **'Código QR'**
  String get qrCodeShort;

  /// No description provided for @changeStateAction.
  ///
  /// In pt, this message translates to:
  /// **'Alterar estado'**
  String get changeStateAction;

  /// No description provided for @cartReportsAction.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios do carro'**
  String get cartReportsAction;

  /// No description provided for @emergencyHint.
  ///
  /// In pt, this message translates to:
  /// **'Para registar consumos rápidos durante ou logo após uma emergência.'**
  String get emergencyHint;

  /// No description provided for @emergencyModeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Modo de emergência'**
  String get emergencyModeTitle;

  /// No description provided for @emergencyShort.
  ///
  /// In pt, this message translates to:
  /// **'Emergência'**
  String get emergencyShort;

  /// No description provided for @emergencyResume.
  ///
  /// In pt, this message translates to:
  /// **'Voltar ao modo de emergência'**
  String get emergencyResume;

  /// No description provided for @autoStateRule.
  ///
  /// In pt, this message translates to:
  /// **'Regra automática (quando ativa): produto expirado ou em falta → Reposição necessária; verificação mensal com mais de 31 dias → Verificação em atraso.'**
  String get autoStateRule;

  /// No description provided for @printLabel.
  ///
  /// In pt, this message translates to:
  /// **'Imprimir etiqueta'**
  String get printLabel;

  /// No description provided for @productLocation.
  ///
  /// In pt, this message translates to:
  /// **'Gaveta {number} · {drawer} · posição {position}'**
  String productLocation(int number, String drawer, String position);

  /// No description provided for @drawerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gaveta {number} · {name}'**
  String drawerTitle(int number, String name);

  /// No description provided for @drawerSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{cart} · {rows} × {columns} · {positions} posições'**
  String drawerSubtitle(String cart, int rows, int columns, int positions);

  /// No description provided for @drawerSubtitleShort.
  ///
  /// In pt, this message translates to:
  /// **'{cart} · {rows} × {columns}'**
  String drawerSubtitleShort(String cart, int rows, int columns);

  /// No description provided for @drawerSelectHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque numa posição para ver o produto, a quantidade e a validade.'**
  String get drawerSelectHint;

  /// No description provided for @slotPositionInDrawer.
  ///
  /// In pt, this message translates to:
  /// **'Posição {position} · Gaveta {drawer}'**
  String slotPositionInDrawer(String position, int drawer);

  /// No description provided for @slotFreeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Posição livre'**
  String get slotFreeTitle;

  /// No description provided for @unitsOf.
  ///
  /// In pt, this message translates to:
  /// **'{current} de {target} un.'**
  String unitsOf(int current, int target);

  /// No description provided for @ofTargetUnits.
  ///
  /// In pt, this message translates to:
  /// **'de {target} unidades'**
  String ofTargetUnits(int target);

  /// No description provided for @expiryLabel.
  ///
  /// In pt, this message translates to:
  /// **'Validade'**
  String get expiryLabel;

  /// No description provided for @lotLabel.
  ///
  /// In pt, this message translates to:
  /// **'Lote'**
  String get lotLabel;

  /// No description provided for @minimumLabel.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo'**
  String get minimumLabel;

  /// No description provided for @lotWithUnits.
  ///
  /// In pt, this message translates to:
  /// **'{lot} · {units} un.'**
  String lotWithUnits(String lot, int units);

  /// No description provided for @daysCount.
  ///
  /// In pt, this message translates to:
  /// **'{days, plural, =1{1 dia} other{{days} dias}}'**
  String daysCount(int days);

  /// No description provided for @changeProductAction.
  ///
  /// In pt, this message translates to:
  /// **'Trocar produto'**
  String get changeProductAction;

  /// No description provided for @changeProductConfirm.
  ///
  /// In pt, this message translates to:
  /// **'O produto atual sai desta posição juntamente com os lotes registados. O histórico de consumos mantém-se.'**
  String get changeProductConfirm;

  /// No description provided for @panelSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{product} · {position} · atual {current} de {target}'**
  String panelSubtitle(
    String product,
    String position,
    int current,
    int target,
  );

  /// No description provided for @quantityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade'**
  String get quantityLabel;

  /// No description provided for @confirmConsumption.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar consumo'**
  String get confirmConsumption;

  /// No description provided for @consumptionRecorded.
  ///
  /// In pt, this message translates to:
  /// **'Consumo registado.'**
  String get consumptionRecorded;

  /// No description provided for @confirmReplenishment.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar reposição'**
  String get confirmReplenishment;

  /// No description provided for @replenishmentRecorded.
  ///
  /// In pt, this message translates to:
  /// **'Reposição registada.'**
  String get replenishmentRecorded;

  /// No description provided for @replenishScanHelp.
  ///
  /// In pt, this message translates to:
  /// **'Leia o Data Matrix da embalagem para preencher lote e validade.'**
  String get replenishScanHelp;

  /// No description provided for @correctionRecorded.
  ///
  /// In pt, this message translates to:
  /// **'Correção registada.'**
  String get correctionRecorded;

  /// No description provided for @reconcileRecorded.
  ///
  /// In pt, this message translates to:
  /// **'Reconciliação registada.'**
  String get reconcileRecorded;

  /// No description provided for @catalogSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar no catálogo'**
  String get catalogSearchHint;

  /// No description provided for @monthlyCheckSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{cart} · Gaveta {index} de {total} · {drawer}'**
  String monthlyCheckSubtitle(String cart, int index, int total, String drawer);

  /// No description provided for @saveAndExit.
  ///
  /// In pt, this message translates to:
  /// **'Guardar e sair'**
  String get saveAndExit;

  /// No description provided for @progressSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Gaveta {index} de {total}'**
  String progressSemantics(int index, int total);

  /// No description provided for @monthlyCheckEmptyDrawer.
  ///
  /// In pt, this message translates to:
  /// **'Esta gaveta não tem produtos atribuídos.'**
  String get monthlyCheckEmptyDrawer;

  /// No description provided for @expiresOn.
  ///
  /// In pt, this message translates to:
  /// **'expira a {date}'**
  String expiresOn(String date);

  /// No description provided for @expectedUnits.
  ///
  /// In pt, this message translates to:
  /// **'esperado {count}'**
  String expectedUnits(int count);

  /// No description provided for @expiryShort.
  ///
  /// In pt, this message translates to:
  /// **'val. {date}'**
  String expiryShort(String date);

  /// No description provided for @checkVerified.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 verificada} other{{count} verificadas}}'**
  String checkVerified(int count);

  /// No description provided for @checkProblems.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 com problema} other{{count} com problema}}'**
  String checkProblems(int count);

  /// No description provided for @checkPending.
  ///
  /// In pt, this message translates to:
  /// **'{count} por verificar'**
  String checkPending(int count);

  /// No description provided for @monthlyCheckHelp.
  ///
  /// In pt, this message translates to:
  /// **'Toque numa linha para confirmar quantidade e validade. Toque de novo para assinalar um problema; toque longo para limpar. Os problemas ficam registados no relatório.'**
  String get monthlyCheckHelp;

  /// No description provided for @checkMarkAll.
  ///
  /// In pt, this message translates to:
  /// **'Marcar restantes como verificadas'**
  String get checkMarkAll;

  /// No description provided for @addNote.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar nota'**
  String get addNote;

  /// No description provided for @editNote.
  ///
  /// In pt, this message translates to:
  /// **'Editar nota'**
  String get editNote;

  /// No description provided for @noteHint.
  ///
  /// In pt, this message translates to:
  /// **'Observações para o relatório'**
  String get noteHint;

  /// No description provided for @nextDrawer.
  ///
  /// In pt, this message translates to:
  /// **'Gaveta seguinte'**
  String get nextDrawer;

  /// No description provided for @previousDrawer.
  ///
  /// In pt, this message translates to:
  /// **'Gaveta anterior'**
  String get previousDrawer;

  /// No description provided for @finishCheck.
  ///
  /// In pt, this message translates to:
  /// **'Concluir e gerar relatório'**
  String get finishCheck;

  /// No description provided for @reportKindMonthlyCheck.
  ///
  /// In pt, this message translates to:
  /// **'Verificação mensal'**
  String get reportKindMonthlyCheck;

  /// No description provided for @reportKindEmergency.
  ///
  /// In pt, this message translates to:
  /// **'Resumo de emergência'**
  String get reportKindEmergency;

  /// No description provided for @reportMonthlyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Relatório de verificação mensal'**
  String get reportMonthlyTitle;

  /// No description provided for @reportEmergencyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Resumo de emergência'**
  String get reportEmergencyTitle;

  /// No description provided for @reportSigned.
  ///
  /// In pt, this message translates to:
  /// **'Assinado'**
  String get reportSigned;

  /// No description provided for @reportPendingSignature.
  ///
  /// In pt, this message translates to:
  /// **'Por assinar'**
  String get reportPendingSignature;

  /// No description provided for @reportDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get reportDate;

  /// No description provided for @reportCheckedBy.
  ///
  /// In pt, this message translates to:
  /// **'Verificado por'**
  String get reportCheckedBy;

  /// No description provided for @reportStartedBy.
  ///
  /// In pt, this message translates to:
  /// **'Iniciado por'**
  String get reportStartedBy;

  /// No description provided for @reportPositionsChecked.
  ///
  /// In pt, this message translates to:
  /// **'Posições verificadas'**
  String get reportPositionsChecked;

  /// No description provided for @reportPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Período'**
  String get reportPeriod;

  /// No description provided for @xOfY.
  ///
  /// In pt, this message translates to:
  /// **'{x} de {y}'**
  String xOfY(int x, int y);

  /// No description provided for @reportFindings.
  ///
  /// In pt, this message translates to:
  /// **'Problemas encontrados ({count})'**
  String reportFindings(int count);

  /// No description provided for @reportNoFindings.
  ///
  /// In pt, this message translates to:
  /// **'Sem problemas encontrados.'**
  String get reportNoFindings;

  /// No description provided for @findingOther.
  ///
  /// In pt, this message translates to:
  /// **'diferença'**
  String get findingOther;

  /// No description provided for @emergencyConsumptions.
  ///
  /// In pt, this message translates to:
  /// **'Consumos registados ({count})'**
  String emergencyConsumptions(int count);

  /// No description provided for @reportNotes.
  ///
  /// In pt, this message translates to:
  /// **'Notas'**
  String get reportNotes;

  /// No description provided for @downloadPdf.
  ///
  /// In pt, this message translates to:
  /// **'Descarregar PDF'**
  String get downloadPdf;

  /// No description provided for @signedByOn.
  ///
  /// In pt, this message translates to:
  /// **'Assinado por {name} · {date}'**
  String signedByOn(String name, String date);

  /// No description provided for @reportLockedHelp.
  ///
  /// In pt, this message translates to:
  /// **'Depois de assinado, o relatório não pode ser alterado.'**
  String get reportLockedHelp;

  /// No description provided for @signReport.
  ///
  /// In pt, this message translates to:
  /// **'Assinar relatório'**
  String get signReport;

  /// No description provided for @signReportHelp.
  ///
  /// In pt, this message translates to:
  /// **'Ao assinar confirma que verificou o carro e que os dados estão corretos. Depois de assinado, o relatório não pode ser alterado.'**
  String get signReportHelp;

  /// No description provided for @confirmCheck.
  ///
  /// In pt, this message translates to:
  /// **'Confirmo a verificação'**
  String get confirmCheck;

  /// No description provided for @pinLabel.
  ///
  /// In pt, this message translates to:
  /// **'PIN'**
  String get pinLabel;

  /// No description provided for @signNeedsPin.
  ///
  /// In pt, this message translates to:
  /// **'Defina primeiro um PIN neste dispositivo para assinar.'**
  String get signNeedsPin;

  /// No description provided for @signNeedsConfirmation.
  ///
  /// In pt, this message translates to:
  /// **'Marque “Confirmo a verificação” para assinar.'**
  String get signNeedsConfirmation;

  /// No description provided for @signWrongPin.
  ///
  /// In pt, this message translates to:
  /// **'PIN errado.'**
  String get signWrongPin;

  /// No description provided for @reportSignedMessage.
  ///
  /// In pt, this message translates to:
  /// **'Relatório assinado.'**
  String get reportSignedMessage;

  /// No description provided for @reportsFilterPending.
  ///
  /// In pt, this message translates to:
  /// **'Por assinar ({count})'**
  String reportsFilterPending(int count);

  /// No description provided for @reportsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há relatórios. São criados no fim de uma verificação mensal ou de um modo de emergência.'**
  String get reportsEmpty;

  /// No description provided for @emergencyNotActive.
  ///
  /// In pt, this message translates to:
  /// **'O modo de emergência deste carro já terminou.'**
  String get emergencyNotActive;

  /// No description provided for @emergencyHeader.
  ///
  /// In pt, this message translates to:
  /// **'Modo de emergência · {cart}'**
  String emergencyHeader(String cart);

  /// No description provided for @emergencyStarted.
  ///
  /// In pt, this message translates to:
  /// **'Iniciado às {time} (há {minutes} min) · {name}'**
  String emergencyStarted(String time, int minutes, String name);

  /// No description provided for @emergencyEnd.
  ///
  /// In pt, this message translates to:
  /// **'Terminar emergência'**
  String get emergencyEnd;

  /// No description provided for @emergencyEndConfirm.
  ///
  /// In pt, this message translates to:
  /// **'O carro passa a “Reposição necessária” e é criado um resumo dos consumos para assinar.'**
  String get emergencyEndConfirm;

  /// No description provided for @drawerShort.
  ///
  /// In pt, this message translates to:
  /// **'Gaveta {number}'**
  String drawerShort(int number);

  /// No description provided for @emergencyHelp.
  ///
  /// In pt, this message translates to:
  /// **'Toque numa posição para registar 1 unidade usada. Toque longo para outra quantidade.'**
  String get emergencyHelp;

  /// No description provided for @emergencyNothingLeft.
  ///
  /// In pt, this message translates to:
  /// **'Esta posição já não tem unidades.'**
  String get emergencyNothingLeft;

  /// No description provided for @emergencyNotSent.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 consumo não foi enviado ao servidor; fica no resumo.} other{{count} consumos não foram enviados ao servidor; ficam no resumo.}}'**
  String emergencyNotSent(int count);

  /// No description provided for @undoLast.
  ///
  /// In pt, this message translates to:
  /// **'Desfazer último'**
  String get undoLast;

  /// No description provided for @scanProductCaption.
  ///
  /// In pt, this message translates to:
  /// **'Aponte para o código do produto'**
  String get scanProductCaption;

  /// No description provided for @scanModeProduct.
  ///
  /// In pt, this message translates to:
  /// **'Produto'**
  String get scanModeProduct;

  /// No description provided for @scanModeCart.
  ///
  /// In pt, this message translates to:
  /// **'Carro'**
  String get scanModeCart;

  /// No description provided for @scanHelp.
  ///
  /// In pt, this message translates to:
  /// **'QR, Data Matrix (GS1) ou código de barras. Também funciona com leitor USB.'**
  String get scanHelp;

  /// No description provided for @scanLastRead.
  ///
  /// In pt, this message translates to:
  /// **'Último código lido'**
  String get scanLastRead;

  /// No description provided for @scanLot.
  ///
  /// In pt, this message translates to:
  /// **'Lote {lot}'**
  String scanLot(String lot);

  /// No description provided for @scanExpiry.
  ///
  /// In pt, this message translates to:
  /// **'Val. {date}'**
  String scanExpiry(String date);

  /// No description provided for @scanReplenishThis.
  ///
  /// In pt, this message translates to:
  /// **'Repor este produto'**
  String get scanReplenishThis;

  /// No description provided for @scanManual.
  ///
  /// In pt, this message translates to:
  /// **'Manual'**
  String get scanManual;

  /// No description provided for @scanManualProductLabel.
  ///
  /// In pt, this message translates to:
  /// **'GTIN ou código GS1'**
  String get scanManualProductLabel;

  /// No description provided for @scanOtherInstitution.
  ///
  /// In pt, this message translates to:
  /// **'Este carro pertence a outra instituição.'**
  String get scanOtherInstitution;

  /// No description provided for @scanNotInAnyCart.
  ///
  /// In pt, this message translates to:
  /// **'Este produto não está atribuído a nenhum carro a que tenha acesso.'**
  String get scanNotInAnyCart;

  /// No description provided for @exportReport.
  ///
  /// In pt, this message translates to:
  /// **'Exportar relatório'**
  String get exportReport;

  /// No description provided for @metricOperational.
  ///
  /// In pt, this message translates to:
  /// **'Carrinhos operacionais'**
  String get metricOperational;

  /// No description provided for @metricNeedReplenishment.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhum precisa de reposição} =1{1 precisa de reposição} other{{count} precisam de reposição}}'**
  String metricNeedReplenishment(int count);

  /// No description provided for @metricExpiring30.
  ///
  /// In pt, this message translates to:
  /// **'A expirar em 30 dias'**
  String get metricExpiring30;

  /// No description provided for @metricInCarts.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{em 1 carrinho} other{em {count} carrinhos}}'**
  String metricInCarts(int count);

  /// No description provided for @metricChecksOverdue.
  ///
  /// In pt, this message translates to:
  /// **'Verificações em atraso'**
  String get metricChecksOverdue;

  /// No description provided for @metricEmergencies.
  ///
  /// In pt, this message translates to:
  /// **'Emergências este mês'**
  String get metricEmergencies;

  /// No description provided for @metricUnitsRecorded.
  ///
  /// In pt, this message translates to:
  /// **'{count} consumos registados'**
  String metricUnitsRecorded(int count);

  /// No description provided for @cartsNeedingAttention.
  ///
  /// In pt, this message translates to:
  /// **'Carrinhos que precisam de atenção'**
  String get cartsNeedingAttention;

  /// No description provided for @columnCart.
  ///
  /// In pt, this message translates to:
  /// **'Carrinho'**
  String get columnCart;

  /// No description provided for @columnState.
  ///
  /// In pt, this message translates to:
  /// **'Estado'**
  String get columnState;

  /// No description provided for @columnAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas'**
  String get columnAlerts;

  /// No description provided for @columnServiceLocation.
  ///
  /// In pt, this message translates to:
  /// **'Serviço · local'**
  String get columnServiceLocation;

  /// No description provided for @activityEmergency.
  ///
  /// In pt, this message translates to:
  /// **'Modo de emergência · {count} consumos'**
  String activityEmergency(int count);

  /// No description provided for @activityCheckSigned.
  ///
  /// In pt, this message translates to:
  /// **'Verificação mensal assinada'**
  String get activityCheckSigned;

  /// No description provided for @activityCheckDone.
  ///
  /// In pt, this message translates to:
  /// **'Verificação mensal concluída'**
  String get activityCheckDone;

  /// No description provided for @cartsServicesSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{carts, plural, =1{1 carrinho} other{{carts} carrinhos}} · {services, plural, =1{1 serviço} other{{services} serviços}}'**
  String cartsServicesSubtitle(int carts, int services);

  /// No description provided for @createFromTemplate.
  ///
  /// In pt, this message translates to:
  /// **'Criar a partir de modelo'**
  String get createFromTemplate;

  /// No description provided for @newCart.
  ///
  /// In pt, this message translates to:
  /// **'Novo carrinho'**
  String get newCart;

  /// No description provided for @cartsSearchHintLong.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar carrinho ou serviço'**
  String get cartsSearchHintLong;

  /// No description provided for @cartsFilterOutOfService.
  ///
  /// In pt, this message translates to:
  /// **'Fora de serviço ({count})'**
  String cartsFilterOutOfService(int count);

  /// No description provided for @columnLastCheck.
  ///
  /// In pt, this message translates to:
  /// **'Última verificação'**
  String get columnLastCheck;

  /// No description provided for @columnOnShift.
  ///
  /// In pt, this message translates to:
  /// **'Responsável no turno'**
  String get columnOnShift;

  /// No description provided for @cartCreated.
  ///
  /// In pt, this message translates to:
  /// **'Carrinho “{name}” criado.'**
  String cartCreated(String name);

  /// No description provided for @templateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Modelo'**
  String get templateLabel;

  /// No description provided for @templatesEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há modelos. Crie um em Modelos.'**
  String get templatesEmpty;

  /// No description provided for @fieldName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get fieldName;

  /// No description provided for @fieldService.
  ///
  /// In pt, this message translates to:
  /// **'Serviço'**
  String get fieldService;

  /// No description provided for @fieldServiceHint.
  ///
  /// In pt, this message translates to:
  /// **'ex.: Urgência'**
  String get fieldServiceHint;

  /// No description provided for @fieldLocation.
  ///
  /// In pt, this message translates to:
  /// **'Local'**
  String get fieldLocation;

  /// No description provided for @fieldLocationHint.
  ///
  /// In pt, this message translates to:
  /// **'ex.: Piso 0 · Sala de reanimação'**
  String get fieldLocationHint;

  /// No description provided for @cartConfigSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Configuração do carrinho'**
  String get cartConfigSubtitle;

  /// No description provided for @archiveCart.
  ///
  /// In pt, this message translates to:
  /// **'Arquivar carrinho'**
  String get archiveCart;

  /// No description provided for @archiveCartConfirm.
  ///
  /// In pt, this message translates to:
  /// **'O carrinho deixa de aparecer nas listas. O histórico e os relatórios mantêm-se.'**
  String get archiveCartConfirm;

  /// No description provided for @cartArchived.
  ///
  /// In pt, this message translates to:
  /// **'Carrinho arquivado.'**
  String get cartArchived;

  /// No description provided for @saveChanges.
  ///
  /// In pt, this message translates to:
  /// **'Guardar alterações'**
  String get saveChanges;

  /// No description provided for @cartInfoTitle.
  ///
  /// In pt, this message translates to:
  /// **'Informação'**
  String get cartInfoTitle;

  /// No description provided for @originTemplate.
  ///
  /// In pt, this message translates to:
  /// **'Modelo de origem'**
  String get originTemplate;

  /// No description provided for @autoStateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar o estado automaticamente'**
  String get autoStateLabel;

  /// No description provided for @drawersCount.
  ///
  /// In pt, this message translates to:
  /// **'Gavetas ({count})'**
  String drawersCount(int count);

  /// No description provided for @addDrawer.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar gaveta'**
  String get addDrawer;

  /// No description provided for @columnNumber.
  ///
  /// In pt, this message translates to:
  /// **'Nº'**
  String get columnNumber;

  /// No description provided for @columnSize.
  ///
  /// In pt, this message translates to:
  /// **'Dimensão'**
  String get columnSize;

  /// No description provided for @columnPositions.
  ///
  /// In pt, this message translates to:
  /// **'Posições'**
  String get columnPositions;

  /// No description provided for @columnWithProduct.
  ///
  /// In pt, this message translates to:
  /// **'Com produto'**
  String get columnWithProduct;

  /// No description provided for @editGrid.
  ///
  /// In pt, this message translates to:
  /// **'Editar grelha'**
  String get editGrid;

  /// No description provided for @drawerNameHint.
  ///
  /// In pt, this message translates to:
  /// **'ex.: Fármacos'**
  String get drawerNameHint;

  /// No description provided for @gridEditorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Gaveta {number} · {name}'**
  String gridEditorTitle(int number, String name);

  /// No description provided for @gridEditorSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{cart} · editar grelha e posições'**
  String gridEditorSubtitle(String cart);

  /// No description provided for @saveGrid.
  ///
  /// In pt, this message translates to:
  /// **'Guardar grelha'**
  String get saveGrid;

  /// No description provided for @gridSaved.
  ///
  /// In pt, this message translates to:
  /// **'Grelha guardada.'**
  String get gridSaved;

  /// No description provided for @mergePositions.
  ///
  /// In pt, this message translates to:
  /// **'Juntar posições'**
  String get mergePositions;

  /// No description provided for @clearPosition.
  ///
  /// In pt, this message translates to:
  /// **'Limpar posição'**
  String get clearPosition;

  /// No description provided for @clearPositionConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Remove {product} da posição {position}. Os lotes registados são removidos; o histórico mantém-se.'**
  String clearPositionConfirm(String product, String position);

  /// No description provided for @gridSelectionHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque numa posição para a configurar. Toque em várias para as juntar.'**
  String get gridSelectionHint;

  /// No description provided for @mergeLosesAssignments.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 posição perde o produto, que fica em “sem posição” até ser reatribuído.} other{{count} posições perdem o produto, que fica em “sem posição” até ser reatribuído.}}'**
  String mergeLosesAssignments(int count);

  /// No description provided for @unsavedGridTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alterações por guardar'**
  String get unsavedGridTitle;

  /// No description provided for @unsavedGridMessage.
  ///
  /// In pt, this message translates to:
  /// **'Sair sem guardar a grelha?'**
  String get unsavedGridMessage;

  /// No description provided for @discardChanges.
  ///
  /// In pt, this message translates to:
  /// **'Descartar'**
  String get discardChanges;

  /// No description provided for @orphansTitle.
  ///
  /// In pt, this message translates to:
  /// **'Produtos sem posição ({count})'**
  String orphansTitle(int count);

  /// No description provided for @orphanReassignHint.
  ///
  /// In pt, this message translates to:
  /// **'Selecione uma posição livre na grelha e toque em Reatribuir.'**
  String get orphanReassignHint;

  /// No description provided for @positionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Posição {position}'**
  String positionTitle(String position);

  /// No description provided for @positionsSelected.
  ///
  /// In pt, this message translates to:
  /// **'{count} posições selecionadas'**
  String positionsSelected(int count);

  /// No description provided for @positionSelectHint.
  ///
  /// In pt, this message translates to:
  /// **'Selecione uma posição para configurar o produto.'**
  String get positionSelectHint;

  /// No description provided for @gridUnsavedHint.
  ///
  /// In pt, this message translates to:
  /// **'Guarde a grelha antes de configurar posições.'**
  String get gridUnsavedHint;

  /// No description provided for @chooseProduct.
  ///
  /// In pt, this message translates to:
  /// **'Escolher produto'**
  String get chooseProduct;

  /// No description provided for @catalogNoMatches.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum produto corresponde à pesquisa.'**
  String get catalogNoMatches;

  /// No description provided for @minimumQuantityLabel.
  ///
  /// In pt, this message translates to:
  /// **'Quantidade mínima'**
  String get minimumQuantityLabel;

  /// No description provided for @expiryWarningDaysLabel.
  ///
  /// In pt, this message translates to:
  /// **'Aviso de validade (dias)'**
  String get expiryWarningDaysLabel;

  /// No description provided for @askLotOnReplenish.
  ///
  /// In pt, this message translates to:
  /// **'Pedir lote e validade na reposição'**
  String get askLotOnReplenish;

  /// No description provided for @applyToPosition.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar à posição'**
  String get applyToPosition;

  /// No description provided for @positionApplied.
  ///
  /// In pt, this message translates to:
  /// **'Posição atualizada.'**
  String get positionApplied;

  /// No description provided for @catalogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Catálogo de consumíveis'**
  String get catalogTitle;

  /// No description provided for @catalogSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 produto} other{{count} produtos}} · usados em {carts, plural, =1{1 carrinho} other{{carts} carrinhos}}'**
  String catalogSubtitle(int count, int carts);

  /// No description provided for @importCsv.
  ///
  /// In pt, this message translates to:
  /// **'Importar CSV'**
  String get importCsv;

  /// No description provided for @importCsvHelp.
  ///
  /// In pt, this message translates to:
  /// **'Cole uma linha por produto: nome; apresentação; GTIN; categoria; aviso de validade (dias). Os produtos com nome ou GTIN já existentes são ignorados.'**
  String get importCsvHelp;

  /// No description provided for @importCsvHint.
  ///
  /// In pt, this message translates to:
  /// **'Cole aqui o conteúdo do ficheiro CSV'**
  String get importCsvHint;

  /// No description provided for @importAction.
  ///
  /// In pt, this message translates to:
  /// **'Importar'**
  String get importAction;

  /// No description provided for @importResult.
  ///
  /// In pt, this message translates to:
  /// **'{created, plural, =1{1 produto importado} other{{created} produtos importados}} · {skipped} ignorados.'**
  String importResult(int created, int skipped);

  /// No description provided for @newProduct.
  ///
  /// In pt, this message translates to:
  /// **'Novo produto'**
  String get newProduct;

  /// No description provided for @editProduct.
  ///
  /// In pt, this message translates to:
  /// **'Editar produto'**
  String get editProduct;

  /// No description provided for @catalogSearchByNameOrGtin.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar por nome ou GTIN'**
  String get catalogSearchByNameOrGtin;

  /// No description provided for @filterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get filterAll;

  /// No description provided for @categoryDrug.
  ///
  /// In pt, this message translates to:
  /// **'Fármaco'**
  String get categoryDrug;

  /// No description provided for @categoryDrugs.
  ///
  /// In pt, this message translates to:
  /// **'Fármacos'**
  String get categoryDrugs;

  /// No description provided for @categoryMaterial.
  ///
  /// In pt, this message translates to:
  /// **'Material'**
  String get categoryMaterial;

  /// No description provided for @categoryFluid.
  ///
  /// In pt, this message translates to:
  /// **'Fluido'**
  String get categoryFluid;

  /// No description provided for @categoryFluids.
  ///
  /// In pt, this message translates to:
  /// **'Fluidos'**
  String get categoryFluids;

  /// No description provided for @columnPresentation.
  ///
  /// In pt, this message translates to:
  /// **'Apresentação'**
  String get columnPresentation;

  /// No description provided for @columnGtin.
  ///
  /// In pt, this message translates to:
  /// **'GTIN'**
  String get columnGtin;

  /// No description provided for @columnCategory.
  ///
  /// In pt, this message translates to:
  /// **'Categoria'**
  String get columnCategory;

  /// No description provided for @columnInUse.
  ///
  /// In pt, this message translates to:
  /// **'Em uso'**
  String get columnInUse;

  /// No description provided for @expiryWarningShort.
  ///
  /// In pt, this message translates to:
  /// **'Aviso de validade'**
  String get expiryWarningShort;

  /// No description provided for @inCartsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{—} =1{1 carrinho} other{{count} carrinhos}}'**
  String inCartsCount(int count);

  /// No description provided for @productCreated.
  ///
  /// In pt, this message translates to:
  /// **'Produto “{name}” criado.'**
  String productCreated(String name);

  /// No description provided for @productUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Produto atualizado.'**
  String get productUpdated;

  /// No description provided for @gtinTaken.
  ///
  /// In pt, this message translates to:
  /// **'Já existe um produto com este GTIN.'**
  String get gtinTaken;

  /// No description provided for @gtinInvalid.
  ///
  /// In pt, this message translates to:
  /// **'O GTIN tem 8, 12, 13 ou 14 algarismos.'**
  String get gtinInvalid;

  /// No description provided for @scanGtin.
  ///
  /// In pt, this message translates to:
  /// **'Ler GTIN da embalagem'**
  String get scanGtin;

  /// No description provided for @expiryWarningDefaultHint.
  ///
  /// In pt, this message translates to:
  /// **'Vazio = valor da instituição'**
  String get expiryWarningDefaultHint;

  /// No description provided for @templatesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Modelos de carrinho'**
  String get templatesTitle;

  /// No description provided for @templatesSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Crie carrinhos iguais a partir de um modelo'**
  String get templatesSubtitle;

  /// No description provided for @templatesEmptyDashboard.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há modelos. Crie um a partir de um carrinho já configurado.'**
  String get templatesEmptyDashboard;

  /// No description provided for @newTemplate.
  ///
  /// In pt, this message translates to:
  /// **'Novo modelo'**
  String get newTemplate;

  /// No description provided for @editTemplate.
  ///
  /// In pt, this message translates to:
  /// **'Editar modelo'**
  String get editTemplate;

  /// No description provided for @deleteTemplate.
  ///
  /// In pt, this message translates to:
  /// **'Eliminar modelo'**
  String get deleteTemplate;

  /// No description provided for @deleteTemplateConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Eliminar o modelo “{name}”? Os carrinhos já criados a partir dele não são alterados.'**
  String deleteTemplateConfirm(String name);

  /// No description provided for @templateDeleted.
  ///
  /// In pt, this message translates to:
  /// **'Modelo eliminado.'**
  String get templateDeleted;

  /// No description provided for @templateSaved.
  ///
  /// In pt, this message translates to:
  /// **'Modelo guardado.'**
  String get templateSaved;

  /// No description provided for @templateSummary.
  ///
  /// In pt, this message translates to:
  /// **'{drawers, plural, =1{1 gaveta} other{{drawers} gavetas}} · {positions} posições · usado em {carts, plural, =1{1 carrinho} other{{carts} carrinhos}}'**
  String templateSummary(int drawers, int positions, int carts);

  /// No description provided for @templateUpdatedBy.
  ///
  /// In pt, this message translates to:
  /// **'Atualizado a {date} por {name}'**
  String templateUpdatedBy(String date, String name);

  /// No description provided for @templateDrawerSize.
  ///
  /// In pt, this message translates to:
  /// **'{rows} × {columns} · {positions} posições'**
  String templateDrawerSize(int rows, int columns, int positions);

  /// No description provided for @templateCopyNote.
  ///
  /// In pt, this message translates to:
  /// **'Os carrinhos criados a partir do modelo copiam gavetas, posições e quantidades alvo. Stock e histórico não são copiados.'**
  String get templateCopyNote;

  /// No description provided for @createCartFromThisTemplate.
  ///
  /// In pt, this message translates to:
  /// **'Criar carrinho a partir deste modelo'**
  String get createCartFromThisTemplate;

  /// No description provided for @templateCopyName.
  ///
  /// In pt, this message translates to:
  /// **'{name} (cópia)'**
  String templateCopyName(String name);

  /// No description provided for @templateSourceCart.
  ///
  /// In pt, this message translates to:
  /// **'Carrinho de origem'**
  String get templateSourceCart;

  /// No description provided for @templateRefreshFromCart.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar a partir de um carrinho'**
  String get templateRefreshFromCart;

  /// No description provided for @templateKeepStructure.
  ///
  /// In pt, this message translates to:
  /// **'Manter a estrutura atual'**
  String get templateKeepStructure;

  /// No description provided for @templateChooseCart.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um carrinho'**
  String get templateChooseCart;

  /// No description provided for @usersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Utilizadores e permissões'**
  String get usersTitle;

  /// No description provided for @usersCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 utilizador} other{{count} utilizadores}}'**
  String usersCount(int count);

  /// No description provided for @inviteUser.
  ///
  /// In pt, this message translates to:
  /// **'Convidar utilizador'**
  String get inviteUser;

  /// No description provided for @sendInvite.
  ///
  /// In pt, this message translates to:
  /// **'Enviar convite'**
  String get sendInvite;

  /// No description provided for @inviteNote.
  ///
  /// In pt, this message translates to:
  /// **'A pessoa recebe um e-mail para definir a sua palavra-passe.'**
  String get inviteNote;

  /// No description provided for @inviteSent.
  ///
  /// In pt, this message translates to:
  /// **'Convite enviado para {email}.'**
  String inviteSent(String email);

  /// No description provided for @resendInvite.
  ///
  /// In pt, this message translates to:
  /// **'Reenviar e-mail de acesso'**
  String get resendInvite;

  /// No description provided for @emailTaken.
  ///
  /// In pt, this message translates to:
  /// **'Já existe um utilizador com este e-mail.'**
  String get emailTaken;

  /// No description provided for @emailInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Indique um e-mail válido.'**
  String get emailInvalid;

  /// No description provided for @fieldEmail.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get fieldEmail;

  /// No description provided for @usersSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Pesquisar por nome ou e-mail'**
  String get usersSearchHint;

  /// No description provided for @usersFilterManagers.
  ///
  /// In pt, this message translates to:
  /// **'Gestores ({count})'**
  String usersFilterManagers(int count);

  /// No description provided for @usersFilterProfessionals.
  ///
  /// In pt, this message translates to:
  /// **'Profissionais de saúde ({count})'**
  String usersFilterProfessionals(int count);

  /// No description provided for @usersFilterInvited.
  ///
  /// In pt, this message translates to:
  /// **'Convites pendentes ({count})'**
  String usersFilterInvited(int count);

  /// No description provided for @usersNoMatches.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum utilizador corresponde à pesquisa.'**
  String get usersNoMatches;

  /// No description provided for @columnUserType.
  ///
  /// In pt, this message translates to:
  /// **'Tipo de utilizador'**
  String get columnUserType;

  /// No description provided for @allServices.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get allServices;

  /// No description provided for @moreActions.
  ///
  /// In pt, this message translates to:
  /// **'Mais ações'**
  String get moreActions;

  /// No description provided for @cannotEditSelf.
  ///
  /// In pt, this message translates to:
  /// **'Não pode alterar a sua própria conta.'**
  String get cannotEditSelf;

  /// No description provided for @changeUserType.
  ///
  /// In pt, this message translates to:
  /// **'Alterar tipo de utilizador'**
  String get changeUserType;

  /// No description provided for @deactivateUser.
  ///
  /// In pt, this message translates to:
  /// **'Desativar'**
  String get deactivateUser;

  /// No description provided for @reactivateUser.
  ///
  /// In pt, this message translates to:
  /// **'Reativar'**
  String get reactivateUser;

  /// No description provided for @deactivateUserConfirm.
  ///
  /// In pt, this message translates to:
  /// **'{name} deixa de conseguir entrar. O histórico mantém-se.'**
  String deactivateUserConfirm(String name);

  /// No description provided for @reactivateUserConfirm.
  ///
  /// In pt, this message translates to:
  /// **'{name} volta a conseguir entrar.'**
  String reactivateUserConfirm(String name);

  /// No description provided for @userUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Utilizador atualizado.'**
  String get userUpdated;

  /// No description provided for @permissionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Permissões'**
  String get permissionsTitle;

  /// No description provided for @permissionsNote.
  ///
  /// In pt, this message translates to:
  /// **'Proposta (D2). As permissões ficam guardadas neste dispositivo até existir suporte no servidor.'**
  String get permissionsNote;

  /// No description provided for @permViewCarts.
  ///
  /// In pt, this message translates to:
  /// **'Ver carrinhos e gavetas'**
  String get permViewCarts;

  /// No description provided for @permRecordConsumption.
  ///
  /// In pt, this message translates to:
  /// **'Registar consumos'**
  String get permRecordConsumption;

  /// No description provided for @permReplenish.
  ///
  /// In pt, this message translates to:
  /// **'Repor stock (lote e validade)'**
  String get permReplenish;

  /// No description provided for @permMonthlyCheck.
  ///
  /// In pt, this message translates to:
  /// **'Fazer a verificação mensal'**
  String get permMonthlyCheck;

  /// No description provided for @permSignReports.
  ///
  /// In pt, this message translates to:
  /// **'Assinar relatórios'**
  String get permSignReports;

  /// No description provided for @permEmergencyMode.
  ///
  /// In pt, this message translates to:
  /// **'Usar o modo de emergência'**
  String get permEmergencyMode;

  /// No description provided for @permChangeCartState.
  ///
  /// In pt, this message translates to:
  /// **'Alterar o estado do carrinho'**
  String get permChangeCartState;

  /// No description provided for @permEditDrawers.
  ///
  /// In pt, this message translates to:
  /// **'Editar gavetas e grelhas'**
  String get permEditDrawers;

  /// No description provided for @permManageUsersAndShifts.
  ///
  /// In pt, this message translates to:
  /// **'Gerir utilizadores e turnos'**
  String get permManageUsersAndShifts;

  /// No description provided for @shiftsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Turnos'**
  String get shiftsTitle;

  /// No description provided for @shiftsWeekOf.
  ///
  /// In pt, this message translates to:
  /// **'Semana de {start} a {end}'**
  String shiftsWeekOf(String start, String end);

  /// No description provided for @previousWeek.
  ///
  /// In pt, this message translates to:
  /// **'Semana anterior'**
  String get previousWeek;

  /// No description provided for @nextWeek.
  ///
  /// In pt, this message translates to:
  /// **'Semana seguinte'**
  String get nextWeek;

  /// No description provided for @addShift.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar turno'**
  String get addShift;

  /// No description provided for @copyPreviousWeek.
  ///
  /// In pt, this message translates to:
  /// **'Copiar semana anterior'**
  String get copyPreviousWeek;

  /// No description provided for @shiftsCopied.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhum turno copiado.} =1{1 turno copiado.} other{{count} turnos copiados.}}'**
  String shiftsCopied(int count);

  /// No description provided for @shiftsByCart.
  ///
  /// In pt, this message translates to:
  /// **'Por carrinho'**
  String get shiftsByCart;

  /// No description provided for @shiftsByPerson.
  ///
  /// In pt, this message translates to:
  /// **'Por pessoa'**
  String get shiftsByPerson;

  /// No description provided for @columnPerson.
  ///
  /// In pt, this message translates to:
  /// **'Pessoa'**
  String get columnPerson;

  /// No description provided for @shiftsNoneThisWeek.
  ///
  /// In pt, this message translates to:
  /// **'Sem turnos nesta semana.'**
  String get shiftsNoneThisWeek;

  /// No description provided for @shiftsLegend.
  ///
  /// In pt, this message translates to:
  /// **'M = manhã (08–16) · T = tarde (16–24) · N = noite (00–08)'**
  String get shiftsLegend;

  /// No description provided for @shiftMorningShort.
  ///
  /// In pt, this message translates to:
  /// **'M'**
  String get shiftMorningShort;

  /// No description provided for @shiftAfternoonShort.
  ///
  /// In pt, this message translates to:
  /// **'T'**
  String get shiftAfternoonShort;

  /// No description provided for @shiftNightShort.
  ///
  /// In pt, this message translates to:
  /// **'N'**
  String get shiftNightShort;

  /// No description provided for @shiftMorning.
  ///
  /// In pt, this message translates to:
  /// **'Manhã'**
  String get shiftMorning;

  /// No description provided for @shiftAfternoon.
  ///
  /// In pt, this message translates to:
  /// **'Tarde'**
  String get shiftAfternoon;

  /// No description provided for @shiftNight.
  ///
  /// In pt, this message translates to:
  /// **'Noite'**
  String get shiftNight;

  /// No description provided for @shiftDay.
  ///
  /// In pt, this message translates to:
  /// **'Dia'**
  String get shiftDay;

  /// No description provided for @shiftResponsible.
  ///
  /// In pt, this message translates to:
  /// **'Responsável'**
  String get shiftResponsible;

  /// No description provided for @shiftNobody.
  ///
  /// In pt, this message translates to:
  /// **'Ninguém'**
  String get shiftNobody;

  /// No description provided for @shiftSaved.
  ///
  /// In pt, this message translates to:
  /// **'Turno guardado.'**
  String get shiftSaved;

  /// No description provided for @reportsHistoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios e histórico'**
  String get reportsHistoryTitle;

  /// No description provided for @exportCsv.
  ///
  /// In pt, this message translates to:
  /// **'Exportar CSV'**
  String get exportCsv;

  /// No description provided for @exportCsvHelp.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 evento} other{{count} eventos}} do período e carrinho escolhidos. Copie e cole numa folha de cálculo.'**
  String exportCsvHelp(int count);

  /// No description provided for @copyCsv.
  ///
  /// In pt, this message translates to:
  /// **'Copiar'**
  String get copyCsv;

  /// No description provided for @csvCopied.
  ///
  /// In pt, this message translates to:
  /// **'CSV copiado.'**
  String get csvCopied;

  /// No description provided for @tabReports.
  ///
  /// In pt, this message translates to:
  /// **'Relatórios'**
  String get tabReports;

  /// No description provided for @tabEvents.
  ///
  /// In pt, this message translates to:
  /// **'Histórico de eventos'**
  String get tabEvents;

  /// No description provided for @tabStatistics.
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas'**
  String get tabStatistics;

  /// No description provided for @filterCart.
  ///
  /// In pt, this message translates to:
  /// **'Carrinho: {name}'**
  String filterCart(String name);

  /// No description provided for @filterAllCarts.
  ///
  /// In pt, this message translates to:
  /// **'todos'**
  String get filterAllCarts;

  /// No description provided for @filterPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Período: {period}'**
  String filterPeriod(String period);

  /// No description provided for @columnReport.
  ///
  /// In pt, this message translates to:
  /// **'Relatório'**
  String get columnReport;

  /// No description provided for @columnDate.
  ///
  /// In pt, this message translates to:
  /// **'Data'**
  String get columnDate;

  /// No description provided for @columnSignedBy.
  ///
  /// In pt, this message translates to:
  /// **'Assinado por'**
  String get columnSignedBy;

  /// No description provided for @reportPendingSignatureShort.
  ///
  /// In pt, this message translates to:
  /// **'Por assinar'**
  String get reportPendingSignatureShort;

  /// No description provided for @actionOpen.
  ///
  /// In pt, this message translates to:
  /// **'Abrir'**
  String get actionOpen;

  /// No description provided for @reportsEmptyPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Sem relatórios neste período.'**
  String get reportsEmptyPeriod;

  /// No description provided for @eventsEmptyPeriod.
  ///
  /// In pt, this message translates to:
  /// **'Sem eventos neste período.'**
  String get eventsEmptyPeriod;

  /// No description provided for @eventsCapped.
  ///
  /// In pt, this message translates to:
  /// **'A mostrar os {count} eventos mais recentes da instituição.'**
  String eventsCapped(int count);

  /// No description provided for @statConsumed.
  ///
  /// In pt, this message translates to:
  /// **'Consumido'**
  String get statConsumed;

  /// No description provided for @statReplenished.
  ///
  /// In pt, this message translates to:
  /// **'Reposto'**
  String get statReplenished;

  /// No description provided for @statChecks.
  ///
  /// In pt, this message translates to:
  /// **'Verificações'**
  String get statChecks;

  /// No description provided for @statEmergencies.
  ///
  /// In pt, this message translates to:
  /// **'Emergências'**
  String get statEmergencies;

  /// No description provided for @statPendingSignatures.
  ///
  /// In pt, this message translates to:
  /// **'Por assinar'**
  String get statPendingSignatures;

  /// No description provided for @statTopProducts.
  ///
  /// In pt, this message translates to:
  /// **'Produtos mais consumidos'**
  String get statTopProducts;

  /// No description provided for @statByCart.
  ///
  /// In pt, this message translates to:
  /// **'Por carrinho'**
  String get statByCart;

  /// No description provided for @pagerRange.
  ///
  /// In pt, this message translates to:
  /// **'{from}–{to} de {total}'**
  String pagerRange(int from, int to, int total);

  /// No description provided for @pagerPrevious.
  ///
  /// In pt, this message translates to:
  /// **'Página anterior'**
  String get pagerPrevious;

  /// No description provided for @pagerNext.
  ///
  /// In pt, this message translates to:
  /// **'Página seguinte'**
  String get pagerNext;

  /// No description provided for @closePanel.
  ///
  /// In pt, this message translates to:
  /// **'Fechar painel'**
  String get closePanel;

  /// No description provided for @viewAsApp.
  ///
  /// In pt, this message translates to:
  /// **'Ver como App (teste)'**
  String get viewAsApp;

  /// No description provided for @viewAsDashboard.
  ///
  /// In pt, this message translates to:
  /// **'Ver como Dashboard (teste)'**
  String get viewAsDashboard;
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
