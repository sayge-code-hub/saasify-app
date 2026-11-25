-- Employee purchase orders and their PDFs are staff-only (non-destructive).
-- Safe to re-run. Changes RLS policies only; it does not delete or modify data.

begin;

do $$
begin
  if to_regclass('public.employee_purchase_orders') is null then
    return;
  end if;

  drop policy if exists employee_purchase_orders_select_tenant on public.employee_purchase_orders;
  drop policy if exists "employee_purchase_orders_select_rbac" on public.employee_purchase_orders;
  drop policy if exists employee_purchase_orders_select_rbac on public.employee_purchase_orders;

  create policy employee_purchase_orders_select_tenant
    on public.employee_purchase_orders for select to authenticated
    using (
      public.app_is_staff()
      and public.app_same_company(coalesce(company_id, public.app_company_id()))
    );
end;
$$;

drop policy if exists employee_pos_storage_select on storage.objects;
create policy employee_pos_storage_select
  on storage.objects for select to authenticated
  using (bucket_id = 'employee-pos' and public.app_is_staff());

commit;
