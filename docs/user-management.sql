-- Run once in Supabase SQL Editor to enable ADMIN-only profile editing.
-- Never allow public/anonymous account management.
drop policy if exists profiles_admin_update on public.profiles;
create policy profiles_admin_update on public.profiles
for update to authenticated
using ((select public.is_roster_admin()))
with check ((select public.is_roster_admin()));
-- Restrict role escalation to admins: policy grants updates only to current admins.
-- Accounts are created in Supabase Authentication > Users, never by inserting profiles directly.
