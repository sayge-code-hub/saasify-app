-- Correct the tenant overlay: membership establishes the tenant boundary, but
-- it must not turn employee accounts into company-wide readers.  Employees
-- receive only their own employee record, payslips and employee documents.

begin;

do $$
declare
  t text;
begin
  foreach t in array array[
    'clients', 'dms_entities', 'expenses', 'expense_categories', 'invoices',
    'payroll_runs', 'proposals', 'employee_purchase_orders'
  ]
  loop
    if to_regclass('public.' || t) is null then continue; end if;
    execute format('drop policy if exists %I on public.%I', t || '_select_tenant', t);
    execute format(
      'create policy %I on public.%I for select to authenticated using (
        public.app_is_staff() and public.app_same_company(company_id)
      )', t || '_select_tenant', t
    );
  end loop;
end $$;

drop policy if exists documents_select_tenant on public.documents;
create policy documents_select_tenant on public.documents for select to authenticated
using (
  (public.app_is_staff() and public.app_same_company(company_id))
  or (
    entity_type = 'employee'
    and entity_id = public.app_employee_id()
    and public.app_same_company(company_id)
  )
);

drop policy if exists payslip_records_select_tenant on public.payslip_records;
create policy payslip_records_select_tenant on public.payslip_records for select to authenticated
using (
  (public.app_is_staff() and public.app_same_company(company_id))
  or (
    employee_id = public.app_employee_id()
    and public.app_same_company(company_id)
  )
);

commit;
