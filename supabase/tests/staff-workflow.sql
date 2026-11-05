\set ON_ERROR_STOP on
begin;
create function pg_temp.check_true(ok boolean, label text) returns void language plpgsql as $$
begin if ok is distinct from true then raise exception 'FAIL: %',label; end if; raise notice 'PASS: %',label; end $$;
create function pg_temp.reject(q text, expected text) returns void language plpgsql as $$
begin begin execute q; exception when others then if sqlstate<>expected then raise; end if; return; end; raise exception 'Unexpected permission: %',q; end $$;
create function pg_temp.actor(n integer) returns void language sql as $$
select set_config('request.jwt.claims',jsonb_build_object('sub','11111111-1111-4111-8111-'||lpad(n::text,12,'0'),'is_anonymous',false,'role','authenticated')::text,true)::void $$;
insert into auth.users(id) select ('11111111-1111-4111-8111-'||lpad(n::text,12,'0'))::uuid from generate_series(1,4)n;
update public.profiles set is_admin=true where id='11111111-1111-4111-8111-000000000003';
update public.profiles set is_governor=true,governor_district='Demo North' where id='11111111-1111-4111-8111-000000000004';
insert into storage.objects(bucket_id,name) select 'files','11111111-1111-4111-8111-'||lpad(n::text,12,'0')||'/photo.jpg' from generate_series(1,4)n;
set local role authenticated;
select pg_temp.actor(1);
select set_config('test.id',public.create_report(gen_random_uuid(),'{"title":"Road","description":"Synthetic inspection","category":"cat_pothole","district":"Demo North","latitude":30,"longitude":31,"photo_url":"storage:11111111-1111-4111-8111-000000000001/photo.jpg"}')->>'id',true);
select pg_temp.actor(4);
select pg_temp.reject($q$select public.transition_report(gen_random_uuid(),current_setting('test.id')::uuid,'in_progress','Skip review',null)$q$,'22023');
select pg_temp.reject($q$select public.transition_report(gen_random_uuid(),current_setting('test.id')::uuid,'assigned','Self-approve',null)$q$,'42501');
select pg_temp.actor(3);
select public.transition_report('22222222-2222-4222-8222-000000000001',current_setting('test.id')::uuid,'assigned','Inspection complete','storage:11111111-1111-4111-8111-000000000003/photo.jpg');
select public.transition_report('22222222-2222-4222-8222-000000000001',current_setting('test.id')::uuid,'assigned','Inspection complete','storage:11111111-1111-4111-8111-000000000003/photo.jpg');
select pg_temp.check_true((select status='assigned' and fix_photo_url is null from public.reports),'handoff does not imply completed repair');
select pg_temp.check_true((select count(*)=1 from public.status_updates where photo_url='storage:11111111-1111-4111-8111-000000000003/photo.jpg' and updated_by='Staff review'),'first photo persists in history once');
select pg_temp.reject($q$select public.transition_report(gen_random_uuid(),current_setting('test.id')::uuid,'in_progress','Staff starts work',null)$q$,'42501');
select pg_temp.actor(4);
select public.transition_report(gen_random_uuid(),current_setting('test.id')::uuid,'in_progress','Work started','storage:11111111-1111-4111-8111-000000000004/photo.jpg');
select public.transition_report(gen_random_uuid(),current_setting('test.id')::uuid,'in_progress','Waiting for materials',null);
select pg_temp.check_true((select status='in_progress' and fix_photo_url is null from public.reports),'progress note keeps repair open');
select pg_temp.reject($q$select public.transition_report(gen_random_uuid(),current_setting('test.id')::uuid,'resolved','Done',null)$q$,'22023');
select pg_temp.reject($q$select public.transition_report(gen_random_uuid(),current_setting('test.id')::uuid,'in_progress','Wrong photo','https://invalid.test/a.png')$q$,'22023');
select pg_temp.actor(3);
select pg_temp.reject($q$select public.transition_report(gen_random_uuid(),current_setting('test.id')::uuid,'resolved','Staff closes','storage:11111111-1111-4111-8111-000000000003/photo.jpg')$q$,'42501');
select pg_temp.actor(1);
select pg_temp.check_true((select count(*)=3 from storage.objects),'citizen can read original, review and progress evidence');
select pg_temp.actor(2);
select pg_temp.check_true((select count(*)=0 from public.status_updates),'other citizen cannot see update photos');
select pg_temp.check_true((select count(*)=1 from storage.objects),'other citizen sees only own unused upload');
select pg_temp.actor(4);
select public.transition_report(gen_random_uuid(),current_setting('test.id')::uuid,'resolved','Repair completed','storage:11111111-1111-4111-8111-000000000004/photo.jpg');
select pg_temp.check_true((select status='resolved' and fix_photo_url='storage:11111111-1111-4111-8111-000000000004/photo.jpg' from public.reports),'district closes with final evidence');
select pg_temp.check_true((select count(*)=3 from public.status_updates where updated_by='District team'),'district authorship is recorded');
-- Fill only this transaction's fixture to the bounded history limit.
reset role;
update public.reports set status='in_progress' where id=current_setting('test.id')::uuid;
insert into public.status_updates(report_id,status,text,updated_by)
select current_setting('test.id')::uuid,'in_progress','Synthetic boundary fixture','District team' from generate_series(1,94);
set local role authenticated;
select pg_temp.actor(4);
select pg_temp.reject($q$select public.transition_report(gen_random_uuid(),current_setting('test.id')::uuid,'in_progress','One extra note',null)$q$,'54000');
select public.transition_report(gen_random_uuid(),current_setting('test.id')::uuid,'resolved','Final evidence remains allowed','storage:11111111-1111-4111-8111-000000000004/photo.jpg');
select pg_temp.check_true((select count(*)=100 from public.status_updates),'history limit reserves the final repair entry');
rollback;
\echo STAFF WORKFLOW ASSERTIONS PASSED
