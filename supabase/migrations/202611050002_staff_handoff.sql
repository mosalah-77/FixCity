-- Keep existing records; add a review handoff and evidence on each update.
alter table public.reports drop constraint reports_status_check;
alter table public.reports add constraint reports_status_check check (status in ('pending','assigned','in_progress','resolved'));
alter table public.status_updates add column photo_url text;

-- Preserve historical resolution evidence where the report already has it.
update public.status_updates u set photo_url=r.fix_photo_url
from public.reports r where u.report_id=r.id and u.status='resolved' and r.fix_photo_url is not null;

create or replace function public.can_read_media(object_name text) returns boolean
language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and not coalesce((auth.jwt()->>'is_anonymous')::boolean,false) and (
   starts_with(object_name,auth.uid()::text || '/') or exists (
     select 1 from public.reports r where public.can_access_report(r) and
       ('storage:' || object_name in (r.photo_url,r.fix_photo_url) or exists (
         select 1 from public.status_updates u where u.report_id=r.id and u.photo_url='storage:' || object_name))))
$$;

create or replace function public.transition_report(p_request_id uuid,p_report_id uuid,p_status text,p_note text,p_fix_photo_url text default null) returns void
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
    or not coalesce((r.status='pending' and p_status='assigned') or (r.status='assigned' and p_status='in_progress') or (r.status='in_progress' and p_status in ('in_progress','resolved')),false)
    or (p_status='resolved' and public.valid_report_media(p_fix_photo_url,r.workspace_id is not null) is distinct from true)
    or (p_fix_photo_url is not null and public.valid_report_media(p_fix_photo_url,r.workspace_id is not null) is distinct from true) then
    raise invalid_parameter_value using message='Use the next status, an update note and repair evidence when resolving';
  end if;
  -- Demo personas share an owned synthetic workspace. Normal roles come from server-managed profiles.
  if r.workspace_id is null and not exists (
    select 1 from public.profiles p where p.id=uid and
      ((p_status='assigned' and p.is_admin) or
       (p_status in ('in_progress','resolved') and p.is_governor and p.governor_district=r.district))) then
    raise insufficient_privilege using message='Staff review hands off reports; the assigned district records repairs';
  end if;
  if (select count(*) from public.status_updates where report_id=r.id)>=(case when p_status='resolved' then 100 else 99 end) then
    raise program_limit_exceeded using message='This report has reached its update limit';
  end if;
  update public.reports set status=p_status,
    fix_photo_url=case when p_status='resolved' then p_fix_photo_url else fix_photo_url end,
    updated_at=now() where id=r.id;
  insert into public.status_updates(report_id,status,text,updated_by,photo_url)
    values(r.id,p_status,btrim(p_note),case when p_status='assigned' then 'Staff review' else 'District team' end,p_fix_photo_url);
  insert into public.notifications(user_id,report_id,title,body)
    values(r.user_id,r.id,'Report updated / تحديث البلاغ',p_status || ': ' || btrim(p_note));
  insert into public.report_requests(user_id,request_id,action,payload,report_id) values(uid,p_request_id,'transition',payload,r.id);
end $$;
