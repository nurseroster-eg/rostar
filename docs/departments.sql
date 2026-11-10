begin;
create table if not exists public.departments (
 id bigint generated always as identity primary key,
 name text unique not null check(length(trim(name))>0)
);
alter table public.profiles add column if not exists department_id bigint references public.departments(id);
alter table public.departments enable row level security;
revoke all on public.departments from anon, authenticated;
grant select, insert, update on public.departments to authenticated;
grant update(full_name, employee_no, role, department_id) on public.profiles to authenticated;
drop policy if exists departments_read on public.departments;
create policy departments_read on public.departments for select to authenticated using (
 (select public.is_roster_admin()) or exists(
  select 1 from public.profiles where id=(select auth.uid()) and department_id=departments.id
 )
);
drop policy if exists departments_manage on public.departments;
create policy departments_manage on public.departments for all to authenticated
using ((select public.is_roster_admin())) with check ((select public.is_roster_admin()));
notify pgrst, 'reload schema';
commit;
