-- Sprint 0 only: authentication profile, roles and row-level security.

create type public.user_role as enum ('SDR', 'BUSINESS', 'ADMIN');
create type public.user_status as enum ('PENDING', 'ACTIVE', 'SUSPENDED');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.user_role not null,
  display_name text not null check (char_length(display_name) between 2 and 80),
  email text not null,
  status public.user_status not null default 'PENDING',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.profiles is 'Sprint 0 application identity linked one-to-one to auth.users.';

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_role text := new.raw_user_meta_data ->> 'role';
  safe_display_name text := trim(coalesce(new.raw_user_meta_data ->> 'display_name', ''));
begin
  if requested_role not in ('SDR', 'BUSINESS') then
    raise exception 'Invalid public signup role';
  end if;

  if char_length(safe_display_name) < 2 or char_length(safe_display_name) > 80 then
    raise exception 'Display name must be between 2 and 80 characters';
  end if;

  insert into public.profiles (id, role, display_name, email, status)
  values (
    new.id,
    requested_role::public.user_role,
    safe_display_name,
    coalesce(new.email, ''),
    case when requested_role = 'BUSINESS' then 'PENDING'::public.user_status else 'ACTIVE'::public.user_status end
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute procedure public.set_updated_at();

alter table public.profiles enable row level security;

create policy "Users can read their own profile"
  on public.profiles for select
  to authenticated
  using ((select auth.uid()) = id);

create policy "Users can update their own profile"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- RLS limits rows; column grants prevent users from changing role, status or email.
revoke all on table public.profiles from anon;
revoke insert, delete, update on table public.profiles from authenticated;
grant select on table public.profiles to authenticated;
grant update (display_name) on table public.profiles to authenticated;

revoke all on function public.handle_new_user() from public;
revoke all on function public.set_updated_at() from public;
