-- Run AFTER docs/schema.sql in Supabase SQL Editor.
create table if not exists public.roster_audit (
 id bigint generated always as identity primary key,
 actor_id uuid references auth.users(id) on delete set null,
 subject_id uuid references auth.users(id) on delete set null,
 work_date date,
 operation text not null,
 old_shift text,
 new_shift text,
 happened_at timestamptz not null default now()
);
alter table public.roster_audit enable row level security;
drop policy if exists audit_admin_read on public.roster_audit;
create policy audit_admin_read on public.roster_audit for select to authenticated
using ((select public.is_roster_admin()));
create or replace function public.audit_roster_assignment()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
 insert into public.roster_audit(actor_id,subject_id,work_date,operation,old_shift,new_shift)
 values ((select auth.uid()),coalesce(new.user_id,old.user_id),
 coalesce(new.work_date,old.work_date),tg_op,
 case when tg_op='INSERT' then null else old.shift_code end,
 case when tg_op='DELETE' then null else new.shift_code end);
 return coalesce(new,old);
end; $$;
drop trigger if exists roster_assignment_audit on public.assignments;
create trigger roster_assignment_audit after insert or update or delete on public.assignments
for each row execute function public.audit_roster_assignment();
-- Prevent users from directly inserting/updating/deleting audit records.
revoke insert,update,delete on public.roster_audit from anon,authenticated;
grant select on public.roster_audit to authenticated;
