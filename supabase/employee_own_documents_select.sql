-- Allow linked employees to read their own DMS documents only.
-- Purchase orders remain staff-only; writes remain staff-only.

drop policy if exists "documents_select_rbac" on public.documents;
create policy "documents_select_rbac"
  on public.documents for select
  to authenticated
  using (
    public.app_is_staff()
    or (
      entity_type = 'employee'
      and entity_id = public.app_employee_id()
    )
  );

-- Purchase-order access is deliberately not broadened here.
