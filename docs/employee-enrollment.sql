begin;
create table if not exists public.employee_enrollment (
 employee_no text primary key check (length(employee_no) between 1 and 40),
 full_name text not null check (length(trim(full_name)) between 1 and 120),
 requested_login text,
 auth_user_id uuid references auth.users(id) on delete set null,
 requested_at timestamptz,
 approved_at timestamptz
);
alter table public.employee_enrollment enable row level security;
revoke all on public.employee_enrollment from public, anon, authenticated;
grant select, insert, update on public.employee_enrollment to service_role;
commit;
