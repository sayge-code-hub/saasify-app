-- Close tenant-boundary gaps on records that inherit their company from a
-- parent and on private files.  RLS policies are permissive by default, so a
-- single staff-only policy must never be left alongside a tenant policy.

begin;

-- Proposal and invoice line items do not carry company_id.  They must inherit
-- their tenant and staff access exclusively from their parent record.
do $$
declare
  child_table text;
  parent_table text;
  foreign_key text;
  action text;
begin
  for child_table, parent_table, foreign_key in
    select * from (values
      ('proposal_line_items'::text, 'proposals'::text, 'proposal_id'::text),
      ('invoice_line_items'::text, 'invoices'::text, 'invoice_id'::text)
    ) as parents(child_table, parent_table, foreign_key)
  loop
    if to_regclass('public.' || child_table) is null
       or to_regclass('public.' || parent_table) is null then continue; end if;

    execute format('alter table public.%I enable row level security', child_table);
    foreach action in array array['select', 'insert', 'update', 'delete'] loop
      execute format('drop policy if exists %I on public.%I', child_table || '_' || action || '_tenant', child_table);
      execute format('drop policy if exists %I on public.%I', child_table || '_' || action || '_rbac', child_table);
    end loop;

    execute format('create policy %I on public.%I for select to authenticated using (exists (select 1 from public.%I parent where parent.id = %I and public.app_is_staff() and public.app_same_company(parent.company_id)))', child_table || '_select_tenant', child_table, parent_table, foreign_key);
    execute format('create policy %I on public.%I for insert to authenticated with check (exists (select 1 from public.%I parent where parent.id = %I and public.app_is_staff() and public.app_same_company(parent.company_id)))', child_table || '_insert_tenant', child_table, parent_table, foreign_key);
    execute format('create policy %I on public.%I for update to authenticated using (exists (select 1 from public.%I parent where parent.id = %I and public.app_is_staff() and public.app_same_company(parent.company_id))) with check (exists (select 1 from public.%I parent where parent.id = %I and public.app_is_staff() and public.app_same_company(parent.company_id)))', child_table || '_update_tenant', child_table, parent_table, foreign_key, parent_table, foreign_key);
    execute format('create policy %I on public.%I for delete to authenticated using (exists (select 1 from public.%I parent where parent.id = %I and public.app_is_staff() and public.app_same_company(parent.company_id)))', child_table || '_delete_tenant', child_table, parent_table, foreign_key);
  end loop;
end $$;

-- Private DMS files must be found through an authorised document record;
-- employees may additionally read only documents attached to themselves.
drop policy if exists documents_storage_select on storage.objects;
create policy documents_storage_select on storage.objects for select to authenticated
using (
  bucket_id = 'documents'
  and exists (
    select 1 from public.documents d
    where d.storage_path = storage.objects.name
      and (
        (public.app_is_staff() and public.app_same_company(d.company_id))
        or (
          d.entity_type = 'employee'
          and d.entity_id = public.app_employee_id()
          and public.app_same_company(d.company_id)
        )
      )
  )
);

-- Purchase-order paths begin with their employee ID.  Matching that employee
-- to the active company keeps upload, download, replacement and cleanup
-- scoped to one tenant, including files uploaded before the PO row exists.
drop policy if exists employee_pos_storage_select on storage.objects;
drop policy if exists employee_pos_storage_insert on storage.objects;
drop policy if exists employee_pos_storage_update on storage.objects;
drop policy if exists employee_pos_storage_delete on storage.objects;

create policy employee_pos_storage_select on storage.objects for select to authenticated
using (
  bucket_id = 'employee-pos'
  and public.app_is_staff()
  and exists (
    select 1 from public.employees e
    where e.employee_id = (storage.foldername(storage.objects.name))[1]
      and public.app_same_company(e.company_id)
  )
);

create policy employee_pos_storage_insert on storage.objects for insert to authenticated
with check (
  bucket_id = 'employee-pos'
  and public.app_is_staff()
  and exists (
    select 1 from public.employees e
    where e.employee_id = (storage.foldername(storage.objects.name))[1]
      and public.app_same_company(e.company_id)
  )
);

create policy employee_pos_storage_update on storage.objects for update to authenticated
using (
  bucket_id = 'employee-pos'
  and public.app_is_staff()
  and exists (
    select 1 from public.employees e
    where e.employee_id = (storage.foldername(storage.objects.name))[1]
      and public.app_same_company(e.company_id)
  )
)
with check (
  bucket_id = 'employee-pos'
  and public.app_is_staff()
  and exists (
    select 1 from public.employees e
    where e.employee_id = (storage.foldername(storage.objects.name))[1]
      and public.app_same_company(e.company_id)
  )
);

create policy employee_pos_storage_delete on storage.objects for delete to authenticated
using (
  bucket_id = 'employee-pos'
  and public.app_is_staff()
  and exists (
    select 1 from public.employees e
    where e.employee_id = (storage.foldername(storage.objects.name))[1]
      and public.app_same_company(e.company_id)
  )
);

commit;
