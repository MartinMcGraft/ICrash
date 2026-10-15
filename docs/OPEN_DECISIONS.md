# Open decisions

What is decided, what is only proposed, and what still needs the team or the clinicians.
Updated 15 Oct 2026.

**Sources:**
- Product decisions: the design audit of 12 Oct 2026 (claude.ai project "I-Crash",
  `audit-figma-vs-app-2026-10-12.md`, §8–9).
- Confirmation status: the cover of the Figma file "I-Crash · Design v2" (13 Oct 2026).

**Rule:** never invent a clinical answer in code or in the designs. If something
depends on an open question, make it configurable or leave it visibly undecided.

---

## 1. Product direction (decided)

| # | Decision | Resolution |
|---|---|---|
| R1 | Platform split | One Flutter codebase: **App** on Android/iOS/iPadOS, **Dashboard** on web/Windows/macOS/Linux |
| R2 | Monthly management | In scope, and the App's **default mode** |
| R3 | Phones | In scope, landscape |
| R4 | Orientation and navigation | Landscape only; permanent side bar |
| R5 | Offline | Required, with sync on reconnect |
| R6 | Cart state | Manual, with an optional automatic rule (D7) |
| R7 | Structure editing (drawers, grid, catalogue, templates, users) | Dashboard only |

## 2. Design decisions

| # | Decision | Status | What was chosen / proposed | Where in the app |
|---|---|---|---|---|
| D1 | Shell by platform or by role | **Decided** | The platform picks the shell; the role decides what's visible inside it | `resolveShellKind()` in `app_root.dart` |
| D2 | User types and permissions | **Confirmed** (13 Oct) | Engineer Admin, Institution Manager, Health Professional (a 4th type still undefined). The Health Professional may view carts, record consumption, replenish, do the monthly check, sign reports and use emergency mode; structure stays with managers. **Still to do:** map it to the code roles and update `firestore.rules` (today a HP may change only `currentQuantity`) | B7, `AppPermission` |
| D3 | Cart login and PIN | **Confirmed** (13 Oct) | Scanning the cart QR opens a session limited to that cart; the PIN unlocks the session saved on the device (local, works offline, no billing) | A2, A3 |
| D4 | Monthly check content | **Half-confirmed** (13 Oct) | Confirm drawer by drawer; positions with differences are flagged in the report. Open: the checklist items, the frequency (clinical Q7) and whether every slot must be confirmed (clinical Q8) | A8 |
| D5 / §9 | Emergency mode | **Idea kept, out of the final prototype** | Consumption only, tap = −1 unit, a red shell, and ending it sets "Reposição necessária" and creates a summary. Open questions are in §4 | A10 |
| D6 | Report signing | **Confirmed** (13 Oct) | Name + PIN + timestamp; the report is read-only once signed. Not a qualified digital signature (CMD / Cartão de Cidadão) | A9 |
| D7 | Automatic cart state | **Confirmed** (13 Oct) | Expired or missing product → Reposição necessária; check older than 31 days → Verificação em atraso; otherwise Operacional; Fora de serviço is always manual. Switchable per cart | B3, `suggestedCartStatus` |
| D8 | Shifts | **Confirmed** (13 Oct) | One responsible Health Professional per cart per shift (morning / afternoon / night) | B8 |
| D9 | Scanning | Default implemented | GS1 Data Matrix, EAN-13 and Code 128; internal QR for carts. **NFC deferred** (stub) | A11 |
| D10 | Minimum stock | Default implemented | Optional `minimumQuantity` per slot, set in the grid editor | B4 |
| D11 | Grid cell content | Default implemented | Short name + quantity + a badge when not OK | `SlotCell` |
| D12 | Slot interaction | Default implemented | Tap opens the side panel (no long-press) | A6 |
| D13 | What a Health Professional sees on the carts list | Default implemented | Their carts with state; cross-cart alerts are manager+ (a Firestore limitation, see FIREBASE.md §6) | A4 |
| D14 | Offline conflicts (two devices, same slot) | **Open** | Proposal: increments + append-only events for stock; last write wins for structure. Blocked on the offline-write fix | — |
| D15 | Deleting things that have history | Partly decided | **Archive, never delete.** Carts can be archived (the rules forbid deleting them). Products and drawers: still to define | B3 |

**Infrastructure:**
- The Firebase project `i-crash-pt-2026` (Firestore in `eur3`) is set up and used.
- **No billing is authorised** (Spark plan), so nothing that needs Cloud Functions.
- The repository is `https://github.com/MartinMcGraft/ICrash.git`.

---

## 3. Clinical questions (for the nurses)

These need clinicians, not engineering. Keep the wording when asking them.

1. Can a physical compartment have an L/T/non-rectangular shape?
2. Should Managers be allowed to change active drawer structures?
3. Can more than one healthcare professional simultaneously be responsible for one cart?
4. Is a minimum stock quantity useful in addition to current and target/max quantity?
5. Should GS1 Data Matrix scanning during replenishment eventually become mandatory?
6. Is the conservative lot strategy correct: daily consumption changes only aggregate quantity and lot reconciliation happens during physical audits?
7. How often should a complete physical cart audit occur?
8. Must every individual slot be explicitly confirmed, or is mandatory confirmation of every drawer sufficient?
9. Which checklist items are operationally required?
10. Which notifications are valuable without producing alert fatigue?
11. Which roles may correct historical inventory entries?
12. Which GS1 information should normal users actually see?
13. How often are carts duplicated from an identical configuration?
14. Are there institution-specific rules for expiry warning periods?
15. Is it useful in a future version to distinguish stock usage between individual consecutive emergencies, or is aggregate post-emergency recording preferable?
16. Should replenishment require confirmation that the scanned Data Matrix product matches the slot product?
17. How should partially known lots be displayed during the period between emergency consumption and the next physical reconciliation?

---

## 4. Emergency mode: questions to settle before it's built for real

1. What can be done in it? Only record consumption, or also replenish?
2. Speed vs control: no confirmation dialogs? Bigger targets? Tap to decrement?
3. Does entering it need a login or PIN, or can anyone at the cart use it?
4. Recording style: per item during the event, or one total afterwards (clinical Q15)?
5. Leaving it: a summary screen? Automatic "Reposição necessária"? A report to sign?
6. It must work with no network (depends on the offline-write fix).
7. How different must it look so nobody stays in it by accident?
8. Is "daily management" the same as emergency mode, or is there also a calm daily
   check (e.g. a seal check at shift start)?
