# FixCity's separate demo backend

The versioned schema in `supabase/migrations/202611040001_fixcity.sql` reconstructs the active Flutter workflow. It is new portfolio work, not an export of the original team's Supabase project. Apply it only to a fresh, isolated project. It must never be run over the old backend or real citizen data.

## Provisioning

1. Create a free Supabase project. Keep the database password outside Git. Disable automatic table exposure and enable automatic row security; the migration grants only the permissions needed by the app.
2. Apply all numbered migrations in order with the Supabase CLI or SQL editor. `platform-stub.sql` is **only for the disposable PostgreSQL test container**; never upload it to Supabase.
3. Enable anonymous sign-in for the demo. Disable the Email provider and leave every other sign-in provider off in this demo-only project. Anonymous sign-in remains enabled. The hosted free-project dashboard shows a read-only anonymous limit of 30 per hour per IP; the separate database guard adds 100 new anonymous identities per rolling 24 hours and 500 retained anonymous identities globally. The checked-in `config.toml` describes local settings; it does not change a hosted project's dashboard settings.
4. Set the site URL to the published demo URL and keep redirects restricted to the actual demo and local development URL. Public builds use only the project URL and publishable/anon client key. Never embed a service-role key, database password or management token.
5. Before public release, verify anonymous abuse controls and quotas. Supabase recommends CAPTCHA for anonymous sign-in; if enabled, wire its challenge token into the app before release. API rate limits are not a substitute for CAPTCHA or a total resource budget. The first release uses database caps and the platform IP limit; it has no CAPTCHA challenge. These bounds limit stored data, not all request/egress abuse. Review usage while sharing the demo; stop anonymous signup if abusive traffic appears.
6. Schedule `select public.prune_demo_accounts();` hourly through Supabase Cron (or a trusted server task). Only the database owner/service role can call it. It deletes expired workspaces and their report/history/notification/request rows; never normal reports. Expired rows are inaccessible immediately, even before cleanup runs. The account cleanup additionally removes anonymous Auth identities older than seven days only when they have no active workspace. It preserves ordinary accounts and active demo sessions. Never run it over a production project.
7. Test with two independent anonymous sessions and ordinary citizen/staff/district accounts before claiming the backend is verified. Privileged test accounts are created privately; no shared admin login belongs in the public demo.

The public demo uses synthetic sample illustrations, not uploads or real official contacts. Each anonymous identity owns one workspace, with two starting reports and a maximum of 20 total reports. Data expires after seven days. Reset removes only that visitor's workspace and is limited to once per minute. Signing out or clearing app/browser storage loses access to the old anonymous identity.

## Permissions and consistency

- Normal citizens can read their own reports. Normal staff can read across districts and hand pending reports to the selected district. District accounts can start, update and resolve repairs only in their assigned district. Staff cannot complete repairs using the staff role alone.
- Anonymous demo users can simulate all three personas only inside their own workspace. Ordinary staff cannot browse demo workspaces. Client routes and persona buttons grant no database privileges.
- Profile updates are restricted to name, phone and SMS preference columns. Auth signup copies name/phone metadata but ignores any supplied roles or points. Roles and district assignments require a privileged operator; do not expose them through signup or public RPCs.
- `create_report` saves the report, initial history, notification, ten points and retry result in one transaction. `transition_report` saves status, history, the update's photo and notification together. The client does not insert points or notifications separately.
- Retry IDs are unique per actor. Identical retries return the original result; changed payloads with the same ID are rejected. Per-user row locks serialize report limits and simultaneous retries.
- Transitions are `pending → assigned → in_progress → resolved`. The UI labels `assigned` as "Sent to district". An `in_progress → in_progress` update records progress without closing the report. Every update needs a note; photos are optional until resolution, which requires repair media. Invalid transitions and failed final writes roll back the operation.
- `status_updates.photo_url` retains each update's evidence. Only resolution changes the report's final `fix_photo_url`. History is capped at 100 entries; non-final updates stop at 99 so one slot remains for resolution.
- Tracking codes are not public credentials. Searching a code still obeys the caller's report permissions.

## Private media outside the demo

The `files` bucket is private, restricted to JPEG/PNG and 5 MiB. Normal users upload under their own user-ID folder with a new filename. Reports store `storage:<path>`, not a public URL; the client obtains short-lived signed URLs only for authorized reads. A user cannot attach another person's upload. Staff may attach inspection evidence during handoff; district users may attach progress and repair evidence for reports they can manage. Reading an update's attachment requires permission to read its report. Clients cannot delete or overwrite images, including unused uploads. This prevents a concurrent delete from removing evidence as a report attaches it. Unused uploads require trusted maintenance with report writes stopped and references rechecked; no automatic orphan cleanup is installed. Keep this in mind before enabling real accounts and uploads.

Storage upload and SQL are separate operations. Keep a successful upload for a retry when a save response is uncertain. Leave cleanup to trusted maintenance as described above. Signed URLs remain usable for their short lifetime after access is revoked. Public demo uploads stay disabled.

## Reproduce the SQL checks

Docker must be running. The pinned test image is PostgreSQL 17; no host port or existing volume is mounted:

```sh
docker run --rm -d --name fixcity-demo-test-db -e POSTGRES_HOST_AUTH_METHOD=trust postgres@sha256:266d3c257594e195b309ae9d1805e54c788f1d7b375f56bf6c367aac6c917e7b
bash supabase/tests/run-local.sh
docker stop fixcity-demo-test-db
```

The script recreates only `fixcity_test` inside that named disposable container. It tests SQL permissions, owner/district/workspace boundaries, retry conflicts, transaction rollback, media retention and two concurrent duplicate requests. A minimal test-only Auth/Storage schema supplies Supabase's SQL interfaces. This is not a full Supabase Auth, Storage upload, Realtime or REST integration test; those require the separate hosted/local Supabase stack.

## Original source secret

The exposed Gemini key in the original source still needs owner-side rotation/revocation if not already done. It was removed from this portfolio copy, never tested and never reused. The demo's category suggestion runs locally; it makes no live Gemini call.

References: [Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [anonymous sign-in](https://supabase.com/docs/guides/auth/auth-anonymous), [rate limits](https://supabase.com/docs/guides/auth/rate-limits), [local configuration](https://supabase.com/docs/guides/local-development/cli/config).

## Hosted project verified on 4 November 2026

Project `goohgkzuggxxqpcnikjn` is a new free project in Paris. `app/demo-config.json` contains its public URL and publishable client key. These values identify the backend; they do not bypass access policies. No privileged key is in the app.

The local suite includes concurrency at the final signup slot and cleanup that preserves active demo sessions. The separate `python3 supabase/tests/hosted-smoke.py --run` check uses two real anonymous Auth sessions and the public REST API. It deliberately creates only synthetic demo records, refuses any other project URL, keeps tokens in memory, and lets its records expire normally.

Cron setup for this dedicated project:

```sql
create extension if not exists pg_cron;
select cron.schedule('fixcity-expired-demos', '17 * * * *',
  $$select public.prune_demo_accounts();
    delete from cron.job_run_details where jobid in
      (select jobid from cron.job where jobname='fixcity-expired-demos')
      and end_time < now()-interval '7 days';$$);
```

Supabase documents [SQL cleanup for anonymous users](https://supabase.com/docs/guides/auth/auth-anonymous) and [Cron scheduling](https://supabase.com/docs/guides/cron/quickstart). The extra active-workspace condition prevents deleting a visitor who renewed their demo. Check Cron history after enabling it. Free projects may pause after inactivity; no always-on availability is promised.

On 5 November, migration `202611050001_retain_report_media.sql` was also applied to the hosted demo. The SQL editor confirmed that the client deletion policy was absent. This migration changes permissions only; it does not delete stored data.

Migration `202611050002_staff_handoff.sql` was applied on the same day. It adds the assigned state, role-specific transitions and history photos. Existing in-progress/resolved reports remain valid; existing final repair photos are also attached to their resolved history entries. The hosted Auth/REST check and live browser workflow passed after migration. See [release verification](docs/RELEASE-VERIFICATION.md).
