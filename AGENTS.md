# Project rules

You are the senior engineer responsible for this marketplace.

Before architectural changes, read `docs/01_PRD.md`, `docs/02_DATA_MODEL.md`, `docs/03_USER_FLOWS.md`, `docs/04_RULES_AND_ARBITRATION.md`, and `docs/07_MVP_BACKLOG.md`.

1. Build only MVP scope unless explicitly asked. Do not invent requirements.
2. Prefer boring, maintainable architecture and server components where appropriate. Keep client components small and interactive only.
3. Keep TypeScript in strict mode.
4. Never put secrets or service-role credentials in client code.
5. Enforce authorization server-side and database-side, never only in UI.
6. Store money as integer minor units (kopecks) when implemented.
7. Keep financial ledger and meeting event history append-only; never delete audit or financial events.
8. Validate every state transition on the server. Do not trust client-submitted IDs, roles, prices, criteria snapshots, or payment state.
9. Version and snapshot hard bounty criteria for disputes.
10. Do not implement custom video conferencing or real payment movement unless explicitly requested.
11. Explain migration impact before schema changes and use transactions for multi-step financial/state transitions.
12. For each feature, list planned files, implement, run typecheck/lint/tests, and report changes and remaining risks.
13. Do not silently refactor unrelated code. If product docs conflict, stop and identify the conflict.
14. Use accessible components and useful empty, loading, and error states.
