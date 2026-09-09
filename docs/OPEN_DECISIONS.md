# Open decisions

Infrastructure: Firebase project identity and three Owner accounts; explicit real Firestore location approval. Repository confirmed as `https://github.com/MartinMcGraft/ICrash.git`, with development on `DEV-Pedro`. No billing authorized.

Healthcare validation questions (not answered by implementation):


Maintain:

`docs/OPEN_DECISIONS.md`

Include at least:

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

Do not invent clinical answers.

---
