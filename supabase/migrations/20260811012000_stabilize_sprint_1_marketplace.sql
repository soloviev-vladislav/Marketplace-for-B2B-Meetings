-- Stabilize Sprint 1 marketplace rules without rewriting applied migrations.

create or replace function public.pause_active_bounties_for_suspended_business()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if new.verification_status = 'SUSPENDED' and old.verification_status is distinct from 'SUSPENDED' then
    update public.bounties
       set status = 'PAUSED'
     where business_id = new.id and status = 'ACTIVE';
  end if;
  return new;
end;
$$;

create trigger businesses_pause_active_bounties
after update of verification_status on public.businesses
for each row execute procedure public.pause_active_bounties_for_suspended_business();

create or replace function public.require_verified_business_for_active_bounty()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if new.status = 'ACTIVE' and not exists (
    select 1 from public.businesses x
    where x.id = new.business_id and x.verification_status = 'VERIFIED'
  ) then
    raise exception using errcode = 'P0001', message = 'BUSINESS_NOT_VERIFIED';
  end if;
  return new;
end;
$$;

create trigger bounties_require_verified_business
before insert or update of status, business_id on public.bounties
for each row execute procedure public.require_verified_business_for_active_bounty();

create or replace function public.bounty_versioned_snapshot(target_bounty_id uuid)
returns jsonb language sql stable security definer set search_path = ''
as $$
  select jsonb_build_object(
    'bounty', jsonb_build_object(
      'business_id', b.business_id, 'title', b.title, 'summary', b.summary,
      'product_description', b.product_description, 'sales_website', b.sales_website,
      'reward_amount', b.reward_amount, 'platform_fee_amount', b.platform_fee_amount,
      'currency', b.currency, 'meeting_limit', b.meeting_limit,
      'active_until', b.active_until, 'minimum_duration_minutes', b.minimum_duration_minutes,
      'meeting_format', b.meeting_format, 'existing_crm_rule', b.existing_crm_rule,
      'acceptance_notes', b.acceptance_notes
    ),
    'icp', jsonb_build_object(
      'geography', i.geography, 'industries', i.industries,
      'excluded_industries', i.excluded_industries, 'min_revenue', i.min_revenue,
      'max_revenue', i.max_revenue, 'min_employees', i.min_employees,
      'max_employees', i.max_employees, 'allowed_roles', i.allowed_roles,
      'excluded_company_inns', i.excluded_company_inns, 'hard_rules', i.hard_rules,
      'soft_notes', i.soft_notes
    ),
    'materials', coalesce((
      select jsonb_agg(jsonb_build_object(
        'label', m.label, 'content', m.content, 'external_url', m.external_url,
        'material_type', m.material_type, 'sort_order', m.sort_order
      ) order by m.sort_order, m.material_type, m.label)
      from public.bounty_materials m where m.bounty_id = b.id
    ), '[]'::jsonb)
  )
  from public.bounties b
  join public.bounty_icp i on i.bounty_id = b.id
  where b.id = target_bounty_id;
$$;

-- Canonicalize legacy Sprint 1 snapshots without mutating their immutable rows.
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
      'excluded_company_inns', source#>'{icp,excluded_company_inns}', 'hard_rules', source#>'{icp,hard_rules}',
      'soft_notes', source#>'{icp,soft_notes}'
    ),
    'materials', coalesce((select jsonb_agg(jsonb_build_object(
      'label', item->'label', 'content', item->'content', 'external_url', item->'external_url',
      'material_type', item->'material_type', 'sort_order', item->'sort_order'
    ) order by (item->>'sort_order')::integer, item->>'material_type', item->>'label')
    from jsonb_array_elements(coalesce(source->'materials', '[]'::jsonb)) item), '[]'::jsonb)
  );
$$;

create or replace function public.admin_save_bounty(target_id uuid, payload jsonb, action text)
returns uuid language plpgsql security definer set search_path = ''
as $$
declare
  actor uuid := (select auth.uid());
  saved_id uuid;
  material jsonb;
  version_snapshot jsonb;
  previous_snapshot jsonb;
  previous_version integer;
begin
  if not public.is_admin() then raise exception using errcode = '42501', message = 'FORBIDDEN'; end if;
  if action not in ('SAVE', 'PUBLISH', 'PAUSE') then raise exception 'INVALID_ACTION'; end if;

  -- PAUSE is status-only. It must never rewrite content or create a version.
  if action = 'PAUSE' then
    if target_id is null then raise exception 'BOUNTY_NOT_FOUND'; end if;
    update public.bounties set status = 'PAUSED'
      where id = target_id and status in ('ACTIVE', 'PAUSED');
    if not found then raise exception 'BOUNTY_CANNOT_BE_PAUSED'; end if;
    return target_id;
  end if;

  if not exists (select 1 from public.businesses where id = (payload->>'business_id')::uuid) then
    raise exception 'BUSINESS_NOT_FOUND';
  end if;
  if action = 'PUBLISH' and not exists (
    select 1 from public.businesses
    where id = (payload->>'business_id')::uuid and verification_status = 'VERIFIED'
  ) then
    raise exception 'BUSINESS_NOT_VERIFIED';
  end if;
  if action = 'PUBLISH' and (payload->>'active_until')::timestamptz <= now() then
    raise exception 'ACTIVE_UNTIL_IN_PAST';
  end if;

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
      case when action = 'PUBLISH' then 'ACTIVE'::public.bounty_status else 'DRAFT'::public.bounty_status end,
      actor, case when action = 'PUBLISH' then actor end, case when action = 'PUBLISH' then now() end
    ) returning id into saved_id;
  else
    select id into saved_id from public.bounties where id = target_id for update;
    if saved_id is null then raise exception 'BOUNTY_NOT_FOUND'; end if;
    update public.bounties set
      business_id = (payload->>'business_id')::uuid, title = trim(payload->>'title'), slug = trim(payload->>'slug'),
      summary = trim(payload->>'summary'), product_description = trim(payload->>'product_description'),
      sales_website = trim(payload->>'sales_website'), reward_amount = (payload->>'reward_amount')::bigint,
      platform_fee_amount = (payload->>'platform_fee_amount')::bigint, meeting_limit = (payload->>'meeting_limit')::integer,
      active_until = (payload->>'active_until')::timestamptz,
      minimum_duration_minutes = (payload->>'minimum_duration_minutes')::integer,
      meeting_format = payload->>'meeting_format', existing_crm_rule = trim(payload->>'existing_crm_rule'),
      acceptance_notes = trim(coalesce(payload->>'acceptance_notes', '')),
      status = case when action = 'PUBLISH' then 'ACTIVE'::public.bounty_status else status end,
      approved_by = case when action = 'PUBLISH' then actor else approved_by end,
      published_at = case when action = 'PUBLISH' then coalesce(published_at, now()) else published_at end
    where id = saved_id;
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
    geography = excluded.geography, industries = excluded.industries,
    excluded_industries = excluded.excluded_industries, min_revenue = excluded.min_revenue,
    max_revenue = excluded.max_revenue, min_employees = excluded.min_employees,
    max_employees = excluded.max_employees, allowed_roles = excluded.allowed_roles,
    excluded_company_inns = excluded.excluded_company_inns, hard_rules = excluded.hard_rules,
    soft_notes = excluded.soft_notes;

  delete from public.bounty_materials where bounty_id = saved_id;
  for material in select * from jsonb_array_elements(payload->'materials') loop
    if coalesce(trim(material->>'content'), '') <> '' or coalesce(trim(material->>'external_url'), '') <> '' then
      insert into public.bounty_materials (bounty_id, label, content, external_url, material_type, sort_order)
      values (saved_id, material->>'label', nullif(trim(material->>'content'), ''),
        nullif(trim(material->>'external_url'), ''), material->>'material_type', (material->>'sort_order')::integer);
    end if;
  end loop;

  -- Only published content is versioned. Status and audit timestamps are excluded.
  if (select status = 'ACTIVE' from public.bounties where id = saved_id) then
    version_snapshot := public.bounty_versioned_snapshot(saved_id);
    select version, snapshot into previous_version, previous_snapshot
      from public.bounty_versions where bounty_id = saved_id order by version desc limit 1;
    if previous_snapshot is null or public.normalize_bounty_version_snapshot(previous_snapshot) is distinct from version_snapshot then
      insert into public.bounty_versions (bounty_id, version, snapshot, created_by)
      values (saved_id, coalesce(previous_version, 0) + 1, version_snapshot, actor);
      update public.bounties set current_version = coalesce(previous_version, 0) + 1 where id = saved_id;
    end if;
  end if;
  return saved_id;
end;
$$;

drop function public.sdr_workspace();
create function public.sdr_workspace()
returns table (
  id uuid, slug text, title text, brand_name text, reward_amount bigint,
  status public.bounty_status, is_expired boolean, geography text[], industries text[],
  allowed_roles text[], taken_at timestamptz
)
language sql stable security definer set search_path = ''
as $$
  select b.id, b.slug, b.title, x.brand_name, b.reward_amount, b.status,
    (b.status = 'ACTIVE' and b.active_until <= now()) as is_expired,
    i.geography, i.industries, i.allowed_roles, t.taken_at
  from public.bounty_takers t
  join public.bounties b on b.id = t.bounty_id
  join public.businesses x on x.id = b.business_id
  join public.bounty_icp i on i.bounty_id = b.id
  where public.is_sdr() and t.sdr_profile_id = (select auth.uid()) and t.status = 'ACTIVE'
  order by (b.status = 'ACTIVE' and b.active_until <= now()), t.taken_at desc;
$$;

-- Return derived expiry in detail while preserving private historical access.
create or replace function public.marketplace_bounty_detail(target_slug text)
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
declare result jsonb; has_taken boolean; actor_is_admin boolean := public.is_admin();
begin
  if not public.is_sdr() and not actor_is_admin then raise exception 'FORBIDDEN'; end if;
  select exists (
    select 1 from public.bounty_takers t join public.bounties b on b.id = t.bounty_id
    where b.slug = target_slug and t.sdr_profile_id = (select auth.uid()) and t.status = 'ACTIVE'
  ) into has_taken;
  select jsonb_build_object(
    'bounty', jsonb_build_object(
      'id', b.id, 'slug', b.slug, 'title', b.title, 'summary', b.summary, 'status', b.status,
      'is_expired', (b.status = 'ACTIVE' and b.active_until <= now()),
      'product_description', b.product_description, 'sales_website', b.sales_website,
      'reward_amount', b.reward_amount, 'platform_fee_amount', b.platform_fee_amount,
      'meeting_limit', b.meeting_limit, 'accepted_count', b.accepted_count,
      'active_until', b.active_until, 'minimum_duration_minutes', b.minimum_duration_minutes,
      'meeting_format', b.meeting_format, 'existing_crm_rule', b.existing_crm_rule,
      'acceptance_notes', b.acceptance_notes
    ),
    'business', jsonb_build_object('brand_name', x.brand_name, 'website', x.website, 'domain', x.domain, 'description', x.description),
    'icp', jsonb_build_object(
      'geography', i.geography, 'industries', i.industries, 'excluded_industries', i.excluded_industries,
      'min_revenue', i.min_revenue, 'max_revenue', i.max_revenue, 'min_employees', i.min_employees,
      'max_employees', i.max_employees, 'allowed_roles', i.allowed_roles,
      'hard_rules', i.hard_rules, 'soft_notes', i.soft_notes
    ),
    'has_taken', has_taken,
    'materials', case when has_taken or actor_is_admin then coalesce((
      select jsonb_agg(jsonb_build_object('label', m.label, 'content', m.content,
        'external_url', m.external_url, 'material_type', m.material_type) order by m.sort_order)
      from public.bounty_materials m where m.bounty_id = b.id
    ), '[]'::jsonb) else '[]'::jsonb end
  ) into result
  from public.bounties b join public.businesses x on x.id = b.business_id
  join public.bounty_icp i on i.bounty_id = b.id
  where b.slug = target_slug and ((b.status = 'ACTIVE' and b.active_until > now()) or has_taken or actor_is_admin);
  return result;
end;
$$;

revoke all on function public.pause_active_bounties_for_suspended_business(),
  public.require_verified_business_for_active_bounty(), public.bounty_versioned_snapshot(uuid),
  public.normalize_bounty_version_snapshot(jsonb) from public;
revoke all on function public.admin_save_bounty(uuid, jsonb, text), public.sdr_workspace(),
  public.marketplace_bounty_detail(text) from public;
grant execute on function public.admin_save_bounty(uuid, jsonb, text), public.sdr_workspace(),
  public.marketplace_bounty_detail(text) to authenticated;
