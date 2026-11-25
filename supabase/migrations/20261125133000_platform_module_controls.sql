-- Global product controls. These flags are independent of a tenant's billing.
-- The owner is deliberately resolved through Auth, never by a client-supplied ID.

begin;

create table if not exists public.platform_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.platform_module_flags (
  module_key text primary key check (module_key in ('hrms', 'dms', 'finances', 'pos')),
  is_enabled boolean not null default true,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null
);

insert into public.platform_module_flags (module_key, is_enabled)
values ('hrms', true), ('dms', true), ('finances', true), ('pos', true)
on conflict (module_key) do nothing;

do $$
declare
  owner_id uuid;
begin
  select id into owner_id
  from auth.users
  where lower(email) = 'everythingatsayge@gmail.com'
  limit 1;

  if owner_id is null then
    raise exception 'Platform owner Auth account is missing';
  end if;

  insert into public.platform_admins (user_id)
  values (owner_id)
  on conflict (user_id) do nothing;
end;
$$;

alter table public.platform_admins enable row level security;
alter table public.platform_module_flags enable row level security;
revoke all on public.platform_admins, public.platform_module_flags from anon, authenticated;

create or replace function public.platform_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.platform_admins where user_id = auth.uid()
  );
$$;

create or replace function public.platform_modules_state()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'is_platform_admin', public.platform_is_admin(),
    'modules', coalesce(jsonb_object_agg(module_key, is_enabled), '{}'::jsonb)
  )
  from public.platform_module_flags;
$$;

create or replace function public.platform_set_module_enabled(
  p_module text,
  p_enabled boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.platform_is_admin() then
    raise exception 'PLATFORM_FORBIDDEN' using errcode = '42501';
  end if;
  if p_module not in ('hrms', 'dms', 'finances', 'pos') then
    raise exception 'PLATFORM_UNKNOWN_MODULE' using errcode = 'P0001';
  end if;
  update public.platform_module_flags
  set is_enabled = p_enabled, updated_at = now(), updated_by = auth.uid()
  where module_key = p_module;
  return public.platform_modules_state();
end;
$$;

revoke all on function public.platform_is_admin() from public;
revoke all on function public.platform_modules_state() from public;
revoke all on function public.platform_set_module_enabled(text, boolean) from public;
grant execute on function public.platform_is_admin() to authenticated;
grant execute on function public.platform_modules_state() to authenticated;
grant execute on function public.platform_set_module_enabled(text, boolean) to authenticated;

commit;
