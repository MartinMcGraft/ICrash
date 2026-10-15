# I-Crash: design

The visual and interaction design of the app: where the design lives, the principles,
the design tokens, the components, and how the Figma file maps to the code.

Updated 15 Oct 2026. Sources: the Figma file **"I-Crash · Design v2"** (Martim Pinheiro
Alves, 13 Oct 2026, *draft for review*) and its mirror in code,
`app/lib/src/ui/core/theme/tokens.dart`.

---

## 1. Where the design lives

**Figma:** [I-Crash · Design v2](https://www.figma.com/design/SN7TkBRDszbTFs8oR1uhPR/I-Crash)
(file key `SN7TkBRDszbTFs8oR1uhPR`)

| Page | Content |
|---|---|
| 00 · Capa e índice | Cover, page index, screen list, decision status |
| 01 · Fundamentos — Cores | Primitives and semantic colour tokens (variable collections `v2 · Primitivos`, `v2 · Cor`) |
| 02 · Fundamentos — Tipografia e layout | IBM Plex Sans/Mono, spacing, radii, elevation, grids for the three screen sizes |
| 03 · Componentes | Buttons, states, slot cells, cards, fields, navigation and more |
| 04 · Padrões e estados | Loading, empty, error, offline, no access; emergency mode; confirmations |
| 10 / 11 · App — Wireframes | 12 screens each: phone 844×390, tablet 1280×800 |
| 12 / 13 · App — Mockups | The same 12 screens with components and realistic data |
| 20 / 21 · Dashboard — Wireframes / Mockups | 9 screens, 1440×900 |
| ARQ · … | The previous version (Codex, 11 Oct). **Reference only, don't use** |

**Screens:**
- **App:** A1 Login · A2 PIN · A3 Cart login (QR/NFC) · A4 Carts · A5 Cart (drawers +
  menu) · A6 Drawer (grid + panel) · A7 Replenish · A8 Monthly check · A9 Report (sign) ·
  A10 Emergency mode · A11 Scanner · A12 Carts offline.
- **Dashboard:** B1 Overview · B2 Carts · B3 Cart configuration · B4 Grid editor ·
  B5 Catalogue · B6 Templates · B7 Users & permissions · B8 Shifts · B9 Reports &
  history.

What each screen does is in [APP.md](APP.md).

**Decision status shown on the cover (13 Oct 2026):**

| Decision | Screen | Status |
|---|---|---|
| D2 User types and permissions | B7 | Confirmed |
| D3 Cart login and PIN | A2, A3 | Confirmed |
| D4 Monthly check content | A8 | Half-confirmed |
| D6 Report signature | A9 | Confirmed |
| D7 Automatic cart state | B3 | Confirmed |
| D8 Shifts | B8 | Confirmed |
| §9 Emergency mode | A10 | Idea kept (wireframes and mockups saved), **left out of the final prototype** |

**Sync rule:** Figma is the source of truth for the look, and `tokens.dart` mirrors it
with the same names. When a variable changes in Figma, change the same token in code,
and the reverse.

Related: the broader **I-Crash Design Standards** (brand, website and company design,
Sep 2026), published at <https://claude.ai/code/artifact/7b2bbe80-2ce6-45db-ba28-5bbe44cdb687>.

---

## 2. Principles

The app is used at a crash cart, often in a hurry, sometimes with gloves, by people
whose job is patient care, not software.

1. **Landscape, side navigation, content first.** The App is landscape only. The
   navigation is a permanent side rail (App) or sidebar (Dashboard) with the same items on
   every screen. Most of the space goes to the content, especially the drawer grid.
2. **Big targets.** Minimum touch target **48 px** (`IcSize.touchMin`), for gloved use.
3. **Status is never colour alone.** Every state has a colour, an **icon** and a
   **label** (WCAG 2.2 AA).
4. **Show what matters, where it is.** Grid cells show the product's short name and
   quantity, not codes. Product search shows the drawer and position. Events always say
   when, who and where.
5. **One way out.** No duplicate exits. Top-level screens have no back button.
6. **Hide what you can't use.** Controls a role can't use are hidden, never labelled
   "manager+" or shown with raw ids.
7. **No scrolling on tablets and desktops; vertical only on phones; never sideways.**
   Content that grows is split into pages that fit (§6).
8. **Emergency is unmistakable.** Emergency mode turns the shell **red** so nobody stays
   in it by accident.
9. **Free is not empty.** A slot with no product looks different from a product with
   0 units.
10. **Frames show only what the user sees.** Notes go beside the frame in Figma, never
    inside the UI.

---

## 3. Colour

The brand is **Clinical Navy** (trust, clinical calm) and **Seal Red**, taken from the
real crash cart's tamper seal. Both sit on **warm neutral** surfaces.

### Primitives (`v2 · Primitivos`)

| Family | Tokens |
|---|---|
| Navy | `navy900 #0F2A3D` · `navy800 #16384F` · `navy700 #1F4E6B` · `navy600 #2A6286` · `navy500 #3B7AA3` · `navy200 #B9D0E1` · `navy100 #DCE8F1` · `navy50 #EEF4F8` |
| Warm neutrals | `warm0 #FFFFFF` · `warm25 #FBFAF7` · `warm50 #F6F4EF` · `warm100 #EEEBE4` · `warm200 #E2DED5` · `warm300 #CDC8BD` · `warm500 #8C877D` · `warm700 #555149` · `warm900 #1E1D1A` |
| Red (Seal Red) | `red800 #7F1322` · `red700 #A6192E` · `red600 #C62034` · `red100 #F9DEE1` · `red50 #FCEFF1` |
| Amber | `amber800 #6E4700` · `amber700 #8A5A00` · `amber500 #D99A1E` · `amber100 #FBEFD3` |
| Green | `green800 #17543A` · `green700 #1F6B45` · `green500 #2F9A63` · `green100 #DDF1E5` |

### Semantic tokens (`v2 · Cor`). Use these in screens, not the primitives.

| Role | Token → value |
|---|---|
| Backgrounds | `bgCanvas` warm50 · `bgSurface` warm0 · `bgSurfaceMuted` warm100 · `bgSurfaceSunken` warm200 · `bgSidebar` navy900 · `bgSidebarActive` navy700 |
| Text | `textPrimary` warm900 · `textSecondary` warm700 · `textMuted` warm500 · `textOnDark` warm0 · `textOnDarkMuted` navy200 · `textLink` navy700 |
| Borders | `borderDefault` warm200 · `borderStrong` warm300 · `borderFocus` navy500 |
| Actions | `actionPrimary` navy700 (pressed navy800) · `actionSecondary` navy50 · `actionDanger` red700 |
| Status: ok | fg green700 / bg green100 |
| Status: warning | fg amber700 / bg amber100 / accent amber500 |
| Status: danger | fg red700 / bg red100 |
| Status: neutral | fg warm700 / bg warm100 |
| Status: info | fg navy700 / bg navy50 |
| Emergency | `emergencyBg` red700 · `emergencyBgDeep` red800 · `emergencyFg` warm0 |

In Figma (and in the generated CSS names) these appear as `--icrash-color-*`, e.g.
`--icrash-color-bg-canvas`, `--icrash-color-action-danger`.

---

## 4. Typography, spacing, shape

**Fonts:** **IBM Plex Sans** for the interface and **IBM Plex Mono** for codes, lots
and GTINs.
- Both are bundled in `app/assets/fonts/` under the SIL Open Font License (see
  `LICENSE-IBM-Plex.txt`).
- Families in code: `IcFonts.sans` and `IcFonts.mono`.

| Style (`v2/…` in Figma → `IcText.…`) | Size / line height | Weight |
|---|---|---|
| Display → `display` | 32 / 40 | SemiBold 600 |
| Título L → `titleL` | 24 / 32 | SemiBold 600 (letter-spacing −0.2) |
| Título M → `titleM` | 20 / 28 | SemiBold 600 |
| Título S → `titleS` | 17 / 24 | SemiBold 600 |
| Corpo L → `bodyL` | 17 / 26 in Figma, 17 / 24 in code | Regular 400 |
| Corpo M → `bodyM` | 15 / 22 | Regular 400 |
| Corpo S → `bodyS` | 13 / 18 | Regular 400 |
| Etiqueta L → `labelL` | 16 / 20 | Medium 500 |
| Etiqueta M → `labelM` | 14 / 18 | Medium 500 |
| Etiqueta S → `labelS` | 12 / 16 | SemiBold 600 (+0.2) |
| Número L → `numberL` | 28 / 32 | SemiBold 600 (metric tiles) |
| Mono → `mono` | 13 / 18 | Plex Mono 400 |

> **Small drift to fix:** Figma has Display −0.3 and Título M −0.1 letter-spacing and
> Corpo L line height 26. The code has no letter-spacing on those two and 24 for Corpo L.
> Align `tokens.dart` to Figma.

| Spacing (`IcSpace`) | 2 · 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48 |
|---|---|
| **Radius (`IcRadius`)** | sm 6 (badges) · md 10 (buttons, fields) · lg 14 (cards, dialogs) · xl 20 · full 999 (chips) |
| **Sizes (`IcSize`)** | touch target 48 · App rail 96 (tablet) / 72 (phone) · Dashboard sidebar 240 |
| **Elevation** | `icElevation1`: two soft shadows (y 1, blur 2 and 3, warm900 at 6% and 8%) |

**Screen sizes designed:** phone **844×390**, tablet **1280×800**, desktop **1440×900**.

---

## 5. Components

All live in `app/lib/src/ui/core/`. Use them instead of building ad-hoc widgets.

| Figma component | Code | Notes |
|---|---|---|
| Brand mark | `Monogram` (`widgets/brand.dart`) | White "IC" on a Seal Red rounded square |
| Button | `IcButton` (`widgets/ic_button.dart`) | Styles: primary (navy), secondary (navy50), danger (red), ghost (outlined). Sizes M and L. `IcIconButton` for icon-only |
| Estado do carro | `CartStateChip` (`widgets/status.dart`) | Pill with icon + label (see table below) |
| Estado da posição | `SlotHealthBadge` | Small badge (radius 6) with icon + label |
| Célula de posição | `SlotCell` + `SlotGrid` (`widgets/slot_grid.dart`) | Short name + quantity + badge when not OK. Compacts as space shrinks: full → name + quantity → one line. On phones cells keep ≥ 48 px and the grid scrolls vertically |
| Notice | `Notice` | info · warning · critical (announced to screen readers) · offline |
| Sync indicator | `SyncIndicator` | Offline · "N pending" · Synced |
| Pill | `StatusPill` | ok / warning / danger / info / neutral |
| Page header, card, side panel | `PageHeader`, `SurfaceCard`, `SidePanel` (`widgets/layout.dart`) | |
| Tabs, search, field | `SegmentedTabs`, `SearchField`, `LabeledField` | |
| Quantity | `QuantityStepper` | Large − / + controls |
| Checks | `CheckBox3`, `CheckRow` | Three states: unchecked / checked / problem (monthly check) |
| Metrics | `MetricTile` | Tones: neutral, ok, warning, danger |
| Events | `EventRow` | Consumption, replenishment, correction, check, emergency |
| Tables | `DataTableCard`, `FitDataTable` | |
| Empty/loading/error | `StateView` | |
| Scanner frame | `ScannerViewport` | Dashed frame over the camera |
| Pagination | `Pager` (`widgets/fit.dart`) | "1–10 de 212 ‹ ›" |
| Icons | `IcIcon` + `IcIconView` (`icons/ic_icons.dart`) | 43 icons stored as SVG paths, no icon font |

**Icons** (names in PT, as in Figma):
`carro gaveta grelha relatorio historico ler qr nfc catalogo utilizador utilizadores
turnos modelo estatistica painel emergencia assinar sair idioma pesquisar mais menos
confirmar fechar voltar seguinte alerta relogio cadeado sincronizar semRede opcoes
editar arquivar descarregar filtro lanterna teclado escudo apagar calendario info
okCirculo`

### State system

**Cart state** (`CartStateChip`):

| State | Tone | Icon |
|---|---|---|
| Operacional | ok (green) | `okCirculo` |
| Reposição necessária | warning (amber) | `alerta` |
| Verificação em atraso | info (navy) | `relogio` |
| Fora de serviço | neutral (grey) | `cadeado` |
| Emergência ativa (while emergency mode is open) | danger (red) | `emergencia` |

**Slot state** (`SlotHealthBadge`, most urgent wins):

| State | Tone | Icon |
|---|---|---|
| Expirado | danger | `alerta` |
| Em falta (0 units) | danger | `fechar` |
| A expirar (within the warning window) | warning | `relogio` |
| Stock baixo | warning | `menos` |
| OK | ok | `okCirculo` |
| Livre (no product) | neutral | `info` |

A drawer and a cart show the **worst** state of what they contain, plus counts
("1 expirado · 2 em falta").

---

## 6. Layout

| | Phone 844×390 | Tablet 1280×800 | Desktop 1440×900 |
|---|---|---|---|
| Shell | App, 72 px icon rail | App, 96 px rail with labels | Dashboard, 240 px sidebar |
| Scrolling | Vertical allowed | **None** | **None** |
| Long lists and tables | Scroll | Pages that fit + `Pager` | Pages that fit + `Pager` |
| Drawer grid | Cells ≥ 48 px, scrolls vertically | Always fits; cell content compacts | Always fits |
| Detail panel | Over the grid | **Over** the grid (`OverlayPanelLayout`), closed with ✕ or by tapping the slot again | Same |

Breakpoints in code (`formFactorOf`, `widgets/fit.dart`): **phone** when the height is
under 500, **tablet** up to 1360 wide, **desktop** above.

`app/test/ui/layout_fit_test.dart` renders screens at the three sizes with heavy data and
fails on any overflow or forbidden scroll.

---

## 7. Copy and language

- **PT-PT first** (the template language); English second. All strings live in
  `app/lib/l10n/app_pt.arb` and `app_en.arb`. Design one length-check board in Figma
  instead of duplicating screens in English.
- **Short, plain and clinical:** *Repor stock*, *Verificação mensal*, *Fora de serviço*.
  No database ids, role ids (`institutionAdmin`) or event codes in the UI.
- **Use realistic data** in mockups and demos (Adrenalina 1 mg/ml, Amiodarona 150 mg,
  Seringa 10 ml, "Carro Urgência 1"), never "Produto DEMO 02".
- Exports (CSV/PDF) are always in Portuguese.

---

## 8. Changing the design

1. Change it in Figma first (variables for tokens, components for widgets) and keep the
   frames free of notes.
2. Mirror it in `tokens.dart`, `app_theme.dart` (stock Material widgets) or the widget in
   `ui/core/widgets/`, using the same names.
3. Screens use only tokens and `ui/core` widgets: no hex colours or magic numbers in
   `features/`.
4. Run `flutter test` (the layout test catches overflow) and check the three sizes.
