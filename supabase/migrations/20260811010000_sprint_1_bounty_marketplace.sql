-- Sprint 1 only: businesses, bounty marketplace, immutable versions and takers.

create type public.business_verification_status as enum ('PENDING', 'VERIFIED', 'REJECTED', 'SUSPENDED');
create type public.bounty_status as enum ('DRAFT', 'MODERATION', 'ACTIVE', 'PAUSED', 'COMPLETED', 'REJECTED', 'ARCHIVED');

create table public.businesses (
  id uuid primary key default gen_random_uuid(),
  owner_profile_id uuid references public.profiles(id) on delete set null,
  legal_name text not null check (char_length(trim(legal_name)) between 2 and 200),
  brand_name text not null check (char_length(trim(brand_name)) between 2 and 120),
  inn text not null unique check (char_length(trim(inn)) between 2 and 32),
  website text not null,
  domain text not null,
  description text not null default '',
  verification_status public.business_verification_status not null default 'PENDING',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.bounties (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete restrict,
  title text not null check (char_length(trim(title)) between 3 and 160),
  slug text not null unique,
  summary text not null check (char_length(trim(summary)) between 10 and 500),
  product_description text not null,
  sales_website text not null,
  reward_amount bigint not null check (reward_amount > 0),
  platform_fee_amount bigint not null check (platform_fee_amount >= 0),
  currency text not null default 'RUB' check (currency = 'RUB'),
  meeting_limit integer not null check (meeting_limit > 0),
  accepted_count integer not null default 0 check (accepted_count >= 0 and accepted_count <= meeting_limit),
  status public.bounty_status not null default 'DRAFT',
  active_until timestamptz not null,
  minimum_duration_minutes integer not null check (minimum_duration_minutes > 0),
  meeting_format text not null check (meeting_format in ('ONLINE', 'OFFLINE', 'BOTH')),
  existing_crm_rule text not null,
  acceptance_notes text not null default '',
  created_by uuid not null references public.profiles(id) on delete restrict,
  approved_by uuid references public.profiles(id) on delete restrict,
  current_version integer not null default 0 check (current_version >= 0),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.bounty_icp (
  bounty_id uuid primary key references public.bounties(id) on delete cascade,
  geography text[] not null check (cardinality(geography) > 0),
  industries text[] not null check (cardinality(industries) > 0),
  excluded_industries text[] not null default '{}',
  min_revenue bigint not null check (min_revenue >= 0),
  max_revenue bigint check (max_revenue is null or max_revenue >= min_revenue),
  min_employees integer check (min_employees is null or min_employees >= 0),
  max_employees integer check (max_employees is null or max_employees >= min_employees),
  allowed_roles text[] not null check (cardinality(allowed_roles) > 0),
  excluded_company_inns text[] not null default '{}',
  hard_rules text not null default '',
  soft_notes text not null default '',
  updated_at timestamptz not null default now()
);

-- Private sales brief rows. ACTIVE bounty access is granted only after Take.
create table public.bounty_materials (
  id uuid primary key default gen_random_uuid(),
  bounty_id uuid not null references public.bounties(id) on delete cascade,
  label text not null,
  content text,
  external_url text,
  material_type text not null check (material_type in ('PAINS', 'VALUE_PROPOSITIONS', 'OUTREACH_NOTES', 'LINK')),
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  check (content is not null or external_url is not null)
);

create table public.bounty_takers (
  id uuid primary key default gen_random_uuid(),
  bounty_id uuid not null references public.bounties(id) on delete cascade,
  sdr_profile_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'ACTIVE' check (status in ('ACTIVE', 'LEFT')),
  taken_at timestamptz not null default now(),
  unique (bounty_id, sdr_profile_id)
);

create table public.bounty_versions (
  id uuid primary key default gen_random_uuid(),
  bounty_id uuid not null references public.bounties(id) on delete restrict,
  version integer not null check (version > 0),
  snapshot jsonb not null,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  unique (bounty_id, version)
);

create or replace function public.prevent_bounty_version_mutation()
returns trigger language plpgsql set search_path = ''
as $$ begin raise exception 'Bounty versions are immutable'; end; $$;

create trigger bounty_versions_immutable
before update or delete on public.bounty_versions
for each row execute procedure public.prevent_bounty_version_mutation();

create index bounties_marketplace_idx on public.bounties (status, active_until desc);
create index bounties_business_idx on public.bounties (business_id, created_at desc);
create index bounty_takers_sdr_idx on public.bounty_takers (sdr_profile_id, taken_at desc);

create trigger businesses_set_updated_at before update on public.businesses
for each row execute procedure public.set_updated_at();
create trigger bounties_set_updated_at before update on public.bounties
for each row execute procedure public.set_updated_at();
create trigger bounty_icp_set_updated_at before update on public.bounty_icp
for each row execute procedure public.set_updated_at();

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'ADMIN' and status = 'ACTIVE'
  );
$$;

create or replace function public.is_sdr()
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'SDR' and status = 'ACTIVE'
  );
$$;

alter table public.businesses enable row level security;
alter table public.bounties enable row level security;
alter table public.bounty_icp enable row level security;
alter table public.bounty_materials enable row level security;
alter table public.bounty_takers enable row level security;
alter table public.bounty_versions enable row level security;

create policy profiles_admin_read on public.profiles for select to authenticated
using ((select public.is_admin()));

create policy businesses_admin_all on public.businesses for all to authenticated
using ((select public.is_admin())) with check ((select public.is_admin()));
create policy businesses_owner_read on public.businesses for select to authenticated
using (owner_profile_id = (select auth.uid()));

create policy bounties_admin_all on public.bounties for all to authenticated
using ((select public.is_admin())) with check ((select public.is_admin()));
create policy bounties_business_read on public.bounties for select to authenticated
using (exists (select 1 from public.businesses x where x.id = business_id and x.owner_profile_id = (select auth.uid())));

create policy bounty_icp_admin_all on public.bounty_icp for all to authenticated
using ((select public.is_admin())) with check ((select public.is_admin()));
create policy bounty_icp_business_read on public.bounty_icp for select to authenticated
using (exists (select 1 from public.bounties b join public.businesses x on x.id = b.business_id where b.id = bounty_id and x.owner_profile_id = (select auth.uid())));

create policy bounty_materials_admin_all on public.bounty_materials for all to authenticated
using ((select public.is_admin())) with check ((select public.is_admin()));
create policy bounty_materials_business_read on public.bounty_materials for select to authenticated
using (exists (select 1 from public.bounties b join public.businesses x on x.id = b.business_id where b.id = bounty_id and x.owner_profile_id = (select auth.uid())));
create policy bounty_materials_taker_read on public.bounty_materials for select to authenticated
using ((select public.is_sdr()) and exists (select 1 from public.bounty_takers t where t.bounty_id = bounty_id and t.sdr_profile_id = (select auth.uid()) and t.status = 'ACTIVE'));

create policy bounty_takers_admin_read on public.bounty_takers for select to authenticated
using ((select public.is_admin()));
create policy bounty_takers_own_read on public.bounty_takers for select to authenticated
using (sdr_profile_id = (select auth.uid()));

create policy bounty_versions_admin_read on public.bounty_versions for select to authenticated
using ((select public.is_admin()));
create policy bounty_versions_business_read on public.bounty_versions for select to authenticated
using (exists (select 1 from public.bounties b join public.businesses x on x.id = b.business_id where b.id = bounty_id and x.owner_profile_id = (select auth.uid())));

-- All writes use validated RPCs; direct table writes are denied by grants/RLS.
revoke all on public.businesses, public.bounties, public.bounty_icp, public.bounty_materials, public.bounty_takers, public.bounty_versions from anon;
revoke insert, update, delete on public.businesses, public.bounties, public.bounty_icp, public.bounty_materials, public.bounty_takers, public.bounty_versions from authenticated;
grant select on public.businesses, public.bounties, public.bounty_icp, public.bounty_materials, public.bounty_takers, public.bounty_versions to authenticated;

create or replace function public.admin_create_business(payload jsonb)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare new_id uuid;
begin
  if not public.is_admin() then raise exception 'Forbidden'; end if;
  insert into public.businesses (legal_name, brand_name, inn, website, domain, description, verification_status)
  values (
    trim(payload->>'legal_name'), trim(payload->>'brand_name'), trim(payload->>'inn'),
    trim(payload->>'website'), lower(trim(payload->>'domain')), trim(coalesce(payload->>'description', '')),
    (payload->>'verification_status')::public.business_verification_status
  ) returning id into new_id;
  return new_id;
end;
$$;

create or replace function public.admin_update_business(target_id uuid, payload jsonb)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if not public.is_admin() then raise exception 'Forbidden'; end if;
  update public.businesses set
    legal_name = trim(payload->>'legal_name'), brand_name = trim(payload->>'brand_name'),
    inn = trim(payload->>'inn'), website = trim(payload->>'website'), domain = lower(trim(payload->>'domain')),
    description = trim(coalesce(payload->>'description', '')),
    verification_status = (payload->>'verification_status')::public.business_verification_status
  where id = target_id;
  if not found then raise exception 'Business not found'; end if;
end;
$$;

create or replace function public.admin_save_bounty(target_id uuid, payload jsonb, action text)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare
  actor uuid := (select auth.uid());
  saved_id uuid;
  next_status public.bounty_status;
  next_version integer;
  business_verified boolean;
  material jsonb;
  version_snapshot jsonb;
begin
  if not public.is_admin() then raise exception 'Forbidden'; end if;
  if action not in ('SAVE', 'PUBLISH', 'PAUSE') then raise exception 'Invalid action'; end if;

  select verification_status = 'VERIFIED' into business_verified
  from public.businesses where id = (payload->>'business_id')::uuid;
  if business_verified is null then raise exception 'Business not found'; end if;
  if (action = 'PUBLISH' or (target_id is not null and action = 'SAVE' and exists (select 1 from public.bounties where id = target_id and status = 'ACTIVE')))
     and not business_verified then raise exception 'Business must be VERIFIED'; end if;
  if action = 'PUBLISH' and (payload->>'active_until')::timestamptz <= now() then raise exception 'Active until must be in the future'; end if;

  next_status := case action when 'PUBLISH' then 'ACTIVE' when 'PAUSE' then 'PAUSED' else 'DRAFT' end;

  if target_id is null then
    insert into public.bounties (
      business_id, title, slug, summary, product_description, sales_website,
      reward_amount, platform_fee_amount, meeting_limit, active_until,
      minimum_duration_minutes, meeting_format, existing_crm_rule, acceptance_notes,
      status, created_by, approved_by, published_at
    ) values (
      (payload->>'business_id')::uuid, trim(payload->>'title'), trim(payload->>'slug'), trim(payload->>'summary'),
      trim(payload->>'product_description'), trim(payload->>'sales_website'),
      (payload->>'reward_amount')::bigint, (payload->>'platform_fee_amount')::bigint,
      (payload->>'meeting_limit')::integer, (payload->>'active_until')::timestamptz,
      (payload->>'minimum_duration_minutes')::integer, payload->>'meeting_format',
      trim(payload->>'existing_crm_rule'), trim(coalesce(payload->>'acceptance_notes', '')),
      next_status, actor, case when action = 'PUBLISH' then actor else null end,
      case when action = 'PUBLISH' then now() else null end
    ) returning id into saved_id;
  else
    saved_id := target_id;
    update public.bounties set
      business_id = (payload->>'business_id')::uuid, title = trim(payload->>'title'), slug = trim(payload->>'slug'),
      summary = trim(payload->>'summary'), product_description = trim(payload->>'product_description'),
      sales_website = trim(payload->>'sales_website'), reward_amount = (payload->>'reward_amount')::bigint,
      platform_fee_amount = (payload->>'platform_fee_amount')::bigint, meeting_limit = (payload->>'meeting_limit')::integer,
      active_until = (payload->>'active_until')::timestamptz, minimum_duration_minutes = (payload->>'minimum_duration_minutes')::integer,
      meeting_format = payload->>'meeting_format', existing_crm_rule = trim(payload->>'existing_crm_rule'),
      acceptance_notes = trim(coalesce(payload->>'acceptance_notes', '')),
      status = case when action = 'SAVE' and status = 'ACTIVE' then 'ACTIVE' else next_status end,
      approved_by = case when action = 'PUBLISH' then actor else approved_by end,
      published_at = case when action = 'PUBLISH' then coalesce(published_at, now()) else published_at end
    where id = target_id;
    if not found then raise exception 'Bounty not found'; end if;
  end if;

  insert into public.bounty_icp (
    bounty_id, geography, industries, excluded_industries, min_revenue, max_revenue,
    min_employees, max_employees, allowed_roles, excluded_company_inns, hard_rules, soft_notes
  ) values (
    saved_id, array(select jsonb_array_elements_text(payload->'geography')),
    array(select jsonb_array_elements_text(payload->'industries')),
    array(select jsonb_array_elements_text(payload->'excluded_industries')),
    (payload->>'min_revenue')::bigint, nullif(payload->>'max_revenue', '')::bigint,
    nullif(payload->>'min_employees', '')::integer, nullif(payload->>'max_employees', '')::integer,
    array(select jsonb_array_elements_text(payload->'allowed_roles')),
    array(select jsonb_array_elements_text(payload->'excluded_company_inns')),
    trim(coalesce(payload->>'hard_rules', '')), trim(coalesce(payload->>'soft_notes', ''))
  ) on conflict (bounty_id) do update set
    geography = excluded.geography, industries = excluded.industries, excluded_industries = excluded.excluded_industries,
    min_revenue = excluded.min_revenue, max_revenue = excluded.max_revenue,
    min_employees = excluded.min_employees, max_employees = excluded.max_employees,
    allowed_roles = excluded.allowed_roles, excluded_company_inns = excluded.excluded_company_inns,
    hard_rules = excluded.hard_rules, soft_notes = excluded.soft_notes;

  delete from public.bounty_materials where bounty_id = saved_id;
  for material in select * from jsonb_array_elements(payload->'materials') loop
    if coalesce(trim(material->>'content'), '') <> '' or coalesce(trim(material->>'external_url'), '') <> '' then
      insert into public.bounty_materials (bounty_id, label, content, external_url, material_type, sort_order)
      values (saved_id, material->>'label', nullif(trim(material->>'content'), ''), nullif(trim(material->>'external_url'), ''), material->>'material_type', (material->>'sort_order')::integer);
    end if;
  end loop;

  if action = 'PUBLISH' or (action = 'SAVE' and (select status = 'ACTIVE' from public.bounties where id = saved_id)) then
    select current_version + 1 into next_version from public.bounties where id = saved_id for update;
    select jsonb_build_object(
      'bounty', to_jsonb(b), 'icp', to_jsonb(i),
      'materials', coalesce((select jsonb_agg(to_jsonb(m) order by m.sort_order) from public.bounty_materials m where m.bounty_id = saved_id), '[]'::jsonb)
    ) into version_snapshot
    from public.bounties b join public.bounty_icp i on i.bounty_id = b.id where b.id = saved_id;
    insert into public.bounty_versions (bounty_id, version, snapshot, created_by)
    values (saved_id, next_version, version_snapshot, actor);
    update public.bounties set current_version = next_version where id = saved_id;
  end if;

  return saved_id;
end;
$$;

create or replace function public.take_bounty(target_bounty_id uuid)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if not public.is_sdr() then raise exception 'Only active SDR can take a bounty'; end if;
  if not exists (select 1 from public.bounties where id = target_bounty_id and status = 'ACTIVE' and active_until > now()) then
    raise exception 'Bounty is not active';
  end if;
  insert into public.bounty_takers (bounty_id, sdr_profile_id)
  values (target_bounty_id, (select auth.uid()))
  on conflict (bounty_id, sdr_profile_id) do update set status = 'ACTIVE';
end;
$$;

create or replace function public.marketplace_bounties()
returns table (
  id uuid, slug text, title text, summary text, brand_name text, reward_amount bigint,
  meeting_limit integer, accepted_count integer, active_until timestamptz,
  geography text[], industries text[], allowed_roles text[], min_revenue bigint,
  max_revenue bigint, min_employees integer, max_employees integer
) language sql stable security definer set search_path = ''
as $$
  select b.id, b.slug, b.title, b.summary, x.brand_name, b.reward_amount,
    b.meeting_limit, b.accepted_count, b.active_until, i.geography, i.industries,
    i.allowed_roles, i.min_revenue, i.max_revenue, i.min_employees, i.max_employees
  from public.bounties b
  join public.businesses x on x.id = b.business_id
  join public.bounty_icp i on i.bounty_id = b.id
  where (public.is_sdr() or public.is_admin()) and b.status = 'ACTIVE' and b.active_until > now()
  order by b.reward_amount desc, b.published_at desc;
$$;

create or replace function public.marketplace_bounty_detail(target_slug text)
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
declare result jsonb; has_taken boolean;
begin
  if not public.is_sdr() and not public.is_admin() then raise exception 'Forbidden'; end if;
  select exists (select 1 from public.bounty_takers t join public.bounties b on b.id = t.bounty_id where b.slug = target_slug and t.sdr_profile_id = (select auth.uid()) and t.status = 'ACTIVE') into has_taken;
  select jsonb_build_object(
    'bounty', jsonb_build_object('id', b.id, 'slug', b.slug, 'title', b.title, 'summary', b.summary, 'product_description', b.product_description, 'sales_website', b.sales_website, 'reward_amount', b.reward_amount, 'platform_fee_amount', b.platform_fee_amount, 'meeting_limit', b.meeting_limit, 'accepted_count', b.accepted_count, 'active_until', b.active_until, 'minimum_duration_minutes', b.minimum_duration_minutes, 'meeting_format', b.meeting_format, 'existing_crm_rule', b.existing_crm_rule, 'acceptance_notes', b.acceptance_notes),
    'business', jsonb_build_object('brand_name', x.brand_name, 'website', x.website, 'domain', x.domain, 'description', x.description),
    'icp', jsonb_build_object('geography', i.geography, 'industries', i.industries, 'excluded_industries', i.excluded_industries, 'min_revenue', i.min_revenue, 'max_revenue', i.max_revenue, 'min_employees', i.min_employees, 'max_employees', i.max_employees, 'allowed_roles', i.allowed_roles, 'hard_rules', i.hard_rules, 'soft_notes', i.soft_notes),
    'has_taken', has_taken,
    'materials', case when has_taken or public.is_admin() then coalesce((select jsonb_agg(jsonb_build_object('label', m.label, 'content', m.content, 'external_url', m.external_url, 'material_type', m.material_type) order by m.sort_order) from public.bounty_materials m where m.bounty_id = b.id), '[]'::jsonb) else '[]'::jsonb end
  ) into result
  from public.bounties b join public.businesses x on x.id = b.business_id join public.bounty_icp i on i.bounty_id = b.id
  where b.slug = target_slug and b.status = 'ACTIVE' and b.active_until > now();
  return result;
end;
$$;

create or replace function public.sdr_workspace()
returns table (id uuid, slug text, title text, brand_name text, reward_amount bigint, geography text[], industries text[], allowed_roles text[], taken_at timestamptz)
language sql stable security definer set search_path = ''
as $$
  select b.id, b.slug, b.title, x.brand_name, b.reward_amount, i.geography, i.industries, i.allowed_roles, t.taken_at
  from public.bounty_takers t join public.bounties b on b.id = t.bounty_id join public.businesses x on x.id = b.business_id join public.bounty_icp i on i.bounty_id = b.id
  where public.is_sdr() and t.sdr_profile_id = (select auth.uid()) and t.status = 'ACTIVE'
  order by t.taken_at desc;
$$;

revoke all on function public.admin_create_business(jsonb), public.admin_update_business(uuid, jsonb), public.admin_save_bounty(uuid, jsonb, text), public.take_bounty(uuid), public.marketplace_bounties(), public.marketplace_bounty_detail(text), public.sdr_workspace() from public;
grant execute on function public.admin_create_business(jsonb), public.admin_update_business(uuid, jsonb), public.admin_save_bounty(uuid, jsonb, text), public.take_bounty(uuid), public.marketplace_bounties(), public.marketplace_bounty_detail(text), public.sdr_workspace() to authenticated;
revoke all on function public.is_admin(), public.is_sdr() from public;
grant execute on function public.is_admin(), public.is_sdr() to authenticated;
revoke all on function public.prevent_bounty_version_mutation() from public;
