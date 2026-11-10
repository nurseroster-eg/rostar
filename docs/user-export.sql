begin;
create or replace function public.roster_user_logins()
returns table(user_id uuid, login text)
language sql stable security definer set search_path=''
as $$
 select u.id, case when lower(split_part(u.email,'@',2))='roster.invalid'
  then split_part(u.email,'@',1) else coalesce(u.email,'') end
 from auth.users u join public.profiles p on p.id=u.id
 where (select public.is_roster_admin())
$$;
revoke all on function public.roster_user_logins() from public, anon;
grant execute on function public.roster_user_logins() to authenticated;
notify pgrst,'reload schema';
commit;
