# I-Crash: design changes made in code (for Figma)

**Created 29 Oct 2026**, branch `DEV-Martim` (commits `301a9f8` … `fd24f23`). **For:** a later
Figma session. Figma itself was **not** edited.

The app was aligned with the database decisions of 28 Oct (`docs/DATABASE.md`,
`docs/OPEN_DECISIONS.md` §2b). This file lists every **visible** change the Figma file
`SN7TkBRDszbTFs8oR1uhPR` doesn't show yet, so the frames can be updated without reading
the code.

**How to read an entry**
- **Where:** screen, platform, and the frames and nodes, as `page: frame id → node ids`.
  Pages: **p10** App wireframes mobile (`421:267`), **p11** App wireframes tablet
  (`421:268`), **p12** App mockups mobile (`421:269`), **p13** App mockups tablet
  (`421:270`), **p20** Dashboard wireframes (`421:272`), **p21** Dashboard mockups
  (`421:273`), **p03** Componentes (`421:264`), **p04** Padrões e estados (`421:265`).
  Node ids beginning with `I` are inside a component instance.
- **Copy:** PT / EN, with the l10n key (`app/lib/l10n/app_pt.arb`, `app_en.arb`).
  `{x}` is a placeholder.
- **Status:** `to do` until the frame is updated.

Every frame id listed here was read from the file on 29 Oct 2026. The design changes, so
check the node again before editing it.

---

## Shared: components and patterns

### DC-01 · Drawer card shows "Gaveta N", not a name
- **Where:** p03 component set **Cartão de gaveta** `444:631` (variants Alertas=Nenhum /
  Atenção / Crítico; texts "1", "Via aérea", "5 × 7 · 35 posições · 32 com produto").
  Every A5 instance: p10 `455:425` → `455:455`, `455:464`, `455:473`, `455:482`;
  p11 `454:472` → `454:508`, `454:518`, `454:528`, `454:538`; p12 `451:608` →
  `I451:667;444:595`, `I451:683;444:621`, `I451:701;444:608`, `I451:717;444:595`;
  p13 `447:669` → `I447:729;444:595`, `I447:745;444:621`, `I447:763;444:608`,
  `I447:779;444:595`.
- **What:** the title line ("Via aérea") becomes **"Gaveta 1"**. The number badge on the
  left stays. Drawers are listed by their stored number.
- **Copy:** `drawerShort` "Gaveta {number}" / "Drawer {number}".
- **Components:** change it in the component (title text), then check the instances.
- **Why:** P17, drawers have a number and no name. `ui/features/cart/cart_screen.dart`,
  `cart_view_model.dart`.
- **Status:** to do

### DC-02 · Page header titles with a drawer use "Gaveta N" only
- **Where:** p03 **Cabeçalho de página** `436:706`; instances listed in DC-09 (A6), DC-14
  (A7), DC-17 (A8) and DC-26 (B4).
- **What:** "Gaveta 2 · Fármacos" becomes **"Gaveta 2"**. The component doesn't change,
  only the instance texts.
- **Copy:** `drawerShort` "Gaveta {number}" / "Drawer {number}".
- **Components:** frames only.
- **Why:** P17.
- **Status:** to do

### DC-03 · Shared error and lock messages (snackbars and notices)
- **Where:** p04 section **"Confirmação e retorno"** (inside `459:261`): add these to the
  message examples. They're used in A6, A7, B3 and B4.
- **What:** new messages shown in a snackbar after a refused action:

  | Key | PT | EN | When |
  |---|---|---|---|
  | `errorExceedsTarget` | A posição não pode ter mais unidades do que a quantidade alvo. | A position can't hold more units than its target quantity. | Replenish, correct, reconcile or place above the target (P5) |
  | `errorBelowZero` | A quantidade não pode ficar abaixo de 0. | The quantity can't go below 0. | A correction below 0 |
  | `errorTargetBelowCurrent` | A quantidade alvo não pode ser inferior ao stock atual. Registe primeiro o consumo ou uma correção. | The target can't be lower than the current stock. Record the consumption or a correction first. | B4, target lower than stock (Q6) |
  | `errorInvalidTarget` | A quantidade alvo tem de ser maior do que 0. | The target must be greater than 0. | — |
  | `errorQuantityRequired` | Indique uma quantidade maior do que 0. | Enter a quantity greater than 0. | A7 |
  | `slotTaken` | Esta posição já tem um produto. | This position already has a product. | Placing a product in an occupied slot |
  | `slotInUseHint` | Esta posição já tem histórico: mantém o seu produto e não pode ser limpa. A estrutura de um carrinho em uso não pode ser alterada. | This position already has history: it keeps its product and can't be cleared. The structure of a cart in use can't be changed. | P1, see DC-12 and DC-30 |
  | `drawerInUseHint` | Esta gaveta já tem histórico: a grelha não pode ser redimensionada, fundida nem dividida. Pode alterar a quantidade alvo das posições. | This drawer already has history: its grid can't be resized, merged or split. You can still change the positions' target quantities. | P1/P2, see DC-29 |
  | `drawerNumberTaken` | Já existe uma gaveta com este número neste carrinho. | This cart already has a drawer with this number. | B3 |
- **Components:** **Aviso** `431:442` is used for the in-panel notices (DC-18, DC-30, DC-33).
- **Why:** P5, Q6, P1/P2, P17. `ui/core/widgets/dialogs.dart` (`actionCodeText`).
- **Status:** to do

### DC-04 · Slot states: "Stock baixo" now means "below target"
- **Where:** p03 **Estado da posição** `431:376` (variant Estado=Stock baixo) and
  **Célula de posição** `442:629` (Estado=Stock baixo); p04 state legend, if any.
- **What:** no visual change. Only the meaning (and any annotation that mentions a
  minimum) changes: "Stock baixo" = fewer units than the target, but not 0. There's no
  minimum any more. The six states and their order are unchanged (expired > missing >
  expiring > low stock > ok; free).
- **Copy:** unchanged (`slotHealthLowStock` "Stock baixo" / "Low stock").
- **Components:** annotations only.
- **Why:** D10; the order is kept as Martim decided on 29 Oct (P4 sets the values later).
  `domain/inventory_health.dart` (`slotStatePriority`).
- **Status:** to do

### DC-05 · Profile menu: no "Definir PIN"; a credentials note
- **Where:** the Profile menu isn't drawn. It opens from **Nav · Perfil** in **Barra
  lateral · App** `436:586` (e.g. p13 `I447:413;436:523;436:343`) and from the profile
  area of **Barra lateral · Dashboard** `436:587`. App and Dashboard.
- **What:** remove "Definir PIN" / "Alterar PIN". In its place, a non-tappable row with
  an info icon and grey small text. The remaining items are: language, "Bloquear agora"
  (only when the device holds a PIN), switch institution, the debug shell switch, and sign
  out. A new frame for the menu is suggested.
- **Copy:** `credentialsContactAdmin` "Para alterar as suas credenciais, contacte a
  administração." / "To change your credentials, contact the administration."
- **Components:** none (dialog). Icon `Ícone/info` `430:483`.
- **Why:** DB3, credentials are set by the administration only. `ui/shells/profile_menu.dart`.
- **Status:** to do

---

## App: A1–A12

### DC-06 · A1: remove "Esqueci-me da palavra-passe"; add the credentials note
- **Where:** A1 · Iniciar sessão. p10 `455:263` (no link drawn; add the note under
  "Entrar"); p11 `454:263` → `454:284`; p12 `451:263` → `451:311`; p13 `447:263` →
  `447:289`. Phone and tablet.
- **What:** delete the "Esqueci-me da palavra-passe" link. Between "Entrar" and the
  "Desbloquear com PIN / Entrar no carro" row, add one line of small secondary text.
- **Copy:** `credentialsContactAdmin` "Para alterar as suas credenciais, contacte a
  administração." / "To change your credentials, contact the administration."
  (Removed keys: `loginForgotPassword`, `loginResetSent`, `loginResetNeedsEmail`.)
- **Components:** frames only.
- **Why:** DB3. `ui/features/auth/login_screen.dart`.
- **Status:** to do

### DC-07 · A2: the annotation still describes a device-only PIN
- **Where:** annotation texts next to A2: p10 `455:1091`, p11 `454:1528`, p12 `451:1964`,
  p13 `447:1162` ("Proposta (D3): o PIN desbloqueia…").
- **What:** no change to the screen. The note should now say that the PIN is **set by
  the administration in B7**; that the device keeps a copy of its hash after each online
  sign-in, so A2 still works offline; and that 5 wrong tries still drop the session. If
  the person has no PIN yet, A1 doesn't offer A2.
- **Copy:** unchanged on screen.
- **Components:** none.
- **Why:** DB3. `ui/app/app_root_view_model.dart`, `data/local/local_repositories.dart`.
- **Status:** to do

### DC-08 · A5: emergency mode entry hidden
- **Where:** A5 · Carrinho, "Menu do carro". p10 `455:425` → `455:500`; p11 `454:472` →
  `454:562` (help text), `454:565` (button); p12 `451:608` → `I451:760;431:289`; p13
  `447:669` → `447:841` (help), `I447:842;431:294` (button). Also p04 section "Modo mensal
  e modo de emergência" `459:338` (`459:340`, `I459:436;431:289`).
- **What:** the red "Modo de emergência" button and its help line no longer appear. The
  menu ends after "Relatórios do carro". (If an emergency session is already open on the
  device, "Retomar emergência" still shows.)
- **Copy:** none new.
- **Components:** frames only. Keep the A10 frames and the emergency components; they
  come back later.
- **Why:** P12, no emergency mode for now; Q5, hidden behind `kEmergencyModeEnabled`
  (`ui/features/cart/cart_screen.dart`).
- **Status:** to do

### DC-09 · A6: header without the drawer name
- **Where:** A6 · Gaveta. p10 `455:501` → `455:520`; p11 `454:566` → `454:593`; p12
  `451:775` → `I451:816;436:704`; p13 `447:857` → `I447:908;436:704`.
- **What:** "Gaveta 2 · Fármacos" becomes **"Gaveta 2"**. The panel line "Posição A5 ·
  Gaveta 2" (p11 `454:777`, p13 `447:1118`) is already correct.
- **Copy:** `drawerShort` "Gaveta {number}".
- **Components:** Cabeçalho de página (instance text).
- **Why:** P17.
- **Status:** to do

### DC-10 · A6 panel: remove the "Mínimo" row; lot may be "sem lote"
- **Where:** A6 panel **Painel · Posição** (p13 `447:1109`): "Mínimo" p11 `454:790`, p13
  `447:1131`; "Lote" row p11 `454:786`, p13 `447:1127`. Tablet only; the phone panel is
  compact and shows neither.
- **What:** delete the "Mínimo" row. The "Lote" row shows the first batch's lot and
  units, e.g. "A829 · 2 un.". A batch without a lot number shows **"sem lote · 2 un."**.
- **Copy:** `noLot` "sem lote" / "no lot"; `lotWithUnits` "{lot} · {units} un." /
  "{lot} · {units} units". (Removed: `minimumLabel`.)
- **Components:** frames only.
- **Why:** D10 (no minimum), P9 (lot optional). `ui/features/drawer/drawer_screen.dart`.
- **Status:** to do

### DC-11 · A6 panel: "Repor stock" disabled when the slot is full
- **Where:** A6 panel, "Repor stock" button: p13 `I447:1141;431:279`; same button in p11
  `454:566`.
- **What:** new **disabled** state for "Repor stock" when current = target (e.g.
  "4 de 4 unidades"). Suggest showing it next to a full slot.
- **Copy:** none.
- **Components:** **Botão** `431:305` secondary, disabled variant (check one exists).
- **Why:** P5, no overfill.
- **Status:** to do

### DC-12 · A6 panel: "Trocar produto" on a slot with history
- **Where:** A6 panel, "Trocar produto": p11 `454:802`, p13 `I447:1149;431:299`.
- **What:** when the slot's product has any history (consumption, replenishment,
  correction, reconciliation), tapping "Trocar produto" doesn't open the assign panel; it
  shows the snackbar `slotInUseHint`. Design option: draw the button disabled with a small
  lock, or keep it enabled and show the message (the code does the latter).
- **Copy:** `slotInUseHint` (DC-03).
- **Components:** Botão ghost; snackbar pattern.
- **Why:** P1, a used slot keeps its consumable.
- **Status:** to do

### DC-13 · A6 panels not drawn yet: correction, assign, reconcile
- **Where:** A6, tablet and phone. Opened from "Corrigir" (p13 `I447:1154;431:299`),
  "Atribuir / Trocar produto" and "Reconciliar". No frames exist; suggest one panel
  variant each, drawn like **Painel · Repor stock** (p13 `449:1174`).
- **What:**
  - **Corrigir:** list of the slot's last events (radio), an "Ajuste (positivo ou
    negativo)" stepper whose limits keep the slot within 0 … target, and a **new text
    field "Motivo (opcional)"** with a hint. Max 500 characters.
  - **Atribuir produto:** product search and list, "Quantidade alvo" stepper (min 1),
    "Quantidade inicial" stepper with **max = target**.
  - **Reconciliar:** "Quantidade confirmada fisicamente" stepper with **max = target**,
    and the batch checkboxes ("Lote A829 · 28/10/2026", or "sem lote · 28/10/2026").
    Batches left unticked are marked removed, not deleted.
- **Copy:** `correctionReasonLabel` "Motivo (opcional)" / "Reason (optional)";
  `correctionReasonHint` "ex.: registado na posição errada" / "e.g. recorded in the wrong
  position"; `adjustmentLabel` "Ajuste (positivo ou negativo)"; `initialQuantityLabel`
  "Quantidade inicial"; `confirmedQuantityLabel` "Quantidade confirmada fisicamente";
  `noLot`, `batchLotLabel` "Lote {lotNumber}".
- **Components:** **Campo** `442:520` (Normal/Foco/Erro), **Quantidade** `442:652`,
  **Caixa de verificação** `442:648`.
- **Why:** HISTORY `reason`, P5, DB1. `ui/features/drawer/drawer_screen.dart`.
- **Status:** to do

### DC-14 · A7: lot optional; quantity up to the target; header without the name
- **Where:** A7 · Repor stock. Header: p10 `455:638` → `455:657`; p11 `454:806` →
  `454:833`; p12 `451:1045` → `I451:1086;436:704`; p13 `449:929` → `I449:982;436:704`.
  Lot field: p10 `455:767`; p11 `454:1026`; p12 `I451:1296;442:508`; p13
  `I449:1193;442:508`. Expiry field p13 `I449:1204;442:508`.
- **What:**
  - The field label "Lote" becomes **"Lote (opcional)"**; an empty lot is accepted.
  - The expiry date stays **required** (error: `replenishMissingExpiry`).
  - The quantity stepper can't go above **target − current**, and the default is that
    value.
  - The help text "Leia o Data Matrix…" is unchanged.
  - A month-only GS1 expiry is pre-filled as the **last day of the month** (e.g.
    30/06/2026).
  - The header loses the drawer name (DC-02).
- **Copy:** `lotOptionalLabel` "Lote (opcional)" / "Lot (optional)";
  `replenishMissingExpiry` "Indique a validade do lote." / "Enter the batch's expiry
  date."; `errorQuantityRequired`, `errorExceedsTarget` (DC-03). (Removed:
  `lotRequiredValidation` "Indique o lote".)
- **Components:** Campo (frame only).
- **Why:** P9, P5, P11, P17. `ui/features/drawer/drawer_screen.dart`,
  `services/gs1_data_matrix_parser.dart`.
- **Status:** to do

### DC-15 · A5 product search: result line without a drawer name
- **Where:** A5 › "Pesquisar produto" dialog (not drawn). Button p13 `I447:805;431:279`.
- **What:** each result reads "Gaveta 2 · posição B3" (was "Gaveta 2 · Fármacos ·
  posição B3").
- **Copy:** `productLocation` "Gaveta {number} · posição {position}" / "Drawer {number} ·
  position {position}".
- **Components:** none.
- **Why:** P17. `ui/features/cart/product_search_dialog.dart`.
- **Status:** to do

### DC-16 · A11: the "Repor este produto" pre-fill follows A7
- **Where:** A11 · Ler código. p10 `455:982` → `455:1009`; p11 `454:1360` → `454:1393`;
  p12 `451:1711` → `451:1777`; p13 `449:1688` → `449:1755`.
- **What:** no layout change. A code without a lot shows only the GTIN and expiry; a
  month-only expiry shows the last day of the month.
- **Copy:** unchanged.
- **Components:** none.
- **Why:** P9, P11.
- **Status:** to do (check only)

### DC-17 · A8: subtitle and summary without the drawer name
- **Where:** A8 · Verificação mensal. p10 `455:778` → `455:800`; p11 `454:1042` →
  `454:1069`, `454:1130`; p12 `451:1317` → `I451:1363;436:705`; p13 `449:1225` →
  `I449:1271;436:705`, `449:1349`.
- **What:** the subtitle becomes "Carro Urgência 1 · Gaveta 2 (2 de 4)", and the summary
  title "Gaveta 2". The rest of A8 is unchanged; the flagged-batches rewrite (D4) is a
  separate task.
- **Copy:** `monthlyCheckSubtitle` "{cart} · Gaveta {number} ({index} de {total})" /
  "{cart} · Drawer {number} ({index} of {total})"; `drawerShort`.
- **Components:** Cabeçalho de página (instance).
- **Why:** P17.
- **Status:** to do

### DC-18 · A9: only the person who did the check signs
- **Where:** A9 · Relatório — assinar, sign panel: p10 `455:844` → `455:887`, `455:893`,
  `455:899`; p11 `454:1155` → `454:1209`, `454:1216`, `454:1222`; p12 `451:1439` →
  `451:1522`, `I451:1528;442:508`, `I451:1533;431:269`; p13 `449:1380` → `449:1469`,
  `I449:1471;442:640`, `I449:1476;442:508`, `I449:1481;431:274`.
- **What:** **new state** for anyone who isn't the report's author: the panel shows the
  title "Assinar relatório", an **info notice** (no checkbox, no PIN field, no "Assinar"
  button), and "Descarregar PDF". The author sees the current panel.
- **Copy:** `signOnlyAuthorTitle` "Só quem fez a verificação pode assinar" / "Only the
  person who did the check can sign"; `signOnlyAuthorMessage` "Este relatório é assinado
  por {name}, que fez a verificação." / "This report is signed by {name}, who did the
  check."
- **Components:** **Aviso** `431:442` (info).
- **Why:** DB4. `ui/features/reports/report_screen.dart`.
- **Status:** to do

### DC-19 · A9: no PIN yet → ask the administration
- **Where:** A9 sign panel (as DC-18).
- **What:** if the author has no PIN, "Assinar" shows a snackbar; there's no "set PIN"
  dialog any more.
- **Copy:** `signNeedsAdminPin` "Ainda não tem PIN. Peça à administração que lhe atribua
  um para poder assinar." / "You don't have a PIN yet. Ask the administration to set one
  so you can sign." (Removed: `signNeedsPin`.)
- **Components:** snackbar pattern.
- **Why:** DB3.
- **Status:** to do

---

## Dashboard: B1–B9

### DC-20 · B3: drawers table without "Nome"; "Alterar número"
- **Where:** B3 · Carrinho — configuração, "Gavetas (4)" table. p20 `458:634` → header
  `458:726` (Nome), rows `458:735`, `458:750`, `458:765`, `458:780`; p21 `456:884` →
  header `456:1040` (Nº), `456:1041` (Nome), rows `456:1050`, `456:1071`, `456:1092`,
  `456:1113`, "Editar grelha" `I456:1058;431:279` etc.
- **What:**
  - Delete the **Nome** column.
  - The **Nº** column, now wider, shows "Gaveta 1", "Gaveta 2"…
  - Before "Editar grelha", add an icon button **"Alterar número"** (pencil). It's
    **disabled** on a drawer that has history, unless the drawer never had a number.
- **Copy:** `drawerShort`; `editDrawerNumber` "Alterar número" / "Change number"
  (tooltip); success `drawerNumberSaved` "Número da gaveta alterado." / "Drawer number
  changed."
- **Components:** frames only; icon button like other `Ícone/editar` `430:436` uses.
- **Why:** P17, Q8. `ui/features/dashboard/cart_config_screen.dart`.
- **Status:** to do

### DC-21 · B3: "Adicionar gaveta" asks for a number, not a name
- **Where:** B3, button "Adicionar gaveta" p21 `I456:1031;431:279`. The dialog isn't drawn.
- **What:** dialog "Adicionar gaveta" with:
  1. **"Número da gaveta"** stepper (1–99; default = lowest free number), with a help
     line below. When the number is already used, the line turns red and shows the error,
     and "Criar" is disabled.
  2. "Linhas" and "Colunas" steppers (1–12, default 5 × 6).
  3. "Cancelar" / "Criar".

  The drawer is created with one position per cell.

  Also draw a small **"Alterar número"** dialog: the number stepper with the same
  help/error line, "Cancelar" / "Guardar".
- **Copy:** `addDrawer` "Adicionar gaveta"; `drawerNumberLabel` "Número da gaveta" /
  "Drawer number"; `drawerNumberHelp` "O número impresso no carrinho (1 = em cima). Não
  pode repetir-se no mesmo carrinho." / "The number printed on the cart (1 = top). It
  can't repeat within a cart."; `drawerNumberTaken` (DC-03); `createDrawerRowsLabel`
  "Linhas"; `createDrawerColumnsLabel` "Colunas"; `actionCreate` "Criar"; `actionSave`
  "Guardar". (Removed: `drawerNameHint` "ex.: Fármacos".)
- **Components:** **Quantidade** `442:652`.
- **Why:** P17. `ui/features/dashboard/drawer_form_dialog.dart`.
- **Status:** to do

### DC-22 · B4: header without the drawer name
- See **DC-26**.

### DC-23 · B4 position panel: remove "Mínimo"
- **Where:** B4 · Editor de grelha, panel "Posição C6": p20 `458:791` → `458:1016`; p21
  `456:1130` → `456:1483` (between "Quantidade alvo" `456:1468` and "Aviso de validade"
  `I456:1494;442:508`).
- **What:** delete the "Quantidade mínima" stepper row.
- **Copy:** removed `minimumQuantityLabel`.
- **Components:** frames only.
- **Why:** D10.
- **Status:** to do

### DC-24 · B4: new text for the "ask for lot" checkbox
- **Where:** p20 `458:1031`; p21 `I456:1498;442:640`.
- **What:** text only. The checkbox stays always on and read-only.
- **Copy:** `askLotOnReplenish` "Pedir validade (e lote, se existir) na reposição" / "Ask
  for expiry (and lot, if any) on replenishment" (was "Pedir lote e validade na
  reposição").
- **Components:** Caixa de verificação (instance text).
- **Why:** P9.
- **Status:** to do

### DC-25 · B4: lowering the target below the stock is refused
- **Where:** B4 position panel, "Aplicar à posição" `I456:1504;431:274`.
- **What:** a snackbar with `errorTargetBelowCurrent` (DC-03). There's no new element.
- **Why:** Q6.
- **Status:** to do (message example)

### DC-26 · B4: header "Gaveta N"
- **Where:** p20 `458:841`; p21 `I456:1224;436:704`.
- **What:** "Gaveta 2 · Fármacos" becomes "Gaveta 2".
- **Copy:** `drawerShort`.
- **Components:** Cabeçalho de página (instance).
- **Why:** P17.
- **Status:** to do

### DC-27 · B4: target-only editing on a used slot is still allowed
- (Covered in DC-30.)

### DC-28 · B4: orphan "Remover" disabled when the orphan has history
- **Where:** B4, orange "sem posição" block under the grid (not drawn).
- **What:** for an orphan placement with history, **"Remover"** is disabled;
  "Reatribuir" stays (a repair for old data).
- **Copy:** unchanged (`actionRemove`, `actionReassign`).
- **Components:** Botão ghost disabled.
- **Why:** Q7. `ui/features/dashboard/grid_editor_screen.dart`.
- **Status:** to do

### DC-29 · B4: locked layout once the drawer has history
- **Where:** B4 toolbar: p21 `456:1130` → "Linhas" `I456:1233;442:508`, "Colunas"
  `I456:1237;442:508`, "Juntar posições" (merge button), "Dividir" `I456:1251;431:279`, and
  the hint line under the toolbar; p20 `458:791` → `458:845`, `458:849`, `458:858`.
- **What:** **new locked state**:
  - the Linhas/Colunas steppers are shown but can't change (both +/− disabled);
  - "Juntar posições" and "Dividir" are disabled;
  - the grey hint "Toque numa posição…" is replaced by an **amber** text line,
    `drawerInUseHint`;
  - "Guardar grelha" stays disabled (nothing can change).

  Positions can still be selected to edit their target.
- **Copy:** `drawerInUseHint` (DC-03). Hint it replaces: `gridSelectionHint` "Toque numa
  posição para a configurar. Toque em várias para as juntar."
- **Components:** Quantidade (disabled), Botão secondary disabled.
- **Why:** P1/P2. `grid_editor_screen.dart`, `grid_editor_view_model.dart`
  (`layoutLocked`).
- **Status:** to do

### DC-30 · B4 position panel: a used slot keeps its product
- **Where:** p21 panel "Posição C6" `456:1460` (product picker card, "Limpar posição"
  `I456:1260;431:299` in the toolbar); p20 `458:861`.
- **What:** **new state**:
  - at the top of the panel, a **warning notice** with title `slotInUse` and message
    `slotInUseHint`;
  - the product card isn't tappable (no picker);
  - "Limpar posição" is **disabled**;
  - "Quantidade alvo" and "Aviso de validade" stay editable, and "Aplicar à posição"
    works.
- **Copy:** `slotInUse` "Posição em uso" / "Position in use"; `slotInUseHint` (DC-03).
- **Components:** **Aviso** `431:442` (warning).
- **Why:** P1.
- **Status:** to do

### DC-31 · B5: GTINs shown with 14 digits
- **Where:** B5 · Catálogo, GTIN column p21 `456:1636`, search `I456:1618;442:528`; p20
  `458:1104`.
- **What:** no layout change. A GTIN typed or imported as EAN-13 ("5601234567890") is
  saved and shown as 14 digits ("05601234567890"). The GTIN field still accepts 8 or
  12–14 digits.
- **Copy:** unchanged.
- **Why:** P16. `domain/gtin.dart`, `catalog_view_model.dart`.
- **Status:** to do (sample data only)

### DC-32 · B6: "Ativos / Arquivados" tabs
- **Where:** B6 · Modelos. p20 `458:1245`; p21 `456:1801`, between the page header
  (`I456:1889;436:696`) and the template list.
- **What:**
  - New **tabs**, "Ativos (n)" and "Arquivados (n)". The list shows the current tab.
  - Empty archived tab: "Não há modelos arquivados."
- **Copy:** `templatesTabActive` "Ativos ({count})" / "Active ({count})";
  `templatesTabArchived` "Arquivados ({count})" / "Archived ({count})";
  `templatesArchivedEmpty` "Não há modelos arquivados." / "There are no archived
  templates."
- **Components:** **Separador** `442:680`.
- **Why:** P3, templates are archived, never deleted.
  `ui/features/dashboard/templates_screen.dart`.
- **Status:** to do

### DC-33 · B6 preview: "Arquivar modelo" and the archived state
- **Where:** B6 preview panel: "Criar carrinho a partir deste modelo" p21
  `I456:1956;431:274`, p20 `458:1342`; "Editar modelo" p21 `I456:1963;431:279`, p20
  `458:1345`.
- **What:**
  - **Active template:** next to "Editar modelo", an **icon button "Arquivar modelo"**
    (archive icon). It asks for confirmation first (not destructive).
  - **Archived template:**
    - the panel shows an **info notice** instead of "Criar carrinho a partir deste
      modelo";
    - the archive icon becomes a **"Restaurar"** button;
    - "Editar modelo" and "Duplicar" still work.
- **Copy:** `archiveTemplate` "Arquivar modelo" / "Archive template";
  `archiveTemplateConfirm` "Arquivar o modelo “{name}”? Deixa de aparecer ao criar
  carrinhos; os carrinhos já criados não mudam. Pode restaurá-lo mais tarde." / "Archive
  the template “{name}”? It won't be offered when creating carts; carts already created
  don't change. You can restore it later."; `templateArchived` "Modelo arquivado." /
  "Template archived."; `restoreTemplate` "Restaurar" / "Restore"; `templateRestored`
  "Modelo restaurado." / "Template restored."; `templateArchivedTitle` "Modelo arquivado"
  / "Template archived"; `templateArchivedMessage` "Não pode ser usado para criar
  carrinhos. Restaure-o para voltar a usá-lo." / "It can't be used to create carts.
  Restore it to use it again." (Removed: `deleteTemplate`, `deleteTemplateConfirm`,
  `templateDeleted`. Figma had no delete button.)
- **Components:** Botão secondary; Aviso (info); icon `Ícone/arquivar` `430:441`.
- **Why:** P3.
- **Status:** to do

### DC-34 · B6 preview: drawer list without names
- **Where:** p20 `458:1323`, `458:1327`, `458:1331`, `458:1335`; p21 `456:1939`,
  `456:1943`, `456:1947`, `456:1951`.
- **What:** "1 · Via aérea" becomes **"Gaveta 1"**. The size text on the right is
  unchanged.
- **Copy:** `drawerShort`.
- **Components:** frames only.
- **Why:** P17.
- **Status:** to do

### DC-35 · B2/B6: archived templates aren't offered for new carts
- **Where:** B2 "Novo carrinho" › from a template (dialog not drawn), and B6 "Criar
  carrinho a partir deste modelo".
- **What:** the template dropdown lists only active templates.
- **Why:** P3.
- **Status:** to do (if the dialog gets drawn)

### DC-36 · B7: "Criar utilizador" replaces "Convidar utilizador"
- **Where:** B7 · Utilizadores e permissões, header button: p20 `458:1346` → `458:1388`;
  p21 `456:1969` → `I456:2051;431:269`.
- **What:** the button label becomes **"Criar utilizador"**. New dialog (not drawn):
  - "Nome", "E-mail", "Tipo de utilizador" (dropdown);
  - **"Palavra-passe"** and **"Repetir palavra-passe"** side by side (obscured, min 8);
  - **"PIN"** and **"Repetir PIN"** side by side (4 digits, obscured);
  - a note;
  - "Cancelar" / "Criar utilizador".

  Field errors appear under each field. On success:
  "Utilizador criado: {email}. Entregue-lhe a palavra-passe e o PIN."
- **Copy:** `createUser` "Criar utilizador" / "Create user"; `fieldName`, `fieldEmail`,
  `columnUserType`; `loginPasswordLabel` "Palavra-passe" / "Password";
  `passwordRepeatLabel` "Repetir palavra-passe" / "Repeat password"; `pinLabel` "PIN";
  `pinRepeatLabel` "Repetir PIN" / "Repeat PIN"; `passwordTooShort` "A palavra-passe tem
  de ter pelo menos {min} caracteres" / "The password must have at least {min}
  characters"; `passwordMismatch` "As palavras-passe não coincidem" / "The passwords don't
  match"; `pinFourDigits` "O PIN tem 4 dígitos"; `pinMismatch` "Os PIN não coincidem";
  `createUserNote` "Entregue a palavra-passe e o PIN à pessoa. Só a administração os pode
  alterar; a pessoa não os pode mudar." / "Hand the password and PIN to the person. Only
  the administration can change them; the person can't."; `userCreated`
  "Utilizador criado: {email}. Entregue-lhe a palavra-passe e o PIN." / "User created:
  {email}. Hand over their password and PIN."; `emailTaken`. (Removed: `inviteUser`,
  `inviteNote`, `sendInvite`, `inviteSent`.)
- **Components:** **Campo** `442:520` (Normal/Erro), Botão primary.
- **Why:** DB3. `ui/features/dashboard/users_screen.dart`.
- **Status:** to do

### DC-37 · B7 member menu: "Definir novo PIN" and "Redefinir palavra-passe"
- **Where:** B7 table row "⋯" menu (not drawn). Rows in p21 `456:1969` (status pills
  `456:2101` …).
- **What:**
  - Menu items: "Alterar tipo de utilizador", "Desativar"/"Reativar", **"Definir novo
    PIN"**, **"Redefinir palavra-passe"**. "Reenviar e-mail de acesso" is gone.
  - **Definir novo PIN** opens a dialog titled "Novo PIN para {name}", with "Novo PIN
    (4 dígitos)", "Repetir PIN", a note, and "Cancelar" / "Guardar".
  - **Redefinir palavra-passe** opens an info dialog with the support message and a
    "Fechar" button.
  - The menu doesn't exist on your own row (unchanged).
- **Copy:** `setNewPin` "Definir novo PIN" / "Set new PIN"; `setNewPinFor` "Novo PIN para
  {name}" / "New PIN for {name}"; `pinNewLabel`; `pinRepeatLabel`; `setPinNote` "O novo
  PIN passa a valer num tablet na próxima vez que a pessoa entrar nele com ligação à
  rede." / "The new PIN takes effect on a tablet the next time the person signs in on it
  while online."; `pinSetFor` "PIN de {name} alterado. Entregue-lhe o novo PIN." /
  "{name}'s PIN changed. Hand over the new PIN."; `resetPasswordAction` "Redefinir
  palavra-passe" / "Reset password"; `resetPasswordSupport` "Nesta versão, a
  palavra-passe de outra pessoa não pode ser alterada a partir da aplicação. Peça ao
  suporte técnico (departamento de informática) que a redefina." / "In this version,
  another person's password can't be changed from the app. Ask technical support (the IT
  department) to reset it."; `actionClose` "Fechar". (Removed: `resendInvite`.)
- **Components:** Campo; Botão.
- **Why:** DB3, Q4.
- **Status:** to do

### DC-38 · B7: "Convites pendentes" and "Convite pendente" are legacy
- **Where:** p20 `458:1406` (tab), `458:1486` (pill); p21 `I456:2080;442:677`, `456:2161`.
- **What:** new users are created **active**, and invitations no longer exist. The code
  now shows the "Convites pendentes" tab **only when its count is above 0** (members
  invited before 29 Oct 2026); the pill stays for those rows. Remove both from the mockups,
  or show them as the legacy case.
- **Copy:** `usersFilterInvited` "Convites pendentes ({count})" (still in code).
- **Why:** DB3.
- **Status:** to do (decision for the Figma session)

### DC-39 · B9: correction reason in the event list and the CSV
- **Where:** B9 · Relatórios e histórico, events tab: p21 `456:2587`, p20 `458:1848`. Rows
  use **Linha de evento** `444:696`.
- **What:** a correction row's subtitle ends with its reason:
  "Carro 1 › Gaveta 2 › B3 · Ana Silva · registado na posição errada". The CSV export
  gains a last column, **Motivo**.
- **Copy:** CSV header "Motivo" (exports are always PT).
- **Components:** Linha de evento (example instance).
- **Why:** DATABASE.md HISTORY `reason`.
- **Status:** to do

### DC-40 · B7: permissions panel 380 px wide
- **Where:** B7 right-hand "Permissões" panel: p21 `456:1969` → `456:2187` and its
  checkboxes (`I456:2199;442:640` …); p20 `458:1346`. Tablet and desktop.
- **What:**
  - The panel is **380 px** wide in code (was 320). At 320 px the "Profissional de
    saúde / Gestor" tabs needed a sideways scroll and the wrapped labels overflowed
    (found by the layout test). The users table takes the remaining width.
  - The grey note under the checkboxes moved into an **info icon tooltip** next to the
    "Permissões" title, so the panel fits a 1280 × 800 tablet without scrolling.
- **Copy:** unchanged (`permissionsNote` "Proposta (D2). As permissões ficam guardadas
  neste dispositivo até existir suporte no servidor." / "Proposal (D2). Permissions are
  stored on this device until the server supports them.").
- **Components:** Separador `442:680`, Caixa de verificação `442:648` (frame only).
- **Why:** layout rule (no scrolling on tablet or desktop). `users_screen.dart`.
- **Status:** to do

---

## 30 Oct 2026 device review (`docs/REVIEW_2026-10-30.md`)

Frame ids read on 30 Oct 2026.

### DC-41 · A1 on phones: fields side by side, 460 px form everywhere (RV-5, RV-6)
- **Where:** A1 p12 `451:263` (already matches: brand 280, fields in one row, form 460);
  p13 `447:263` → `447:272` (form 400 wide, buttons `447:291`/`447:300` 194 wide); p10/p11
  wireframes.
- **What:**
  - Phones now match p12: brand panel **280 px**, e-mail and password **side by side**,
    smaller gaps, "Entrar" button 48 high. The form fits an iPhone 16 without scrolling.
  - Tablets: the form is **460 px** wide (was 400), so "Desbloquear com PIN" and "Entrar
    no carro" each get about 224 px. At 194 px "Desbloquear com PIN" is cut. Update p13
    to 460 / 224 px.
- **Copy:** unchanged.
- **Components:** Botão (frame only).

### DC-42 · App rail grows by the notch inset (RV-14)
- **Where:** component **Barra lateral · App** (every A-frame, e.g. p12 `451:399`).
- **What:** on a landscape iPhone the rail is 72 px **plus the safe-area inset** (59 px
  on an iPhone 16), so its icons keep their width beside the notch. The content keeps
  out of the home indicator (21 px at the bottom). Figma frames have no notch, so
  nothing to draw; note it on the component.

### DC-43 · A5 drawer row: state at the right end; one-line grid text (RV-13, RV-22 part)
- **Where:** component **Cartão de gaveta** `444:631`; A5 p12 `451:608` → `451:667` …,
  p13 `447:669` → `447:729` ….
- **What:**
  - The state line (e.g. "1 expirado · 2 em falta") and the arrow are **right-aligned**
    at the end of the row, not in the middle.
  - The grid line ("5 × 7 · 35 posições · 32 com produto") stays on **one line**: when
    the long form doesn't fit (iPad mini) it shows the short form "5 × 7 · 35 posições".
  - Phones: no grid line; the state line gets more room and may take two lines.
  - The drawer's optional name comes in phase 4 (D20).
- **Copy:** `drawerGridLong`, `drawerGridShort` (unchanged).

### DC-44 · Side panels scroll on phones (A8, A9) (RV-7–RV-9)
- **Where:** A8 p12 `451:1317` → `451:1414`; A9 p12 `451:1439` → `451:1521`.
- **What:** on phones the right-hand panel scrolls vertically when its content is taller
  than the screen; its bottom actions follow the content instead of being pinned to the
  bottom. Tablets unchanged. A8's last-drawer button reads **"Concluir"** on phones.
- **Copy:** new `finishCheckShort` "Concluir" / "Finish".
- **Note:** A8 is rewritten in phase 5 (D22), which replaces this frame.

### DC-45 · A5 cart menu: no QR; same actions on phones; reports open the Relatórios section (RV-10, RV-12, RV-21)
- **Where:** A5 "Menu do carro": p12 `451:608` → `451:730`; p13 `447:669` (menu frame);
  p10/p11 wireframes.
- **What:**
  - **"Mostrar código QR" is removed** from the App. The cart's QR is printed or saved
    from **B3** (DC-46).
  - Phones show **"Alterar estado"** and **"Relatórios do carro"** like tablets; the menu
    scrolls if needed. On phones the "Responsável no turno: {name}" line moves from the
    header into the menu.
  - "Relatórios do carro" switches the rail to **Relatórios** (highlighted) and lists that
    cart's reports; back returns to the cart.
- **Copy:** unchanged (`cartReportsAction`, `changeStateAction`, `responsibleOnShift`).

### DC-46 · B3: "Código QR" button (RV-21)
- **Where:** B3 header: p21 `456:884`, p20 B3 wireframe.
- **What:** a secondary button **"Código QR"** (icon qr) before "Arquivar carro" opens the
  cart code dialog (QR, readable code, **Imprimir**), to stick the code on the cart.
- **Copy:** `qrCodeShort` "Código QR" / "QR code".

### DC-47 · A6 panel: no "Corrigir" / "Reconciliar"; "Trocar produto" on phones; closes after a consumption (RV-11, RV-23, D23)
- **Where:** A6 "Painel · Posição": p12 `451:775` → `451:1017`; p13 `447:857` (panel).
- **What:**
  - **"Corrigir" and "Reconciliar" are removed** (D23, P15: a signed report never
    changes, no correction events). Their panels are gone.
  - "Trocar produto" is a full-width ghost button under "Repor stock", on phones too.
  - After **"Confirmar consumo"** the panel closes (with the success message).
- **Copy:** unchanged.

### DC-48 · Scan sheet: "Cancelar" + "Inserir manualmente" (RV-24)
- **Where:** the "Ler GTIN da embalagem" dialog opened from A6/A7 and B5 (no frame yet;
  p04 scanner pattern if any).
- **What:** two buttons, **"Cancelar"** and **"Inserir manualmente"**. The second replaces
  the camera with a field "GTIN ou código GS1" and a **"Confirmar"** button.
- **Copy:** new `scanEnterManually` "Inserir manualmente" / "Enter manually";
  `scanManualProductLabel`, `actionConfirm`, `actionCancel`.

### DC-49 · A11 inside a cart: consumables only (RV-26)
- **Where:** A11 p12 `451:1711` → `451:1769` (tabs "Tipo"); p13 A11.
- **What:** when the person is inside a cart (cart login, or a cart open in Carrinhos), the
  **Consumível / Carro tabs are hidden** and reading a cart code shows "Dentro de um carro só
  pode ler consumíveis."
- **Copy:** new `scanOnlyConsumables` / "Inside a cart you can only scan consumables."

### DC-50 · Profile menu: App shows only lock and sign out; language on A1 (RV-15)
- **Where:** Profile menu (no frame; p04 if drawn); A1 p12 `451:263` → `451:272`, p13
  `447:263` → `447:273`.
- **What:**
  - App: the menu shows the user, the credentials note, **Bloquear agora** and **Terminar
    sessão**. "Mudar de instituição" only for Super (D16, D18); the shell switch only in
    debug builds.
  - Dashboard: the **language** switch stays in the menu.
  - A1: a **PT / EN** switch sits on the right of "Iniciar sessão".
- **Copy:** `languagePortuguese`, `languageEnglish` (unchanged).

### DC-51 · "Produto" → "Consumível" everywhere (D19)
- **Where:** every frame and component with "Produto(s)" / "produto": A4–A11, B1–B9,
  p03 components (e.g. Cartão de gaveta "… com produto", Estado da posição), p04 patterns.
- **What:** short form **Consumível / Consumíveis**; long form **Consumível clínico /
  Consumíveis clínicos** for the catalogue title (B5) and the "new" dialog. Examples:
  "Trocar consumível", "Atribuir consumível", "Pesquisar consumível", "Repor este
  consumível", "Consumíveis sem posição", "… com consumível", A11 tab "Consumível", B1
  "Consumíveis mais usados" (was "Produtos mais consumidos"). EN: "Consumable(s)",
  "Clinical consumables".
- **Copy:** 48 PT / 50 EN strings in the ARB files; CSV column "Consumível".

### DC-52 · Drawers have an optional name again (D20, RV-22)
- **Where:** component **Cartão de gaveta** `444:631` (title text); A5 p12 `451:608`, p13
  `447:669`; A6/B4 page titles; A8 panel title; B3 drawers table and "Adicionar gaveta"
  dialog (p21 `456:884`); B6 template drawer list (p21 `456:1801`). Reverses DC-01's
  "Gaveta N" title where a name exists.
- **What:**
  - A5 row: number badge, then the **name** (e.g. "Via aérea"); "Gaveta N" only when the
    drawer has none.
  - A6, B4, A8 titles: **"Gaveta 2 · Via aérea"** (or "Gaveta 2").
  - B3: new column **"Nome"** ("—" when empty); "Adicionar gaveta" has **"Nome (opcional)"**
    (hint "Ex.: Via aérea", max 50); the row's edit button opens **"Editar gaveta"**:
    number (only while allowed, else a locked note) and name (always).
- **Copy:** new `columnName` "Nome"/"Name", `drawerNameLabel` "Nome (opcional)"/"Name
  (optional)", `drawerNameHint` "Ex.: Via aérea"/"E.g. Airway", `editDrawer` "Editar
  gaveta"/"Edit drawer", `drawerSaved` "Gaveta guardada."/"Drawer saved.",
  `drawerNumberLocked` "Esta gaveta já tem histórico: o número não pode mudar. O nome
  pode." / "This drawer already has history: its number can't change. Its name can."

### DC-53 · A8 rebuilt as "Gestão mensal" (D22, D23, RV-16–RV-18)
- **Where:** A8 all pages: p12 `451:1317`, p13 `449:1225`, p10/p11 wireframes. Replaces
  DC-17 and DC-44's A8 part. Frame needs redrawing.
- **What:**
  - Lists only **expired and expiring lots**, one drawer per step (progress bar = drawers
    with something to handle; a finished step turns green).
  - Row: state icon (alerta red / relógio amber), consumable name, "Expirado · A1 · Lote L1 ·
    expira a 12/10/2026", and on the right **"Por resolver"** or the outcome with a green
    tick. No checkboxes, no "Marcar restantes", no "Guardar e sair" (everything autosaves).
  - Tapping a row opens a dialog: state line, outcome tabs (**Substituído / Retirado sem
    reposição** for expired; **Mantido / Substituído** for expiring), units stepper, **Nova
    validade** and **Lote (opcional)** for Substituído, a warning "Ao confirmar, o stock do
    carro é atualizado…", buttons Cancelar / Confirmar (and "Limpar resposta" for Mantido).
  - Right panel: drawer title ("Gaveta 1 · Via aérea"), "N por resolver", "N resolvidos",
    help line, Adicionar nota, **Gaveta seguinte** / **Concluir e gerar relatório**
    ("Concluir" on phones), Gaveta anterior.
  - Empty cart state: "Nada expirado nem a expirar neste carro."
  - Cart menu: **"Retomar verificação"** when a check was left half-way.
- **Copy:** new keys `checkOutcomeReplaced`, `checkOutcomeRemoved`, `checkOutcomeKept`,
  `checkPendingLabel`, `checkToHandle`, `checkHandled`, `checkOnlyFlaggedHelp`,
  `checkNothingToHandle`, `checkStepSubtitle`, `checkStockWarning`, `checkKeptHelp`,
  `checkRemovedHelp`, `checkNewExpiryLabel`, `checkClearAnswer`, `resumeCheck`.

### DC-54 · A9: "Lotes tratados", leave prompt, badges, PIN spacing (RV-19, RV-20, RV-25)
- **Where:** A9 p12 `451:1439`, p13 `449:1380`; rail component "Barra lateral · App"
  (Relatórios item); A5 cart menu.
- **What:**
  - Monthly report list title **"Lotes tratados (N)"**, one line per lot with drawer,
    position, lot, expiry and outcome.
  - Leaving a report you still have to sign: dialog **"Relatório por assinar"** — "Este
    relatório ainda não está assinado. Pode assiná-lo mais tarde em Relatórios → Por
    assinar." [Sair] [Assinar agora].
  - A red **count badge** on the Relatórios rail icon; "Relatórios do carro (N)".
  - 16 px between the PIN field and "Assinar".
- **Copy:** `checkLotsTitle`, `leaveUnsignedTitle`, `leaveUnsignedMessage`,
  `leaveUnsignedExit`, `leaveUnsignedSignNow`.

### DC-55 · User types Super / Admin / Gestor (D16, RV-1, RV-4)
- **Where:** B7 p21 `456:1969` (filters, role column, permissions panel, create dialog);
  Dashboard sidebar (all B-frames); profile menu subtitle.
- **What:**
  - Role labels: **"Super (I-Crash)"**, **"Admin"**, **"Gestor"** (EN "Manager"); no
    "Profissional de saúde" type.
  - B7 filters: Todos · **Admins (N)** · **Gestores (N)** · Convites pendentes.
  - B7 permissions panel: no role tabs; it shows "Gestor" and only the cart actions (7
    switches); "Editar gavetas" and "Gerir utilizadores e turnos" are gone (Admin only).
  - "Criar utilizador": type Gestor (default) or Admin.
  - Sidebar: Catálogo, Modelos, Utilizadores and Turnos only for an Admin.
- **Copy:** `roleSuperAdmin`, `roleInstitutionAdmin`, `roleManager` changed; new
  `usersFilterAdmins` "Admins ({count})".

### DC-56 · Support access: Admin section, Super's picker and banner (D18, RV-2)
- **Where:** new Dashboard section (no frame; next to B9 on p20/p21); institution picker
  (no frame); a banner above both shells.
- **What:**
  - Sidebar item **"Acesso do suporte"** (icon escudo), the institution's own Admin only.
  - Screen: left card — closed: "Acesso fechado", help, **Motivo**, **Duração** tabs
    "4 h / 24 h / 7 dias", **Abrir acesso**; open: warning "Acesso aberto até {data}",
    Motivo, Aberto por, Desde, **Fechar acesso agora** (danger, confirm). Right: "Registo de
    acessos" table (Quando, Quem, Ação: Entrou/Saiu).
  - Super's picker: title "Acesso do suporte", subtitle "Instituições que abriram acesso à
    equipa I-Crash", each row "Até {data} · {motivo}", refresh button, empty "Nenhum
    pedido de acesso aberto.", warning when a window ended.
  - Banner (amber, full width, top): "Acesso do suporte · {instituição} · termina às {hora}".
- **Copy:** the `support*` keys, `navSupport`, `actionRefresh`.

### DC-57 · A1 on a tablet: "Configurar dispositivo"; A1 of a registered tablet (D17)
- **Where:** A1 (all A1 frames); new variant "A1 · tablet registado" (no frame).
- **What:**
  - Unregistered A1 on a tablet: ghost button **"Configurar dispositivo"** (icon opções) under
    "Desbloquear com PIN / Entrar no carro". Not on phones (personal devices; A1 must fit).
  - Registered A1: brand panel with the institution; right side: title = tablet name
    ("Tablet Carro 3 · UCI"), "Tablet registado em {instituição}", optional info notice
    ("Sessão terminada por inatividade.", "Demasiadas tentativas erradas…"), **Entrar com PIN**
    (primary, L), **Entrar no carro** (secondary, L), note "Neste tablet não é preciso
    palavra-passe…", ghost **"Remover registo deste tablet"**. No e-mail/password fields.
  - Revoked: critical notice "Este dispositivo foi desativado" + "Um Administrador revogou…",
    primary **Configurar dispositivo**.
- **Copy:** `deviceSetUp`, `deviceRegisteredTo`, `deviceNoPasswordNote`,
  `deviceRemoveRegistration`, `deviceRevokedTitle`, `deviceRevokedMessage`, `deviceNotice*`.

### DC-58 · A0 · Configurar dispositivo (new screen, D17)
- **Where:** new frame after A1 (no frame yet).
- **What:** A1's brand panel; right, title "Configurar dispositivo".
  - Step 1: "Um Administrador inicia sessão uma vez…", E-mail, Palavra-passe, **Cancelar** /
    **Continuar**. Error "Só um Administrador da instituição pode registar um tablet."
  - Step 2: "Instituição: {nome}", **Nome do tablet** (hint "Ex.: Tablet Carro 3 · UCI", 60
    chars), **Carros deste tablet** (checkbox per cart, "Carro · Serviço · Local"),
    **Cancelar** / **Registar tablet** (disabled until a name and ≥ 1 cart).
- **Copy:** `deviceSetupAdminNote`, `deviceSetupNotAdmin`, `deviceSetupInstitution`,
  `deviceNameLabel`, `deviceNameHint`, `deviceCartsLabel`, `deviceRegister`,
  `deviceSetupPickCart`, `deviceSetupNoCarts`, `actionContinue`.

### DC-59 · A2b · Identificação (new screen, D17)
- **Where:** new frame next to A2.
- **What:** like A2 with the person replaced by a form: title "Identificação" (or "Remover
  registo deste tablet"), subtitle tablet name, field **"Nº mecanográfico ou e-mail"**, label
  PIN + 4 dots, hint "Escreva o nº mecanográfico ou o e-mail e marque o PIN.", ghost
  **Cancelar**; A2's keypad on the right. Errors in the hint line (red): "Nº/e-mail ou PIN
  errado. Restam N tentativas." (same text for an unknown number), "A administração ainda não
  definiu o seu PIN.", "Não está registado em nenhum carro deste tablet.", "Não está registado
  neste carro.", "Só um Administrador pode remover o registo."
- **Copy:** `deviceIdentify*`, `deviceIdentifierLabel`, `deviceSignInHint`,
  `deviceEnterIdentifierFirst`, `deviceWrongCredentials`, `deviceNoPin`,
  `deviceNoCartsForPerson`, `deviceNotOnCart`, `deviceRemoveNotAdmin`, `deviceRemoveNote`.

### DC-60 · B7: "Dispositivos" tab and nº mecanográfico (D17)
- **Where:** B7 (p20/p21 users frames).
- **What:**
  - Tab **"Dispositivos (n)"** after the people tabs (n = active tablets). Table: Nome, Carros
    ("Carro 1, Carro 3"), Registado por ("Rita Lopes · 30 out 2026"), Estado (Ativo /
    Revogado pill), menu **Alterar nome e carros** (dialog: name + cart checkboxes) and
    **Revogar** (danger confirm). Empty: "Nenhum tablet registado. Um tablet regista-se nele
    próprio, em "Configurar dispositivo"."
  - "Criar utilizador": **E-mail** and **Nº mecanográfico** (optional) side by side. The people
    table's E-mail column shows "email · nº".
  - Tablet accounts never appear in the people tabs.
- **Copy:** `usersFilterDevices`, `devicesEmpty`, `deviceCartsColumn`,
  `deviceRegisteredByColumn`, `deviceState*`, `deviceEdit`, `deviceRevoke*`, `deviceUpdated`,
  `userNumberLabel`, `userNumberTaken`.

## Not changed in code yet, but will affect the design later

| Item | Frames affected | Waits on |
|---|---|---|
| **Emergency mode hidden**, not removed: the A10 frames, the A5 button (DC-08), p04 section `459:338`, B1 "Emergências este mês" (p21 `I456:432;444:701`, p20 `458:328`) and "Modo de emergência · 6 consumos" (`I456:523;444:691`), B7 permission "Usar o modo de emergência" (`I456:2214;442:640`), B9 "Resumo de emergência" | A10 p10 `455:900`, p11 `454:1226`, p12 `451:1540`, p13 `449:1496`; B1, B7, B9 | P12 |
| ~~A8 rewrite~~ done on 30 Oct (DC-53) | — | — |
| **Login by `userNumber`** (or the hospital's directory) instead of e-mail on personal devices; A2 checked by the server (on tablets the number works since DC-59) | A1, A2, A3 | DB3 login method, defined last |
| Setting the nº mecanográfico of an existing member (only "Criar utilizador" has the field) | B7 member menu | — |
| One institution per user: the institution picker and "Mudar de instituição" go | Picker, Profile menu | Out of scope |
| **Departments** (with floor) instead of free-text "Serviço" | B2, B3 "Serviço", A4/A5 subtitles | DATABASE.md DEPARTMENT |
| Discard and Count history types; same-date batch merge; first stock when a cart is configured | A6 panels, A7, B9 filters | P7, P10, P6/P19 |
| Slot-state priority values; whether "missing" or any shortage triggers D7 "Reposição necessária" | Estado da posição legend, B3 auto-state help `456:1026` | P4, P13 |
| Per-product expiry warning (B4 "Aviso de validade", B5 column) | B4 `I456:1494;442:508`, B5 | DB12 |
| `weight` / `volume` instead of "Apresentação" | B5 table and form | DB10 (decided; not in this task) |
| Who assigns responsible people to carts (no screen) | B3 or B8 | P18 |
| Corrections: same-slot rule and whether the reason becomes mandatory | DC-13 Corrigir panel | P15 |
| ~~Roles~~ done on 30 Oct (DC-55, D16) | — | — |
| Report "In progress" status and reports shared between tablets | A9, B9 | Local stubs (out of scope) |
| Annotations "Proposta (D3)…" next to A2/A3 (p10 `455:1091`, `455:1093`; p11 `454:1528`, `454:1530`; p12 `451:1964`, `451:1966`; p13 `447:1162`, `447:1164`) describe the old device-only PIN | Annotations | DC-07 |

## Entries per screen

| Screen | Entries |
|---|---|
| Shared components / patterns | 5 (DC-01 … DC-05) |
| A1 | 1 (DC-06) |
| A2 | 1 (DC-07) |
| A5 | 2 (DC-08, DC-15) |
| A6 | 5 (DC-09 … DC-13) |
| A7 | 1 (DC-14) |
| A8 | 1 (DC-17) |
| A9 | 2 (DC-18, DC-19) |
| A11 | 1 (DC-16) |
| B3 | 2 (DC-20, DC-21) |
| B4 | 7 changes (DC-23 … DC-26, DC-28 … DC-30; DC-22 and DC-27 only point to DC-26 and DC-30) |
| B5 | 1 (DC-31) |
| B6 | 3 (DC-32 … DC-34) |
| B2/B6 | 1 (DC-35) |
| B7 | 4 (DC-36 … DC-38, DC-40) |
| B9 | 1 (DC-39) |
| 30 Oct review (A1, rail, A5, A6, A8, A9, A11, B3, B7, menu, terminology, drawer name, roles, support access) | DC-41 … DC-56 |
| D17 registered tablets (A1, A0, A2b, B7) | DC-57 … DC-60 |
