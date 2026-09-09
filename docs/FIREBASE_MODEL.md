# Firebase model
Status: requirements only; no Firebase implementation, collections or rules created.
Latest specification explicitly selects Authentication and Cloud Firestore, replacing the earlier relational preference. Separate local Auth/Firestore emulators from cloud demo; test configuration must never target demo data. No billing, Storage or deployed Functions for initial prototype.
Hierarchy: institution → cart → drawer → slot, with separate products, cart-product assignments, batches and immutable events. One product occupies at most one slot per cart.
currentQuantity is the authoritative operational aggregate. Daily consumption changes it and creates immutable events; batches and earliestKnownExpiry remain unchanged. Replenishment can lower earliestKnownExpiry. Only physical reconciliation may establish absence of an earlier lot. Do not assume aggregate equals batch sum between audits.
Rules must enforce institution isolation, membership, cart assignment, roles, protected audit history and prevention of privilege escalation. Offline/concurrent writes and aggregate bounds require explicit design and emulator tests in Phase 2.
Real Firestore location awaits user confirmation. No security guarantees claimed before implementation/testing.
