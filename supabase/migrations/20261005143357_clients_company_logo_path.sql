alter table public.clients
  add column if not exists logo_path text not null default '';

alter table public.company_details
  add column if not exists logo_path text not null default '';

insert into storage.buckets (id, name, public)
values ('brand-logos', 'brand-logos', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "brand_logos_storage_select" on storage.objects;
drop policy if exists "brand_logos_storage_insert" on storage.objects;
drop policy if exists "brand_logos_storage_update" on storage.objects;
drop policy if exists "brand_logos_storage_delete" on storage.objects;

create policy "brand_logos_storage_select"
  on storage.objects for select
  to authenticated, anon
  using (bucket_id = 'brand-logos');

create policy "brand_logos_storage_insert"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'brand-logos');

create policy "brand_logos_storage_update"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'brand-logos')
  with check (bucket_id = 'brand-logos');

create policy "brand_logos_storage_delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'brand-logos');
;
