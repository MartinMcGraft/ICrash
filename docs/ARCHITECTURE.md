# Architecture
Status: proposed V2 direction; not implemented.
Existing app: legacy Flutter screens and HTTP RequestHandler targeting old Django endpoint. Prior modernization preserved functionality but did not replace backend.
V2: presentation → application use cases → domain/repository interfaces → Firebase/scanner/report/notification adapters. Domain testable without Firebase. Institution-scoped memberships and explicit cart assignments. Portuguese (Portugal) and English; Android first; responsive desktop/web.
See ICRASH_V2_SPECIFICATION.md for authoritative scope and dependency order. Implementation starts only after Phase 0.
