begin;
create or replace function public.delete_roster_user(target_id uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
 if not public.is_roster_admin() or target_id=auth.uid() then
  raise exception 'الحذف متاح للمشرف لحساب آخر فقط' using errcode='42501';
 end if;
 perform 1 from public.profiles where id=target_id and role='nurse' for update;
 if not found then raise exception 'يمكن حذف حساب ممرض فقط'; end if;
 delete from public.roster_audit where subject_id=target_id or actor_id=target_id;
 delete from public.preferences where user_id=target_id;
 delete from public.assignments where user_id=target_id;
 -- The assignment delete trigger can append audit rows.
 delete from public.roster_audit where subject_id=target_id;
 delete from auth.users where id=target_id;
 if not found then raise exception 'حساب الدخول غير موجود'; end if;
end;
$$;
revoke all on function public.delete_roster_user(uuid) from public,anon,authenticated;
grant execute on function public.delete_roster_user(uuid) to authenticated;
notify pgrst,'reload schema';
commit;
