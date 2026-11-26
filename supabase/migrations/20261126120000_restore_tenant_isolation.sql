-- Tenant isolation is enforced at the database boundary.  A later PO
-- hardening migration accidentally added an unscoped staff SELECT policy;
-- PostgreSQL combines permissive policies with OR, so that policy allowed a
-- staff member to enumerate another company's purchase orders.

begin;

do $$
declare
  t text;
begin
  foreach t in array array[
    'clients', 'dms_entities', 'documents', 'expenses', 'expense_categories',
    'invoices', 'payroll_runs', 'payslip_records', 'proposals',
    'employee_purchase_orders'
  ]
  loop
    if to_regclass('public.' || t) is null or not exists (
      select 1 from information_schema.columns
      where table_schema = 'public' and table_name = t and column_name = 'company_id'
    ) then
      continue;
    end if;

    -- Remove the legacy/unscoped read policy where present.
    execute format('drop policy if exists %I on public.%I', t || '_select_rbac', t);
    execute format('drop policy if exists %I on public.%I', t || '_select_tenant', t);

    if t = 'employee_purchase_orders' then
      execute format(
        'create policy %I on public.%I for select to authenticated using (
          public.app_is_staff() and public.app_same_company(company_id)
        )',
        t || '_select_tenant', t
      );
    else
      execute format(
        'create policy %I on public.%I for select to authenticated using (
          public.app_in_company(company_id)
        )',
        t || '_select_tenant', t
      );
    end if;
  end loop;
end $$;

-- Employees retain self-service access only to their own row; staff are still
-- restricted to the signed-in company.
drop policy if exists employees_select_rbac on public.employees;
drop policy if exists employees_select_company on public.employees;
create policy employees_select_company on public.employees
  for select to authenticated
  using (
    (public.app_is_staff() and public.app_same_company(company_id))
    or (
      employee_id = public.app_employee_id()
      and public.app_same_company(company_id)
    )
  );

-- A user profile can never disclose another tenant's membership data.
drop policy if exists users_select_rbac on public.users;
drop policy if exists users_select_company on public.users;
create policy users_select_company on public.users
  for select to authenticated
  using (
    id = auth.uid()
    or (public.app_is_staff() and public.app_same_company(company_id))
  );

commit;
