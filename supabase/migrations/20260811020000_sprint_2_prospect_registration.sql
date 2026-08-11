-- Sprint 2 only: prospect registration, company ownership and admin review.

create type public.prospect_status as enum ('PENDING', 'APPROVED', 'REJECTED');

create or replace function public.normalize_company_inn(raw_value text)
returns text language sql immutable strict set search_path = ''
as $$
  select nullif(regexp_replace(upper(trim(raw_value)), '[^0-9A-ZА-ЯЁ]', '', 'g'), '');
$$;

create or replace function public.normalize_company_domain(raw_value text)
returns text language plpgsql immutable strict set search_path = ''
as $$
declare normalized text;
begin
  normalized := lower(trim(raw_value));
  normalized := regexp_replace(normalized, '^[a-z][a-z0-9+.-]*://', '', 'i');
  normalized := regexp_replace(normalized, '^www\.', '', 'i');
  normalized := split_part(normalized, '/', 1);
  normalized := split_part(normalized, '?', 1);
  normalized := split_part(normalized, '#', 1);
  normalized := regexp_replace(normalized, '\.$', '');
  return nullif(normalized, '');
end;
$$;

create table public.prospects (
  id uuid primary key default gen_random_uuid(),
  bounty_id uuid not null references public.bounties(id) on delete restrict,
  sdr_profile_id uuid not null references public.profiles(id) on delete restrict,
  company_name text not null check (char_length(trim(company_name)) between 2 and 200),
  company_inn text,
  normalized_company_inn text,
  company_domain text,
  normalized_company_domain text,
  company_identity_key text not null,
  contact_name text not null check (char_length(trim(contact_name)) between 2 and 160),
  contact_title text not null check (char_length(trim(contact_title)) between 2 and 160),
  contact_email text not null check (contact_email = lower(contact_email) and position('@' in contact_email) > 1),
  contact_phone text,
  contact_telegram text,
  source_url text,
  status public.prospect_status not null default 'PENDING',
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles(id) on delete restrict,
  check (normalized_company_inn is not null or normalized_company_domain is not null),
  check (
    (status = 'REJECTED' and rejection_reason is not null and char_length(trim(rejection_reason)) > 0)
    or (status <> 'REJECTED' and rejection_reason is null)
  ),
  check (
    (reviewed_at is null and reviewed_by is null and status = 'PENDING')
    or (reviewed_at is not null and reviewed_by is not null and status <> 'PENDING')
  )
);

comment on column public.prospects.company_identity_key is
  'Authoritative identity: inn:<normalized INN>, otherwise domain:<normalized domain>.';

-- This partial unique index is the concurrency-safe ownership lock.
-- REJECTED rows remain as history but no longer participate in ownership.
create unique index prospects_active_company_ownership_unique
  on public.prospects (bounty_id, company_identity_key)
  where status in ('PENDING', 'APPROVED');

create index prospects_sdr_created_idx
  on public.prospects (sdr_profile_id, created_at desc);
create index prospects_admin_queue_idx
  on public.prospects (status, created_at asc);
create index prospects_bounty_idx
  on public.prospects (bounty_id, created_at desc);

create trigger prospects_set_updated_at
before update on public.prospects
for each row execute procedure public.set_updated_at();

alter table public.prospects enable row level security;

create policy prospects_sdr_own_read
  on public.prospects for select to authenticated
  using (sdr_profile_id = (select auth.uid()) and (select public.is_sdr()));

create policy prospects_admin_read
  on public.prospects for select to authenticated
  using ((select public.is_admin()));

revoke all on table public.prospects from anon;
revoke insert, update, delete on table public.prospects from authenticated;
grant select on table public.prospects to authenticated;

create or replace function public.register_prospect(target_bounty_id uuid, payload jsonb)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare
  actor uuid := (select auth.uid());
  normalized_inn text;
  normalized_domain text;
  identity_key text;
  new_id uuid;
  bounty_available boolean;
begin
  if not public.is_sdr() then
    raise exception using errcode = '42501', message = 'FORBIDDEN';
  end if;

  -- Lock both rows so business suspension / bounty pause cannot race registration.
  select b.status = 'ACTIVE'
    and b.active_until > now()
    and x.verification_status = 'VERIFIED'
  into bounty_available
  from public.bounties b
  join public.businesses x on x.id = b.business_id
  where b.id = target_bounty_id
  for share of b, x;

  if bounty_available is null then raise exception 'BOUNTY_NOT_FOUND'; end if;
  if not bounty_available then raise exception 'BOUNTY_NOT_AVAILABLE'; end if;

  if not exists (
    select 1 from public.bounty_takers t
    where t.bounty_id = target_bounty_id
      and t.sdr_profile_id = actor
      and t.status = 'ACTIVE'
  ) then
    raise exception 'BOUNTY_NOT_TAKEN';
  end if;

  normalized_inn := public.normalize_company_inn(nullif(payload->>'company_inn', ''));
  normalized_domain := public.normalize_company_domain(nullif(payload->>'company_domain', ''));

  if normalized_inn is null and normalized_domain is null then
    raise exception 'COMPANY_IDENTITY_REQUIRED';
  end if;

  identity_key := case
    when normalized_inn is not null then 'inn:' || normalized_inn
    else 'domain:' || normalized_domain
  end;

  if normalized_inn is not null and exists (
    select 1
    from public.bounty_icp i,
      unnest(i.excluded_company_inns) excluded_inn
    where i.bounty_id = target_bounty_id
      and public.normalize_company_inn(excluded_inn) = normalized_inn
  ) then
    raise exception 'COMPANY_NOT_ELIGIBLE';
  end if;

  begin
    insert into public.prospects (
      bounty_id, sdr_profile_id, company_name, company_inn,
      normalized_company_inn, company_domain, normalized_company_domain,
      company_identity_key, contact_name, contact_title, contact_email,
      contact_phone, contact_telegram, source_url
    ) values (
      target_bounty_id, actor, trim(payload->>'company_name'),
      nullif(trim(payload->>'company_inn'), ''), normalized_inn,
      nullif(trim(payload->>'company_domain'), ''), normalized_domain,
      identity_key, trim(payload->>'contact_name'), trim(payload->>'contact_title'),
      lower(trim(payload->>'contact_email')),
      nullif(trim(payload->>'contact_phone'), ''),
      nullif(trim(payload->>'contact_telegram'), ''),
      nullif(trim(payload->>'source_url'), '')
    ) returning id into new_id;
  exception when unique_violation then
    raise exception 'PROSPECT_DUPLICATE';
  end;

  return new_id;
end;
$$;

create or replace function public.review_prospect(
  target_prospect_id uuid,
  decision public.prospect_status,
  reason text default null
)
returns void language plpgsql security definer set search_path = ''
as $$
declare
  current_status public.prospect_status;
  current_reason text;
begin
  if not public.is_admin() then
    raise exception using errcode = '42501', message = 'FORBIDDEN';
  end if;
  if decision not in ('APPROVED', 'REJECTED') then raise exception 'INVALID_DECISION'; end if;
  if decision = 'REJECTED' and coalesce(trim(reason), '') = '' then
    raise exception 'REJECTION_REASON_REQUIRED';
  end if;

  select status, rejection_reason into current_status, current_reason
  from public.prospects where id = target_prospect_id for update;
  if current_status is null then raise exception 'PROSPECT_NOT_FOUND'; end if;

  -- Exact retries are idempotent; conflicting reviews are explicit errors.
  if current_status = decision
    and (decision = 'APPROVED' or current_reason = trim(reason)) then
    return;
  end if;
  if current_status <> 'PENDING' then raise exception 'PROSPECT_ALREADY_REVIEWED'; end if;

  update public.prospects set
    status = decision,
    rejection_reason = case when decision = 'REJECTED' then trim(reason) else null end,
    reviewed_at = now(),
    reviewed_by = (select auth.uid())
  where id = target_prospect_id;
end;
$$;

create or replace function public.sdr_prospects()
returns table (
  id uuid,
  bounty_id uuid,
  bounty_slug text,
  bounty_title text,
  company_name text,
  company_inn text,
  company_domain text,
  contact_name text,
  contact_title text,
  contact_email text,
  contact_phone text,
  contact_telegram text,
  source_url text,
  status public.prospect_status,
  rejection_reason text,
  created_at timestamptz,
  reviewed_at timestamptz
)
language sql stable security definer set search_path = ''
as $$
  select
    p.id, p.bounty_id, b.slug, b.title,
    p.company_name, p.company_inn, p.company_domain,
    p.contact_name, p.contact_title, p.contact_email,
    p.contact_phone, p.contact_telegram, p.source_url,
    p.status, p.rejection_reason, p.created_at, p.reviewed_at
  from public.prospects p
  join public.bounties b on b.id = p.bounty_id
  where public.is_sdr() and p.sdr_profile_id = (select auth.uid())
  order by p.created_at desc;
$$;

revoke all on function public.normalize_company_inn(text),
  public.normalize_company_domain(text), public.register_prospect(uuid, jsonb),
  public.review_prospect(uuid, public.prospect_status, text), public.sdr_prospects()
from public;

grant execute on function public.normalize_company_inn(text),
  public.normalize_company_domain(text), public.register_prospect(uuid, jsonb),
  public.review_prospect(uuid, public.prospect_status, text), public.sdr_prospects()
to authenticated;
