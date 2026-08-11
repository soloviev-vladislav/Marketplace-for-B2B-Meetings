-- PostgreSQL requires a newly added enum value to be committed before it can
-- be referenced by the following transactional migration.
alter type public.prospect_status add value if not exists 'EXPIRED';
