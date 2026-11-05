\set ON_ERROR_STOP on
begin;
create function pg_temp.check_true(ok boolean, label text) returns void language plpgsql as $$
begin
  if ok is distinct from true then raise exception 'FAIL: %', label; end if;
  raise notice 'PASS: %', label;
end $$;
create function pg_temp.expect_error(query text, expected_state text, label text) returns void language plpgsql as $$
begin
  begin
    execute query;
  exception when others then
    if sqlstate <> expected_state then raise exception 'FAIL: %, expected %, got %: %', label, expected_state, sqlstate, sqlerrm; end if;
    raise notice 'PASS: %', label;
    return;
  end;
  raise exception 'FAIL: % did not reject', label;
end $$;
create function pg_temp.as_user(n integer, anonymous boolean default false) returns void language sql as $$
  select set_config('request.jwt.claims', jsonb_build_object('sub', '00000000-0000-4000-8000-' || lpad(n::text,12,'0'), 'is_anonymous', anonymous, 'role','authenticated')::text, true)::void
$$;
create function pg_temp.payload(photo text default 'storage:00000000-0000-4000-8000-000000000001/report.jpg', district text default 'Demo North') returns jsonb language sql as $$
 select jsonb_build_object('title','Damaged road','description','A synthetic road surface needs repair.','category','cat_pothole','district',district,'latitude',30.04,'longitude',31.23,'photo_url',photo)
$$;
select pg_temp.check_true(to_regclass('public.reports') is not null, 'reproducible schema exists');
insert into auth.users(id,raw_user_meta_data,is_anonymous)
select ('00000000-0000-4000-8000-' || lpad(n::text,12,'0'))::uuid,
  '{"full_name":"Test Citizen","phone":"synthetic","is_admin":true,"points":999}', n>=5
from generate_series(1,6) n;
select pg_temp.check_true((select full_name='Test Citizen' and phone='synthetic' and not is_admin and points=0 from public.profiles where id='00000000-0000-4000-8000-000000000001'), 'signup persists metadata without accepting role or points');
update public.profiles set is_admin=true where id='00000000-0000-4000-8000-000000000003';
update public.profiles set is_governor=true, governor_district='Demo North' where id='00000000-0000-4000-8000-000000000004';
insert into storage.objects(bucket_id,name,owner_id) values
 ('files','00000000-0000-4000-8000-000000000001/report.jpg','00000000-0000-4000-8000-000000000001'),
 ('files','00000000-0000-4000-8000-000000000003/repair.jpg','00000000-0000-4000-8000-000000000003'),
 ('files','00000000-0000-4000-8000-000000000004/repair.jpg','00000000-0000-4000-8000-000000000004');
set local role authenticated;
select pg_temp.as_user(1);
select set_config('test.report', (public.create_report('10000000-0000-4000-8000-000000000001',pg_temp.payload())->>'id'),true);
select pg_temp.check_true((select count(*)=1 from public.reports), 'owner sees own report');
select pg_temp.check_true((select count(*)=1 from public.status_updates), 'create stores initial history');
select pg_temp.check_true((select count(*)=1 from public.notifications), 'create stores one notification');
select pg_temp.check_true((select points=10 from public.profiles), 'create awards points once');
select pg_temp.check_true(public.create_report('10000000-0000-4000-8000-000000000001',pg_temp.payload())->>'id'=current_setting('test.report'), 'same retry returns original report');
select pg_temp.check_true((select count(*)=1 from public.reports) and (select points=10 from public.profiles), 'retry does not duplicate report or points');
select pg_temp.expect_error($q$select public.create_report('10000000-0000-4000-8000-000000000001',pg_temp.payload() || '{"description":"Different content"}')$q$,'23505','conflicting request reuse rejected');
select pg_temp.expect_error($q$update public.profiles set is_admin=true$q$,'42501','role escalation denied');
select pg_temp.expect_error($q$update public.profiles set points=999$q$,'42501','points edits denied');
select pg_temp.expect_error($q$update public.reports set status='resolved'$q$,'42501','direct report write denied');
select pg_temp.expect_error($q$insert into public.status_updates(report_id,text) values (current_setting('test.report')::uuid,'Forged')$q$,'42501','direct history write denied');
select pg_temp.expect_error($q$select public.transition_report(gen_random_uuid(),current_setting('test.report')::uuid,'in_progress','Mine',null)$q$,'42501','citizen cannot transition normal report');
select pg_temp.expect_error($q$select public.create_report(gen_random_uuid(),pg_temp.payload() || '{"user_id":"00000000-0000-4000-8000-000000000002"}')$q$,'22023','forged owner payload rejected');
select pg_temp.expect_error($q$select public.create_report(gen_random_uuid(),pg_temp.payload() || '{"latitude":999}')$q$,'22023','invalid coordinates rejected');
select pg_temp.expect_error($q$select public.create_report(gen_random_uuid(),pg_temp.payload() || '{"description":null}')$q$,'22023','null description rejected at boundary');
select pg_temp.expect_error($q$select public.create_report(gen_random_uuid(),pg_temp.payload() || '{"title":42}')$q$,'22023','non-text title rejected at boundary');
select pg_temp.expect_error($q$select public.create_report(gen_random_uuid(),pg_temp.payload('https://tracker.invalid/a.jpg'))$q$,'22023','arbitrary media URL rejected');
update public.profiles set full_name='Updated name' where id=auth.uid();
select pg_temp.check_true((select full_name='Updated name' from public.profiles), 'permitted profile field editable');
select pg_temp.as_user(2);
select pg_temp.check_true((select count(*)=0 from public.reports) and (select count(*)=0 from public.status_updates) and (select count(*)=0 from public.notifications), 'other citizen cannot enumerate report/history/notification');
select pg_temp.check_true((select count(*)=0 from storage.objects), 'other citizen cannot read private media');
select pg_temp.expect_error($q$select public.create_report(gen_random_uuid(),pg_temp.payload())$q$,'22023','cannot attach another citizen media');
select pg_temp.as_user(3);
select pg_temp.check_true((select count(*)=1 from public.reports), 'staff can read normal report');
select pg_temp.check_true((select count(*)=1 from storage.objects where name like '%/report.jpg'), 'staff can read authorized report media');
select pg_temp.expect_error($q$select public.transition_report(gen_random_uuid(),current_setting('test.report')::uuid,'resolved','Done','storage:00000000-0000-4000-8000-000000000003/repair.jpg')$q$,'22023','cannot skip in-progress step');
select public.transition_report('20000000-0000-4000-8000-000000000001',current_setting('test.report')::uuid,'in_progress','Assigned for repair',null);
select public.transition_report('20000000-0000-4000-8000-000000000001',current_setting('test.report')::uuid,'in_progress','Assigned for repair',null);
select pg_temp.check_true((select count(*)=2 from public.status_updates), 'transition retry creates only one history item');
select pg_temp.expect_error($q$select public.transition_report('20000000-0000-4000-8000-000000000001',current_setting('test.report')::uuid,'resolved','Changed',null)$q$,'23505','conflicting transition retry rejected');
select pg_temp.expect_error($q$select public.transition_report(gen_random_uuid(),current_setting('test.report')::uuid,'resolved','Done',null)$q$,'22023','resolution requires repair media');
select pg_temp.expect_error($q$select public.transition_report(gen_random_uuid(),current_setting('test.report')::uuid,'resolved','   ','storage:00000000-0000-4000-8000-000000000003/repair.jpg')$q$,'22023','resolution requires nonblank note');
select pg_temp.as_user(4);
delete from storage.objects where name='00000000-0000-4000-8000-000000000004/repair.jpg';
select pg_temp.check_true((select count(*)=1 from storage.objects where name='00000000-0000-4000-8000-000000000004/repair.jpg'), 'client cannot delete an upload while it may be attached');
select public.transition_report(gen_random_uuid(),current_setting('test.report')::uuid,'resolved','Surface repaired','storage:00000000-0000-4000-8000-000000000004/repair.jpg');
select pg_temp.check_true((select status='resolved' from public.reports), 'assigned district can resolve with evidence');
reset role;
update public.profiles set is_governor=false where id='00000000-0000-4000-8000-000000000004';
set local role authenticated;
delete from storage.objects where name='00000000-0000-4000-8000-000000000004/repair.jpg';
select pg_temp.check_true((select count(*)=1 from storage.objects where name='00000000-0000-4000-8000-000000000004/repair.jpg'), 'revoked staff cannot delete evidence they uploaded');
reset role;
update public.profiles set is_governor=true where id='00000000-0000-4000-8000-000000000004';
set local role authenticated;
select pg_temp.as_user(1);
select public.create_report('10000000-0000-4000-8000-000000000002',pg_temp.payload(district=>'Demo South'));
select pg_temp.as_user(4);
select pg_temp.check_true((select count(*)=1 from public.reports), 'district cannot enumerate another district');
reset role;
select set_config('test.south',(select id::text from public.reports where district='Demo South'),true);
set local role authenticated;
select pg_temp.expect_error($q$select public.transition_report(gen_random_uuid(),current_setting('test.south')::uuid,'in_progress','Wrong district',null)$q$,'42501','district cannot transition another district');
select pg_temp.as_user(3);
select public.transition_report(gen_random_uuid(),current_setting('test.south')::uuid,'in_progress','Staff cross-district review',null);
select pg_temp.check_true((select status='in_progress' from public.reports where id=current_setting('test.south')::uuid), 'global staff may transition across districts');

-- An error after report/history writes must roll the entire operation back.
reset role;
create function pg_temp.fail_notification() returns trigger language plpgsql as $$ begin raise exception 'simulated final insert failure'; end $$;
create trigger test_notification_failure before insert on public.notifications for each row execute function pg_temp.fail_notification();
set local role authenticated;
select pg_temp.as_user(1);
select pg_temp.expect_error($q$select public.create_report('10000000-0000-4000-8000-000000000003',pg_temp.payload())$q$,'P0001','create propagates final-write failure');
select pg_temp.check_true((select count(*)=2 from public.reports) and (select points=20 from public.profiles), 'failed create rolls back report and points');
select pg_temp.as_user(3);
select pg_temp.expect_error($q$select public.transition_report('20000000-0000-4000-8000-000000000002',current_setting('test.south')::uuid,'resolved','Repair complete','storage:00000000-0000-4000-8000-000000000003/repair.jpg')$q$,'P0001','transition propagates final-write failure');
select pg_temp.check_true((select status='in_progress' from public.reports where id=current_setting('test.south')::uuid), 'failed transition rolls back status');
reset role;
drop trigger test_notification_failure on public.notifications;
set local role authenticated;

select pg_temp.as_user(5,true);
select set_config('test.workspace', public.start_demo()::text,true);
select pg_temp.check_true(public.start_demo()::text=current_setting('test.workspace'), 'demo bootstrap is idempotent');
select pg_temp.check_true((select count(*)=2 from public.reports), 'demo starts with two synthetic examples');
select set_config('test.demo_report',(public.create_report('30000000-0000-4000-8000-000000000001',pg_temp.payload('sample:pothole'))->>'id'),true);
select public.transition_report(gen_random_uuid(),current_setting('test.demo_report')::uuid,'in_progress','Demo staff review',null);
select public.transition_report(gen_random_uuid(),current_setting('test.demo_report')::uuid,'resolved','Demo repair completed','sample:repaired-road');
select pg_temp.check_true((select status='resolved' from public.reports where id=current_setting('test.demo_report')::uuid), 'demo owner can complete the synthetic workflow');
select pg_temp.expect_error($q$select public.create_report(gen_random_uuid(),pg_temp.payload())$q$,'22023','demo cannot attach private or uploaded media');
select pg_temp.expect_error($q$select public.transition_report(gen_random_uuid(),current_setting('test.report')::uuid,'resolved','Forged persona','sample:repaired-road')$q$,'42501','demo persona cannot touch normal reports');
select pg_temp.expect_error($q$insert into storage.objects(bucket_id,name) values('files',auth.uid()::text || '/x.jpg')$q$,'42501','anonymous uploads denied');
select pg_temp.as_user(6,true);
select public.start_demo();
select pg_temp.check_true((select count(*)=0 from public.reports where id=current_setting('test.demo_report')::uuid), 'second visitor cannot read first visitor report');
select pg_temp.check_true((select count(*)=0 from public.status_updates where report_id=current_setting('test.demo_report')::uuid), 'second visitor cannot read first visitor history');
select pg_temp.check_true((select count(*)=0 from public.notifications where report_id=current_setting('test.demo_report')::uuid), 'second visitor cannot read first visitor notification');
select pg_temp.expect_error($q$select public.transition_report(gen_random_uuid(),current_setting('test.demo_report')::uuid,'in_progress','Other visitor',null)$q$,'42501','second visitor cannot edit first visitor');
select pg_temp.as_user(3);
select pg_temp.check_true((select count(*)=0 from public.reports where workspace_id is not null), 'ordinary staff cannot browse private demo workspaces');
select pg_temp.as_user(5,true);
do $$ begin for i in 1..17 loop perform public.create_report(gen_random_uuid(),pg_temp.payload('sample:pothole')); end loop; end $$;
select pg_temp.expect_error($q$select public.create_report(gen_random_uuid(),pg_temp.payload('sample:pothole'))$q$,'54000','workspace capped at twenty reports');
select pg_temp.expect_error($q$select public.reset_demo()$q$,'55000','reset cooldown limits rapid churn');
reset role;
update public.demo_workspaces set created_at=now()-interval '2 minutes' where owner_id='00000000-0000-4000-8000-000000000005';
set local role authenticated;
select pg_temp.check_true(public.reset_demo()::text<>current_setting('test.workspace'), 'reset creates a fresh owned workspace');
select pg_temp.check_true((select count(*)=2 from public.reports) and (select points=20 from public.profiles), 'reset removes prior rows and resets points');
select pg_temp.as_user(6,true);
select pg_temp.check_true((select count(*)=2 from public.reports), 'reset leaves other visitors intact');
reset role;
update public.demo_workspaces set expires_at=now()-interval '1 second' where owner_id='00000000-0000-4000-8000-000000000006';
set local role authenticated;
select pg_temp.check_true((select count(*)=0 from public.reports), 'expired workspace is inaccessible');
select pg_temp.expect_error($q$select public.create_report(gen_random_uuid(),pg_temp.payload('sample:pothole'))$q$,'42501','expired workspace cannot write');
reset role;
select public.prune_demo_workspaces();
select pg_temp.check_true((select count(*)=0 from public.demo_workspaces where expires_at<now()), 'retention cleanup removes expired data');
rollback;
\echo ALL WORKFLOW ASSERTIONS PASSED
