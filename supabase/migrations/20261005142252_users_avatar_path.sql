alter table public.users
  add column if not exists avatar_path text not null default '';

insert into storage.buckets (id, name, public)
values ('user-avatars', 'user-avatars', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "user_avatars_storage_select" on storage.objects;
drop policy if exists "user_avatars_storage_insert" on storage.objects;
drop policy if exists "user_avatars_storage_update" on storage.objects;
drop policy if exists "user_avatars_storage_delete" on storage.objects;

create policy "user_avatars_storage_select"
  on storage.objects for select
  to authenticated, anon
  using (bucket_id = 'user-avatars');

create policy "user_avatars_storage_insert"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'user-avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "user_avatars_storage_update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'user-avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'user-avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "user_avatars_storage_delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'user-avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
;
