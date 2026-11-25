-- Purchase orders are commercial records. Employees must not be able to
-- enumerate or read their own POs; access is restricted to staff roles.

drop policy if exists "employee_purchase_orders_select_rbac"
  on public.employee_purchase_orders;

create policy "employee_purchase_orders_select_rbac"
  on public.employee_purchase_orders for select
  to authenticated
  using (public.app_is_staff());
