# Staff handoff implementation plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan in the current session.

**Goal:** Separate review from repair and allow a photo on the first update.

**Architecture:** Add an assigned state and per-update photo to the existing transactional workflow. Keep one report-detail component with role-specific actions; enforce normal roles on the server.

**Tech Stack:** Flutter, Dart, Supabase/PostgreSQL.

**Spec:** ../specs/2026-11-05-staff-handoff.md

## Global constraints

No new dependencies, data reset, public uploads, production persona switching, or changes to team attribution. Preserve Arabic/English and private media.

## Review focus

First-update photos survive reload and retries. Staff cannot close reports, and districts cannot skip review or cross district boundaries. Progress notes do not accidentally resolve reports. Resolution still needs evidence. Citizen access to update photos follows report access.

## Tasks

- [x] Write failing widget and SQL regressions for first-update evidence, role actions, progress notes, private media and retry handling.
- [x] Add a migration with `assigned`, `status_updates.photo_url`, permitted transitions and actor labels. Preserve the RPC signature and locking/idempotency. Extend authorized media reads to history attachments.
- [x] Update the shared detail screen, district wrapper, status labels/filtering, tracking history and workflow tests. Explain handoff and recording steps in the docs.
- [x] Run demo/normal Flutter suites, SQL suites and analysis; review the diff and publish the tested migration and updated demo/APKs. Verify the live workflow and record the Android checks that actually ran.

## Progress

Initial source is 43a8edc. Root cause: the UI and database forbid photos except at resolution; both roles share transitions, differing only in report scope.

54 demo tests and 41 normal-mode tests passed on 5 November (3 demo-only skips). Analysis had 97 informational findings, no errors or warnings. SQL workflow, concurrency, isolation, update-media access and cap/resolution boundary checks passed. Independent read-only review found no remaining blocking issues. The tested migration is applied to the isolated hosted demo; signed 1.1.1 APKs are published and the live browser workflow passed.

The real hosted Auth/REST smoke test passed all four stages, update-photo history, separate visitor isolation and privilege-denial checks. Signed version 1.1.1+3 is installed over the emulator app with data retained. Publishable-source secret scanning flagged only the existing Supabase publishable key; private signing files remain Git-ignored. No new dependency was added.

GitHub Actions run 42083578860 passed and the live site reports 1.1.1/build 3. Mohamed's 6 November recording shows the Android report, handoff and repair sequence. The updated automated Android integration script was not rerun; physical-device and normal-account camera/GPS/upload tests remain unverified. See [release verification](../../RELEASE-VERIFICATION.md).
