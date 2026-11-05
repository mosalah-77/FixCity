#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
# This script resets only the named database inside our disposable, portless test container.
container=fixcity-demo-test-db
database=fixcity_test
docker exec "$container" dropdb -U postgres --if-exists "$database"
docker exec "$container" createdb -U postgres "$database"
docker exec -i "$container" psql -U postgres -d "$database" -v ON_ERROR_STOP=1 < supabase/tests/platform-stub.sql
for migration in supabase/migrations/*.sql; do
  docker exec -i "$container" psql -U postgres -d "$database" -v ON_ERROR_STOP=1 < "$migration"
done
docker exec -i "$container" psql -U postgres -d "$database" -v ON_ERROR_STOP=1 < supabase/tests/workflow.sql
bash supabase/tests/concurrency.sh
docker exec -i "$container" psql -U postgres -d "$database" -v ON_ERROR_STOP=1 < supabase/tests/demo-budget.sql
docker exec -i "$container" psql -U postgres -d "$database" -v ON_ERROR_STOP=1 < supabase/tests/staff-workflow.sql
