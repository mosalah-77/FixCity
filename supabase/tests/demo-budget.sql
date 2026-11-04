\set ON_ERROR_STOP on
begin;
create function pg_temp.assert_ok(ok boolean, label text) returns void language plpgsql as $$
begin if ok is distinct from true then raise exception 'FAIL: %',label; end if; raise notice 'PASS: %',label; end $$;
create function pg_temp.must_reject(query text, expected text) returns void language plpgsql as $$
begin
  begin execute query; exception when others then
    if sqlstate=expected then return; end if;
    raise exception 'Wrong rejection: % %',sqlstate,sqlerrm;
  end;
  raise exception 'Expected rejection: %',query;
end $$;
update public.demo_workspaces set expires_at=now()-interval '1 second';
-- Fill the rolling 24-hour allowance exactly; normal signups remain separate.
insert into auth.users(id,is_anonymous,created_at) select gen_random_uuid(),true,now() from generate_series(1,100-(select count(*)::int from auth.users where is_anonymous));
select pg_temp.must_reject('insert into auth.users(id,is_anonymous,created_at) values(gen_random_uuid(),true,now())','54000');
select pg_temp.assert_ok((select count(*)=100 from auth.users where is_anonymous), 'daily anonymous budget is enforced');
insert into auth.users(id,is_anonymous,created_at) values('10000000-0000-4000-8000-000000000001',false,now());
select pg_temp.assert_ok(exists(select 1 from public.profiles where id='10000000-0000-4000-8000-000000000001'), 'ordinary users are outside the anonymous cap');
-- Move each batch into the past so the independent total cap is tested.
do $$ begin for n in 1..4 loop
  update auth.users set created_at=now()-interval '2 days' where is_anonymous;
  insert into auth.users(id,is_anonymous,created_at) select gen_random_uuid(),true,now() from generate_series(1,100);
end loop; end $$;
update auth.users set created_at=now()-interval '2 days' where is_anonymous;
select pg_temp.must_reject('insert into auth.users(id,is_anonymous,created_at) values(gen_random_uuid(),true,now())','54000');
select pg_temp.assert_ok((select count(*)=500 from auth.users where is_anonymous), 'total anonymous budget is enforced');
update auth.users set created_at=now()-interval '8 days';
select set_config('test.retained',(select id::text from auth.users where is_anonymous limit 1),true);
select set_config('request.jwt.claims',jsonb_build_object('sub',current_setting('test.retained'),'is_anonymous',true)::text,true);
set local role authenticated;
select public.start_demo();
select pg_temp.must_reject('select public.prune_demo_accounts()','42501');
reset role;
select public.prune_demo_accounts();
select pg_temp.assert_ok((select count(*)=1 from auth.users where is_anonymous), 'cleanup preserves an old identity with an active workspace');
select pg_temp.assert_ok(exists(select 1 from auth.users where not is_anonymous), 'cleanup never deletes ordinary accounts');
update public.demo_workspaces set expires_at=now()-interval '1 second';
select public.prune_demo_accounts();
select pg_temp.assert_ok((select count(*)=0 from auth.users where is_anonymous), 'cleanup removes expired anonymous identities');
select pg_temp.assert_ok((select count(*)=0 from public.demo_workspaces) and (select count(*)=0 from public.reports), 'cleanup cascades only expired demo data');
rollback;
