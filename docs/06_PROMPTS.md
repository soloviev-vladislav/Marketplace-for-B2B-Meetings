# Vibecoding Prompts

## PROMPT 0 — Permanent project instruction

Use this as Project Rules / CLAUDE.md / AGENTS.md:

You are the senior engineer responsible for this marketplace.

Read `/docs/01_PRD.md`, `/docs/02_DATA_MODEL.md`, `/docs/03_USER_FLOWS.md`, `/docs/04_RULES_AND_ARBITRATION.md`, and `/docs/07_MVP_BACKLOG.md` before making architectural changes.

Rules:
1. Build only MVP scope unless explicitly asked.
2. Prefer boring, maintainable architecture.
3. TypeScript strict mode.
4. Never put secrets or service-role credentials in client code.
5. Authorization must be enforced server-side/database-side, not only hidden in UI.
6. All money values are integer minor units when implemented in code (kopecks), even if docs display rubles.
7. Financial ledger and meeting event history are append-only in normal workflows.
8. Never delete audit/financial events.
9. Every state transition must be validated on server.
10. Do not trust client-submitted user_id, business_id, SDR id, role, price, bounty criteria snapshot, or payment state.
11. Hard bounty criteria must be versioned/snapshotted for meeting disputes.
12. Do not implement custom video conferencing.
13. Do not implement real payment movement until specifically requested.
14. Before changing schema, explain migration impact.
15. For every feature:
   - list files you plan to change;
   - implement;
   - run typecheck/lint/tests;
   - report exactly what changed and remaining risks.
16. Do not silently refactor unrelated code.
17. If product docs conflict, stop and identify the conflict.
18. Prefer server components where appropriate and small client components only for interactivity.
19. Use accessible components and useful empty/loading/error states.
20. Use transactions for multi-step financial/state transitions.

Do not invent requirements.

---

## PROMPT 1 — Bootstrap

Create the initial application for the B2B Bounty Marketplace described in `/docs/01_PRD.md`.

Tech:
- Next.js App Router
- TypeScript strict
- Tailwind
- shadcn/ui
- Supabase
- Zod validation

First implement ONLY:
- application shell;
- Supabase browser/server clients;
- authentication;
- `profiles` with SDR/BUSINESS/ADMIN roles;
- protected routes;
- basic dashboard routing by role;
- seed/instructions for first admin.

Do not implement bounties yet.

Before coding, propose the folder structure and database migration.
After coding, run typecheck and lint and give me manual test steps.

---

## PROMPT 2 — Database schema

Implement the PostgreSQL/Supabase MVP schema from `/docs/02_DATA_MODEL.md`.

Requirements:
- UUID primary keys;
- timestamptz;
- money stored as bigint integer kopecks;
- created_at defaults;
- necessary unique indexes;
- foreign keys;
- status enums or CHECK constraints;
- append-only `meeting_events` and `ledger_entries`;
- `bounty_versions` or another robust mechanism to snapshot hard criteria;
- RLS enabled for all user-facing tables.

Do not create permissive `USING (true)` write policies.

Provide:
1. migration;
2. RLS policy explanation;
3. seed data;
4. rollback notes;
5. tests or SQL verification queries.

---

## PROMPT 3 — Bounty feed

Build the SDR bounty marketplace vertical slice.

Implement:
- `/bounties`
- `/bounties/[slug]`
- filters by reward, industry, geography, allowed role;
- public preview;
- `Take bounty`;
- full brief visible to authenticated SDR after taking;
- `My active bounties`.

Use server-side authorization.
Do not expose excluded-company data or sensitive campaign materials before allowed.

Design should feel like a professional B2B marketplace, not a crypto dashboard.

Add realistic seed data for 8 bounties.

---

## PROMPT 4 — Admin bounty wizard

Build the admin bounty creation wizard.

Steps:
1. Business/product
2. Reward and quota
3. ICP
4. Decision-maker roles
5. Exclusions
6. Meeting acceptance rules
7. Sales materials
8. Review/publish

Important:
- explicitly separate HARD CRITERIA from SOFT NOTES;
- show warnings for ambiguous criteria;
- generate immutable bounty version when published;
- editing a live bounty's hard criteria creates a new version;
- existing prospects retain old criteria snapshot.

Do not add AI yet.

---

## PROMPT 5 — Prospect registration

Implement the prospect registration workflow from `/docs/03_USER_FLOWS.md`.

SDR enters:
- company name;
- INN;
- domain;
- contact name;
- title;
- corporate email;
- optional contact link;
- source note.

Backend:
- normalize domain and email;
- validate INN as a string field without assuming every jurisdiction has same format;
- check active ownership collision;
- snapshot bounty version/criteria;
- create registration;
- allow admin approve/reject.

Security:
- another SDR must never receive prospect PII.
- business must not receive full prospect contact details before the configured reveal/funding point.

Write tests for duplicate/ownership behavior.

---

## PROMPT 6 — Meeting state machine

Implement meeting submission as an explicit state machine.

Allowed transitions must be centralized and server validated.

Use the statuses defined in docs.

Every transition appends a `meeting_event`.

Implement:
- submit meeting;
- admin/manual `mark secured`;
- schedule;
- await result;
- accept;
- dispute;
- reject;
- payout_due;
- paid.

Do not allow arbitrary status updates from forms.

Provide a state transition table in code comments/tests.

---

## PROMPT 7 — Auto acceptance

Implement default acceptance.

Rule:
- after meeting expected end, meeting enters AWAITING_RESULT;
- business has 24 hours to file a valid dispute;
- after deadline, auto-accept;
- accepted transition is idempotent;
- it cannot double-release money.

Use a cron/scheduled route appropriate for the deployment platform.
Protect cron endpoint.
Add idempotency and tests.

Do not implement real payout.

---

## PROMPT 8 — Disputes

Implement dispute flow.

Business can dispute only for allowed reason codes from `/docs/04_RULES_AND_ARBITRATION.md`.

Require evidence where policy requires it.

Admin page must show:
- bounty version;
- hard criteria;
- qualification snapshot;
- meeting event timeline;
- business evidence;
- SDR response/evidence;
- actor statistics.

Admin can rule:
- SDR wins;
- Business wins.

Resolution must be transactional, immutable in event log, and idempotent.

Do not use AI to decide.

---

## PROMPT 9 — Internal financial ledger

Implement an INTERNAL accounting ledger for MVP.

Important:
This is not a bank account and must never be presented as real escrow.

Requirements:
- wallet per business, SDR, platform;
- transaction group id;
- balanced transaction groups where applicable;
- deposits manually confirmed by admin;
- hold/release/refund/platform fee/payout states;
- money bigint kopecks;
- no direct balance column as source of truth: derive via ledger entries or safe cached view;
- immutable entries;
- idempotency keys.

Implement admin views:
- balances;
- held;
- payout due;
- transaction history.

Write invariants/tests preventing double release and negative unintended balances.

---

## PROMPT 10 — Telegram

Add Telegram bot notification integration.

Use Telegram only for:
- account linking;
- new bounty notifications;
- deep links to web app;
- workflow notifications.

Implement secure account linking with a short-lived one-time token initiated from the logged-in web account.

Never authenticate a web user merely from an arbitrary telegram_user_id received from the client.

Create notification templates and retry/error logging.

---

## PROMPT 11 — UX audit

Act as a senior marketplace product designer.

Do NOT code yet.

Review current app against `/docs/01_PRD.md`.

Walk through these jobs:
1. new SDR finds a suitable bounty in <2 minutes;
2. SDR understands exactly what gets paid;
3. SDR registers prospect with minimal friction;
4. business sees what requires review;
5. moderator resolves a dispute without opening database tools.

List:
- confusing steps;
- missing states;
- trust problems;
- unnecessary fields;
- dangerous ambiguity.

Rank P0/P1/P2.
Then propose only P0 UI changes.

---

## PROMPT 12 — Security review

Act as a hostile security reviewer.

Audit:
- auth;
- RLS;
- IDOR;
- role escalation;
- prospect PII leakage;
- file access;
- service role exposure;
- arbitrary status transitions;
- bounty price tampering;
- duplicate payout;
- webhook spoofing;
- cron spoofing;
- race conditions in prospect ownership;
- race conditions in bounty quota;
- audit log mutation.

Give exploit scenario + exact fix for each vulnerability.
Do not make cosmetic changes.

---

## PROMPT 13 — Pre-launch test

Create Playwright end-to-end tests for:

1. SDR signup → take bounty → register prospect.
2. Admin approves prospect.
3. SDR schedules meeting.
4. Admin marks secured.
5. Business accepts → payout due.
6. Business disputes → admin SDR wins.
7. Business disputes → admin Business wins.
8. No business action → auto accept.
9. Two SDRs race to register same prospect.
10. Unauthorized SDR cannot read competitor prospect.
11. Business cannot change old criteria to invalidate existing prospect.
12. Accepted meeting cannot pay twice.

Use deterministic seed data and clean database state per test suite.

---

## PROMPT 14 — AI bounty assistant (only after core MVP)

Add an AI assistant for admins creating bounty drafts.

Input:
- business website/product description;
- free-form sales brief.

Output STRUCTURED draft only:
- target industries;
- company size;
- geography;
- allowed decision-maker roles;
- potential hard criteria;
- soft sales hypotheses;
- ambiguities/questions.

The AI must NEVER publish or silently turn a suggested criterion into a hard criterion.

Every AI-generated field must visibly indicate that it is a suggestion until admin confirms it.

Use structured JSON output and schema validation.
