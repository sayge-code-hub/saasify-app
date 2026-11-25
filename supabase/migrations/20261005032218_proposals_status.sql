alter table public.proposals
  add column if not exists status text not null default 'active'
  check (status in ('active', 'voided', 'rejected', 'archived'));

create index if not exists proposals_status_idx
  on public.proposals (status);
;
