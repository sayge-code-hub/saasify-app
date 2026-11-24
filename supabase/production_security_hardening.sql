-- Production security hardening (non-destructive, safe to re-run).
--
-- This migration retires the legacy password-gated platform-ops API. Those
-- RPCs were SECURITY DEFINER functions callable by anon/authenticated users;
-- a password embedded in a web/mobile client is not a secret.  Do not grant
-- these functions back to application roles. Platform-level operations must
-- be performed from a separately authenticated, server-side administrative
-- tool using the service role.
--
-- This script changes grants only. It does not delete or modify tenant,
-- employee, payroll, financial, document, or billing data.

begin;

-- Remove access from both roles explicitly and from PUBLIC. PUBLIC grants are
-- inherited by anon/authenticated in Postgres, so all three revocations matter.
-- Some installations never applied every legacy script, so revoke only a
-- function overload that actually exists.
do $$
declare
  signature text;
begin
  foreach signature in array array[
    'public.platform_ops_snapshot(text)',
    'public.platform_ops_update_plan(text, text, text, numeric, integer)',
    'public.platform_ops_set_plan_active(text, text, boolean)',
    'public.platform_ops_set_live_plan(text, text)',
    'public.platform_ops_create_company(text, text, text, text, text, text)',
    'public.platform_ops_set_company_plan(text, text, text)',
    'public.platform_ops_prepare_owner_invite(text, text, text, text)'
  ] loop
    if to_regprocedure(signature) is not null then
      execute format('revoke all on function %s from public, anon, authenticated', signature);
    end if;
  end loop;
end;
$$;

-- Tenant/RLS helpers must be callable by signed-in users because policies and
-- authenticated RPCs use them, but anonymous callers have no legitimate use.
-- Trigger helpers are included so future direct RPC exposure cannot happen by
-- accident; this does not alter any rows or trigger definitions.
do $$
declare
  signature text;
begin
  foreach signature in array array[
    'public.app_company_id()',
    'public.app_in_company(text)',
    'public.app_is_company_staff()',
    'public.app_same_company(text)',
    'public.saasify_set_company_id()',
    'public.saasify_slugify(text)'
  ] loop
    if to_regprocedure(signature) is not null then
      execute format('revoke all on function %s from public, anon', signature);
      execute format('grant execute on function %s to authenticated, service_role', signature);
    end if;
  end loop;
end;
$$;

-- The legacy functions must not be executable by the browser-facing roles.
-- This assertion fails the rollout rather than silently leaving an exposure.
do $$
declare
  exposed text;
begin
  select string_agg(p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')', ', ')
    into exposed
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in (
      'platform_ops_snapshot',
      'platform_ops_update_plan',
      'platform_ops_set_plan_active',
      'platform_ops_set_live_plan',
      'platform_ops_create_company',
      'platform_ops_set_company_plan',
      'platform_ops_prepare_owner_invite'
    )
    and (
      has_function_privilege('anon', p.oid, 'EXECUTE')
      or has_function_privilege('authenticated', p.oid, 'EXECUTE')
    );

  if exposed is not null then
    raise exception 'PRODUCTION_HARDENING_FAILED: legacy platform ops still executable: %', exposed;
  end if;
end;
$$;

-- No helper in this list may be publicly executable after this migration.
do $$
declare
  exposed text;
begin
  select string_agg(p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')', ', ')
    into exposed
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in (
      'app_company_id',
      'app_in_company',
      'app_is_company_staff',
      'app_same_company',
      'saasify_set_company_id',
      'saasify_slugify'
    )
    and has_function_privilege('anon', p.oid, 'EXECUTE');

  if exposed is not null then
    raise exception 'PRODUCTION_HARDENING_FAILED: tenant helper executable by anon: %', exposed;
  end if;
end;
$$;

commit;
