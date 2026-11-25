alter table public.employees
  add column if not exists photo_path text not null default '';

insert into storage.buckets (id, name, public)
values ('employee-avatars', 'employee-avatars', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "employee_avatars_storage_select" on storage.objects;
drop policy if exists "employee_avatars_storage_insert" on storage.objects;
drop policy if exists "employee_avatars_storage_update" on storage.objects;
drop policy if exists "employee_avatars_storage_delete" on storage.objects;

create policy "employee_avatars_storage_select"
  on storage.objects for select
  to authenticated, anon
  using (bucket_id = 'employee-avatars');

create policy "employee_avatars_storage_insert"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'employee-avatars');

create policy "employee_avatars_storage_update"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'employee-avatars')
  with check (bucket_id = 'employee-avatars');

create policy "employee_avatars_storage_delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'employee-avatars');

update public.employees
set photo_path = 'documents/employee/2319/doc-employee-2319-1791210002400000_Screenshot_2026-03-27_at_1.15.01_PM.webp'
where employee_id = '2319';
;
