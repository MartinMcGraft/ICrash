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
  String get cartStatusAuditRequired => 'Verificação em atraso';

  @override
  String get cartStatusOutOfService => 'Fora de serviço';

  @override
  String get roleSuperAdmin => 'Engenheiro (suporte)';

  @override
  String get roleInstitutionAdmin => 'Gestor da instituição';

  @override
  String get roleManager => 'Gestor de serviço';

  @override
  String get roleUser => 'Profissional de saúde';

  @override
  String get membershipStatusActive => 'Ativo';

  @override
  String get membershipStatusInvited => 'Convidado';

  @override
  String get membershipStatusDisabled => 'Desativado';

  @override
  String get loginTagline => 'Gestão de carros de emergência';

  @override
  String get loginEmailLabel => 'E-mail institucional';

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
  String get productSearchHint => 'Nome do produto ou GTIN';

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

  @override
  String get historyScreenTitle => 'Histórico';

  @override
  String get historyFilterAll => 'Todos';

  @override
  String historyLoadError(Object error) {
    return 'Não foi possível carregar o histórico: $error';
  }

  @override
  String get historyEmpty => 'Sem eventos para mostrar.';

  @override
  String get exportCsvButton => 'Exportar CSV';

  @override
  String get actionCopy => 'Copiar';

  @override
  String get csvCopiedMessage => 'CSV copiado.';

  @override
  String get exportPdfButton => 'Exportar PDF';

  @override
  String get historyPdfDocumentTitle => 'Histórico de atividade';

  @override
  String get summaryViewButton => 'Ver resumo';

  @override
  String get summaryDialogTitle => 'Resumo';

  @override
  String get summaryGroupProduct => 'Produto';

  @override
  String get summaryGroupCart => 'Carro';

  @override
  String get summaryGroupPeriod => 'Período';

  @override
  String get periodUnitDay => 'Dia';

  @override
  String get periodUnitWeek => 'Semana';

  @override
  String get periodUnitMonth => 'Mês';

  @override
  String get summaryEmpty => 'Sem dados para resumir.';

  @override
  String summaryConsumedReplenished(int consumed, int replenished) {
    return 'Consumido: $consumed   Reposto: $replenished';
  }

  @override
  String summaryOtherAdjustments(String value) {
    return '   Outros ajustes: $value';
  }

  @override
  String get productRemoved => 'Produto removido';

  @override
  String get cartRemoved => 'Carro removido';

  @override
  String get dashboardOpenCartError => 'Não foi possível abrir este carro.';

  @override
  String get dashboardCreateCartError =>
      'Não foi possível criar o carro. Tente novamente.';

  @override
  String dashboardLoadCartsError(Object error) {
    return 'Não foi possível carregar os carros: $error';
  }

  @override
  String get dashboardCartsEmpty =>
      'Ainda não existem carros de emergência nesta instituição.';

  @override
  String get dashboardSearchCartLabel => 'Pesquisar carro';

  @override
  String get dashboardNoCartMatches => 'Nenhum carro corresponde à pesquisa.';

  @override
  String get dashboardAlertsTitle => 'Alertas';

  @override
  String get alertBelowMinimum => 'Stock abaixo do mínimo';

  @override
  String get dashboardRecentActivityTitle => 'Atividade recente';

  @override
  String get assignConflictError =>
      'Este produto já está atribuído a outro slot deste carro.';

  @override
  String get assignGenericError =>
      'Não foi possível atribuir o produto. Tente novamente.';

  @override
  String get consumeExceedsError =>
      'Não pode consumir mais do que a quantidade atual.';

  @override
  String get consumeGenericError =>
      'Não foi possível registar o consumo. Tente novamente.';

  @override
  String get replenishMissingExpiry => 'Indique a validade do lote.';

  @override
  String get replenishGenericError =>
      'Não foi possível repor o stock. Tente novamente.';

  @override
  String get gs1UnknownGtin =>
      'GTIN não reconhecido no catálogo — não foi associado a nenhum produto.';

  @override
  String gs1WrongProductWarning(String productName) {
    return 'Atenção: este código corresponde a \"$productName\", não ao produto deste slot.';
  }

  @override
  String get reconcileGenericError =>
      'Não foi possível reconciliar. Tente novamente.';

  @override
  String get correctGenericError =>
      'Não foi possível corrigir. Tente novamente.';

  @override
  String get emptySlotTitle => 'Slot vazio';

  @override
  String get emptySlotMessage => 'Este slot ainda não tem produto atribuído.';

  @override
  String get assignDialogTitle => 'Atribuir produto';

  @override
  String get noProductsMessage =>
      'Crie primeiro um produto no catálogo da instituição.';

  @override
  String get productLabel => 'Produto';

  @override
  String get initialQuantityLabel => 'Quantidade inicial';

  @override
  String get targetQuantityLabel => 'Quantidade alvo';

  @override
  String get chooseProductValidation => 'Escolha um produto';

  @override
  String get actionAssign => 'Atribuir';

  @override
  String get recordConsumptionTitle => 'Registar consumo';

  @override
  String get consumedQuantityLabel => 'Quantidade consumida';

  @override
  String get validatePositiveInt => 'Indique um número positivo';

  @override
  String get replenishStockTitle => 'Repor stock';

  @override
  String get receivedQuantityLabel => 'Quantidade recebida';

  @override
  String get lotNumberLabel => 'Número de lote';

  @override
  String get lotRequiredValidation => 'Indique o lote';

  @override
  String get chooseExpiryLabel => 'Escolher validade';

  @override
  String expiryDateLabel(String date) {
    return 'Validade: $date';
  }

  @override
  String get reconcileDialogTitle => 'Reconciliar (auditoria)';

  @override
  String get confirmedQuantityLabel => 'Quantidade confirmada fisicamente';

  @override
  String get validateNonNegativeInt => 'Indique um número válido';

  @override
  String get noBatchesMessage =>
      'Sem lotes registados; a reconciliação fica sem lotes confirmados.';

  @override
  String get confirmedBatchesLabel =>
      'Lotes confirmados como fisicamente presentes:';

  @override
  String batchLotLabel(String lotNumber) {
    return 'Lote $lotNumber';
  }

  @override
  String get correctEventDialogTitle => 'Corrigir evento';

  @override
  String get noEventsToCorrect => 'Ainda não existem eventos para corrigir.';

  @override
  String get eventToCorrectLabel => 'Evento a corrigir';

  @override
  String get chooseEventValidation => 'Escolha um evento';

  @override
  String get adjustmentLabel => 'Ajuste (positivo ou negativo)';

  @override
  String get validateNonZeroInt => 'Indique um ajuste diferente de zero';

  @override
  String currentTargetLabel(int current, int target) {
    return 'Atual: $current   Alvo: $target';
  }

  @override
  String get actionCorrect => 'Corrigir';

  @override
  String get actionReconcile => 'Reconciliar';

  @override
  String get slotSelectionNotRectangle =>
      'A seleção tem de formar um retângulo sem espaços.';

  @override
  String get drawerSavedMessage => 'Gaveta guardada.';

  @override
  String get drawerSaveError =>
      'Não foi possível guardar a gaveta. Tente novamente.';

  @override
  String get reassignSlotError =>
      'Não foi possível reatribuir o slot. Tente novamente.';

  @override
  String get removeAssignmentTitle => 'Remover atribuição';

  @override
  String get removeAssignmentMessage =>
      'Esta atribuição aponta para um slot que já não existe nesta gaveta. Remover a atribuição também remove os lotes registados; o histórico de eventos mantém-se. Esta ação não pode ser desfeita.';

  @override
  String get actionRemove => 'Remover';

  @override
  String get deleteAssignmentError =>
      'Não foi possível remover a atribuição. Tente novamente.';

  @override
  String loadSlotsError(Object error) {
    return 'Não foi possível carregar os slots: $error';
  }

  @override
  String get actionMerge => 'Juntar';

  @override
  String get actionSplit => 'Dividir';

  @override
  String get orphanedAssignmentsHeader =>
      'Atribuições sem slot válido (de uma junção/divisão anterior):';

  @override
  String get actionReassign => 'Reatribuir';

  @override
  String get reassignTooltip => 'Reatribuir a um slot livre';

  @override
  String slotPositionTooltip(int row, int column) {
    return 'Linha $row, coluna $column';
  }

  @override
  String get languageSwitcherTooltip => 'Idioma';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get cartStateEmergencyActive => 'Emergência ativa';

  @override
  String get slotHealthOk => 'OK';

  @override
  String get slotHealthExpiring => 'A expirar';

  @override
  String get slotHealthExpired => 'Expirado';

  @override
  String get slotHealthLowStock => 'Stock baixo';

  @override
  String get slotHealthMissing => 'Em falta';

  @override
  String get slotHealthFree => 'Livre';

  @override
  String get syncSynced => 'Sincronizado';

  @override
  String syncPending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alterações por enviar',
      one: '1 alteração por enviar',
    );
    return '$_temp0';
  }

  @override
  String get syncOffline => 'Sem ligação · a trabalhar offline';

  @override
  String get actionBackTooltip => 'Voltar';

  @override
  String get stateLoading => 'A carregar…';

  @override
  String get stateLoadError => 'Não foi possível carregar os dados.';

  @override
  String get stateRetry => 'Tentar novamente';

  @override
  String get stateNoAccess => 'Não tem acesso a esta área.';

  @override
  String get actionGenericError =>
      'Não foi possível concluir a ação. Tente novamente.';

  @override
  String get actionOfflineError =>
      'Sem ligação. A alteração será enviada quando a ligação voltar.';

  @override
  String get actionPermissionError => 'Não tem permissão para esta ação.';

  @override
  String get stubNotice =>
      'Funcionalidade de demonstração: os dados ficam guardados só neste dispositivo.';

  @override
  String formatToday(String time) {
    return 'Hoje, $time';
  }

  @override
  String formatYesterday(String time) {
    return 'Ontem, $time';
  }

  @override
  String slotQuantitySemantics(int current, int target) {
    return '$current de $target unidades';
  }

  @override
  String get loginTitle => 'Iniciar sessão';

  @override
  String get loginForgotPassword => 'Esqueci-me da palavra-passe';

  @override
  String get loginUsePin => 'Desbloquear com PIN';

  @override
  String get loginCartLogin => 'Entrar no carro';

  @override
  String get loginNeedsSavedSession =>
      'Inicie sessão uma vez neste dispositivo para usar o PIN ou entrar num carro.';

  @override
  String get loginResetSent =>
      'Enviámos um e-mail para redefinir a palavra-passe.';

  @override
  String get loginResetNeedsEmail => 'Escreva primeiro o seu e-mail.';

  @override
  String get pinWorksOffline => 'Funciona sem rede';

  @override
  String pinWrong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'PIN errado. Restam $count tentativas.',
      one: 'PIN errado. Resta 1 tentativa.',
    );
    return '$_temp0';
  }

  @override
  String pinNotMe(String name) {
    return 'Não é $name? Iniciar sessão';
  }

  @override
  String get pinDelete => 'Apagar';

  @override
  String pinDigitsSemantics(int entered, int total) {
    return '$entered de $total dígitos';
  }

  @override
  String get scannerUsbHint =>
      'Leitor USB: leia o código ou escreva-o e prima Enter';

  @override
  String get cartLoginCaption => 'Aponte para o código QR do carro';

  @override
  String get cartLoginHelp =>
      'Leia o código QR colado no carro ou aproxime o crachá NFC do leitor. A sessão fica limitada a este carro.';

  @override
  String get cartLoginUseNfc => 'Usar NFC';

  @override
  String get cartLoginNfcUnavailable =>
      'NFC ainda não está disponível nesta versão.';

  @override
  String get scannerTorch => 'Lanterna';

  @override
  String get scannerTorchOff => 'Desligar lanterna';

  @override
  String get cartLoginEnterCode => 'Introduzir código do carro';

  @override
  String get cartLoginCodeLabel => 'Código do carro';

  @override
  String get cartLoginCodeHint => 'Código impresso por baixo do QR';

  @override
  String get cartLoginBackToLogin => 'Voltar ao início de sessão';

  @override
  String get cartLoginNotFound => 'Este carro não existe ou foi arquivado.';

  @override
  String get cartLoginNoAccess => 'Não tem acesso a este carro.';

  @override
  String get profileSetPin => 'Definir PIN';

  @override
  String get profileChangePin => 'Alterar PIN';

  @override
  String get profileLockNow => 'Bloquear agora';

  @override
  String get profileSwitchInstitution => 'Mudar de instituição';

  @override
  String get pinSetupHelp =>
      'O PIN desbloqueia a sessão guardada neste dispositivo, mesmo sem rede. Não é partilhado com outros dispositivos.';

  @override
  String get pinNewLabel => 'Novo PIN (4 dígitos)';

  @override
  String get pinRepeatLabel => 'Repetir PIN';

  @override
  String get pinFourDigits => 'O PIN tem 4 dígitos';

  @override
  String get pinMismatch => 'Os PIN não coincidem';

  @override
  String get pinSaved => 'PIN guardado neste dispositivo.';

  @override
  String get navCarts => 'Carrinhos';

  @override
  String get navReports => 'Relatórios';

  @override
  String get navScan => 'Ler código';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navOverview => 'Visão geral';

  @override
  String get navCatalog => 'Catálogo';

  @override
  String get navTemplates => 'Modelos';

  @override
  String get navUsers => 'Utilizadores';

  @override
  String get navShifts => 'Turnos';

  @override
  String get navHistory => 'Histórico';

  @override
  String dashboardBrandSubtitle(String institution) {
    return 'Gestão · $institution';
  }

  @override
  String cartsSubtitle(String institution, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count carrinhos',
      one: '1 carrinho',
    );
    return '$institution · $_temp0';
  }

  @override
  String get cartsSearchHint => 'Pesquisar carrinho';

  @override
  String cartsFilterAll(int count) {
    return 'Todos ($count)';
  }

  @override
  String cartsFilterAttention(int count) {
    return 'Precisam de atenção ($count)';
  }

  @override
  String cartsFilterAttentionShort(int count) {
    return 'Atenção ($count)';
  }

  @override
  String cartsFilterMine(int count) {
    return 'Os meus ($count)';
  }

  @override
  String get offlineTitle => 'Sem ligação à rede';

  @override
  String offlineMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Pode continuar a trabalhar. $count alterações serão enviadas quando a ligação voltar.',
      one: 'Pode continuar a trabalhar. 1 alteração será enviada quando a ligação voltar.',
      zero: 'Pode continuar a trabalhar. As alterações serão enviadas quando a ligação voltar.',
    );
    return '$_temp0';
  }

  @override
  String countExpired(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expirados',
      one: '1 expirado',
    );
    return '$_temp0';
  }

  @override
  String countMissing(int count) {
    return '$count em falta';
  }

  @override
  String countExpiring(int count) {
    return '$count a expirar';
  }

  @override
  String countLowStock(int count) {
    return '$count com stock baixo';
  }

  @override
  String checkOverdueDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Verificação mensal em atraso ($days dias)',
      one: 'Verificação mensal em atraso (1 dia)',
    );
    return '$_temp0';
  }

  @override
  String get noStockAlerts => 'Sem alertas de stock';

  @override
  String get allCompliant => 'Tudo conforme';

  @override
  String lastCheckLine(String date, String name) {
    return 'Verificação mensal: $date · $name';
  }

  @override
  String get lastCheckNever => 'Verificação mensal: ainda não feita';

  @override
  String get compliant => 'Conforme';

  @override
  String responsibleOnShift(String name) {
    return 'Responsável no turno: $name';
  }

  @override
  String get drawersTitle => 'Gavetas';

  @override
  String drawerGridLong(int rows, int columns, int positions, int withProduct) {
    return '$rows × $columns · $positions posições · $withProduct com produto';
  }

  @override
  String drawerGridShort(int rows, int columns, int positions) {
    return '$rows × $columns · $positions posições';
  }

  @override
  String get cartMenuTitle => 'Menu do carro';

  @override
  String get monthlyCheckTitle => 'Verificação mensal';

  @override
  String get qrCodeShort => 'Código QR';

  @override
  String get changeStateAction => 'Alterar estado';

  @override
  String get cartReportsAction => 'Relatórios do carro';

  @override
  String get emergencyHint =>
      'Para registar consumos rápidos durante ou logo após uma emergência.';

  @override
  String get emergencyModeTitle => 'Modo de emergência';

  @override
  String get emergencyShort => 'Emergência';

  @override
  String get emergencyResume => 'Voltar ao modo de emergência';

  @override
  String get autoStateRule =>
      'Regra automática (quando ativa): produto expirado ou em falta → Reposição necessária; verificação mensal com mais de 31 dias → Verificação em atraso.';

  @override
  String get printLabel => 'Imprimir etiqueta';

  @override
  String productLocation(int number, String drawer, String position) {
    return 'Gaveta $number · $drawer · posição $position';
  }

  @override
  String drawerTitle(int number, String name) {
    return 'Gaveta $number · $name';
  }

  @override
  String drawerSubtitle(String cart, int rows, int columns, int positions) {
    return '$cart · $rows × $columns · $positions posições';
  }

  @override
  String drawerSubtitleShort(String cart, int rows, int columns) {
    return '$cart · $rows × $columns';
  }

  @override
  String get drawerSelectHint =>
      'Toque numa posição para ver o produto, a quantidade e a validade.';

  @override
  String slotPositionInDrawer(String position, int drawer) {
    return 'Posição $position · Gaveta $drawer';
  }

  @override
  String get slotFreeTitle => 'Posição livre';

  @override
  String unitsOf(int current, int target) {
    return '$current de $target un.';
  }

  @override
  String ofTargetUnits(int target) {
    return 'de $target unidades';
  }

  @override
  String get expiryLabel => 'Validade';

  @override
  String get lotLabel => 'Lote';

  @override
  String get minimumLabel => 'Mínimo';

  @override
  String lotWithUnits(String lot, int units) {
    return '$lot · $units un.';
  }

  @override
  String daysCount(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String get changeProductAction => 'Trocar produto';

  @override
  String get changeProductConfirm =>
      'O produto atual sai desta posição juntamente com os lotes registados. O histórico de consumos mantém-se.';

  @override
  String panelSubtitle(
    String product,
    String position,
    int current,
    int target,
  ) {
    return '$product · $position · atual $current de $target';
  }

  @override
  String get quantityLabel => 'Quantidade';

  @override
  String get confirmConsumption => 'Confirmar consumo';

  @override
  String get consumptionRecorded => 'Consumo registado.';

  @override
  String get confirmReplenishment => 'Confirmar reposição';

  @override
  String get replenishmentRecorded => 'Reposição registada.';

  @override
  String get replenishScanHelp =>
      'Leia o Data Matrix da embalagem para preencher lote e validade.';

  @override
  String get correctionRecorded => 'Correção registada.';

  @override
  String get reconcileRecorded => 'Reconciliação registada.';

  @override
  String get catalogSearchHint => 'Pesquisar no catálogo';

  @override
  String monthlyCheckSubtitle(
    String cart,
    int index,
    int total,
    String drawer,
  ) {
    return '$cart · Gaveta $index de $total · $drawer';
  }

  @override
  String get saveAndExit => 'Guardar e sair';

  @override
  String progressSemantics(int index, int total) {
    return 'Gaveta $index de $total';
  }

  @override
  String get monthlyCheckEmptyDrawer =>
      'Esta gaveta não tem produtos atribuídos.';

  @override
  String expiresOn(String date) {
    return 'expira a $date';
  }

  @override
  String expectedUnits(int count) {
    return 'esperado $count';
  }

  @override
  String expiryShort(String date) {
    return 'val. $date';
  }

  @override
  String checkVerified(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verificadas',
      one: '1 verificada',
    );
    return '$_temp0';
  }

  @override
  String checkProblems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count com problema',
      one: '1 com problema',
    );
    return '$_temp0';
  }

  @override
  String checkPending(int count) {
    return '$count por verificar';
  }

  @override
  String get monthlyCheckHelp =>
      'Toque numa linha para confirmar quantidade e validade. Toque de novo para assinalar um problema; toque longo para limpar. Os problemas ficam registados no relatório.';

  @override
  String get checkMarkAll => 'Marcar restantes como verificadas';

  @override
  String get addNote => 'Adicionar nota';

  @override
  String get editNote => 'Editar nota';

  @override
  String get noteHint => 'Observações para o relatório';

  @override
  String get nextDrawer => 'Gaveta seguinte';

  @override
  String get previousDrawer => 'Gaveta anterior';

  @override
  String get finishCheck => 'Concluir e gerar relatório';

  @override
  String get reportKindMonthlyCheck => 'Verificação mensal';

  @override
  String get reportKindEmergency => 'Resumo de emergência';

  @override
  String get reportMonthlyTitle => 'Relatório de verificação mensal';

  @override
  String get reportEmergencyTitle => 'Resumo de emergência';

  @override
  String get reportSigned => 'Assinado';

  @override
  String get reportPendingSignature => 'Por assinar';

  @override
  String get reportDate => 'Data';

  @override
  String get reportCheckedBy => 'Verificado por';

  @override
  String get reportStartedBy => 'Iniciado por';

  @override
  String get reportPositionsChecked => 'Posições verificadas';

  @override
  String get reportPeriod => 'Período';

  @override
  String xOfY(int x, int y) {
    return '$x de $y';
  }

  @override
  String reportFindings(int count) {
    return 'Problemas encontrados ($count)';
  }

  @override
  String get reportNoFindings => 'Sem problemas encontrados.';

  @override
  String get findingOther => 'diferença';

  @override
  String emergencyConsumptions(int count) {
    return 'Consumos registados ($count)';
  }

  @override
  String get reportNotes => 'Notas';

  @override
  String get downloadPdf => 'Descarregar PDF';

  @override
  String signedByOn(String name, String date) {
    return 'Assinado por $name · $date';
  }

  @override
  String get reportLockedHelp =>
      'Depois de assinado, o relatório não pode ser alterado.';

  @override
  String get signReport => 'Assinar relatório';

  @override
  String get signReportHelp =>
      'Ao assinar confirma que verificou o carro e que os dados estão corretos. Depois de assinado, o relatório não pode ser alterado.';

  @override
  String get confirmCheck => 'Confirmo a verificação';

  @override
  String get pinLabel => 'PIN';

  @override
  String get signNeedsPin =>
      'Defina primeiro um PIN neste dispositivo para assinar.';

  @override
  String get signNeedsConfirmation =>
      'Marque “Confirmo a verificação” para assinar.';

  @override
  String get signWrongPin => 'PIN errado.';

  @override
  String get reportSignedMessage => 'Relatório assinado.';

  @override
  String reportsFilterPending(int count) {
    return 'Por assinar ($count)';
  }

  @override
  String get reportsEmpty =>
      'Ainda não há relatórios. São criados no fim de uma verificação mensal ou de um modo de emergência.';

  @override
  String get emergencyNotActive =>
      'O modo de emergência deste carro já terminou.';

  @override
  String emergencyHeader(String cart) {
    return 'Modo de emergência · $cart';
  }

  @override
  String emergencyStarted(String time, int minutes, String name) {
    return 'Iniciado às $time (há $minutes min) · $name';
  }

  @override
  String get emergencyEnd => 'Terminar emergência';

  @override
  String get emergencyEndConfirm =>
      'O carro passa a “Reposição necessária” e é criado um resumo dos consumos para assinar.';

  @override
  String drawerShort(int number) {
    return 'Gaveta $number';
  }

  @override
  String get emergencyHelp =>
      'Toque numa posição para registar 1 unidade usada. Toque longo para outra quantidade.';

  @override
  String get emergencyNothingLeft => 'Esta posição já não tem unidades.';

  @override
  String emergencyNotSent(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count consumos não foram enviados ao servidor; ficam no resumo.',
      one: '1 consumo não foi enviado ao servidor; fica no resumo.',
    );
    return '$_temp0';
  }

  @override
  String get undoLast => 'Desfazer último';

  @override
  String get scanProductCaption => 'Aponte para o código do produto';

  @override
  String get scanModeProduct => 'Produto';

  @override
  String get scanModeCart => 'Carro';

  @override
  String get scanHelp =>
      'QR, Data Matrix (GS1) ou código de barras. Também funciona com leitor USB.';

  @override
  String get scanLastRead => 'Último código lido';

  @override
  String scanLot(String lot) {
    return 'Lote $lot';
  }

  @override
  String scanExpiry(String date) {
    return 'Val. $date';
  }

  @override
  String get scanReplenishThis => 'Repor este produto';

  @override
  String get scanManual => 'Manual';

  @override
  String get scanManualProductLabel => 'GTIN ou código GS1';

  @override
  String get scanOtherInstitution => 'Este carro pertence a outra instituição.';

  @override
  String get scanNotInAnyCart =>
      'Este produto não está atribuído a nenhum carro a que tenha acesso.';

  @override
  String get exportReport => 'Exportar relatório';

  @override
  String get metricOperational => 'Carrinhos operacionais';

  @override
  String metricNeedReplenishment(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count precisam de reposição',
      one: '1 precisa de reposição',
      zero: 'Nenhum precisa de reposição',
    );
    return '$_temp0';
  }

  @override
  String get metricExpiring30 => 'A expirar em 30 dias';

  @override
  String metricInCarts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'em $count carrinhos',
      one: 'em 1 carrinho',
    );
    return '$_temp0';
  }

  @override
  String get metricChecksOverdue => 'Verificações em atraso';

  @override
  String get metricEmergencies => 'Emergências este mês';

  @override
  String metricUnitsRecorded(int count) {
    return '$count consumos registados';
  }

  @override
  String get cartsNeedingAttention => 'Carrinhos que precisam de atenção';

  @override
  String get columnCart => 'Carrinho';

  @override
  String get columnState => 'Estado';

  @override
  String get columnAlerts => 'Alertas';

  @override
  String get columnServiceLocation => 'Serviço · local';

  @override
  String activityEmergency(int count) {
    return 'Modo de emergência · $count consumos';
  }

  @override
  String get activityCheckSigned => 'Verificação mensal assinada';

  @override
  String get activityCheckDone => 'Verificação mensal concluída';

  @override
  String cartsServicesSubtitle(int carts, int services) {
    String _temp0 = intl.Intl.pluralLogic(
      carts,
      locale: localeName,
      other: '$carts carrinhos',
      one: '1 carrinho',
    );
    String _temp1 = intl.Intl.pluralLogic(
      services,
      locale: localeName,
      other: '$services serviços',
      one: '1 serviço',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get createFromTemplate => 'Criar a partir de modelo';

  @override
  String get newCart => 'Novo carrinho';

  @override
  String get cartsSearchHintLong => 'Pesquisar carrinho ou serviço';

  @override
  String cartsFilterOutOfService(int count) {
    return 'Fora de serviço ($count)';
  }

  @override
  String get columnLastCheck => 'Última verificação';

  @override
  String get columnOnShift => 'Responsável no turno';

  @override
  String cartCreated(String name) {
    return 'Carrinho “$name” criado.';
  }

  @override
  String get templateLabel => 'Modelo';

  @override
  String get templatesEmpty => 'Ainda não há modelos. Crie um em Modelos.';

  @override
  String get fieldName => 'Nome';

  @override
  String get fieldService => 'Serviço';

  @override
  String get fieldServiceHint => 'ex.: Urgência';

  @override
  String get fieldLocation => 'Local';

  @override
  String get fieldLocationHint => 'ex.: Piso 0 · Sala de reanimação';

  @override
  String get cartConfigSubtitle => 'Configuração do carrinho';

  @override
  String get archiveCart => 'Arquivar carrinho';

  @override
  String get archiveCartConfirm =>
      'O carrinho deixa de aparecer nas listas. O histórico e os relatórios mantêm-se.';

  @override
  String get cartArchived => 'Carrinho arquivado.';

  @override
  String get saveChanges => 'Guardar alterações';

  @override
  String get cartInfoTitle => 'Informação';

  @override
  String get originTemplate => 'Modelo de origem';

  @override
  String get autoStateLabel => 'Atualizar o estado automaticamente';

  @override
  String drawersCount(int count) {
    return 'Gavetas ($count)';
  }

  @override
  String get addDrawer => 'Adicionar gaveta';

  @override
  String get columnNumber => 'Nº';

  @override
  String get columnSize => 'Dimensão';

  @override
  String get columnPositions => 'Posições';

  @override
  String get columnWithProduct => 'Com produto';

  @override
  String get editGrid => 'Editar grelha';

  @override
  String get drawerNameHint => 'ex.: Fármacos';

  @override
  String gridEditorTitle(int number, String name) {
    return 'Gaveta $number · $name';
  }

  @override
  String gridEditorSubtitle(String cart) {
    return '$cart · editar grelha e posições';
  }

  @override
  String get saveGrid => 'Guardar grelha';

  @override
  String get gridSaved => 'Grelha guardada.';

  @override
  String get mergePositions => 'Juntar posições';

  @override
  String get clearPosition => 'Limpar posição';

  @override
  String clearPositionConfirm(String product, String position) {
    return 'Remove $product da posição $position. Os lotes registados são removidos; o histórico mantém-se.';
  }

  @override
  String get gridSelectionHint =>
      'Toque numa posição para a configurar. Toque em várias para as juntar.';

  @override
  String mergeLosesAssignments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count posições perdem o produto, que fica em “sem posição” até ser reatribuído.',
      one: '1 posição perde o produto, que fica em “sem posição” até ser reatribuído.',
    );
    return '$_temp0';
  }

  @override
  String get unsavedGridTitle => 'Alterações por guardar';

  @override
  String get unsavedGridMessage => 'Sair sem guardar a grelha?';

  @override
  String get discardChanges => 'Descartar';

  @override
  String orphansTitle(int count) {
    return 'Produtos sem posição ($count)';
  }

  @override
  String get orphanReassignHint =>
      'Selecione uma posição livre na grelha e toque em Reatribuir.';

  @override
  String positionTitle(String position) {
    return 'Posição $position';
  }

  @override
  String positionsSelected(int count) {
    return '$count posições selecionadas';
  }

  @override
  String get positionSelectHint =>
      'Selecione uma posição para configurar o produto.';

  @override
  String get gridUnsavedHint => 'Guarde a grelha antes de configurar posições.';

  @override
  String get chooseProduct => 'Escolher produto';

  @override
  String get catalogNoMatches => 'Nenhum produto corresponde à pesquisa.';

  @override
  String get minimumQuantityLabel => 'Quantidade mínima';

  @override
  String get expiryWarningDaysLabel => 'Aviso de validade (dias)';

  @override
  String get askLotOnReplenish => 'Pedir lote e validade na reposição';

  @override
  String get applyToPosition => 'Aplicar à posição';

  @override
  String get positionApplied => 'Posição atualizada.';

  @override
  String get catalogTitle => 'Catálogo de consumíveis';

  @override
  String catalogSubtitle(int count, int carts) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produtos',
      one: '1 produto',
    );
    String _temp1 = intl.Intl.pluralLogic(
      carts,
      locale: localeName,
      other: '$carts carrinhos',
      one: '1 carrinho',
    );
    return '$_temp0 · usados em $_temp1';
  }

  @override
  String get importCsv => 'Importar CSV';

  @override
  String get importCsvHelp =>
      'Cole uma linha por produto: nome; apresentação; GTIN; categoria; aviso de validade (dias). Os produtos com nome ou GTIN já existentes são ignorados.';

  @override
  String get importCsvHint => 'Cole aqui o conteúdo do ficheiro CSV';

  @override
  String get importAction => 'Importar';

  @override
  String importResult(int created, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      created,
      locale: localeName,
      other: '$created produtos importados',
      one: '1 produto importado',
    );
    return '$_temp0 · $skipped ignorados.';
  }

  @override
  String get newProduct => 'Novo produto';

  @override
  String get editProduct => 'Editar produto';

  @override
  String get catalogSearchByNameOrGtin => 'Pesquisar por nome ou GTIN';

  @override
  String get filterAll => 'Todos';

  @override
  String get categoryDrug => 'Fármaco';

  @override
  String get categoryDrugs => 'Fármacos';

  @override
  String get categoryMaterial => 'Material';

  @override
  String get categoryFluid => 'Fluido';

  @override
  String get categoryFluids => 'Fluidos';

  @override
  String get columnPresentation => 'Apresentação';

  @override
  String get columnGtin => 'GTIN';

  @override
  String get columnCategory => 'Categoria';

  @override
  String get columnInUse => 'Em uso';

  @override
  String get expiryWarningShort => 'Aviso de validade';

  @override
  String inCartsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count carrinhos',
      one: '1 carrinho',
      zero: '—',
    );
    return '$_temp0';
  }

  @override
  String productCreated(String name) {
    return 'Produto “$name” criado.';
  }

  @override
  String get productUpdated => 'Produto atualizado.';

  @override
  String get gtinTaken => 'Já existe um produto com este GTIN.';

  @override
  String get gtinInvalid => 'O GTIN tem 8, 12, 13 ou 14 algarismos.';

  @override
  String get scanGtin => 'Ler GTIN da embalagem';

  @override
  String get expiryWarningDefaultHint => 'Vazio = valor da instituição';

  @override
  String get templatesTitle => 'Modelos de carrinho';

  @override
  String get templatesSubtitle => 'Crie carrinhos iguais a partir de um modelo';

  @override
  String get templatesEmptyDashboard =>
      'Ainda não há modelos. Crie um a partir de um carrinho já configurado.';

  @override
  String get newTemplate => 'Novo modelo';

  @override
  String get editTemplate => 'Editar modelo';

  @override
  String get deleteTemplate => 'Eliminar modelo';

  @override
  String deleteTemplateConfirm(String name) {
    return 'Eliminar o modelo “$name”? Os carrinhos já criados a partir dele não são alterados.';
  }

  @override
  String get templateDeleted => 'Modelo eliminado.';

  @override
  String get templateSaved => 'Modelo guardado.';

  @override
  String templateSummary(int drawers, int positions, int carts) {
    String _temp0 = intl.Intl.pluralLogic(
      drawers,
      locale: localeName,
      other: '$drawers gavetas',
      one: '1 gaveta',
    );
    String _temp1 = intl.Intl.pluralLogic(
      carts,
      locale: localeName,
      other: '$carts carrinhos',
      one: '1 carrinho',
    );
    return '$_temp0 · $positions posições · usado em $_temp1';
  }

  @override
  String templateUpdatedBy(String date, String name) {
    return 'Atualizado a $date por $name';
  }

  @override
  String templateDrawerSize(int rows, int columns, int positions) {
    return '$rows × $columns · $positions posições';
  }

  @override
  String get templateCopyNote =>
      'Os carrinhos criados a partir do modelo copiam gavetas, posições e quantidades alvo. Stock e histórico não são copiados.';

  @override
  String get createCartFromThisTemplate =>
      'Criar carrinho a partir deste modelo';

  @override
  String templateCopyName(String name) {
    return '$name (cópia)';
  }

  @override
  String get templateSourceCart => 'Carrinho de origem';

  @override
  String get templateRefreshFromCart => 'Atualizar a partir de um carrinho';

  @override
  String get templateKeepStructure => 'Manter a estrutura atual';

  @override
  String get templateChooseCart => 'Escolha um carrinho';

  @override
  String get usersTitle => 'Utilizadores e permissões';

  @override
  String usersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count utilizadores',
      one: '1 utilizador',
    );
    return '$_temp0';
  }

  @override
  String get inviteUser => 'Convidar utilizador';

  @override
  String get sendInvite => 'Enviar convite';

  @override
  String get inviteNote =>
      'A pessoa recebe um e-mail para definir a sua palavra-passe.';

  @override
  String inviteSent(String email) {
    return 'Convite enviado para $email.';
  }

  @override
  String get resendInvite => 'Reenviar e-mail de acesso';

  @override
  String get emailTaken => 'Já existe um utilizador com este e-mail.';

  @override
  String get emailInvalid => 'Indique um e-mail válido.';

  @override
  String get fieldEmail => 'E-mail';

  @override
  String get usersSearchHint => 'Pesquisar por nome ou e-mail';

  @override
  String usersFilterManagers(int count) {
    return 'Gestores ($count)';
  }

  @override
  String usersFilterProfessionals(int count) {
    return 'Profissionais de saúde ($count)';
  }

  @override
  String usersFilterInvited(int count) {
    return 'Convites pendentes ($count)';
  }

  @override
  String get usersNoMatches => 'Nenhum utilizador corresponde à pesquisa.';

  @override
  String get columnUserType => 'Tipo de utilizador';

  @override
  String get allServices => 'Todos';

  @override
  String get moreActions => 'Mais ações';

  @override
  String get cannotEditSelf => 'Não pode alterar a sua própria conta.';

  @override
  String get changeUserType => 'Alterar tipo de utilizador';

  @override
  String get deactivateUser => 'Desativar';

  @override
  String get reactivateUser => 'Reativar';

  @override
  String deactivateUserConfirm(String name) {
    return '$name deixa de conseguir entrar. O histórico mantém-se.';
  }

  @override
  String reactivateUserConfirm(String name) {
    return '$name volta a conseguir entrar.';
  }

  @override
  String get userUpdated => 'Utilizador atualizado.';

  @override
  String get permissionsTitle => 'Permissões';

  @override
  String get permissionsNote =>
      'Proposta (D2). As permissões ficam guardadas neste dispositivo até existir suporte no servidor.';

  @override
  String get permViewCarts => 'Ver carrinhos e gavetas';

  @override
  String get permRecordConsumption => 'Registar consumos';

  @override
  String get permReplenish => 'Repor stock (lote e validade)';

  @override
  String get permMonthlyCheck => 'Fazer a verificação mensal';

  @override
  String get permSignReports => 'Assinar relatórios';

  @override
  String get permEmergencyMode => 'Usar o modo de emergência';

  @override
  String get permChangeCartState => 'Alterar o estado do carrinho';

  @override
  String get permEditDrawers => 'Editar gavetas e grelhas';

  @override
  String get permManageUsersAndShifts => 'Gerir utilizadores e turnos';

  @override
  String get shiftsTitle => 'Turnos';

  @override
  String shiftsWeekOf(String start, String end) {
    return 'Semana de $start a $end';
  }

  @override
  String get previousWeek => 'Semana anterior';

  @override
  String get nextWeek => 'Semana seguinte';

  @override
  String get addShift => 'Adicionar turno';

  @override
  String get copyPreviousWeek => 'Copiar semana anterior';

  @override
  String shiftsCopied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count turnos copiados.',
      one: '1 turno copiado.',
      zero: 'Nenhum turno copiado.',
    );
    return '$_temp0';
  }

  @override
  String get shiftsByCart => 'Por carrinho';

  @override
  String get shiftsByPerson => 'Por pessoa';

  @override
  String get columnPerson => 'Pessoa';

  @override
  String get shiftsNoneThisWeek => 'Sem turnos nesta semana.';

  @override
  String get shiftsLegend =>
      'M = manhã (08–16) · T = tarde (16–24) · N = noite (00–08)';

  @override
  String get shiftMorningShort => 'M';

  @override
  String get shiftAfternoonShort => 'T';

  @override
  String get shiftNightShort => 'N';

  @override
  String get shiftMorning => 'Manhã';

  @override
  String get shiftAfternoon => 'Tarde';

  @override
  String get shiftNight => 'Noite';

  @override
  String get shiftDay => 'Dia';

  @override
  String get shiftResponsible => 'Responsável';

  @override
  String get shiftNobody => 'Ninguém';

  @override
  String get shiftSaved => 'Turno guardado.';

  @override
  String get reportsHistoryTitle => 'Relatórios e histórico';

  @override
  String get exportCsv => 'Exportar CSV';

  @override
  String exportCsvHelp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eventos',
      one: '1 evento',
    );
    return '$_temp0 do período e carrinho escolhidos. Copie e cole numa folha de cálculo.';
  }

  @override
  String get copyCsv => 'Copiar';

  @override
  String get csvCopied => 'CSV copiado.';

  @override
  String get tabReports => 'Relatórios';

  @override
  String get tabEvents => 'Histórico de eventos';

  @override
  String get tabStatistics => 'Estatísticas';

  @override
  String filterCart(String name) {
    return 'Carrinho: $name';
  }

  @override
  String get filterAllCarts => 'todos';

  @override
  String filterPeriod(String period) {
    return 'Período: $period';
  }

  @override
  String get columnReport => 'Relatório';

  @override
  String get columnDate => 'Data';

  @override
  String get columnSignedBy => 'Assinado por';

  @override
  String get reportPendingSignatureShort => 'Por assinar';

  @override
  String get actionOpen => 'Abrir';

  @override
  String get reportsEmptyPeriod => 'Sem relatórios neste período.';

  @override
  String get eventsEmptyPeriod => 'Sem eventos neste período.';

  @override
  String eventsCapped(int count) {
    return 'A mostrar os $count eventos mais recentes da instituição.';
  }

  @override
  String get statConsumed => 'Consumido';

  @override
  String get statReplenished => 'Reposto';

  @override
  String get statChecks => 'Verificações';

  @override
  String get statEmergencies => 'Emergências';

  @override
  String get statPendingSignatures => 'Por assinar';

  @override
  String get statTopProducts => 'Produtos mais consumidos';

  @override
  String get statByCart => 'Por carrinho';

  @override
  String pagerRange(int from, int to, int total) {
    return '$from–$to de $total';
  }

  @override
  String get pagerPrevious => 'Página anterior';

  @override
  String get pagerNext => 'Página seguinte';

  @override
  String get closePanel => 'Fechar painel';

  @override
  String get viewAsApp => 'Ver como App (teste)';

  @override
  String get viewAsDashboard => 'Ver como Dashboard (teste)';
}
