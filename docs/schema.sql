-- NurseRoster Supabase schema. Run in Supabase SQL Editor.
create extension if not exists pgcrypto;
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null default '',
 employee_no text unique,
 role text not null default 'nurse' check (role in ('nurse','admin')),
 created_at timestamptz not null default now()
);
create table if not exists public.preferences (
 id bigint generated always as identity primary key,
 user_id uuid not null references public.profiles(id) on delete cascade,
 work_date date not null,
 shift_code text not null check (shift_code in ('E','N','8','#')),
 updated_at timestamptz not null default now(),
 unique(user_id,work_date)
);
create table if not exists public.assignments (
 id bigint generated always as identity primary key,
 user_id uuid not null references public.profiles(id) on delete cascade,
 work_date date not null,
 shift_code text not null check (shift_code in ('E','N','8','#')),
 updated_at timestamptz not null default now(),
 unique(user_id,work_date)
);
create table if not exists public.periods (
 month date primary key,
 status text not null default 'open' check (status in ('open','closed','published')),
 updated_at timestamptz not null default now()
);
create or replace function public.is_roster_admin()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin') $$;
revoke all on function public.is_roster_admin() from public;
grant execute on function public.is_roster_admin() to authenticated;
create or replace function public.make_nurse_profile()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
 insert into public.profiles(id,full_name,role)
 values(new.id,coalesce(nullif(new.raw_user_meta_data->>'full_name',''),split_part(new.email,'@',1)),'nurse')
 on conflict (id) do nothing;
 return new;
end; $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.make_nurse_profile();
alter table public.profiles enable row level security;
alter table public.preferences enable row level security;
alter table public.assignments enable row level security;
alter table public.periods enable row level security;
drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles for select to authenticated using (id=(select auth.uid()) or (select public.is_roster_admin()));
drop policy if exists preferences_read on public.preferences;
create policy preferences_read on public.preferences for select to authenticated using (user_id=(select auth.uid()) or (select public.is_roster_admin()));
drop policy if exists preferences_insert on public.preferences;
create policy preferences_insert on public.preferences for insert to authenticated with check (
 user_id=(select auth.uid()) and exists(
 select 1 from public.periods p where p.month=date_trunc('month',work_date)::date and p.status='open'
 )
);
drop policy if exists preferences_update on public.preferences;
create policy preferences_update on public.preferences for update to authenticated using (
 user_id=(select auth.uid()) and exists(
 select 1 from public.periods p where p.month=date_trunc('month',work_date)::date and p.status='open'
 )
) with check (
 user_id=(select auth.uid()) and exists(
 select 1 from public.periods p where p.month=date_trunc('month',work_date)::date and p.status='open'
 )
);
drop policy if exists assignments_read on public.assignments;
create policy assignments_read on public.assignments for select to authenticated using (
 (select public.is_roster_admin()) or
 (user_id=(select auth.uid()) and exists(
 select 1 from public.periods p where p.month=date_trunc('month',work_date)::date and p.status='published'
 ))
);
drop policy if exists assignments_insert on public.assignments;
create policy assignments_insert on public.assignments for insert to authenticated with check (
 (select public.is_roster_admin()) and exists(
 select 1 from public.periods p where p.month=date_trunc('month',work_date)::date and p.status<>'published'
 )
);
drop policy if exists assignments_update on public.assignments;
create policy assignments_update on public.assignments for update to authenticated using (
 (select public.is_roster_admin()) and exists(
 select 1 from public.periods p where p.month=date_trunc('month',work_date)::date and p.status<>'published'
 )
) with check (
 (select public.is_roster_admin()) and exists(
 select 1 from public.periods p where p.month=date_trunc('month',work_date)::date and p.status<>'published'
 )
);
drop policy if exists periods_read on public.periods;
create policy periods_read on public.periods for select to authenticated using (true);
drop policy if exists periods_insert on public.periods;
create policy periods_insert on public.periods for insert to authenticated with check ((select public.is_roster_admin()));
drop policy if exists periods_update on public.periods;
create policy periods_update on public.periods for update to authenticated using ((select public.is_roster_admin())) with check ((select public.is_roster_admin()));
-- After creating YOUR admin user in Supabase Authentication > Users, run once:
-- update public.profiles set role='admin' where id='YOUR_ADMIN_AUTH_USER_UUID';
-- Do not run that update with a real UUID until you have verified the intended account.
