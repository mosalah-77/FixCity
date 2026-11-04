# FixCity Android and browser demo implementation plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task by task. Mohamed approved implementation and an app bug review on 4 November 2026. Native execution keeps the closely related Flutter/backend work in one context; obtain a fresh branch review before release.

**Goal:** Release a reproducible, attributed FixCity demo that completes the reporting workflow on Android and in a browser.

**Architecture:** Retain the existing Flutter screens. Add a reproducible Supabase backend with database-enforced roles and isolated visitor workspaces. Route writes that require consistency through database functions, then expose a clearly labelled synthetic demo in the same app.

**Tech stack:** Flutter/Dart, existing Supabase client, PostgreSQL, GitHub Actions/Pages/Releases. Pin a compatible Flutter 3.35 patch after verifying its official archive and existing lockfile.

**Spec:** ../specs/2026-11-04-fixcity-demo-design.md

## Global constraints

- Keep the existing Flutter/Dart code and Supabase architecture; no framework rewrite.
- Arabic/English and right-to-left behaviour remain in the core flow.
- No real citizen data, live Gemini, new paid service or secret in the client/repository.
- Preserve original README/ATTRIBUTION.md credits; log new work separately.
- Public demo uses isolated synthetic workspaces and sample media; real uploads are disabled there.
- Report creation and transitions must be atomic and retries idempotent.
- An actual backend/device check must be distinguished from mocked tests and successful compilation.

## Review focus

- Slow responses after leaving a page must not update a disposed widget or show stale search results (Tasks 1, 3).
- Repeated taps or interrupted network responses must not duplicate reports, points or history (Tasks 2, 3).
- Edited IDs, tracking codes and profile fields must not cross visitor or role boundaries (Tasks 2, 4).
- Email-confirmation signup must succeed without an authenticated profile-write request (Tasks 1, 2).
- Reloads, narrow screens, denied geolocation and unavailable media/backend must have usable recovery (Tasks 3, 4, 5).

## File map

- Existing app/lib/: preserve screen structure; repair lifecycle, auth, tracking and notification handling where reproduced.
- app/lib/report_actions.dart: the two atomic report RPC calls, shared by citizen/admin/district screens.
- app/lib/demo.dart: compile-time demo flag, current demo persona and workspace bootstrap/reset calls.
- app/lib/demo_page.dart: labelled entry/persona controls; routes into existing screens.
- app/assets/demo/: self-created synthetic report/repair images, no uploaded personal media.
- supabase/migrations/: schema, auth profile trigger, RLS, storage access rules and transactional functions.
- supabase/tests/: executable SQL assertions for role/isolation/consistency failures; test-only identities.
- app/test/: focused regression/widget/RPC tests using the existing flutter_test and http test utilities.
- .github/workflows/: pinned checks/builds and separately permissioned web deployment.
- docs/: reproducible setup, bug evidence, demo walkthrough and remaining limits.

### Task 1: Reproducible baseline and app regressions

**Files:** app/pubspec.lock, app/lib/login_page.dart, signup_page.dart, admin/admin_login_page.dart, governor/governor_login_page.dart, main_scaffold.dart, notifications_page.dart, track_page.dart; app/test/auth_test.dart, notifications_test.dart, tracking_test.dart; docs/BUG-REVIEW.md.

**Interfaces:** Existing page constructors/routes remain. If tests require injection, accept an optional SupabaseClient parameter and default to the existing client; do not create a general state framework.

- [x] Install an officially verified compatible Flutter SDK in a task-local tooling directory; run pub get with the existing lockfile, flutter analyze and a baseline web build. Record exact failures before editing.
- [x] Add failing tests that password whitespace is preserved, confirmation-required signup sends profile metadata without a session-dependent upsert, and leaving an async login does not throw.
- [x] Fix the auth paths and profile-trigger contract using the existing client API.
- [x] Add a failing test that mounting the home tab does not mark notifications read; visit notifications and assert only successfully displayed IDs are marked read. Repair page activation and badge refresh.
- [x] Add a failing tracking test: a slow earlier request cannot overwrite a later code; a transport failure is distinguishable from a genuinely absent report.
- [x] Run the focused tests and analyzer, record passing results and commit this repair set.

### Task 2: Database rules and atomic writes

**Files:** supabase/migrations/202611040001_fixcity.sql; supabase/tests/workflow.sql; supabase/config.toml; BACKEND-SETUP.md.

**Interfaces:** Preserve fields consumed by existing reports/profiles/status_updates/notifications screens. Add workspace ownership and per-user request IDs. SQL functions: create_report(p_request_id uuid, p_report jsonb) returns jsonb; transition_report(p_request_id uuid, p_report_id uuid, p_status text, p_note text, p_fix_photo_url text default null) returns void; start_demo() returns uuid; reset_demo() returns uuid. Only these functions may write workflow status/points/history. Profile updates may change name/phone/preferences, never roles or points.

- [x] Write SQL assertions covering owner/staff/district access, role escalation denial, cross-workspace report/history/notification/media denial, atomic failure, retries and required repair evidence. Confirm they fail against the absent schema.
- [x] Create versioned schema and auth-profile trigger. Keep role assignment privileged. Normal citizens own their reports; staff may operate across districts; district accounts are restricted to their district. Anonymous identities access only their own demo workspace.
- [x] Implement the transactional RPCs with validation and retry keys. Enforce pending -> in_progress -> resolved, with nonblank note and repair evidence for resolution. Reject conflicting reuse of a request ID.
- [x] Implement bounded start/reset: one workspace per identity, max 20 reports per workspace, 7-day retention, only owned records reset. Add cleanup instructions and provision-time rate/CAPTCHA checks. No public shared admin credential.
- [x] Run the SQL assertions on a disposable local database/stack; do not access the old team backend. Record which environment was used and commit migrations/tests.

### Task 3: Connect existing report screens to reliable operations

**Files:** app/lib/report_actions.dart, report_page.dart, admin/report_details_page.dart, governor/governor_report_page.dart, models/problem.dart, my_reports_page.dart; app/test/report_actions_test.dart and report_flow_test.dart.

**Interfaces:** ReportActions(SupabaseClient client); Future<Map<String,dynamic>> createReport({required String requestId, required Map<String,dynamic> report}); Future<void> transitionReport({required String requestId, required String reportId, required String status, required String note, String? fixPhotoUrl}). Request IDs remain stable across retries of the same operation.

- [x] Write failing RPC/widget tests for failed report saves, duplicate taps, delayed responses, failed transitions and resolving without evidence. Assert no optimistic success side effects.
- [x] Replace separate client writes with the Task 2 functions. Display success only from the persisted result. Remove manual notification/points award controls that bypass the transaction.
- [x] Keep entered form values after failure. Handle media separately; use sample assets in demo, and validate/clean up any retained non-demo upload path. Prevent old page contexts from showing success after navigation.
- [x] Ensure details/history refresh after updates and invalid/absent records have readable error states. Keep unavailable SMS/phone/reward actions hidden or explicitly unavailable in demo.
- [x] Run the focused tests, analyze and build web. Update the bug log with evidence; commit.

### Task 4: Isolated public demo through the existing app

**Files:** app/lib/demo.dart, demo_page.dart, main.dart, splash_page.dart, main_scaffold.dart, report_page.dart, admin/admin_dashboard_page.dart, governor/governor_dashboard_page.dart; app/assets/demo/; app/pubspec.yaml; app/test/demo_test.dart.

**Interfaces:** const bool demoMode = bool.fromEnvironment('DEMO_MODE'); enum DemoPersona { citizen, staff, district }; demo persona is UI-only and never authorizes ordinary rows. Future<String> ensureDemoWorkspace(SupabaseClient client); Future<String> resetDemoWorkspace(SupabaseClient client). Task 2 owns all authorization.

- [x] Test demo bootstrap/reload, reset failure, expired identity, sample-media selection and persona routing. Assert a forged persona cannot grant access to ordinary rows through the SQL tests.
- [x] Add an explicit synthetic/no-government-affiliation entry and visible persona controls. Anonymous sign-in then start_demo creates/reuses an owned workspace. Explain session loss and reset behaviour.
- [x] Seed fictional district/report examples; remove real official contacts from the demo. Select report and repair samples from app assets. Do not request location permission automatically on opening the demo.
- [x] Preserve map attribution, deny unsupported actions clearly, handle unavailable backend and verify mobile/RTL layouts. Pin demo session to its own data and preserve state across reload.
- [x] Run widget/SQL tests and a local interactive web smoke check through the whole cycle; commit.

### Task 5: Build, deployment and release evidence

**Files:** .github/workflows/checks.yml, .github/workflows/pages.yml, app/android/app/build.gradle.kts, app/web/index.html, README.md, ATTRIBUTION.md, BACKEND-SETUP.md, docs/DEMO.md, docs/BUG-REVIEW.md.

- [x] Add formatting/analyzer/tests/web and Android build checks with pinned tooling/actions. Fix application identity to dev.mosalah.fixcity and document private release signing; never commit keys.
- [x] Run local checks and release builds using a separate synthetic Supabase project. If account access/terms are needed, prepare the exact account step for Mohamed while completing independent checks.
- [x] Verify the two-visitor security scenario, browser reload, Arabic/English, mobile viewport, full workflow and backend failure against the separate project. Save results without credentials or personal data.
- [x] Publish the tested web build with /FixCity/ base path and APK release asset only after a fresh branch review. Verify the actual published URL and downloadable artifact. Use no paid service without a new decision.
- [x] Check Android on an emulator and request a real-device smoke check if hardware is unavailable. Record any unverified platform explicitly.
- [x] Complete setup/architecture/known-limits and a short walkthrough. Preserve original attribution; distinguish new AI-assisted work and Mohamed's explainability checkpoints. Commit and report exact tests, releases and remaining user actions.
