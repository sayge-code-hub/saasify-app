-- Company logos are public branding assets, but write access must be scoped
-- to the signed-in tenant. Client logos use the same bucket, so their client
-- record must also belong to that tenant.

begin;

drop policy if exists "brand_logos_storage_write" on storage.objects;
drop policy if exists "brand_logos_storage_update" on storage.objects;
drop policy if exists "brand_logos_storage_delete" on storage.objects;
drop policy if exists "brand_logos_storage_insert" on storage.objects;

create policy "brand_logos_storage_insert_tenant"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'brand-logos'
    and public.app_is_staff()
    and (
      name like ('company/' || public.app_company_id() || '/%')
      or exists (
        select 1
        from public.clients c
        where c.id = split_part(name, '/', 2)
          and c.company_id = public.app_company_id()
          and name like ('clients/' || c.id || '/%')
      )
    )
  );

create policy "brand_logos_storage_update_tenant"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'brand-logos'
    and public.app_is_staff()
    and (
      name like ('company/' || public.app_company_id() || '/%')
      or exists (
        select 1 from public.clients c
        where c.id = split_part(name, '/', 2)
          and c.company_id = public.app_company_id()
          and name like ('clients/' || c.id || '/%')
      )
    )
  )
  with check (
    bucket_id = 'brand-logos'
    and public.app_is_staff()
    and (
      name like ('company/' || public.app_company_id() || '/%')
      or exists (
        select 1 from public.clients c
        where c.id = split_part(name, '/', 2)
          and c.company_id = public.app_company_id()
          and name like ('clients/' || c.id || '/%')
      )
    )
  );

create policy "brand_logos_storage_delete_tenant"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'brand-logos'
    and public.app_is_staff()
    and (
      name like ('company/' || public.app_company_id() || '/%')
      or exists (
        select 1 from public.clients c
        where c.id = split_part(name, '/', 2)
          and c.company_id = public.app_company_id()
          and name like ('clients/' || c.id || '/%')
      )
    )
  );

commit;
