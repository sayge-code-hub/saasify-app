-- Keep authentication accounts and HR employee records purposefully separate,
-- while eliminating conflicting names for linked employee accounts.
-- `employees.employee_name` is the canonical display name whenever users.employee_id
-- is populated. Owners/admins without an employee profile remain users-only.

begin;

-- An employee may be linked to one login account only. The partial index preserves
-- legitimate owner/admin accounts that are not employees.
create unique index if not exists users_one_account_per_employee_idx
  on public.users (employee_id)
  where employee_id is not null and btrim(employee_id) <> '';

-- Reconcile the existing linked data without deleting accounts or HR records.
update public.users u
set full_name = e.employee_name
from public.employees e
where u.employee_id = e.employee_id
  and nullif(btrim(e.employee_name), '') is not null
  and u.full_name is distinct from e.employee_name;

create or replace function public.sync_linked_employee_account_name()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.users
  set full_name = new.employee_name
  where employee_id = new.employee_id
    and full_name is distinct from new.employee_name;
  return new;
end;
$$;

drop trigger if exists employees_sync_linked_account_name on public.employees;
create trigger employees_sync_linked_account_name
after insert or update of employee_id, employee_name on public.employees
for each row execute function public.sync_linked_employee_account_name();

-- Prevent a user profile edit from reintroducing drift. When the linked HR record
-- exists, it quietly retains the employee master name; before HR record creation
-- (for example, an invite) normal account creation remains possible.
create or replace function public.keep_linked_account_name_canonical()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  canonical_name text;
begin
  if new.employee_id is not null and btrim(new.employee_id) <> '' then
    select employee_name into canonical_name
    from public.employees
    where employee_id = new.employee_id;
    if nullif(btrim(canonical_name), '') is not null then
      new.full_name := canonical_name;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists users_keep_linked_account_name_canonical on public.users;
create trigger users_keep_linked_account_name_canonical
before insert or update of employee_id, full_name on public.users
for each row execute function public.keep_linked_account_name_canonical();

commit;
