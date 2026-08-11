-- Separate ACTIVE marketplace discoverability from existing taker history access.
-- No tables or RLS policies are changed.

create or replace function public.marketplace_bounty_detail(target_slug text)
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
declare
  result jsonb;
  has_taken boolean;
  actor_is_admin boolean := public.is_admin();
begin
  if not public.is_sdr() and not actor_is_admin then
    raise exception 'Forbidden';
  end if;

  select exists (
    select 1
    from public.bounty_takers t
    join public.bounties b on b.id = t.bounty_id
    where b.slug = target_slug
      and t.sdr_profile_id = (select auth.uid())
      and t.status = 'ACTIVE'
  ) into has_taken;

  select jsonb_build_object(
    'bounty', jsonb_build_object(
      'id', b.id,
      'slug', b.slug,
      'title', b.title,
      'summary', b.summary,
      'status', b.status,
      'product_description', b.product_description,
      'sales_website', b.sales_website,
      'reward_amount', b.reward_amount,
      'platform_fee_amount', b.platform_fee_amount,
      'meeting_limit', b.meeting_limit,
      'accepted_count', b.accepted_count,
      'active_until', b.active_until,
      'minimum_duration_minutes', b.minimum_duration_minutes,
      'meeting_format', b.meeting_format,
      'existing_crm_rule', b.existing_crm_rule,
      'acceptance_notes', b.acceptance_notes
    ),
    'business', jsonb_build_object(
      'brand_name', x.brand_name,
      'website', x.website,
      'domain', x.domain,
      'description', x.description
    ),
    'icp', jsonb_build_object(
      'geography', i.geography,
      'industries', i.industries,
      'excluded_industries', i.excluded_industries,
      'min_revenue', i.min_revenue,
      'max_revenue', i.max_revenue,
      'min_employees', i.min_employees,
      'max_employees', i.max_employees,
      'allowed_roles', i.allowed_roles,
      'hard_rules', i.hard_rules,
      'soft_notes', i.soft_notes
    ),
    'has_taken', has_taken,
    'materials', case
      when has_taken or actor_is_admin then coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'label', m.label,
            'content', m.content,
            'external_url', m.external_url,
            'material_type', m.material_type
          ) order by m.sort_order
        )
        from public.bounty_materials m
        where m.bounty_id = b.id
      ), '[]'::jsonb)
      else '[]'::jsonb
    end
  ) into result
  from public.bounties b
  join public.businesses x on x.id = b.business_id
  join public.bounty_icp i on i.bounty_id = b.id
  where b.slug = target_slug
    and (
      (b.status = 'ACTIVE' and b.active_until > now())
      or has_taken
      or actor_is_admin
    );

  return result;
end;
$$;

-- PostgreSQL requires a drop when a function's return row type changes.
drop function public.sdr_workspace();

create function public.sdr_workspace()
returns table (
  id uuid,
  slug text,
  title text,
  brand_name text,
  reward_amount bigint,
  status public.bounty_status,
  geography text[],
  industries text[],
  allowed_roles text[],
  taken_at timestamptz
)
language sql stable security definer set search_path = ''
as $$
  select
    b.id,
    b.slug,
    b.title,
    x.brand_name,
    b.reward_amount,
    b.status,
    i.geography,
    i.industries,
    i.allowed_roles,
    t.taken_at
  from public.bounty_takers t
  join public.bounties b on b.id = t.bounty_id
  join public.businesses x on x.id = b.business_id
  join public.bounty_icp i on i.bounty_id = b.id
  where public.is_sdr()
    and t.sdr_profile_id = (select auth.uid())
    and t.status = 'ACTIVE'
  order by
    case b.status
      when 'ACTIVE' then 1
      when 'PAUSED' then 2
      when 'COMPLETED' then 3
      when 'ARCHIVED' then 4
      else 5
    end,
    t.taken_at desc;
$$;

revoke all on function public.marketplace_bounty_detail(text), public.sdr_workspace() from public;
grant execute on function public.marketplace_bounty_detail(text), public.sdr_workspace() to authenticated;
