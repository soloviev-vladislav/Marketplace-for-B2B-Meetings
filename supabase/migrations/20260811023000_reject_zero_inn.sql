-- Reject mathematically checksum-valid but fictitious all-zero Russian INNs.
-- Fail closed if legacy zero-INN ownership already exists; remediation must be
-- explicit because silently deleting or rewriting ownership is unsafe.

do $$
declare zero_inn_count bigint;
begin
  select count(*) into zero_inn_count
  from public.prospects
  where normalized_company_inn in ('0000000000', '000000000000');

  if zero_inn_count > 0 then
    raise exception using
      errcode = '23514',
      message = 'ZERO_INN_LEGACY_DATA_FOUND',
      detail = format('%s prospect row(s) use a fictitious all-zero INN; resolve them explicitly before applying this migration.', zero_inn_count);
  end if;
end;
$$;

create or replace function public.normalize_company_inn(raw_value text)
returns text language plpgsql immutable strict set search_path = ''
as $$
declare normalized text;
begin
  normalized := regexp_replace(trim(raw_value), '[[:space:]-]', '', 'g');
  if normalized !~ '^[0-9]{10}([0-9]{2})?$' or normalized ~ '^0+$' then return null; end if;
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
  drop constraint prospects_valid_russian_inn_checksum;

alter table public.prospects
  add constraint prospects_valid_russian_inn_checksum
  check (public.is_valid_russian_inn(normalized_company_inn));

revoke all on function public.normalize_company_inn(text),
  public.is_valid_russian_inn(text) from public;
grant execute on function public.normalize_company_inn(text),
  public.is_valid_russian_inn(text) to authenticated;
