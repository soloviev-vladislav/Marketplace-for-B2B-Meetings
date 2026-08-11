# Implementation Plan — Build in Vertical Slices

## Sprint 0 — Foundation

Deliverable:
App runs in production.

Tasks:
- Next.js + TypeScript
- Tailwind + shadcn/ui
- Supabase project
- env handling
- login/logout
- profiles + roles
- basic layout
- seed admin
- CI/typecheck/lint

Do not build marketplace UI before schema/auth works.

## Sprint 1 — Bounty marketplace

Deliverable:
Admin can publish a bounty; SDR can browse and take it.

Pages:
- `/`
- `/bounties`
- `/bounties/[slug]`
- `/sdr/workspace`
- `/admin/bounties`
- `/admin/bounties/new`

Features:
- create bounty
- edit draft
- publish
- public card
- take bounty
- full brief for takers

## Sprint 2 — Prospects

Deliverable:
SDR can register a prospect and admin can validate.

Pages:
- `/sdr/workspace/[bountyId]`
- `/sdr/prospects/new`
- `/admin/prospects`

Features:
- form
- normalized email/domain
- duplicate check
- ownership expiration
- approval/rejection
- criteria snapshot

## Sprint 3 — Meetings

Deliverable:
SDR can submit booked meeting.

Pages:
- `/sdr/meetings`
- `/business/meetings`
- `/admin/meetings`

Features:
- scheduled date/time
- meeting link
- statuses
- meeting event timeline
- manual secured flag
- funding state

## Sprint 4 — Acceptance + disputes

Deliverable:
Full result workflow works.

Features:
- 24h review deadline
- accept
- dispute
- evidence upload
- admin resolution
- append-only event history
- scheduled job for auto-accept

## Sprint 5 — Ledger + manual payouts

Deliverable:
Money state is auditable.

Features:
- wallets
- ledger entries
- manual deposit confirmation
- hold
- release
- refund
- payout due
- mark paid
- admin finance view

Important:
Do not call a database number "escrow" unless funds are actually held in a legally/provider-supported escrow/safe-deal structure.

## Sprint 6 — Telegram

Deliverable:
Marketplace can recruit/activate SDRs through Telegram.

Bot actions:
- `/start`
- link account
- send active bounty notifications
- deep link to bounty
- alert about prospect status
- alert about deposit
- alert about meeting review/dispute/payout

Do not duplicate all web UI inside bot.

## Sprint 7 — Analytics / reputation

Business public stats.
SDR public stats.
Admin funnel.

Events:
- bounty_viewed
- bounty_taken
- prospect_registered
- prospect_approved
- meeting_submitted
- meeting_secured
- meeting_accepted
- dispute_opened
- dispute_resolved
- payout_paid

## Sprint 8 — Real money provider

Only after:
- legal flow approved;
- provider approves business model;
- pilot validates transaction flow.

Integrate provider webhook → internal ledger.

Provider webhook must be authoritative for payment states.

## Sprint 9 — AI

Useful first AI features:
1. turn business free-form brief into structured bounty draft;
2. detect ambiguous hard criteria;
3. summarize product/materials for SDR;
4. suggest ICP/outreach hypotheses;
5. assist moderator with disputes, but NEVER auto-rule initially.

## First UI

### SDR dashboard
Top:
- available bounty value
- earnings
- accepted meetings
- dispute rate

Main:
- Recommended bounties
- My active bounties
- Upcoming meetings
- Payouts

### Business dashboard
Top:
- active bounties
- secured funds
- accepted meetings
- cost per accepted meeting

Main:
- Bounty progress
- Meetings awaiting review
- Active disputes

### Admin dashboard
- bounties waiting moderation
- meetings awaiting funding
- disputes
- payout due
- fraud flags
