begin;
create extension if not exists pgtap with schema extensions;
select plan(70);

insert into auth.users (id, instance_id, aud, role, email, encrypted_password, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('c0000000-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'TEST-s2-admin@example.test', '', '{}', '{"role":"SDR","display_name":"TEST S2 Admin"}', now(), now()),
  ('c0000000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'TEST-s2-sdr-a@example.test', '', '{}', '{"role":"SDR","display_name":"TEST S2 SDR A"}', now(), now()),
  ('c0000000-0000-4000-8000-000000000003', '00000000-0000-0000-8000-000000000000', 'authenticated', 'authenticated', 'TEST-s2-sdr-b@example.test', '', '{}', '{"role":"SDR","display_name":"TEST S2 SDR B"}', now(), now()),
  ('c0000000-0000-4000-8000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'TEST-s2-business@example.test', '', '{}', '{"role":"BUSINESS","display_name":"TEST S2 Business"}', now(), now());
update public.profiles set role = 'ADMIN', status = 'ACTIVE' where id = 'c0000000-0000-4000-8000-000000000001';

create or replace function pg_temp.jwt(user_id uuid) returns void language plpgsql as $$
begin perform set_config('request.jwt.claim.sub', user_id::text, true); end $$;

create or replace function pg_temp.bounty_payload(business uuid, slug text, excluded jsonb default '[]'::jsonb)
returns jsonb language sql as $$
  select jsonb_build_object(
    'business_id', business, 'title', 'TEST S2 bounty ' || slug, 'slug', slug,
    'summary', 'TEST S2 summary long enough', 'product_description', 'TEST S2 product description long enough',
    'sales_website', 'https://s2.example', 'reward_amount', 150000, 'platform_fee_amount', 15000,
    'meeting_limit', 7, 'active_until', now() + interval '30 days',
    'minimum_duration_minutes', 30, 'meeting_format', 'ONLINE',
    'existing_crm_rule', 'TEST no active CRM in 90 days', 'acceptance_notes', '',
    'geography', '["TEST RU"]'::jsonb, 'industries', '["TEST SaaS"]'::jsonb,
    'excluded_industries', '[]'::jsonb, 'min_revenue', 0, 'max_revenue', '',
    'min_employees', '', 'max_employees', '', 'allowed_roles', '["TEST CEO"]'::jsonb,
    'excluded_company_inns', excluded, 'hard_rules', 'TEST hard', 'soft_notes', 'TEST soft',
    'materials', '[]'::jsonb
  );
$$;

create or replace function pg_temp.prospect_payload(
  company text, inn text default '', domain text default '', email text default 'contact@test.example'
) returns jsonb language sql as $$
  select jsonb_build_object(
    'company_name', company, 'company_inn', inn, 'company_domain', domain,
    'contact_name', 'TEST Contact', 'contact_title', 'TEST CEO', 'contact_email', email,
    'contact_phone', '', 'contact_telegram', '', 'source_url', ''
  );
$$;

select is(public.normalize_company_domain('https://www.Example.com/about'), 'example.com', '1 domain normalization is authoritative in DB');
select is(public.normalize_company_inn(' 77-070 838-93 '), '7707083893', '2 INN normalization removes formatting');

select pg_temp.jwt('c0000000-0000-4000-8000-000000000001');
insert into public.businesses (id, legal_name, brand_name, inn, website, domain, verification_status)
values
  ('d0000000-0000-4000-8000-000000000001', 'TEST S2 Verified LLC', 'TEST S2 Verified', 'TEST-S2-B1', 'https://s2.example', 's2.example', 'VERIFIED'),
  ('d0000000-0000-4000-8000-000000000002', 'TEST S2 Other LLC', 'TEST S2 Other', 'TEST-S2-B2', 'https://s2b.example', 's2b.example', 'VERIFIED'),
  ('d0000000-0000-4000-8000-000000000003', 'TEST S2 Suspend LLC', 'TEST S2 Suspend', 'TEST-S2-B3', 'https://s2c.example', 's2c.example', 'VERIFIED');

select public.admin_save_bounty(null, pg_temp.bounty_payload('d0000000-0000-4000-8000-000000000001', 'test-s2-main'), 'PUBLISH');
select public.admin_save_bounty(null, pg_temp.bounty_payload('d0000000-0000-4000-8000-000000000002', 'test-s2-other'), 'PUBLISH');
select public.admin_save_bounty(null, pg_temp.bounty_payload('d0000000-0000-4000-8000-000000000001', 'test-s2-excluded', '[" 77-070 838-93 "]'::jsonb), 'PUBLISH');
select public.admin_save_bounty(null, pg_temp.bounty_payload('d0000000-0000-4000-8000-000000000003', 'test-s2-suspend'), 'PUBLISH');

create temporary table s2_baseline as
select id, slug, meeting_limit, accepted_count, current_version
from public.bounties where slug like 'test-s2-%';

select pg_temp.jwt('c0000000-0000-4000-8000-000000000002');
select throws_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-main'), pg_temp.prospect_payload('TEST No Take','7700000009','notake.example'))$$,
  'P0001', 'BOUNTY_NOT_TAKEN', '3 SDR without Take cannot register'
);
select public.take_bounty((select id from public.bounties where slug='test-s2-main'));
select lives_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-main'), pg_temp.prospect_payload('TEST Main Co','77-070 838-93','main.example'))$$,
  '4 SDR with Take registers for ACTIVE bounty'
);
select is((select status::text from public.prospects where company_name='TEST Main Co'), 'PENDING', '5 new prospect is PENDING');
select is((select count(*) from public.sdr_prospects() where company_name='TEST Main Co'), 1::bigint, '6 SDR sees own prospect');

select pg_temp.jwt('c0000000-0000-4000-8000-000000000003');
select is((select count(*) from public.sdr_prospects() where company_name='TEST Main Co'), 0::bigint, '7 another SDR sees no foreign prospect');
select public.take_bounty((select id from public.bounties where slug='test-s2-main'));
select throws_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-main'), pg_temp.prospect_payload('TEST Duplicate INN','7707083893','other-domain.example'))$$,
  'P0001', 'PROSPECT_DUPLICATE', '8 normalized duplicate INN is blocked'
);

select pg_temp.jwt('c0000000-0000-4000-8000-000000000002');
select lives_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-main'), pg_temp.prospect_payload('TEST Domain Co','500100732259','https://www.DomainCo.example/about','domain-a@test.example'))$$,
  '9 valid 12-digit INN registers'
);
select pg_temp.jwt('c0000000-0000-4000-8000-000000000003');
select throws_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-main'), pg_temp.prospect_payload('TEST Domain Duplicate','5001-0073 2259','different.example','domain-b@test.example'))$$,
  'P0001', 'PROSPECT_DUPLICATE', '10 same INN with a different domain is blocked'
);
select public.take_bounty((select id from public.bounties where slug='test-s2-other'));
select lives_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-other'), pg_temp.prospect_payload('TEST Domain Other Bounty','500100732259','domainco.example','domain-c@test.example'))$$,
  '11 same company can exist in another bounty'
);
select throws_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-main'), pg_temp.prospect_payload('TEST Pending Capture','500100732259','domainco.example','domain-d@test.example'))$$,
  'P0001', 'PROSPECT_DUPLICATE', '12 PENDING ownership cannot be captured'
);

select pg_temp.jwt('c0000000-0000-4000-8000-000000000001');
select lives_ok(
  $$select public.review_prospect((select id from public.prospects where company_name='TEST Main Co'), 'APPROVED', null)$$,
  '13 ADMIN can approve'
);
select is((select status::text from public.prospects where company_name='TEST Main Co'), 'APPROVED', '14 approved status is stored');
select lives_ok(
  $$select public.review_prospect((select id from public.prospects where company_name='TEST Main Co'), 'APPROVED', null)$$,
  '15 exact approve retry is idempotent'
);
select pg_temp.jwt('c0000000-0000-4000-8000-000000000003');
select throws_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-main'), pg_temp.prospect_payload('TEST Approved Capture','7707083893','capture.example'))$$,
  'P0001', 'PROSPECT_DUPLICATE', '16 APPROVED ownership cannot be captured'
);
select throws_ok(
  $$select public.review_prospect((select id from public.prospects where company_name='TEST Domain Co'), 'APPROVED', null)$$,
  '42501', 'FORBIDDEN', '17 SDR cannot review'
);

select pg_temp.jwt('c0000000-0000-4000-8000-000000000004');
select throws_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-main'), pg_temp.prospect_payload('TEST Business Register','7700000016','business.example'))$$,
  '42501', 'FORBIDDEN', '18 BUSINESS cannot register'
);
select throws_ok(
  $$select public.review_prospect((select id from public.prospects where company_name='TEST Domain Co'), 'APPROVED', null)$$,
  '42501', 'FORBIDDEN', '19 BUSINESS cannot review'
);

select pg_temp.jwt('c0000000-0000-4000-8000-000000000002');
select public.take_bounty((select id from public.bounties where slug='test-s2-excluded'));
select throws_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-excluded'), pg_temp.prospect_payload('TEST Excluded','7707083893','excluded.example'))$$,
  'P0001', 'COMPANY_NOT_ELIGIBLE', '20 excluded normalized INN is blocked'
);
select ok(not (public.marketplace_bounty_detail('test-s2-excluded')->'icp' ? 'excluded_company_inns'), '21 exclusion list is not exposed to SDR');

select pg_temp.jwt('c0000000-0000-4000-8000-000000000001');
select throws_ok(
  $$select public.review_prospect((select id from public.prospects where company_name='TEST Domain Co'), 'REJECTED', '')$$,
  'P0001', 'REJECTION_REASON_REQUIRED', '22 reject without reason is forbidden'
);
select lives_ok(
  $$select public.review_prospect((select id from public.prospects where company_name='TEST Domain Co'), 'REJECTED', 'TEST ICP mismatch')$$,
  '23 ADMIN can reject with reason'
);
select is((select rejection_reason from public.prospects where company_name='TEST Domain Co'), 'TEST ICP mismatch', '24 rejection reason is stored');
select is((select count(*) from public.prospects where company_name='TEST Domain Co' and status='REJECTED'), 1::bigint, '25 REJECTED history remains');
select pg_temp.jwt('c0000000-0000-4000-8000-000000000003');
select lives_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-main'), pg_temp.prospect_payload('TEST Domain Reclaimed','500100732259','domainco.example','domain-e@test.example'))$$,
  '26 another SDR can register after rejection'
);

select pg_temp.jwt('c0000000-0000-4000-8000-000000000001');
select public.admin_save_bounty((select id from public.bounties where slug='test-s2-main'), '{}'::jsonb, 'PAUSE');
select pg_temp.jwt('c0000000-0000-4000-8000-000000000002');
select throws_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-main'), pg_temp.prospect_payload('TEST Paused','7700000023','paused.example'))$$,
  'P0001', 'BOUNTY_NOT_AVAILABLE', '27 PAUSED bounty rejects new prospect'
);
select is((select count(*) from public.sdr_prospects() where company_name='TEST Main Co'), 1::bigint, '28 existing prospect remains visible after Pause');

select pg_temp.jwt('c0000000-0000-4000-8000-000000000001');
update public.bounties set active_until = now() - interval '1 second' where slug='test-s2-other';
select pg_temp.jwt('c0000000-0000-4000-8000-000000000003');
select throws_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-other'), pg_temp.prospect_payload('TEST Expired','7700000030','expired.example'))$$,
  'P0001', 'BOUNTY_NOT_AVAILABLE', '29 expired bounty rejects new prospect'
);
select is((select count(*) from public.sdr_prospects() where company_name='TEST Domain Other Bounty'), 1::bigint, '30 existing prospect remains visible after expiry');

select pg_temp.jwt('c0000000-0000-4000-8000-000000000003');
select public.take_bounty((select id from public.bounties where slug='test-s2-suspend'));
select pg_temp.jwt('c0000000-0000-4000-8000-000000000001');
update public.businesses set verification_status='SUSPENDED' where id='d0000000-0000-4000-8000-000000000003';
select is((select status::text from public.bounties where slug='test-s2-suspend'), 'PAUSED', '31 suspended business pauses bounty');
select pg_temp.jwt('c0000000-0000-4000-8000-000000000003');
select throws_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-suspend'), pg_temp.prospect_payload('TEST Suspended','7700000048','suspended.example'))$$,
  'P0001', 'BOUNTY_NOT_AVAILABLE', '32 suspended business bounty rejects prospect'
);

select is((select b.meeting_limit from public.bounties b where slug='test-s2-main'), (select meeting_limit from s2_baseline where slug='test-s2-main'), '33 prospects do not change meeting_limit');
select is((select b.accepted_count from public.bounties b where slug='test-s2-main'), (select accepted_count from s2_baseline where slug='test-s2-main'), '34 prospects do not change accepted_count');
select is((select b.current_version from public.bounties b where slug='test-s2-main'), (select current_version from s2_baseline where slug='test-s2-main'), '35 prospects do not create bounty versions');
select is(has_table_privilege('authenticated', 'public.prospects', 'INSERT'), false, '36 authenticated cannot directly INSERT prospects');
select is(has_table_privilege('authenticated', 'public.prospects', 'UPDATE'), false, '37 authenticated cannot directly review prospects');
select has_index('public', 'prospects', 'prospects_active_company_ownership_unique', '38 partial unique ownership index exists');
select throws_ok(
  $$insert into public.prospects (bounty_id,sdr_profile_id,company_name,company_inn,normalized_company_inn,company_domain,normalized_company_domain,company_identity_key,contact_name,contact_title,contact_email,ownership_expires_at) values ((select id from public.bounties where slug='test-s2-main'),'c0000000-0000-4000-8000-000000000002','TEST Direct Race','500100732259','500100732259','race.example','race.example','inn:500100732259','TEST Race','TEST CEO','race@test.example',now()+interval '30 days')$$,
  '23505', 'duplicate key value violates unique constraint "prospects_active_company_ownership_unique"', '39 DB index closes concurrent ownership race'
);

select pg_temp.jwt('c0000000-0000-4000-8000-000000000001');
select is((select count(*) from public.prospects where company_name like 'TEST %'), 4::bigint, '40 ADMIN can read prospect history');
select throws_ok(
  $$select public.review_prospect((select id from public.prospects where company_name='TEST Main Co'), 'REJECTED', 'conflict')$$,
  'P0001', 'PROSPECT_ALREADY_REVIEWED', '41 conflicting repeat review is explicit'
);
select is((select count(*) from public.prospects where status in ('PENDING','APPROVED') and bounty_id=(select id from public.bounties where slug='test-s2-main') and company_identity_key='inn:500100732259'), 1::bigint, '42 exactly one active ownership survives release and reclaim');

select ok(public.is_valid_russian_inn('7707083893'), '43 valid 10-digit checksum is accepted');
select ok(public.is_valid_russian_inn('500100732259'), '44 valid 12-digit checksum is accepted');
select ok(not public.is_valid_russian_inn('7707083894'), '45 invalid checksum is rejected');
select is(public.normalize_company_inn('77AB-12'), null, '46 letters in INN are rejected');
select is(public.normalize_company_inn('1'), null, '47 malformed INN length is rejected');
select is(public.normalize_company_domain('HTTPS://WWW.Example.COM:443/about?q=1'), 'example.com', '48 canonical DB domain matches application examples');
select is(public.normalize_company_domain('пример.рф'), null, '49 Unicode domains are explicitly unsupported');

select pg_temp.jwt('c0000000-0000-4000-8000-000000000001');
select public.admin_save_bounty(null, pg_temp.bounty_payload('d0000000-0000-4000-8000-000000000001', 'test-s2-limits'), 'PUBLISH');
select pg_temp.jwt('c0000000-0000-4000-8000-000000000002');
select public.take_bounty((select id from public.bounties where slug='test-s2-limits'));
select throws_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-limits'), pg_temp.prospect_payload('TEST Missing INN','','missing.example'))$$,
  'P0001', 'COMPANY_INN_INVALID', '50 prospect without INN is rejected'
);
select throws_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-limits'), pg_temp.prospect_payload('TEST Bad Domain','7700000055','bad..example.com'))$$,
  'P0001', 'COMPANY_DOMAIN_INVALID', '51 malformed domain is rejected by RPC'
);

select pg_temp.jwt('c0000000-0000-4000-8000-000000000001');
update public.bounties set accepted_count=meeting_limit where slug='test-s2-limits';
select pg_temp.jwt('c0000000-0000-4000-8000-000000000002');
select throws_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-limits'), pg_temp.prospect_payload('TEST Full Quota','7700000062','quota.example'))$$,
  'P0001', 'BOUNTY_QUOTA_REACHED', '52 full accepted quota blocks registration'
);
select pg_temp.jwt('c0000000-0000-4000-8000-000000000001');
update public.bounties set accepted_count=meeting_limit-1 where slug='test-s2-limits';
select pg_temp.jwt('c0000000-0000-4000-8000-000000000002');
select lives_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-limits'), pg_temp.prospect_payload('TEST Quota Open','7700000062','quota.example'))$$,
  '53 quota below limit permits registration'
);
select ok((select ownership_expires_at = created_at + interval '30 days' from public.prospects where company_name='TEST Quota Open'), '54 ownership is created for exactly 30 days');

select pg_temp.jwt('c0000000-0000-4000-8000-000000000001');
insert into public.prospects (bounty_id,sdr_profile_id,company_name,company_inn,normalized_company_inn,company_domain,normalized_company_domain,company_identity_key,contact_name,contact_title,contact_email,created_at,ownership_expires_at)
select (select id from public.bounties where slug='test-s2-limits'), 'c0000000-0000-4000-8000-000000000002',
  'TEST Slot '||n, inn, inn, 'slot'||n||'.example', 'slot'||n||'.example', 'inn:'||inn,
  'TEST Contact', 'TEST CEO', 'slot'||n||'@test.example', now(), now()+interval '30 days'
from unnest(array['7700000070','7700000087','7700000094','7700000104','7700000111','7700000129','7700000136','7700000143','7700000150','7700000168','7700000175','7700000182','7700000190','7700000200','7700000217','7700000224','7700000231','7700000249','7700000256','7700000263','7700000270','7700000288','7700000295','7700000305']) with ordinality x(inn,n);
select is((select count(*) from public.prospects where bounty_id=(select id from public.bounties where slug='test-s2-limits') and sdr_profile_id='c0000000-0000-4000-8000-000000000002' and status in ('PENDING','APPROVED')), 25::bigint, '55 exactly 25 active prospects are allowed');
select pg_temp.jwt('c0000000-0000-4000-8000-000000000002');
select throws_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-limits'), pg_temp.prospect_payload('TEST Slot 26','7700000312','slot26.example'))$$,
  'P0001', 'PROSPECT_ACTIVE_LIMIT_REACHED', '56 the 26th active prospect is blocked'
);

select pg_temp.jwt('c0000000-0000-4000-8000-000000000001');
select public.review_prospect((select id from public.prospects where company_name='TEST Slot 1'), 'REJECTED', 'TEST release');
select pg_temp.jwt('c0000000-0000-4000-8000-000000000002');
select lives_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-limits'), pg_temp.prospect_payload('TEST Reused Slot','7700000312','slot26.example'))$$,
  '57 a rejected prospect releases an anti-hoarding slot'
);

select pg_temp.jwt('c0000000-0000-4000-8000-000000000001');
update public.prospects set created_at=now()-interval '31 days', ownership_expires_at=now()-interval '1 day' where company_name='TEST Slot 2';
select pg_temp.jwt('c0000000-0000-4000-8000-000000000003');
select public.take_bounty((select id from public.bounties where slug='test-s2-limits'));
select lives_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-limits'), pg_temp.prospect_payload('TEST Expiry Reclaim','7700000087','new-domain.example'))$$,
  '58 expired ownership permits another SDR registration'
);
select is((select status::text from public.prospects where company_name='TEST Slot 2'), 'EXPIRED', '59 stale ownership transitions to EXPIRED');
select is((select count(*) from public.prospects where company_identity_key='inn:7700000087'), 2::bigint, '60 expired historical row is retained');

select pg_temp.jwt('c0000000-0000-4000-8000-000000000001');
create temporary table resume_payload as select pg_temp.bounty_payload('d0000000-0000-4000-8000-000000000001', 'test-s2-resume') payload;
update resume_payload set payload = jsonb_set(
  jsonb_set(payload, '{excluded_company_inns}', '[" 77-070 838-93 "]'::jsonb),
  '{materials}', '[{"label":"Legacy brief label","content":"TEST pains","external_url":"","material_type":"PAINS","sort_order":10}]'::jsonb
);
select public.admin_save_bounty(null, (select payload from resume_payload), 'PUBLISH');
select public.admin_save_bounty((select id from public.bounties where slug='test-s2-resume'), '{}'::jsonb, 'PAUSE');
select is((select current_version from public.bounties where slug='test-s2-resume'), 1, '61 Pause leaves version unchanged');
update resume_payload set payload = jsonb_set(
  jsonb_set(payload, '{excluded_company_inns}', '["7707083893"]'::jsonb),
  '{materials}', '[{"label":"Боли и триггеры","content":"TEST pains","external_url":"","material_type":"PAINS","sort_order":10}]'::jsonb
);
select public.admin_save_bounty((select id from public.bounties where slug='test-s2-resume'), (select payload from resume_payload), 'PUBLISH');
select is((select current_version from public.bounties where slug='test-s2-resume'), 1, '62 Resume with canonicalized real UI/RPC payload leaves version unchanged');
update resume_payload set payload=jsonb_set(payload, '{summary}', '"TEST S2 genuinely changed summary"'::jsonb);
select public.admin_save_bounty((select id from public.bounties where slug='test-s2-resume'), (select payload from resume_payload), 'PUBLISH');
select is((select current_version from public.bounties where slug='test-s2-resume'), 2, '63 changed versioned content creates exactly one version');
select is((select count(*) from public.bounty_versions where bounty_id=(select id from public.bounties where slug='test-s2-resume')), 2::bigint, '64 exactly two immutable snapshots exist after one real change');
select is(public.normalize_company_domain('http://www.example.com:80/path'), 'example.com', '65 DB canonicalization agrees on default port and path removal');

select ok(not public.is_valid_russian_inn('0000000000'), '66 all-zero 10-digit INN is invalid');
select ok(not public.is_valid_russian_inn('000000000000'), '67 all-zero 12-digit INN is invalid');
select pg_temp.jwt('c0000000-0000-4000-8000-000000000002');
select throws_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-limits'), pg_temp.prospect_payload('TEST Zero INN 10','0000000000','zero10.example'))$$,
  'P0001', 'COMPANY_INN_INVALID', '68 RPC rejects all-zero 10-digit INN'
);
select throws_ok(
  $$select public.register_prospect((select id from public.bounties where slug='test-s2-limits'), pg_temp.prospect_payload('TEST Zero INN 12','000000000000','zero12.example'))$$,
  'P0001', 'COMPANY_INN_INVALID', '69 RPC rejects all-zero 12-digit INN'
);
select is(
  (select count(*) from public.prospects where company_name in ('TEST Zero INN 10', 'TEST Zero INN 12')),
  0::bigint,
  '70 rejected zero-INN attempts create no prospect rows'
);

select * from finish();
rollback;
