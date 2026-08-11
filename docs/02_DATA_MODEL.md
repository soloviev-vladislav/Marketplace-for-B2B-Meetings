# Data Model — MVP

Use PostgreSQL.

## enums

### user_role
- SDR
- BUSINESS
- ADMIN

### user_status
- PENDING
- ACTIVE
- SUSPENDED

### bounty_status
- DRAFT
- MODERATION
- ACTIVE
- PAUSED
- COMPLETED
- REJECTED
- ARCHIVED

### prospect_status
- REGISTERED
- APPROVED
- REJECTED
- EXPIRED

### meeting_status
- DRAFT
- SUBMITTED
- AWAITING_DEPOSIT
- SECURED
- SCHEDULED
- AWAITING_RESULT
- ACCEPTED
- DISPUTED
- REJECTED
- NO_SHOW
- RESCHEDULED
- PAYOUT_DUE
- PAID
- CANCELLED

### ledger_type
- DEPOSIT
- HOLD
- RELEASE
- PAYOUT
- REFUND
- PLATFORM_FEE
- MANUAL_ADJUSTMENT

## tables

### profiles
- id uuid PK references auth.users
- role user_role
- display_name
- email
- telegram_user_id nullable
- status
- created_at
- updated_at

### businesses
- id uuid PK
- owner_profile_id
- legal_name
- brand_name
- inn
- website
- domain
- description
- verification_status
- created_at

### sdr_profiles
- profile_id uuid PK
- bio
- specialties text[]
- preferred_industries text[]
- preferred_roles text[]
- created_at

### bounties
- id uuid PK
- business_id
- title
- slug
- summary
- product_description
- reward_amount numeric
- platform_fee_amount numeric
- currency text default RUB
- meeting_limit int
- accepted_count int default 0
- status
- active_until
- created_by
- approved_by nullable
- published_at nullable
- created_at
- updated_at

### bounty_icp
- bounty_id uuid PK
- countries text[]
- regions text[]
- industries text[]
- excluded_industries text[]
- min_revenue numeric nullable
- max_revenue numeric nullable
- min_employees int nullable
- max_employees int nullable
- allowed_roles text[]
- excluded_company_inns text[]
- hard_rules jsonb
- soft_notes text

### bounty_materials
- id
- bounty_id
- label
- file_url nullable
- external_url nullable
- material_type

### bounty_takers
- id
- bounty_id
- sdr_profile_id
- status
- taken_at
unique(bounty_id, sdr_profile_id)

### prospects
- id uuid PK
- bounty_id
- sdr_profile_id
- company_name
- company_inn
- company_domain
- contact_name
- contact_title
- contact_email
- contact_phone nullable
- contact_external_url nullable
- source_note nullable
- status
- registered_at
- ownership_expires_at
- approved_by nullable
- rejection_reason nullable

Suggested uniqueness:
- normalized contact_email + active ownership
- bounty_id + company_inn + normalized contact_email

### meetings
- id uuid PK
- prospect_id
- bounty_id
- business_id
- sdr_profile_id
- scheduled_at timestamptz
- timezone
- duration_minutes nullable
- meeting_url nullable
- status
- secured_amount numeric
- review_deadline nullable
- accepted_at nullable
- rejected_at nullable
- created_at
- updated_at

### meeting_events
Immutable append-only event log.
- id
- meeting_id
- actor_profile_id nullable
- event_type
- payload jsonb
- created_at

Never update or delete events in normal application flows.

### disputes
- id
- meeting_id
- opened_by
- reason_code
- explanation
- status OPEN/WON_BY_SDR/WON_BY_BUSINESS/CLOSED
- resolved_by nullable
- resolution_note nullable
- opened_at
- resolved_at nullable

### dispute_evidence
- id
- dispute_id
- submitted_by
- evidence_type
- file_url nullable
- text_value nullable
- created_at

### wallets
Internal accounting representation, NOT a bank account.
- id
- owner_type BUSINESS/SDR/PLATFORM
- owner_id
- currency
- created_at

### ledger_entries
Append-only double-entry-ish event ledger.
- id
- transaction_group_id uuid
- wallet_id
- type ledger_type
- amount numeric signed
- reference_type
- reference_id
- metadata jsonb
- created_at

Do not calculate money from meeting status alone. Ledger is source for internal financial history.

### payouts
- id
- meeting_id
- sdr_profile_id
- amount
- provider
- provider_reference nullable
- status
- created_at
- paid_at nullable

### ratings_snapshot
Optional MVP cache.
Prefer compute stats via queries/views first.

### fraud_flags
- id
- entity_type
- entity_id
- rule_code
- severity
- payload
- status
- created_at
- resolved_at nullable

## RLS Principles

SDR:
- can read active bounty public fields;
- can read full fields only for bounties they took;
- can CRUD their own prospect drafts/submissions subject to workflow;
- can read meetings they own;
- cannot read other SDR prospect PII.

Business:
- can read/edit own draft bounties;
- can read own meetings and prospects after platform-defined reveal point;
- cannot inspect SDR private data beyond public profile/stats.

Admin:
- privileged server-side access only.

Never expose Supabase service role key to browser.
