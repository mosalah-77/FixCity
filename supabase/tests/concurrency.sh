#!/usr/bin/env bash
set -euo pipefail
psql_test() { docker exec -i fixcity-demo-test-db psql -U postgres -d fixcity_test -v ON_ERROR_STOP=1; }
psql_test <<'SQL'
insert into auth.users(id,is_anonymous) values('00000000-0000-4000-8000-000000000007',true);
set role authenticated;
select set_config('request.jwt.claims','{"sub":"00000000-0000-4000-8000-000000000007","is_anonymous":true}',false);
select public.start_demo();
SQL
create_same_report() {
  psql_test <<'SQL'
begin;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"00000000-0000-4000-8000-000000000007","is_anonymous":true}',true);
select public.create_report('70000000-0000-4000-8000-000000000001','{"title":"Concurrent retry","description":"Same report from two connections","category":"cat_pothole","district":"Demo North","latitude":30.04,"longitude":31.23,"photo_url":"sample:pothole"}');
select pg_sleep(1);
commit;
SQL
}
create_same_report & first=$!
create_same_report & second=$!
wait "$first"
wait "$second"
psql_test <<'SQL'
do $$ begin
 if (select count(*) from public.reports where title='Concurrent retry')<>1
   or (select points from public.profiles where id='00000000-0000-4000-8000-000000000007')<>30 then
   raise exception 'Concurrent retry duplicated report or points';
 end if;
 raise notice 'PASS: concurrent duplicate requests persist once';
end $$;
SQL

# One remaining signup slot must be claimed by only one of two connections.
psql_test <<'SQL'
insert into auth.users(id,is_anonymous,created_at)
select gen_random_uuid(),true,now() from generate_series(1,99-(select count(*)::int from auth.users where is_anonymous));
SQL
create_visitor() {
  psql_test <<'SQL'
begin;
insert into auth.users(id,is_anonymous,created_at) values(gen_random_uuid(),true,now());
select pg_sleep(1);
commit;
SQL
}
create_visitor & first=$!
create_visitor & second=$!
first_result=0; second_result=0
wait "$first" || first_result=$?
wait "$second" || second_result=$?
if [[ "$first_result" -eq 0 && "$second_result" -eq 0 ]] || [[ "$first_result" -ne 0 && "$second_result" -ne 0 ]]; then
  echo 'FAIL: exactly one concurrent signup must succeed' >&2
  exit 1
fi
psql_test <<'SQL'
do $$ begin
 if (select count(*) from auth.users where is_anonymous)<>100 then
   raise exception 'Concurrent signups exceeded the daily budget';
 end if;
 raise notice 'PASS: concurrent signups respect the final daily slot';
end $$;
SQL
