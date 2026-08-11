begin;
create extension if not exists pgtap with schema extensions;
select plan(33);

-- Deterministic, isolated TEST fixtures. The final rollback is the cleanup.
insert into auth.users (id, instance_id, aud, role, email, encrypted_password, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('a0000000-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'TEST-admin@example.test', '', '{}', '{"role":"SDR","display_name":"TEST Admin"}', now(), now()),
  ('a0000000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'TEST-sdr-a@example.test', '', '{}', '{"role":"SDR","display_name":"TEST SDR A"}', now(), now()),
  ('a0000000-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'TEST-sdr-b@example.test', '', '{}', '{"role":"SDR","display_name":"TEST SDR B"}', now(), now()),
  ('a0000000-0000-4000-8000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'TEST-business@example.test', '', '{}', '{"role":"BUSINESS","display_name":"TEST Business"}', now(), now());
update public.profiles set role = 'ADMIN', status = 'ACTIVE' where id = 'a0000000-0000-4000-8000-000000000001';

create or replace function pg_temp.jwt(user_id uuid) returns void language plpgsql as $$
begin perform set_config('request.jwt.claim.sub', user_id::text, true); end $$;
create or replace function pg_temp.payload(business uuid, slug text, hard_rule text default 'TEST hard') returns jsonb language sql as $$
  select jsonb_build_object(
    'business_id', business, 'title', 'TEST bounty ' || slug, 'slug', slug,
    'summary', 'TEST summary long enough', 'product_description', 'TEST product description long enough',
    'sales_website', 'https://test.example', 'reward_amount', 100000, 'platform_fee_amount', 10000,
    'meeting_limit', 5, 'active_until', (now() + interval '30 days'),
    'minimum_duration_minutes', 30, 'meeting_format', 'ONLINE',
    'existing_crm_rule', 'TEST no active CRM in 90 days', 'acceptance_notes', '',
    'geography', '["TEST RU"]'::jsonb, 'industries', '["TEST SaaS"]'::jsonb,
    'excluded_industries', '[]'::jsonb, 'min_revenue', 0, 'max_revenue', '',
    'min_employees', '', 'max_employees', '', 'allowed_roles', '["TEST CEO"]'::jsonb,
    'excluded_company_inns', '[]'::jsonb, 'hard_rules', hard_rule, 'soft_notes', 'TEST soft',
    'materials', '[{"label":"TEST private","content":"TEST SECRET","external_url":"","material_type":"PAINS","sort_order":10}]'::jsonb
  );
$$;

select pg_temp.jwt('a0000000-0000-4000-8000-000000000001');
insert into public.businesses (id, legal_name, brand_name, inn, website, domain, verification_status)
values
 ('b0000000-0000-4000-8000-000000000001', 'TEST Pending LLC', 'TEST Pending', 'TEST-INN-1', 'https://test.example', 'test.example', 'PENDING'),
 ('b0000000-0000-4000-8000-000000000002', 'TEST Verified LLC', 'TEST Verified', 'TEST-INN-2', 'https://test.example', 'test2.example', 'VERIFIED');

select lives_ok($$select public.admin_save_bounty(null, pg_temp.payload('b0000000-0000-4000-8000-000000000001','test-pending'), 'SAVE')$$, '1 PENDING can save DRAFT');
select is((select status::text from public.bounties where slug='test-pending'), 'DRAFT', '1 saved row is DRAFT');
select throws_ok($$select public.admin_save_bounty((select id from public.bounties where slug='test-pending'), pg_temp.payload('b0000000-0000-4000-8000-000000000001','test-pending'), 'PUBLISH')$$, 'P0001', 'BUSINESS_NOT_VERIFIED', '2 PENDING publish rejected');
select is((select status::text from public.bounties where slug='test-pending'), 'DRAFT', '2 status remains DRAFT');

update public.businesses set verification_status='VERIFIED' where id='b0000000-0000-4000-8000-000000000001';
select lives_ok($$select public.admin_save_bounty((select id from public.bounties where slug='test-pending'), pg_temp.payload('b0000000-0000-4000-8000-000000000001','test-pending'), 'PUBLISH')$$, '3 verified publish succeeds');
select is((select status::text from public.bounties where slug='test-pending'), 'ACTIVE', '3 bounty is ACTIVE');

update public.businesses set verification_status='SUSPENDED' where id='b0000000-0000-4000-8000-000000000001';
select is((select status::text from public.bounties where slug='test-pending'), 'PAUSED', '4 suspension atomically pauses ACTIVE bounty');
select is((select count(*) from public.marketplace_bounties() where slug='test-pending'), 0::bigint, '4 paused bounty absent from marketplace');
update public.businesses set verification_status='VERIFIED' where id='b0000000-0000-4000-8000-000000000001';
select is((select status::text from public.bounties where slug='test-pending'), 'PAUSED', '5 verification does not auto-resume');

select public.admin_save_bounty(null, pg_temp.payload('b0000000-0000-4000-8000-000000000002','test-active'), 'PUBLISH');
select pg_temp.jwt('a0000000-0000-4000-8000-000000000002');
select public.take_bounty((select id from public.bounties where slug='test-active'));
select pg_temp.jwt('a0000000-0000-4000-8000-000000000001');
select public.admin_save_bounty((select id from public.bounties where slug='test-active'), '{}'::jsonb, 'PAUSE');
select pg_temp.jwt('a0000000-0000-4000-8000-000000000002');
select is((select status::text from public.sdr_workspace() where slug='test-active'), 'PAUSED', '6 taker keeps paused bounty in workspace');
select is((public.marketplace_bounty_detail('test-active')->>'has_taken')::boolean, true, '6 taker keeps private detail access');
select is(public.marketplace_bounty_detail('test-active')#>>'{materials,0,content}', 'TEST SECRET', '6 private brief remains readable');

select pg_temp.jwt('a0000000-0000-4000-8000-000000000003');
select is((select count(*) from public.marketplace_bounties() where slug='test-active'), 0::bigint, '7 non-taker cannot discover paused bounty');
select is(public.marketplace_bounty_detail('test-active'), null, '7 direct slug reveals nothing to non-taker');
select throws_ok($$select public.take_bounty((select id from public.bounties where slug='test-active'))$$, 'P0001', 'Bounty is not active', '7 Take is rejected');

select pg_temp.jwt('a0000000-0000-4000-8000-000000000001');
create temporary table before_resume as select current_version, taken_at from public.bounties b join public.bounty_takers t on t.bounty_id=b.id where b.slug='test-active' and t.sdr_profile_id='a0000000-0000-4000-8000-000000000002';
select public.admin_save_bounty((select id from public.bounties where slug='test-active'), pg_temp.payload('b0000000-0000-4000-8000-000000000002','test-active'), 'PUBLISH');
select is((select current_version from public.bounties where slug='test-active'), (select current_version from before_resume), '8 resume without content change preserves version');
select is((select taken_at from public.bounty_takers t join public.bounties b on b.id=t.bounty_id where b.slug='test-active' and t.sdr_profile_id='a0000000-0000-4000-8000-000000000002'), (select taken_at from before_resume), '8 original taker and taken_at preserved');
select public.admin_save_bounty((select id from public.bounties where slug='test-active'), pg_temp.payload('b0000000-0000-4000-8000-000000000002','test-active','TEST changed hard'), 'SAVE');
select is((select current_version from public.bounties where slug='test-active'), (select current_version + 1 from before_resume), '9 ACTIVE hard criterion change increments exactly once');
select is((select count(*) from public.bounty_versions v join public.bounties b on b.id=v.bounty_id where b.slug='test-active'), 2::bigint, '9 previous version remains');
select throws_ok($$update public.bounty_versions set snapshot='{}' where bounty_id=(select id from public.bounties where slug='test-active')$$, 'P0001', 'Bounty versions are immutable', '9 previous versions are immutable');

update public.bounties set active_until=now()-interval '1 second' where slug='test-active';
select pg_temp.jwt('a0000000-0000-4000-8000-000000000002');
select is((select is_expired from public.sdr_workspace() where slug='test-active'), true, '10 existing taker sees derived expiry');
select is((public.marketplace_bounty_detail('test-active')#>>'{bounty,is_expired}')::boolean, true, '10 existing taker keeps historical brief');
select pg_temp.jwt('a0000000-0000-4000-8000-000000000003');
select throws_ok($$select public.take_bounty((select id from public.bounties where slug='test-active'))$$, 'P0001', 'Bounty is not active', '10 expired Take rejected');

select pg_temp.jwt('a0000000-0000-4000-8000-000000000001');
update public.bounties set active_until=now()+interval '1 day' where slug='test-active';
select pg_temp.jwt('a0000000-0000-4000-8000-000000000002');
select public.take_bounty((select id from public.bounties where slug='test-active'));
select public.take_bounty((select id from public.bounties where slug='test-active'));
select is((select count(*) from public.bounty_takers t join public.bounties b on b.id=t.bounty_id where b.slug='test-active' and t.sdr_profile_id='a0000000-0000-4000-8000-000000000002'), 1::bigint, '11 repeated Take is idempotent');
select pg_temp.jwt('a0000000-0000-4000-8000-000000000003');
select public.take_bounty((select id from public.bounties where slug='test-active'));
select is((select count(*) from public.bounty_takers t join public.bounties b on b.id=t.bounty_id where b.slug='test-active'), 2::bigint, '12 two SDRs create two taker rows');
select is((select meeting_limit from public.bounties where slug='test-active'), 5, '13 Take does not change meeting_limit');
select is((select accepted_count from public.bounties where slug='test-active'), 0, '13 Take does not change accepted_count');
select throws_ok($$select public.admin_save_bounty(null, '{}'::jsonb, 'SAVE')$$, '42501', 'FORBIDDEN', '14 SDR cannot create or mutate bounty through admin RPC');
select is(has_table_privilege('authenticated', 'public.businesses', 'INSERT'), false, '14 authenticated role cannot directly create business');
select is(has_table_privilege('authenticated', 'public.bounties', 'INSERT'), false, '14 authenticated role cannot directly create bounty');
select is(has_table_privilege('authenticated', 'public.bounties', 'UPDATE'), false, '14 authenticated role cannot directly change price or status');

select pg_temp.jwt('a0000000-0000-4000-8000-000000000004');
select throws_ok($$select public.admin_create_business('{}')$$, 'P0001', 'Forbidden', '15 BUSINESS cannot use admin mutations');
select pg_temp.jwt('a0000000-0000-4000-8000-000000000003');
select is(public.marketplace_bounty_detail('test-pending'), null, '16 another SDR cannot access paused bounty detail/private materials');

select * from finish();
rollback;
