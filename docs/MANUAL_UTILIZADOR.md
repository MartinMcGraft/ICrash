# I-Crash — Guião de Funcionalidades

Manual funcional da aplicação I-Crash: o que cada ecrã mostra e o que cada
botão/ícone faz. Escrito para quem vai usar ou demonstrar a aplicação, não
para programadores (para detalhe técnico/arquitetura ver `docs/ARCHITECTURE.md`
e `docs/FIREBASE_MODEL.md`).

Atualizado: 2026-09-11.

---

## 1. Acesso e contas

A aplicação liga-se ao projeto Firebase de produção `i-crash-pt-2026` sempre
que corre em modo *release* (e ao emulador local sempre que corre em modo
*debug*, salvo override explícito). Não é preciso nenhuma configuração
adicional — basta abrir a app e iniciar sessão.

### Contas com permissões máximas

Foram criadas duas contas de acesso com o nível de permissão mais alto da
aplicação (administrador de plataforma **e** administrador da instituição
principal, para poderem gerir tudo a partir do primeiro ecrã):

| E-mail | Palavra-passe | Nível |
|---|---|---|
| `pajorge01@gmail.com` | `password` | Platform Super Admin + Institution Admin |
| `martimalves@gmail.com` | `password` | Platform Super Admin + Institution Admin |

> Estas não são contas Gmail reais — são apenas credenciais de acesso à
> aplicação (Firebase Authentication por e-mail/palavra-passe), tal como
> qualquer outra conta de utilizador da app. Já foram criadas no projeto de
> produção; falta apenas atribuir-lhes os documentos de permissão no
> Firestore (ver instruções à parte que foram dadas nesta sessão) — assim que
> isso for feito, ambas passam a ver a instituição principal e todos os
> carros, produtos e membros, com acesso total.

Recomenda-se mudar a palavra-passe destas contas dentro da aplicação (ou via
consola Firebase) antes de uma utilização real/pública.

### Modelo de papéis (roles)

Cada utilizador tem um papel por instituição (não é global, exceto o
"Platform Super Admin"):

- **Platform Super Admin** — acima de qualquer instituição; vê e gere tudo em
  todas as instituições. Concedido apenas manualmente (não existe ecrã para
  isto, por desenho).
- **Institution Admin** (administrador da instituição) — gere tudo dentro da
  sua instituição: membros, carros, produtos, gavetas, compartimentos.
- **Manager** (gestor) — as mesmas capacidades de gestão de carros/produtos
  que o admin, mas não gere membros da instituição.
- **User** (utilizador comum) — só vê os carros aos quais foi explicitamente
  atribuído como responsável; pode registar consumos e corrigir eventos, mas
  não pode criar/editar carros, gavetas, produtos ou compartimentos.

Uma conta com estado "disabled" (desativada) perde todo o acesso,
independentemente do papel que tenha.

---

## 2. Ecrã de início de sessão (Login)

**Como se chega aqui:** é o primeiro ecrã, sempre que não há sessão Firebase
ativa.

- Campo **E-mail** — obrigatório.
- Campo **Palavra-passe** — obrigatório, texto oculto.
- Botão **Entrar** — valida os campos e tenta autenticar. Fica desativado e
  mostra um indicador de carregamento enquanto a autenticação decorre.
  - Se as credenciais estiverem erradas: mensagem de erro "credenciais
    inválidas".
  - Se não houver ligação: mensagem de erro "sem ligação".
  - Ao ter sucesso, a app avança automaticamente para a seleção de
    instituição (não há botão de navegação explícito — a mudança de ecrã
    acontece sozinha assim que a sessão fica ativa).

---

## 3. Seleção de instituição

**Como se chega aqui:** automaticamente após o login. Mostra apenas as
instituições onde o utilizador tem uma associação **ativa**.

- Lista de instituições (cada uma como um cartão com ícone de hospital) — tocar
  numa abre o **Painel da instituição** correspondente.
- Se a lista estiver vazia: mensagem "sem instituições".
- Ícone **Terminar sessão** (canto superior direito) — termina a sessão e
  volta ao ecrã de login, sem pedir confirmação.

---

## 4. Painel da instituição (ecrã principal / dashboard)

**Como se chega aqui:** ao escolher uma instituição na lista anterior; é
também o ecrã de retorno depois de sair da maioria dos outros ecrãs.

### Botões na barra superior (da esquerda para a direita)

1. **Ler QR de carro** (ícone de scanner) — só aparece em plataformas com
   câmara suportada. Abre o ecrã de digitalização de QR de carro; ao ler um
   código válido, abre diretamente o **Detalhe do carro** correspondente (se
   o utilizador tiver acesso a esse carro — ler o código não dá acesso extra,
   só atalha a navegação).
2. **Histórico** (ícone de recibo) — abre o ecrã de **Histórico**, disponível
   para qualquer membro ativo.
3. **Produtos** (ícone de medicamento) — só visível para gestor+ (manager,
   institution admin ou platform super admin, com associação ativa). Abre a
   lista de **Produtos** da instituição.
4. **Membros** (ícone de grupo) — só visível para institution admin ou
   platform super admin. Abre o ecrã de **Membros**.
5. **App legada** (ícone de histórico/relógio) — sempre visível. Abre o
   protótipo antigo (pré-arquitetura V2), mantido só por continuidade
   histórica: tem três botões próprios ("Registo", "Leitor QR Code",
   "Teste Data Matrix") que não estão ligados ao backend atual.
6. **Idioma** (ícone de globo) — menu com "Português" / "English"; muda o
   idioma de toda a app de imediato e guarda a escolha para a próxima vez que
   abrir a app.
7. **Terminar sessão** (ícone de logout) — sempre visível, sem confirmação.

### Corpo do ecrã

- **Resumo de estado dos carros** — badges com a contagem de carros por
  estado (Operacional, Reposição necessária, Auditoria necessária, Fora de
  serviço). Apenas informativo, não clicável.
- **Alertas entre carros** — só visível para gestor+. Lista todos os produtos,
  em qualquer carro da instituição, que estejam expirados, a expirar em breve
  ou abaixo da quantidade mínima. Apenas informativo.
- **Atividade recente** — visível para todos; mostra os últimos 5 eventos
  (consumo/reposição/correção) de toda a instituição.
- **Campo de pesquisa** — filtra a lista de carros pelo nome, em tempo real.
- **Lista de carros** — um cartão por carro (nome + estado); tocar abre o
  **Detalhe do carro**.

### Botão flutuante

- **Criar carro** (+) — só para gestor+. Abre o diálogo de criação de carro
  (pede só o nome); o novo carro aparece de imediato na lista.

---

## 5. Diálogo: Criar carro

Um único campo **Nome** (obrigatório). Botões **Cancelar** / **Criar**.

---

## 6. Detalhe do carro

**Como se chega aqui:** ao tocar num carro na lista do painel, ao ler o QR de
um carro, ou a partir de um resultado da pesquisa de produtos.

Mostra o nome do carro e um badge com o estado atual.

### Botões na barra superior

1. **Mostrar código QR** (sempre visível) — abre o ecrã que apresenta o QR
   interno do carro (para o colar fisicamente no carro e permitir reabri-lo
   por leitura).
2. **Pesquisar produto** (sempre visível) — abre a **Pesquisa de produto**
   dentro deste carro.
3. **Menu (⋮)** — só para gestor+:
   - **Editar** — abre o diálogo de edição (nome + estado do carro); ao
     guardar mostra confirmação e volta ao painel.
   - **Duplicar** — abre o diálogo de duplicação (pede o novo nome); cria um
     carro novo com as mesmas gavetas e disposição de compartimentos, mas
     **sem** copiar produtos atribuídos, stock ou histórico.
4. **Responsáveis** (ícone de crachá) — só para gestor+. Abre o ecrã de
   **Utilizadores responsáveis** por este carro.

### Corpo

Lista de gavetas do carro (nome + dimensão, ex. "5 × 7"); tocar abre o
**Editor de compartimentos** dessa gaveta.

### Botão flutuante

- **Criar gaveta** (+) — só para gestor+. Pede nome, número de linhas
  (1–12) e colunas (1–12).

---

## 7. Diálogo: Editar carro

Campo **Nome** e menu suspenso **Estado** (Operacional / Reposição
necessária / Auditoria necessária / Fora de serviço — escolha manual, já que
o estado é normalmente calculado automaticamente). Botões **Cancelar** /
**Guardar**.

## 8. Diálogo: Duplicar carro

Campo **Novo nome**, com aviso de que só a disposição é copiada (nunca stock
nem histórico). Botões **Cancelar** / **Duplicar**.

## 9. Diálogo: Criar gaveta

Campos **Nome**, **Linhas** (1–12) e **Colunas** (1–12). Botões **Cancelar** /
**Criar**. Cada célula começa como um compartimento individual 1×1 — juntar
células em compartimentos maiores faz-se depois no Editor de compartimentos.

---

## 10. Editor de compartimentos (slots)

**Como se chega aqui:** ao tocar numa gaveta no Detalhe do carro.

### Botão na barra superior

- **Guardar** (ícone de disquete) — só para gestor+. Grava toda a disposição
  atual da gaveta (junções/divisões feitas localmente só ficam permanentes ao
  premir este botão). Mostra confirmação ou erro.

### Aviso de compartimentos órfãos

Aparece (só para gestor+) quando há produtos atribuídos a um compartimento
que já não existe (por exemplo depois de uma junção/divisão anterior). Para
cada um:
- **Reatribuir** — escolhe um compartimento vazio da gaveta atual para onde
  mover o produto.
- **Remover** — apaga a atribuição órfã (sem pedido de confirmação).

### Barra de junção/divisão (só gestor+)

- **Juntar** — ativo com 2+ compartimentos selecionados que formem um
  retângulo completo; junta-os num só compartimento maior.
- **Dividir** — ativo com um compartimento selecionado que já resulte de uma
  junção anterior; volta a dividi-lo em células 1×1.

### Grelha de compartimentos

- **Toque simples** — só gestor+: seleciona/desseleciona a célula (para
  juntar/dividir).
- **Toque longo** — qualquer utilizador com acesso ao carro: abre o
  **Diálogo de atribuição/consumo** para esse compartimento.

---

## 11. Diálogo de atribuição, consumo, reposição, reconciliação e correção

Este é o diálogo mais usado no dia a dia. Muda de "modo" consoante a ação:

### Compartimento vazio, utilizador sem permissão de gestão

Mostra apenas "compartimento vazio" e o botão **Fechar** — um utilizador
comum não pode atribuir um novo produto a um compartimento.

### Modo Atribuir (compartimento vazio, gestor+)

- **Produto** (menu suspenso, obrigatório).
- **Quantidade inicial** (número, ≥0, padrão 0).
- **Quantidade alvo** (número, ≥0, padrão 1).
- Botões **Cancelar** / **Atribuir**. Se outro gestor atribuir o mesmo
  compartimento em simultâneo, mostra erro específico de conflito.

### Modo Ver (compartimento já ocupado)

Mostra o nome do produto, "quantidade atual/alvo" e um badge de estado (OK,
Reposição necessária, A expirar, Expirado). Botões:
- **Fechar**
- **Corrigir** — disponível a qualquer utilizador com acesso ao carro.
- **Repor stock** — só gestor+.
- **Reconciliar** — só gestor+ (usado depois de uma auditoria física).
- **Registar consumo** — botão principal, disponível a qualquer utilizador
  com acesso ao carro (é a ação do dia a dia).

### Modo Consumir

- **Quantidade** (número positivo, obrigatório).
- **Confirmar** — impede submeter uma quantidade maior do que o stock
  disponível (mostra aviso em vez de gravar). **Importante**: o consumo
  diário nunca escolhe um lote específico — só reduz a quantidade agregada
  do produto no compartimento. (Regra de negócio intencional — ver secção
  62 da especificação original: não alterar este comportamento.)

### Modo Repor (só gestor+)

- **Quantidade recebida** (número positivo, obrigatório).
- **Ler código GS1** — abre o leitor de código GS1 Data Matrix (câmara ou
  leitor USB/HID). Ao ler um código com sucesso, preenche automaticamente
  lote e validade (sem nunca bloquear a edição manual); se o código incluir
  um GTIN de outro produto diferente do atribuído a este compartimento,
  mostra apenas um aviso — nunca bloqueia a submissão.
- **Número de lote** (obrigatório).
- **Data de validade** (seletor de calendário, obrigatório).
- **Confirmar** — grava a reposição com um novo lote. **Importante**: a
  validade "mais próxima conhecida" do produto é sempre conservadora — uma
  validade nova mais distante nunca a substitui; uma validade nova mais
  próxima avança-a sempre. (Regra de negócio intencional, não alterar.)

### Modo Reconciliar (só gestor+, depois de auditoria física)

- **Quantidade confirmada** (número, pré-preenchido com a quantidade atual).
- Lista de lotes com checkbox (todos pré-marcados como "confirmados");
  desmarcar um lote assinala que já não está fisicamente presente.
- **Confirmar** — grava o resultado da auditoria. (O estado dos lotes só é
  reconciliado neste momento — auditoria física, não automaticamente.)

### Modo Corrigir (qualquer utilizador com acesso ao carro)

- **Evento a corrigir** (menu suspenso com o histórico de eventos deste
  compartimento, pré-selecionado o mais recente).
- **Quantidade de ajuste** (número diferente de zero; por omissão sugere o
  inverso exato do evento escolhido, mas é editável).
- **Confirmar** — grava uma correção. **Importante**: uma correção nunca
  apaga nem altera o evento original — cria sempre um novo evento
  compensatório, mantendo o histórico completo e imutável.

---

## 12. Pesquisa de produto (dentro de um carro)

**Como se chega aqui:** botão de pesquisa no Detalhe do carro.

Campo de texto na própria barra de título — filtra em tempo real os produtos
já atribuídos neste carro, pelo nome. Tocar num resultado abre o mesmo
**Diálogo de atribuição/consumo** descrito acima, para esse compartimento.

---

## 13. Utilizadores responsáveis por um carro

**Como se chega aqui:** botão "Responsáveis" no Detalhe do carro (só
gestor+).

Lista todos os membros da instituição com uma checkbox: marcada = responsável
por este carro (o que lhe dá acesso mesmo sem ser gestor). Marcar/desmarcar
tem efeito imediato, sem confirmação. Um membro desativado não pode ser
marcado.

> Nota de negócio: pertencer à instituição não dá, por si só, acesso a um
> carro — um utilizador comum só vê os carros aos quais é explicitamente
> atribuído aqui. Gestores e administradores veem sempre todos os carros.

---

## 14. Membros da instituição

**Como se chega aqui:** botão "Membros" no painel (só institution admin ou
platform super admin).

Lista de membros com o respetivo papel e estado. Em cada membro (exceto o
próprio utilizador autenticado, que não tem menu sobre si mesmo), um menu
(⋮) com:
- **Mudar papel** — escolher entre Institution Admin / Manager / User.
- **Desativar / Reativar** — alterna o estado da associação (sem
  confirmação). Um membro desativado perde todo o acesso imediatamente.

### Botão flutuante

- **Adicionar membro** — abre o diálogo com **E-mail**, **Palavra-passe**
  (mínimo 6 caracteres) e **Papel**. Cria uma conta de autenticação nova de
  raiz — a palavra-passe tem de ser comunicada ao novo membro por fora da
  app (não existe convite por e-mail automático nesta versão).

---

## 15. Produtos (catálogo da instituição)

**Como se chega aqui:** botão "Produtos" no painel (só gestor+).

Lista simples de produtos (nome + descrição da unidade, se existir). As
linhas não são clicáveis — este ecrã não tem edição/remoção de produtos, só
consulta e criação.

### Botão flutuante

- **Criar produto** — pede **Nome** (obrigatório), **Descrição da unidade**
  (opcional) e **GTIN** (opcional, sem validação de formato).

---

## 16. Histórico e relatórios

**Como se chega aqui:** botão "Histórico" no painel. Disponível a qualquer
membro ativo (só consulta).

- Filtro por tipo de evento (Todos / Consumo / Reposição / Correção /
  Reconciliação de auditoria) — chips clicáveis.
- Lista dos últimos 100 eventos da instituição (produto, tipo, quantidade).

### Botões de ação (sobre a lista já filtrada)

- **Ver resumo** — abre um diálogo com totais agrupados por **Produto**,
  **Carro** ou **Período** (dia / semana a começar à segunda-feira / mês),
  mostrando consumido, reposto e outros ajustes (correções + reconciliações).
- **Exportar CSV** — mostra o texto CSV completo e um botão **Copiar** que o
  coloca na área de transferência (a app não escreve ficheiros no disco).
- **Exportar PDF** — gera um PDF e abre-o diretamente na caixa de
  impressão/partilha nativa do sistema operativo.

> Nota: as exportações (CSV/PDF) usam sempre rótulos fixos em português,
> independentemente do idioma escolhido na app.

---

## 17. Código QR do carro (mostrar)

**Como se chega aqui:** botão de QR no Detalhe do carro.

Ecrã só de leitura: mostra o nome do carro e a imagem do código QR interno
(para imprimir/colar no carro físico). Sem botões de ação.

## 18. Ler código QR de um carro

Abre a câmara (quando suportada) e lê continuamente até encontrar um QR
interno válido — nesse momento abre automaticamente o carro correspondente
(se o utilizador tiver acesso). Um código ilegível mostra um aviso e continua
a tentar. Botão **Cancelar** disponível a qualquer momento.

## 19. Ler código GS1 Data Matrix

Usado a partir do modo "Repor stock". Suporta dois tipos de leitor:
- **Câmara** — pré-visualização ao vivo.
- **Leitor USB/HID** (para Windows/desktop, sem câmara) — um campo de texto
  sempre em foco; o próprio leitor "escreve" o código seguido de Enter.

Um código não reconhecido mostra aviso e continua a aceitar novas leituras
(nunca bloqueia — a leitura é sempre opcional, a introdução manual está
sempre disponível). Botão **Cancelar e inserir manualmente** disponível a
qualquer momento.

---

## 20. Aviso de ligação

Não é um ecrã, é uma barra fina que aparece automaticamente no topo de
**qualquer** ecrã sempre que o dispositivo perde ligação à internet
("sem ligação à internet"), e desaparece sozinha quando a ligação volta. Os
dados já carregados continuam visíveis (cache local do Firestore); qualquer
ação feita offline fica em fila e é sincronizada automaticamente ao
reconectar.

---

## 21. Funcionalidades intencionalmente não implementadas

Para que não sejam confundidas com bugs, ficam aqui registadas as
funcionalidades da especificação original que **não têm** interface na app
atual (a camada de dados/lógica pode existir parcialmente, mas não está
ligada a nenhum ecrã):

- Fluxo guiado de auditoria periódica/mensal.
- Checklist diário.
- Ecrã dedicado de consulta ao registo de auditoria (`AuditRepository`
  existe no código mas não é chamado por nenhum ecrã).
- Galeria de modelos ("templates") de carro/gaveta reutilizáveis além da
  duplicação simples de um carro existente (secção 6/8 acima).

---

## 22. Regras de negócio que nunca devem ser "corrigidas"

Estas foram confirmadas nesta sessão de testes como comportamento
intencional, não bugs, mesmo que pareçam pouco convencionais:

1. O consumo diário nunca escolhe lote — só reduz a quantidade agregada.
2. A validade "mais próxima conhecida" é sempre conservadora (nunca recua).
3. O estado dos lotes só é reconciliado durante auditoria física.
4. Múltiplas emergências consecutivas não exigem sessões separadas.
5. A digitalização (QR ou GS1) nunca contorna permissões — só acelera a
   navegação/preenchimento.
6. Um produto pode existir em vários carros, mas só uma vez por carro.
7. A app nunca guarda dados identificáveis de doentes.
8. Medicamentos usam GS1 Data Matrix; a identificação interna do I-Crash
   (carros) usa QR code — não são o mesmo tipo de código nem são
   intercambiáveis.
