// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'I-Crash';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionClose => 'Fechar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionConfirm => 'Confirmar';

  @override
  String get actionBack => 'Voltar';

  @override
  String get assignmentStatusOk => 'OK';

  @override
  String get assignmentStatusReplenishmentRequired => 'Reposição necessária';

  @override
  String get assignmentStatusExpiringSoon => 'A expirar em breve';

  @override
  String get assignmentStatusExpired => 'Expirado';

  @override
  String get usageEventConsumption => 'Consumo';

  @override
  String get usageEventReplenishment => 'Reposição';

  @override
  String get usageEventCorrection => 'Correção';

  @override
  String get usageEventAuditReconciliation => 'Reconciliação';

  @override
  String get cartStatusOperational => 'Operacional';

  @override
  String get cartStatusReplenishmentRequired => 'Reposição necessária';

  @override
  String get cartStatusAuditRequired => 'Auditoria necessária';

  @override
  String get cartStatusOutOfService => 'Fora de serviço';

  @override
  String get roleSuperAdmin => 'Super administrador';

  @override
  String get roleInstitutionAdmin => 'Administrador da instituição';

  @override
  String get roleManager => 'Gestor';

  @override
  String get roleUser => 'Utilizador';

  @override
  String get membershipStatusActive => 'Ativo';

  @override
  String get membershipStatusInvited => 'Convidado';

  @override
  String get membershipStatusDisabled => 'Desativado';

  @override
  String get loginTagline => 'Gestão de carros de emergência';

  @override
  String get loginEmailLabel => 'E-mail';

  @override
  String get loginEmailRequired => 'Indique o e-mail';

  @override
  String get loginPasswordLabel => 'Palavra-passe';

  @override
  String get loginPasswordRequired => 'Indique a palavra-passe';

  @override
  String get loginSubmit => 'Entrar';

  @override
  String get loginErrorInvalidCredentials =>
      'Credenciais inválidas. Verifique o e-mail e a palavra-passe.';

  @override
  String get loginErrorOffline =>
      'Sem ligação. Verifique a rede e tente novamente.';

  @override
  String get loginErrorGeneric =>
      'Não foi possível iniciar sessão. Tente novamente.';

  @override
  String get actionCreate => 'Criar';

  @override
  String get actionDuplicate => 'Duplicar';

  @override
  String get validationEnterName => 'Indique um nome';

  @override
  String get createCartTitle => 'Novo carro';

  @override
  String get createCartNameLabel => 'Nome do carro';

  @override
  String get createDrawerTitle => 'Nova gaveta';

  @override
  String get createDrawerNameLabel => 'Nome da gaveta';

  @override
  String get createDrawerRowsLabel => 'Linhas';

  @override
  String get createDrawerColumnsLabel => 'Colunas';

  @override
  String get duplicateCartTitle => 'Duplicar carro';

  @override
  String get duplicateCartDescription =>
      'Cria um novo carro com as mesmas gavetas e slots. Não copia produtos, stock nem histórico.';

  @override
  String get duplicateCartNameLabel => 'Nome do novo carro';

  @override
  String get editCartTitle => 'Editar carro';

  @override
  String get editCartStatusLabel => 'Estado';

  @override
  String get createProductTitle => 'Novo produto';

  @override
  String get createProductNameLabel => 'Nome';

  @override
  String get createProductUnitLabel => 'Unidade (opcional)';

  @override
  String get createProductUnitHint => 'ex.: 1 mg/mL, ampola 1 mL';

  @override
  String get createProductGtinLabel => 'GTIN (opcional)';

  @override
  String get addMemberTitle => 'Novo membro';

  @override
  String get addMemberEmailRequired => 'Indique um e-mail';

  @override
  String get addMemberPasswordLabel => 'Palavra-passe temporária';

  @override
  String get addMemberPasswordMinLength => 'Mínimo de 6 caracteres';

  @override
  String get addMemberRoleLabel => 'Cargo';

  @override
  String get cartQrScreenTitle => 'Código do carro';

  @override
  String cartQrSemanticLabel(String cartName) {
    return 'Código QR do carro $cartName';
  }

  @override
  String get cartQrInstruction =>
      'Digitalize este código para abrir diretamente este carro.';

  @override
  String get cartQrScanTitle => 'Ler código do carro';

  @override
  String get cartQrScanError =>
      'Código lido mas não é um código de carro reconhecido. Tente novamente.';

  @override
  String get cartQrScanInstruction => 'Aponte a câmara ao código do carro.';

  @override
  String get scannerPreviewUnavailable =>
      'Pré-visualização da câmara indisponível.';

  @override
  String get gs1ScanTitle => 'Digitalizar código GS1';

  @override
  String get gs1ScanError =>
      'Código lido mas sem GTIN, lote ou validade reconhecidos. Tente novamente.';

  @override
  String get gs1ScanInstructionHid =>
      'Digitalize o código com o leitor de códigos de barras ligado a este computador.';

  @override
  String get gs1ScanInstructionCamera =>
      'Aponte a câmara ao código GS1 Data Matrix da embalagem.';

  @override
  String get actionCancelManualEntry => 'Cancelar e inserir manualmente';

  @override
  String get gs1HidWaitingLabel => 'Aguardando leitura...';

  @override
  String get actionSignOut => 'Terminar sessão';

  @override
  String get institutionSelectionTitle => 'Escolher instituição';

  @override
  String institutionSelectionLoadError(Object error) {
    return 'Não foi possível carregar as instituições: $error';
  }

  @override
  String get institutionSelectionEmpty =>
      'Ainda não tem acesso a nenhuma instituição.\nContacte o administrador da sua instituição.';

  @override
  String get connectivityOfflineMessage =>
      'Sem ligação à internet — a mostrar dados guardados localmente.';

  @override
  String get productsScreenTitle => 'Produtos';

  @override
  String get productsCreateError =>
      'Não foi possível criar o produto. Tente novamente.';

  @override
  String productsLoadError(Object error) {
    return 'Não foi possível carregar os produtos: $error';
  }

  @override
  String get productsEmpty => 'Ainda não existem produtos nesta instituição.';

  @override
  String get membersScreenTitle => 'Membros';

  @override
  String membersLoadError(Object error) {
    return 'Não foi possível carregar os membros: $error';
  }

  @override
  String get membersEmpty => 'Ainda não existem membros nesta instituição.';

  @override
  String get membersCreateErrorConflict =>
      'Já existe uma conta com este e-mail.';

  @override
  String get membersCreateErrorInvalidInput =>
      'E-mail ou palavra-passe inválidos.';

  @override
  String get membersCreateErrorGeneric =>
      'Não foi possível criar o membro. Tente novamente.';

  @override
  String get membersChangeRoleTitle => 'Mudar cargo';

  @override
  String get membersChangeRoleError =>
      'Não foi possível mudar o cargo. Tente novamente.';

  @override
  String get membersToggleStatusError =>
      'Não foi possível alterar o estado do membro. Tente novamente.';

  @override
  String get membersDeactivate => 'Desativar';

  @override
  String get membersReactivate => 'Reativar';

  @override
  String get responsibleUsersTitle => 'Responsáveis pelo carro';

  @override
  String get productSearchHint => 'Pesquisar produto neste carro...';

  @override
  String get productSearchPrompt =>
      'Escreva o nome de um produto para o encontrar neste carro.';

  @override
  String get productSearchEmpty => 'Nenhum produto encontrado neste carro.';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionShowQrCode => 'Mostrar código QR';

  @override
  String get actionSearchProduct => 'Pesquisar produto';

  @override
  String get actionResponsible => 'Responsáveis';

  @override
  String get cartDetailCreateDrawerError =>
      'Não foi possível criar a gaveta. Tente novamente.';

  @override
  String get cartUpdatedMessage => 'Carro atualizado.';

  @override
  String get cartDetailUpdateError =>
      'Não foi possível atualizar o carro. Tente novamente.';

  @override
  String duplicateCartDefaultName(String name) {
    return '$name (cópia)';
  }

  @override
  String cartDuplicatedMessage(String name) {
    return 'Carro duplicado como \"$name\".';
  }

  @override
  String get cartDetailDuplicateError =>
      'Não foi possível duplicar o carro. Tente novamente.';

  @override
  String cartDetailLoadDrawersError(Object error) {
    return 'Não foi possível carregar as gavetas: $error';
  }

  @override
  String get cartDetailDrawersEmpty => 'Ainda não existem gavetas neste carro.';

  @override
  String drawerGridSize(int rows, int columns) {
    return '$rows linhas × $columns colunas';
  }
}
