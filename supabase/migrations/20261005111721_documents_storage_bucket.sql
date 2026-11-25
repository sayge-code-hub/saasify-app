-- Public-read documents bucket for DMS file viewing (metadata already references storage_path).
insert into storage.buckets (id, name, public)
values ('documents', 'documents', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "documents_storage_select" on storage.objects;
drop policy if exists "documents_storage_insert" on storage.objects;
drop policy if exists "documents_storage_update" on storage.objects;
drop policy if exists "documents_storage_delete" on storage.objects;

create policy "documents_storage_select"
  on storage.objects for select
  to authenticated, anon
  using (bucket_id = 'documents');

create policy "documents_storage_insert"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'documents');

create policy "documents_storage_update"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'documents')
  with check (bucket_id = 'documents');

create policy "documents_storage_delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'documents');
;
