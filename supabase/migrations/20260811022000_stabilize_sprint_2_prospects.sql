-- Sprint 2 stabilization only: strict Russian company identity, finite ownership,
-- quota enforcement and concurrency-safe anti-hoarding.

alter table public.prospects
  add column ownership_expires_at timestamptz;

update public.prospects
set ownership_expires_at = created_at + interval '30 days';

alter table public.prospects
  alter column ownership_expires_at set not null,
  alter column company_inn set not null,
  alter column normalized_company_inn set not null,
  alter column company_domain set not null,
  alter column normalized_company_domain set not null;

alter table public.prospects
  drop constraint prospects_check,
  drop constraint prospects_check1,
  drop constraint prospects_check2;

alter table public.prospects
  add constraint prospects_valid_inn_identity check (
    normalized_company_inn is not null
    and company_identity_key = 'inn:' || normalized_company_inn
  ),
  add constraint prospects_rejection_consistency check (
    (status = 'REJECTED' and rejection_reason is not null and char_length(trim(rejection_reason)) > 0)
    or (status <> 'REJECTED' and rejection_reason is null)
  ),
  add constraint prospects_review_consistency check (
    (status = 'PENDING' and reviewed_at is null and reviewed_by is null)
    or (status in ('APPROVED', 'REJECTED') and reviewed_at is not null and reviewed_by is not null)
    or status = 'EXPIRED'
  ),
  add constraint prospects_positive_ownership_window check (ownership_expires_at > created_at);

comment on column public.prospects.company_identity_key is
  'Sprint 2 MVP authoritative identity: inn:<validated normalized Russian INN>.';
comment on column public.prospects.ownership_expires_at is
  'Finite company ownership window; new registrations receive 30 days.';

create or replace function public.normalize_company_inn(raw_value text)
returns text language plpgsql immutable strict set search_path = ''
as $$
declare normalized text;
begin
  normalized := regexp_replace(trim(raw_value), '[[:space:]-]', '', 'g');
  if normalized !~ '^[0-9]{10}([0-9]{2})?$' then return null; end if;
  return normalized;
end;
$$;

create or replace function public.is_valid_russian_inn(raw_value text)
returns boolean language plpgsql immutable strict set search_path = ''
as $$
declare
  value text := public.normalize_company_inn(raw_value);
  digits integer[];
  first_check integer;
  second_check integer;
begin
  if value is null then return false; end if;
  digits := array(select substr(value, position, 1)::integer from generate_series(1, length(value)) position);
  if length(value) = 10 then
    first_check := ((2*digits[1] + 4*digits[2] + 10*digits[3] + 3*digits[4] + 5*digits[5]
      + 9*digits[6] + 4*digits[7] + 6*digits[8] + 8*digits[9]) % 11) % 10;
    return first_check = digits[10];
  end if;
  first_check := ((7*digits[1] + 2*digits[2] + 4*digits[3] + 10*digits[4] + 3*digits[5]
    + 5*digits[6] + 9*digits[7] + 4*digits[8] + 6*digits[9] + 8*digits[10]) % 11) % 10;
  second_check := ((3*digits[1] + 7*digits[2] + 2*digits[3] + 4*digits[4] + 10*digits[5]
    + 3*digits[6] + 5*digits[7] + 9*digits[8] + 4*digits[9] + 6*digits[10]
    + 8*digits[11]) % 11) % 10;
  return first_check = digits[11] and second_check = digits[12];
end;
$$;

alter table public.prospects
  add constraint prospects_valid_russian_inn_checksum
  check (public.is_valid_russian_inn(normalized_company_inn));

create or replace function public.normalize_company_domain(raw_value text)
returns text language sql immutable strict set search_path = ''
as $$
  with input as (
    select lower(trim(raw_value)) value
  ), authority as (
    select value original,
      split_part(split_part(split_part(
        case when value ~ '^https?://' then regexp_replace(value, '^https?://', '') else value end,
        '/', 1), '?', 1), '#', 1) value
    from input
  ), canonical as (
    select original,
      regexp_replace(regexp_replace(regexp_replace(value, '^www\.', ''), '\.$', ''), ':(80|443)$', '') value
    from authority
  )
  select c.value
  from canonical c
  where c.original <> ''
    and c.original not like '%@%'
    and (c.original not like '%://%' or c.original ~ '^https?://')
    and length(c.value) <= 253
    and c.value not like '%:%'
    and cardinality(string_to_array(c.value, '.')) >= 2
    and (string_to_array(c.value, '.'))[cardinality(string_to_array(c.value, '.'))] ~ '^[a-z]{2,63}$'
    and not exists (
      select 1 from unnest(string_to_array(c.value, '.')) label
      where label !~ '^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$'
    );
$$;

-- The admin form displays dates (not timestamps), fixed labels for structured
-- materials, and human-formatted INNs. Compare their semantic representation
-- so a status-only Resume cannot create a phantom bounty version.
create or replace function public.normalize_bounty_version_snapshot(source jsonb)
returns jsonb language sql immutable set search_path = ''
as $$
  select jsonb_build_object(
    'bounty', jsonb_build_object(
      'business_id', source#>'{bounty,business_id}', 'title', source#>'{bounty,title}',
      'summary', source#>'{bounty,summary}', 'product_description', source#>'{bounty,product_description}',
      'sales_website', source#>'{bounty,sales_website}', 'reward_amount', source#>'{bounty,reward_amount}',
      'platform_fee_amount', source#>'{bounty,platform_fee_amount}', 'currency', source#>'{bounty,currency}',
      'meeting_limit', source#>'{bounty,meeting_limit}', 'active_until', source#>'{bounty,active_until}',
      'minimum_duration_minutes', source#>'{bounty,minimum_duration_minutes}',
      'meeting_format', source#>'{bounty,meeting_format}', 'existing_crm_rule', source#>'{bounty,existing_crm_rule}',
      'acceptance_notes', source#>'{bounty,acceptance_notes}'
    ),
    'icp', jsonb_build_object(
      'geography', source#>'{icp,geography}', 'industries', source#>'{icp,industries}',
      'excluded_industries', source#>'{icp,excluded_industries}', 'min_revenue', source#>'{icp,min_revenue}',
      'max_revenue', source#>'{icp,max_revenue}', 'min_employees', source#>'{icp,min_employees}',
      'max_employees', source#>'{icp,max_employees}', 'allowed_roles', source#>'{icp,allowed_roles}',
      'excluded_company_inns', coalesce((
        select jsonb_agg(coalesce(public.normalize_company_inn(item), trim(item)) order by coalesce(public.normalize_company_inn(item), trim(item)))
        from jsonb_array_elements_text(coalesce(source#>'{icp,excluded_company_inns}', '[]'::jsonb)) item
      ), '[]'::jsonb),
      'hard_rules', source#>'{icp,hard_rules}', 'soft_notes', source#>'{icp,soft_notes}'
    ),
    'materials', coalesce((select jsonb_agg(jsonb_build_object(
      'label', to_jsonb(case item->>'material_type'
        when 'PAINS' then 'Боли и триггеры'
        when 'VALUE_PROPOSITIONS' then 'Ценностные предложения'
        when 'OUTREACH_NOTES' then 'Рекомендации по аутричу'
        else item->>'label' end),
      'content', item->'content', 'external_url', item->'external_url',
      'material_type', item->'material_type', 'sort_order', item->'sort_order'
    ) order by (item->>'sort_order')::integer, item->>'material_type', item->>'label')
    from jsonb_array_elements(coalesce(source->'materials', '[]'::jsonb)) item), '[]'::jsonb)
  );
$$;

alter function public.bounty_versioned_snapshot(uuid)
  rename to bounty_versioned_snapshot_raw;

create function public.bounty_versioned_snapshot(target_bounty_id uuid)
returns jsonb language sql stable security definer set search_path = ''
as $$
  select public.normalize_bounty_version_snapshot(
    public.bounty_versioned_snapshot_raw(target_bounty_id)
  );
$$;

revoke all on function public.bounty_versioned_snapshot_raw(uuid),
  public.bounty_versioned_snapshot(uuid), public.normalize_bounty_version_snapshot(jsonb)
from public;

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
  quota_reached boolean;
  active_count integer;
  registered_at timestamptz := now();
begin
  if not public.is_sdr() then
    raise exception using errcode = '42501', message = 'FORBIDDEN';
  end if;

  -- Serialize registrations for one SDR/bounty so concurrent requests cannot
  -- cross the per-SDR limit. The unique index independently serializes INN ownership.
  perform pg_advisory_xact_lock(hashtextextended(actor::text || ':' || target_bounty_id::text, 0));

  select b.status = 'ACTIVE'
      and b.active_until > now()
      and x.verification_status = 'VERIFIED',
    b.accepted_count >= b.meeting_limit
  into bounty_available, quota_reached
  from public.bounties b
  join public.businesses x on x.id = b.business_id
  where b.id = target_bounty_id
  for share of b, x;

  if bounty_available is null then raise exception 'BOUNTY_NOT_FOUND'; end if;
  if not bounty_available then raise exception 'BOUNTY_NOT_AVAILABLE'; end if;
  if quota_reached then raise exception 'BOUNTY_QUOTA_REACHED'; end if;

  if not exists (
    select 1 from public.bounty_takers t
    where t.bounty_id = target_bounty_id and t.sdr_profile_id = actor and t.status = 'ACTIVE'
  ) then raise exception 'BOUNTY_NOT_TAKEN'; end if;

  normalized_inn := public.normalize_company_inn(nullif(payload->>'company_inn', ''));
  if normalized_inn is null or not public.is_valid_russian_inn(normalized_inn) then
    raise exception 'COMPANY_INN_INVALID';
  end if;
  normalized_domain := public.normalize_company_domain(nullif(payload->>'company_domain', ''));
  if normalized_domain is null then raise exception 'COMPANY_DOMAIN_INVALID'; end if;
  identity_key := 'inn:' || normalized_inn;

  if exists (
    select 1 from public.bounty_icp i, unnest(i.excluded_company_inns) excluded_inn
    where i.bounty_id = target_bounty_id
      and public.normalize_company_inn(excluded_inn) = normalized_inn
  ) then raise exception 'COMPANY_NOT_ELIGIBLE'; end if;

  -- Expiry is an explicit historical transition, never a time-dependent index predicate.
  update public.prospects
  set status = 'EXPIRED'
  where bounty_id = target_bounty_id
    and status in ('PENDING', 'APPROVED')
    and ownership_expires_at <= registered_at;

  select count(*) into active_count
  from public.prospects
  where bounty_id = target_bounty_id
    and sdr_profile_id = actor
    and status in ('PENDING', 'APPROVED')
    and ownership_expires_at > registered_at;
  if active_count >= 25 then raise exception 'PROSPECT_ACTIVE_LIMIT_REACHED'; end if;

  begin
    insert into public.prospects (
      bounty_id, sdr_profile_id, company_name, company_inn, normalized_company_inn,
      company_domain, normalized_company_domain, company_identity_key, contact_name,
      contact_title, contact_email, contact_phone, contact_telegram, source_url,
      created_at, ownership_expires_at
    ) values (
      target_bounty_id, actor, trim(payload->>'company_name'), normalized_inn, normalized_inn,
      normalized_domain, normalized_domain, identity_key, trim(payload->>'contact_name'),
      trim(payload->>'contact_title'), lower(trim(payload->>'contact_email')),
      nullif(trim(payload->>'contact_phone'), ''), nullif(trim(payload->>'contact_telegram'), ''),
      nullif(trim(payload->>'source_url'), ''), registered_at, registered_at + interval '30 days'
    ) returning id into new_id;
  exception when unique_violation then
    raise exception 'PROSPECT_DUPLICATE';
  end;
  return new_id;
end;
$$;

create or replace function public.review_prospect(
  target_prospect_id uuid, decision public.prospect_status, reason text default null
)
returns void language plpgsql security definer set search_path = ''
as $$
declare
  current_status public.prospect_status;
  current_reason text;
  expires_at timestamptz;
begin
  if not public.is_admin() then raise exception using errcode = '42501', message = 'FORBIDDEN'; end if;
  if decision not in ('APPROVED', 'REJECTED') then raise exception 'INVALID_DECISION'; end if;
  if decision = 'REJECTED' and coalesce(trim(reason), '') = '' then raise exception 'REJECTION_REASON_REQUIRED'; end if;

  select status, rejection_reason, ownership_expires_at
  into current_status, current_reason, expires_at
  from public.prospects where id = target_prospect_id for update;
  if current_status is null then raise exception 'PROSPECT_NOT_FOUND'; end if;

  if current_status in ('PENDING', 'APPROVED') and expires_at <= now() then
    raise exception 'PROSPECT_OWNERSHIP_EXPIRED';
  end if;
  if current_status = decision and (decision = 'APPROVED' or current_reason = trim(reason)) then return; end if;
  if current_status <> 'PENDING' then raise exception 'PROSPECT_ALREADY_REVIEWED'; end if;

  update public.prospects set
    status = decision,
    rejection_reason = case when decision = 'REJECTED' then trim(reason) else null end,
    reviewed_at = now(), reviewed_by = (select auth.uid())
  where id = target_prospect_id;
end;
$$;

drop function public.sdr_prospects();
create function public.sdr_prospects()
returns table (
  id uuid, bounty_id uuid, bounty_slug text, bounty_title text,
  company_name text, company_inn text, company_domain text,
  contact_name text, contact_title text, contact_email text,
  contact_phone text, contact_telegram text, source_url text,
  status public.prospect_status, rejection_reason text,
  created_at timestamptz, reviewed_at timestamptz, ownership_expires_at timestamptz
)
language sql stable security definer set search_path = ''
as $$
  select p.id, p.bounty_id, b.slug, b.title, p.company_name, p.company_inn,
    p.company_domain, p.contact_name, p.contact_title, p.contact_email,
    p.contact_phone, p.contact_telegram, p.source_url, p.status,
    p.rejection_reason, p.created_at, p.reviewed_at, p.ownership_expires_at
  from public.prospects p
  join public.bounties b on b.id = p.bounty_id
  where public.is_sdr() and p.sdr_profile_id = (select auth.uid())
  order by p.created_at desc;
$$;

revoke all on function public.is_valid_russian_inn(text) from public;
revoke all on function public.register_prospect(uuid, jsonb),
  public.review_prospect(uuid, public.prospect_status, text), public.sdr_prospects() from public;
grant execute on function public.normalize_company_inn(text), public.is_valid_russian_inn(text),
  public.normalize_company_domain(text), public.register_prospect(uuid, jsonb),
  public.review_prospect(uuid, public.prospect_status, text), public.sdr_prospects() to authenticated;
