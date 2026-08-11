# MeetMarket — B2B Meetings Marketplace

Sprint 0 technical foundation for a marketplace of qualified B2B meetings.

## Included in Sprint 0

- Next.js App Router, strict TypeScript, Tailwind CSS and shadcn/ui conventions;
- Supabase email/password authentication using `@supabase/ssr`;
- server-side session refresh, route guards and role-based redirects;
- `profiles` with `SDR`, `BUSINESS` and `ADMIN` roles;
- protected SDR, Business and Admin dashboards;
- Supabase migration with profile creation trigger and RLS.

Marketplace entities and workflows are intentionally not implemented yet.

## Requirements

- Node.js 20+
- npm 10+
- an existing Supabase project

## Local setup

1. Install dependencies:

   ```bash
   npm install
   ```

2. Copy the environment template:

   ```bash
   cp .env.example .env.local
   ```

3. In Supabase Dashboard, open **Project Settings → API** and copy the Project URL and publishable key into `.env.local`:

   ```dotenv
   NEXT_PUBLIC_SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
   NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
   ```

4. Apply [`supabase/migrations/20260811000000_sprint_0_auth_profiles.sql`](supabase/migrations/20260811000000_sprint_0_auth_profiles.sql) in **SQL Editor**. Run it once on a database where these Sprint 0 objects do not yet exist.

5. In **Authentication → URL Configuration**, set Site URL to `http://localhost:3000` and add `http://localhost:3000/auth/callback` to Redirect URLs. Keep email confirmation enabled for the intended production flow.

6. Start the app:

   ```bash
   npm run dev
   ```

Open [http://localhost:3000](http://localhost:3000).

## Create the first admin

Register a normal SDR account through `/signup`, confirm its email, then run this once in Supabase SQL Editor, replacing the email:

```sql
update public.profiles
set role = 'ADMIN', status = 'ACTIVE'
where email = 'admin@example.com';
```

Sign out and sign in again. The account will be routed to `/admin/dashboard`.

Never place a service-role key in `.env.local` or browser code.

## Quality checks

```bash
npm run lint
npm run typecheck
npm run build
```

Product documents live in [`docs/`](docs/).

## Sprint 1 database setup

After the Sprint 0 migration has been applied, run the following file once in Supabase **SQL Editor**:

```text
supabase/migrations/20260811010000_sprint_1_bounty_marketplace.sql
```

It adds only the Sprint 1 business and bounty marketplace tables, immutable bounty versions, RLS policies and authenticated RPC functions. It does not add prospects, meetings or financial tables.

For databases where the initial Sprint 1 migration was already applied, also run:

```text
supabase/migrations/20260811011000_fix_bounty_historical_access.sql
```

This lifecycle patch preserves private brief access for an existing SDR taker after a bounty becomes `PAUSED`, `COMPLETED` or `ARCHIVED`; it does not change tables or RLS policies.

For Sprint 2 prospect registration and ownership, apply next:

```text
supabase/migrations/20260811012000_stabilize_sprint_1_marketplace.sql
supabase/migrations/20260811020000_sprint_2_prospect_registration.sql
```

The Sprint 2 migration adds `prospects`, company identity normalization, concurrency-safe ownership, admin review RPCs and RLS. It does not add meetings or payment entities.

### Optional development data

`supabase/seed.sql` is separate and optional. It requires at least one `ACTIVE` `ADMIN` profile and inserts five fictional verified businesses and five active bounties. Run it once after the Sprint 1 migration. Do not run it on production unless you explicitly want demo records.
