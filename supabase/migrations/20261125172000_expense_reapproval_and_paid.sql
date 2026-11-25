-- Expense lifecycle: pending -> approved -> paid, with any staff correction
-- returning the record to pending so it is reviewed again.

begin;

alter table public.expenses
  drop constraint if exists expenses_approval_status_chk;

alter table public.expenses
  add constraint expenses_approval_status_chk
  check (approval_status in ('pending', 'approved', 'paid', 'rejected'));

create or replace function public.expenses_guard_approval()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_changed boolean;
begin
  if coalesce(auth.role(), '') = 'service_role' then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.approval_status := 'pending';
    new.approved_by := null;
    new.approved_at := null;
    return new;
  end if;

  v_business_changed :=
    new.made_for is distinct from old.made_for or
    new.amount is distinct from old.amount or
    new.paid_from is distinct from old.paid_from or
    new.category is distinct from old.category or
    new.client_id is distinct from old.client_id or
    new.expense_date is distinct from old.expense_date or
    new.receipt_path is distinct from old.receipt_path or
    new.receipt_name is distinct from old.receipt_name;

  if v_business_changed and old.approval_status <> 'pending' then
    if not public.app_is_staff() then
      raise exception 'Only owner or admin can edit an approved expense';
    end if;
    new.approval_status := 'pending';
    new.approved_by := null;
    new.approved_at := null;
  elsif new.approval_status is distinct from old.approval_status
     or new.approved_by is distinct from old.approved_by
     or new.approved_at is distinct from old.approved_at then
    if not public.app_is_staff() then
      raise exception 'Only owner or admin can change expense approval';
    end if;
    if new.approval_status = 'pending' then
      new.approved_by := null;
      new.approved_at := null;
    elsif new.approval_status = 'paid' then
      if old.approval_status <> 'approved' then
        raise exception 'Only an approved expense can be marked paid';
      end if;
      new.approved_by := old.approved_by;
      new.approved_at := old.approved_at;
    elsif new.approval_status in ('approved', 'rejected') then
      new.approved_by := coalesce(new.approved_by, auth.uid());
      new.approved_at := coalesce(new.approved_at, now());
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists expenses_guard_approval on public.expenses;
create trigger expenses_guard_approval
  before insert or update on public.expenses
  for each row execute function public.expenses_guard_approval();

commit;
