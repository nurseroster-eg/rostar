begin;
alter table public.periods
 add column if not exists opens_on date,
 add column if not exists closes_on date;
alter table public.periods add constraint roster_preference_window_dates check (
 (opens_on is null and closes_on is null) or
 (opens_on is not null and closes_on is not null and opens_on <= closes_on)
);
create policy preferences_insert_window on public.preferences as restrictive
for insert to authenticated with check (
 exists(select 1 from public.periods p where p.month=date_trunc('month',work_date)::date
 and (p.opens_on is null or (now() at time zone 'Africa/Cairo')::date between p.opens_on and p.closes_on))
);
create policy preferences_update_window on public.preferences as restrictive
for update to authenticated using (
 exists(select 1 from public.periods p where p.month=date_trunc('month',work_date)::date
 and (p.opens_on is null or (now() at time zone 'Africa/Cairo')::date between p.opens_on and p.closes_on))
) with check (
 exists(select 1 from public.periods p where p.month=date_trunc('month',work_date)::date
 and (p.opens_on is null or (now() at time zone 'Africa/Cairo')::date between p.opens_on and p.closes_on))
);
notify pgrst,'reload schema';
commit;
