-- Read-only post-migration verification. Each query should return the stated result.

-- Expect one row for each retention class.
select record_type, retention_days, legal_hold_supported
from public.data_retention_policies
order by record_type;

-- Expect the trigger to be present exactly once.
select tgname from pg_trigger
where tgname = 'employees_sensitive_audit' and not tgisinternal;

-- Expect no anon/PUBLIC execute grant.
select p.proname, coalesce(r.rolname, 'PUBLIC') as grantee
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
cross join lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
left join pg_roles r on r.oid = a.grantee
where n.nspname = 'public'
  and p.proname = 'consume_sensitive_rate_limit'
  and a.privilege_type = 'EXECUTE'
  and (a.grantee = 0 or r.rolname = 'anon');
