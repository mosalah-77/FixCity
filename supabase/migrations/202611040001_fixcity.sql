-- For a NEW isolated Supabase project only; not a migration of the team's backend.
create table public.profiles (
  id uuid primary key references auth.users on delete cascade,
  full_name text not null default '' check (length(full_name)<=160),
  phone text not null default '' check (length(phone)<=40),
  sms_enabled boolean not null default false,
  points integer not null default 0 check (points>=0),
  is_admin boolean not null default false,
  is_governor boolean not null default false,
  governor_district text
);
create table public.demo_workspaces (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references auth.users on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now()+interval '7 days'
);
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  report_code text not null unique default upper(replace(gen_random_uuid()::text,'-','')),
  user_id uuid not null references auth.users on delete cascade,
  workspace_id uuid references public.demo_workspaces on delete cascade,
  title text not null check (length(btrim(title)) between 1 and 160),
  description text not null check (length(btrim(description)) between 5 and 2000),
  category text not null check (category in ('cat_pothole','cat_trash','cat_lighting','cat_sewage','cat_water','cat_other')),
  district text not null check (length(btrim(district)) between 1 and 120),
  governor_name text not null default '',
  governor_phone text not null default '',
  photo_url text not null,
  fix_photo_url text,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  status text not null default 'pending' check (status in ('pending','in_progress','resolved')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index reports_user on public.reports(user_id,created_at desc);
create index reports_workspace on public.reports(workspace_id);
create index reports_district on public.reports(district);
create table public.status_updates (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references public.reports on delete cascade,
  status text not null,
  text text not null,
  updated_by text not null,
  updated_at timestamptz not null default now()
);
create index status_report on public.status_updates(report_id,updated_at);
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  report_id uuid not null references public.reports on delete cascade,
  title text not null,
  body text not null,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);
create index notifications_user on public.notifications(user_id,created_at desc);
create table public.report_requests (
  user_id uuid not null references auth.users on delete cascade,
  request_id uuid not null,
  action text not null,
  payload jsonb not null,
  report_id uuid not null references public.reports on delete cascade,
  result jsonb,
  primary key(user_id,request_id)
);

create function public.on_auth_user_created() returns trigger
language plpgsql security definer set search_path='' as $$
begin
  insert into public.profiles(id,full_name,phone) values (
    new.id,left(coalesce(new.raw_user_meta_data->>'full_name',''),160),
    left(coalesce(new.raw_user_meta_data->>'phone',''),40));
  return new;
end $$;
create trigger fixcity_profile after insert on auth.users for each row execute function public.on_auth_user_created();

create function public.can_access_report(r public.reports, writing boolean default false) returns boolean
language sql stable security definer set search_path='' as $$
  select auth.uid() is not null and case when r.workspace_id is not null then
    coalesce((auth.jwt()->>'is_anonymous')::boolean,false) and exists (
      select 1 from public.demo_workspaces w where w.id=r.workspace_id and w.owner_id=auth.uid() and w.expires_at>now())
  else
    not coalesce((auth.jwt()->>'is_anonymous')::boolean,false) and exists (
      select 1 from public.profiles p where p.id=auth.uid() and (
        (not writing and r.user_id=p.id) or p.is_admin or (p.is_governor and p.governor_district=r.district)))
  end
$$;
create function public.valid_report_media(media text, demo boolean) returns boolean
language sql stable security definer set search_path='' as $$
 select case when demo then media in ('sample:pothole','sample:trash','sample:lighting','sample:repaired-road','sample:repaired-trash','sample:repaired-lighting')
 else starts_with(media,'storage:' || auth.uid()::text || '/') and exists (
   select 1 from storage.objects o where o.bucket_id='files' and o.name=substring(media from 9)) end
$$;
create function public.can_read_media(object_name text) returns boolean
language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and not coalesce((auth.jwt()->>'is_anonymous')::boolean,false) and (
   starts_with(object_name,auth.uid()::text || '/') or exists (
     select 1 from public.reports r where public.can_access_report(r) and
       ('storage:' || object_name in (r.photo_url,r.fix_photo_url))))
$$;
create function public.can_delete_media(object_name text) returns boolean
language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and not coalesce((auth.jwt()->>'is_anonymous')::boolean,false)
   and starts_with(object_name,auth.uid()::text || '/') and not exists (
     select 1 from public.reports r where 'storage:' || object_name in (r.photo_url,r.fix_photo_url))
$$;

alter table public.profiles enable row level security;
alter table public.demo_workspaces enable row level security;
alter table public.reports enable row level security;
alter table public.status_updates enable row level security;
alter table public.notifications enable row level security;
alter table public.report_requests enable row level security;
revoke all on public.profiles,public.demo_workspaces,public.reports,public.status_updates,public.notifications,public.report_requests from public,anon,authenticated;
grant select on public.profiles,public.demo_workspaces,public.reports,public.status_updates,public.notifications to authenticated;
grant update(full_name,phone,sms_enabled) on public.profiles to authenticated;
grant update(is_read) on public.notifications to authenticated;
grant all on public.profiles,public.demo_workspaces,public.reports,public.status_updates,public.notifications,public.report_requests to service_role;
create policy own_profile on public.profiles for select to authenticated using (id=auth.uid());
create policy edit_profile on public.profiles for update to authenticated using (id=auth.uid()) with check (id=auth.uid());
create policy own_workspace on public.demo_workspaces for select to authenticated using (owner_id=auth.uid() and expires_at>now());
create policy read_reports on public.reports for select to authenticated using (public.can_access_report(reports));
create policy read_history on public.status_updates for select to authenticated using (exists(select 1 from public.reports r where r.id=report_id));
create policy read_notifications on public.notifications for select to authenticated using (user_id=auth.uid() and exists(select 1 from public.reports r where r.id=report_id));
create policy mark_notifications on public.notifications for update to authenticated using (user_id=auth.uid() and exists(select 1 from public.reports r where r.id=report_id)) with check (user_id=auth.uid());

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('files','files',false,5242880,array['image/jpeg','image/png']);
create policy read_report_media on storage.objects for select to authenticated using (bucket_id='files' and public.can_read_media(name));
create policy upload_report_media on storage.objects for insert to authenticated with check (
  bucket_id='files' and not coalesce((auth.jwt()->>'is_anonymous')::boolean,false)
  and starts_with(name,auth.uid()::text || '/') and name ~ '\.(jpg|jpeg|png)$');
create policy delete_unused_media on storage.objects for delete to authenticated using (
  bucket_id='files' and public.can_delete_media(name));

create function public.create_report(p_request_id uuid,p_report jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare
  uid uuid:=auth.uid(); demo boolean:=coalesce((auth.jwt()->>'is_anonymous')::boolean,false);
  workspace uuid; previous public.report_requests; row public.reports; result jsonb;
begin
  if uid is null then raise insufficient_privilege using message='Sign in first'; end if;
  -- Serializes retries and workspace limits for one identity, including concurrent tabs.
  perform 1 from public.profiles where id=uid for update;
  if not found then raise insufficient_privilege using message='Profile unavailable'; end if;
  if demo then
    select id into workspace from public.demo_workspaces where owner_id=uid and expires_at>now();
    if workspace is null then raise insufficient_privilege using message='Start a new demo session'; end if;
  end if;
  select * into previous from public.report_requests where user_id=uid and request_id=p_request_id;
  if found then
    if previous.action<>'create' or previous.payload is distinct from p_report then
      raise unique_violation using message='Request ID already used with different content';
    end if;
    return previous.result;
  end if;
  if p_request_id is null or jsonb_typeof(p_report) is distinct from 'object'
    or p_report-array['title','description','category','district','latitude','longitude','photo_url']<>'{}'::jsonb
    or not (p_report ?& array['title','description','category','district','latitude','longitude','photo_url'])
    or exists(select 1 from jsonb_each(p_report) e where e.key in ('title','description','category','district','photo_url') and jsonb_typeof(e.value)<>'string')
    or length(btrim(p_report->>'title')) not between 1 and 160
    or length(btrim(p_report->>'description')) not between 5 and 2000
    or length(btrim(p_report->>'district')) not between 1 and 120
    or p_report->>'category' not in ('cat_pothole','cat_trash','cat_lighting','cat_sewage','cat_water','cat_other')
    or jsonb_typeof(p_report->'latitude') is distinct from 'number'
    or jsonb_typeof(p_report->'longitude') is distinct from 'number'
    or (p_report->>'latitude')::double precision not between -90 and 90
    or (p_report->>'longitude')::double precision not between -180 and 180
    or public.valid_report_media(p_report->>'photo_url',demo) is distinct from true
    or (demo and p_report->>'district' not in ('Demo North','Demo South')) then
    raise invalid_parameter_value using message='Invalid report fields or media';
  end if;
  if demo and (select count(*) from public.reports where workspace_id=workspace)>=20 then
    raise program_limit_exceeded using message='Demo limit reached; reset the demo';
  end if;
  insert into public.reports(user_id,workspace_id,title,description,category,district,latitude,longitude,photo_url)
  values(uid,workspace,btrim(p_report->>'title'),btrim(p_report->>'description'),p_report->>'category',btrim(p_report->>'district'),
    (p_report->>'latitude')::double precision,(p_report->>'longitude')::double precision,p_report->>'photo_url') returning * into row;
  insert into public.status_updates(report_id,status,text,updated_by) values(row.id,'pending','Report received / تم استلام البلاغ','Citizen');
  update public.profiles set points=points+10 where id=uid;
  insert into public.notifications(user_id,report_id,title,body)
    values(uid,row.id,'Report received / تم استلام البلاغ',row.report_code);
  result:=to_jsonb(row);
  insert into public.report_requests(user_id,request_id,action,payload,report_id,result) values(uid,p_request_id,'create',p_report,row.id,result);
  return result;
end $$;

create function public.transition_report(p_request_id uuid,p_report_id uuid,p_status text,p_note text,p_fix_photo_url text default null) returns void
language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); r public.reports; previous public.report_requests;
  payload jsonb:=jsonb_build_object('report_id',p_report_id,'status',p_status,'note',p_note,'fix_photo_url',p_fix_photo_url);
begin
  if uid is null then raise insufficient_privilege using message='Sign in first'; end if;
  perform 1 from public.profiles where id=uid for update;
  select * into r from public.reports where id=p_report_id for update;
  if not found or public.can_access_report(r,true) is distinct from true then
    raise insufficient_privilege using message='Report unavailable for this account';
  end if;
  select * into previous from public.report_requests where user_id=uid and request_id=p_request_id;
  if found then
    if previous.action<>'transition' or previous.payload is distinct from payload then
      raise unique_violation using message='Request ID already used with different content';
    end if;
    return;
  end if;
  if p_request_id is null or length(btrim(coalesce(p_note,''))) not between 1 and 2000
    or not coalesce((r.status='pending' and p_status='in_progress') or (r.status='in_progress' and p_status='resolved'),false)
    or (p_status='resolved' and public.valid_report_media(p_fix_photo_url,r.workspace_id is not null) is distinct from true)
    or (p_status<>'resolved' and p_fix_photo_url is not null) then
    raise invalid_parameter_value using message='Use the next status, an update note and repair evidence when resolving';
  end if;
  update public.reports set status=p_status,fix_photo_url=p_fix_photo_url,updated_at=now() where id=r.id;
  insert into public.status_updates(report_id,status,text,updated_by)
    values(r.id,p_status,btrim(p_note),case when r.workspace_id is not null then 'Demo team' else 'Municipal team' end);
  insert into public.notifications(user_id,report_id,title,body)
    values(r.user_id,r.id,'Report updated / تحديث البلاغ',p_status || ': ' || btrim(p_note));
  insert into public.report_requests(user_id,request_id,action,payload,report_id) values(uid,p_request_id,'transition',payload,r.id);
end $$;

create function public.start_demo() returns uuid language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); workspace uuid;
begin
  if uid is null or not coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then
    raise insufficient_privilege using message='An anonymous demo session is required';
  end if;
  perform 1 from public.profiles where id=uid for update;
  if not found then raise insufficient_privilege using message='Profile unavailable'; end if;
  select id into workspace from public.demo_workspaces where owner_id=uid and expires_at>now();
  if workspace is not null then return workspace; end if;
  delete from public.demo_workspaces where owner_id=uid;
  update public.profiles set points=0,full_name='Demo citizen',phone='',sms_enabled=false where id=uid;
  insert into public.demo_workspaces(owner_id) values(uid) returning id into workspace;
  perform public.create_report(gen_random_uuid(),jsonb_build_object('title','Sample road report / بلاغ طريق تجريبي','description','Synthetic example: a damaged road surface in Demo North.','category','cat_pothole','district','Demo North','latitude',30.04,'longitude',31.23,'photo_url','sample:pothole'));
  perform public.create_report(gen_random_uuid(),jsonb_build_object('title','Sample waste report / بلاغ نظافة تجريبي','description','Synthetic example: litter collection needed in Demo South.','category','cat_trash','district','Demo South','latitude',30.05,'longitude',31.24,'photo_url','sample:trash'));
  return workspace;
end $$;
create function public.reset_demo() returns uuid language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid();
begin
  if uid is null or not coalesce((auth.jwt()->>'is_anonymous')::boolean,false) then raise insufficient_privilege; end if;
  perform 1 from public.profiles where id=uid for update;
  if exists(select 1 from public.demo_workspaces where owner_id=uid and created_at>now()-interval '1 minute') then
    raise object_not_in_prerequisite_state using message='Wait one minute before resetting again';
  end if;
  delete from public.demo_workspaces where owner_id=uid;
  return public.start_demo();
end $$;
create function public.prune_demo_workspaces() returns void language sql security definer set search_path='' as $$
  delete from public.demo_workspaces where expires_at<=now()
$$;

revoke all on function public.on_auth_user_created(),public.can_access_report(public.reports,boolean),public.valid_report_media(text,boolean),public.can_read_media(text),public.can_delete_media(text),public.create_report(uuid,jsonb),public.transition_report(uuid,uuid,text,text,text),public.start_demo(),public.reset_demo(),public.prune_demo_workspaces() from public,anon,authenticated;
grant execute on function public.can_access_report(public.reports,boolean),public.can_read_media(text),public.can_delete_media(text),public.create_report(uuid,jsonb),public.transition_report(uuid,uuid,text,text,text),public.start_demo(),public.reset_demo() to authenticated;
grant execute on function public.prune_demo_workspaces() to service_role;
