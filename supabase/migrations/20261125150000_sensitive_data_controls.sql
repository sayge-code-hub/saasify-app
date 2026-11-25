-- Sensitive-data operational controls. This migration is non-destructive:
-- it records security events and retention policy only; it never deletes data.

begin;

create table if not exists public.security_rate_limits (
  user_id uuid not null references auth.users(id) on delete cascade,
  action text not null,
  window_started_at timestamptz not null default now(),
  attempt_count integer not null default 0 check (attempt_count >= 0),
  primary key (user_id, action)
);

alter table public.security_rate_limits enable row level security;
revoke all on public.security_rate_limits from anon, authenticated;

create table if not exists public.sensitive_data_audit (
  id bigint generated always as identity primary key,
  occurred_at timestamptz not null default now(),
  actor_id uuid references auth.users(id) on delete set null,
  event_type text not null,
  record_type text not null,
  record_id text not null,
  changed_fields text[] not null default '{}'
);

alter table public.sensitive_data_audit enable row level security;
revoke all on public.sensitive_data_audit from anon, authenticated;
grant select on public.sensitive_data_audit to authenticated;
create policy sensitive_data_audit_staff_read
  on public.sensitive_data_audit for select to authenticated
  using (public.app_is_staff());

create table if not exists public.data_retention_policies (
  record_type text primary key,
  retention_days integer not null check (retention_days > 0),
  legal_hold_supported boolean not null default true,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null
);

insert into public.data_retention_policies (record_type, retention_days)
values
  ('employee_profile', 2555),
  ('employee_document', 2555),
  ('employee_purchase_order', 2555),
  ('security_audit', 2555)
on conflict (record_type) do nothing;

alter table public.data_retention_policies enable row level security;
revoke all on public.data_retention_policies from anon, authenticated;
grant select on public.data_retention_policies to authenticated;
create policy data_retention_policies_staff_read
  on public.data_retention_policies for select to authenticated
  using (public.app_is_staff());

create or replace function public.consume_sensitive_rate_limit(p_action text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  max_attempts integer;
  window_seconds integer := 3600;
  row_state public.security_rate_limits%rowtype;
begin
  if auth.uid() is null then
    return false;
  end if;
  max_attempts := case p_action
    when 'document_upload' then 20
    when 'purchase_order_upload' then 20
    when 'employee_photo_copy' then 30
    else 0
  end;
  if max_attempts = 0 then
    return false;
  end if;

  insert into public.security_rate_limits (user_id, action, window_started_at, attempt_count)
  values (auth.uid(), p_action, now(), 1)
  on conflict (user_id, action) do update
    set attempt_count = case
      when public.security_rate_limits.window_started_at <= now() - make_interval(secs => window_seconds)
        then 1
      else public.security_rate_limits.attempt_count + 1
    end,
    window_started_at = case
      when public.security_rate_limits.window_started_at <= now() - make_interval(secs => window_seconds)
        then now()
      else public.security_rate_limits.window_started_at
    end
  returning * into row_state;

  return row_state.attempt_count <= max_attempts;
end;
$$;

create or replace function public.audit_sensitive_employee_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  fields text[] := '{}';
begin
  if tg_op = 'UPDATE' then
    if new.bank_account is distinct from old.bank_account then fields := array_append(fields, 'bank_account'); end if;
    if new.ifsc is distinct from old.ifsc then fields := array_append(fields, 'ifsc'); end if;
    if new.pan is distinct from old.pan then fields := array_append(fields, 'pan'); end if;
    if new.uan is distinct from old.uan then fields := array_append(fields, 'uan'); end if;
    if new.annual_ctc is distinct from old.annual_ctc then fields := array_append(fields, 'annual_ctc'); end if;
    if new.monthly_ctc is distinct from old.monthly_ctc then fields := array_append(fields, 'monthly_ctc'); end if;
    if new.monthly_rate is distinct from old.monthly_rate then fields := array_append(fields, 'monthly_rate'); end if;
    if cardinality(fields) > 0 then
      insert into public.sensitive_data_audit (actor_id, event_type, record_type, record_id, changed_fields)
      values (auth.uid(), 'updated', 'employee', new.employee_id, fields);
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists employees_sensitive_audit on public.employees;
create trigger employees_sensitive_audit
  after update on public.employees
  for each row execute function public.audit_sensitive_employee_change();

revoke all on function public.consume_sensitive_rate_limit(text) from public;
grant execute on function public.consume_sensitive_rate_limit(text) to authenticated;
revoke all on function public.audit_sensitive_employee_change() from public;

commit;
