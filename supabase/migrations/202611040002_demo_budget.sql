-- Only for the separate, anonymous-only portfolio backend.
create function public.limit_demo_accounts() returns trigger
language plpgsql security definer set search_path='' as $$
begin
  if new.is_anonymous then
    -- Serialize signup checks so parallel requests cannot overrun either cap.
    perform pg_catalog.pg_advisory_xact_lock(660842821);
    if (select count(*) from auth.users where is_anonymous)>=500 or
       (select count(*) from auth.users where is_anonymous and created_at>now()-interval '24 hours')>=100 then
      raise exception 'Demo visitor capacity reached; please try later' using errcode='54000';
    end if;
  end if;
  return new;
end $$;
create trigger fixcity_demo_budget before insert on auth.users
for each row execute function public.limit_demo_accounts();
revoke all on function public.limit_demo_accounts() from public,anon,authenticated;

create function public.prune_demo_accounts() returns void
language plpgsql security definer set search_path='' as $$
begin
  perform public.prune_demo_workspaces();
  delete from auth.users u where u.is_anonymous
    and u.created_at<now()-interval '7 days'
    and not exists(select 1 from public.demo_workspaces w where w.owner_id=u.id and w.expires_at>now());
end $$;
revoke all on function public.prune_demo_accounts() from public,anon,authenticated;
grant execute on function public.prune_demo_accounts() to service_role;
