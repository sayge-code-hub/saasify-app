-- Future subscription enforcement control.
--
-- This ships OFF for every company so the pilot remains unrestricted. A company
-- owner can turn it on later from Settings -> Billing, after billing operations
-- and payment collection are ready. The public snapshot drives the application
-- gate, while billing_writes_allowed also protects guarded server-side writes.

begin;

alter table public.billing_subscription
  add column if not exists access_enforced boolean not null default false;

comment on column public.billing_subscription.access_enforced is
  'When true, only trialing/active subscriptions may access the product. Disabled for pilot by default.';

create or replace function public.billing_access_allowed(
  p_company_id text default null
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company text;
  v_enforced boolean;
  v_status text;
begin
  v_company := coalesce(nullif(trim(p_company_id), ''), public.billing_company_id());
  select access_enforced into v_enforced
  from public.billing_subscription
  where company_id = v_company;

  -- Missing subscriptions and all pilot subscriptions remain accessible.
  if coalesce(v_enforced, false) is false then
    return true;
  end if;

  v_status := public.billing_derive_status(v_company);
  return v_status in ('trialing', 'active');
end;
$$;

create or replace function public.billing_writes_allowed()
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company text;
  v_enforced boolean;
  v_status text;
begin
  v_company := public.billing_company_id();
  select access_enforced into v_enforced
  from public.billing_subscription
  where company_id = v_company;
  v_status := public.billing_derive_status(v_company);

  if coalesce(v_enforced, false) then
    return v_status in ('trialing', 'active');
  end if;
  return v_status in ('trialing', 'active', 'past_due');
end;
$$;

create or replace function public.billing_set_access_enforced(p_enabled boolean)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company text;
begin
  if not public.app_is_staff() then
    raise exception 'BILLING_FORBIDDEN' using errcode = '42501';
  end if;

  v_company := public.billing_company_id();
  update public.billing_subscription
  set access_enforced = coalesce(p_enabled, false)
  where company_id = v_company;

  if not found then
    raise exception 'BILLING_SUBSCRIPTION_MISSING' using errcode = 'P0001';
  end if;

  perform public.billing_log_event(
    'access_enforcement_set',
    jsonb_build_object('company_id', v_company, 'access_enforced', coalesce(p_enabled, false))
  );

  return public.billing_get_state();
end;
$$;

create or replace function public.billing_public_snapshot()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company text;
  v_sub public.billing_subscription%rowtype;
  v_plan public.billing_plans%rowtype;
  v_status text;
  v_count int;
  v_access_allowed boolean;
begin
  if auth.uid() is null then
    raise exception 'BILLING_FORBIDDEN' using errcode = '42501';
  end if;

  v_company := public.billing_company_id();
  select * into v_sub from public.billing_subscription where company_id = v_company;
  if not found then
    return jsonb_build_object(
      'status', 'active', 'writes_allowed', true,
      'access_enforced', false, 'access_allowed', true,
      'pos_enabled', true, 'can_add_employee', true,
      'active_employees', 0, 'employee_limit', 5,
      'plan_code', 'free', 'plan_name', 'Free',
      'company_id', v_company, 'payments_provider', null
    );
  end if;

  select * into v_plan from public.billing_plans where code = v_sub.plan_code;
  v_status := public.billing_derive_status(v_company);
  v_count := public.billing_active_employee_count(v_company);
  v_access_allowed := (not v_sub.access_enforced)
    or v_status in ('trialing', 'active');

  return jsonb_build_object(
    'status', v_status,
    'writes_allowed', public.billing_writes_allowed(),
    'access_enforced', v_sub.access_enforced,
    'access_allowed', v_access_allowed,
    'pos_enabled', v_sub.pos_enabled,
    'can_add_employee', v_count < v_plan.employee_limit
      and public.billing_writes_allowed(),
    'active_employees', v_count, 'employee_limit', v_plan.employee_limit,
    'plan_code', v_plan.code, 'plan_name', v_plan.name,
    'grace_days', v_sub.grace_days,
    'current_period_end', v_sub.current_period_end,
    'company_id', v_company, 'payments_provider', null
  );
end;
$$;

revoke all on function public.billing_access_allowed(text) from public;
revoke all on function public.billing_set_access_enforced(boolean) from public;
grant execute on function public.billing_access_allowed(text) to authenticated, service_role;
grant execute on function public.billing_set_access_enforced(boolean) to authenticated;
grant execute on function public.billing_public_snapshot() to authenticated;

commit;
