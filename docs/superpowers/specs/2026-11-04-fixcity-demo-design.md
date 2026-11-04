# FixCity: working Android and browser demonstration

Date: 4 November 2026
Status: approved by Mohamed on 4 November 2026. Android APK plus browser delivery selected. Mohamed additionally authorised finding and fixing bugs in the main Flutter app. Implementation and verification follow; approval does not claim that deployment already works.

## Purpose

Make the existing six-person graduation project easy to try and technically explainable. A reviewer should be able to report a fictional infrastructure problem, see it enter a staff queue, move it through a district workflow, and see the resolution from the citizen view. Persist the work in a real, separate demo backend so it survives reloads. Demonstrate software workflow and engineering decisions; do not claim municipal adoption, actual repairs or production readiness.

The new work is an attributable follow-on to the team project. Preserve the existing README credits, ATTRIBUTION.md, source revision and AI-use disclosure. Document Mohamed's new decisions and changes as they happen, without retroactively assigning him earlier features.

## Delivery choice and alternatives

1. Android APK only: closest to the original target, but reviewers must install it or watch a recording.
2. Android APK plus a browser demo from the same Flutter project: gives reviewers a direct URL and retains Android evidence. Needs browser compatibility, responsive layout and a hosted backend.

Mohamed chose option 2 on 4 November 2026. Preserve Flutter/Dart and Supabase. A rewrite into another framework is outside the first milestone.

GitHub hosts source, release notes and the downloadable APK. GitHub Pages can host the compiled web frontend. Supabase hosts database, authentication and storage separately. Hosting source alone does not deploy the backend or make the Android app runnable in a browser.

## What exists and what was checked

Local base: commit 5bcbc4f, the sanitized portfolio snapshot. Origin: https://github.com/mosalah-77/FixCity.

- Flutter Android and web scaffolding exist; no dart:io or Image.file use was found in the active Dart files checked. Web operation is still untested.
- Dependencies include Supabase, flutter_map, geolocator and image_picker. The declared Dart minimum is 3.9.
- Reports, tracking, profiles, notification and staff/district screens exist.
- The repository has no reproducible Supabase schema, access policies, storage policies or increment_points function definition.
- Flutter, Dart and adb were not found in PATH; Android SDK/Android Studio were not found in the standard locations checked. A Java launcher exists, but a usable JDK was not verified.
- No build, analyzer, emulator, browser interaction or live-backend test has been run for this review.

Concrete source concerns:

- app/lib/report_page.dart creates points and a success notification before the report insert. A failed report write can leave misleading side effects.
- Staff report status and status-history writes are separate requests. Partial failure can make them disagree.
- The client requests public image URLs and queries tracking codes directly. Backend policy and public-field decisions must precede public access.
- Profile booleans affect staff access. These must be server-controlled; hiding a route is insufficient.
- District data contains named officials and placeholder telephone numbers. Use explicitly fictional demo personnel and disable contact actions for the demo.
- Android uses a template application ID and debug signing configuration for release. A release identity and private signing key are required for a repeatable distributable build.
- The upstream exposed Gemini key was removed from this copy. Its revocation is the upstream owner's responsibility; never reuse or test it.

## First release: one complete reporting cycle

1. Open the demo and see a clear synthetic-data notice. No claim of government affiliation.
2. Start an isolated demo workspace containing citizen, staff and district personas with seeded sample data.
3. As the citizen, select a sample image, enter a description, choose a category and map location, and submit a report.
4. Receive a stable tracking code only after successful persistence. Reload and find the report again.
5. As staff, review the report and its district. As the matching district persona, change pending to in_progress, then resolved with a sample repair photo and a note.
6. Return to the citizen view and see the same status, history and in-app update.
7. Reset only this visitor's demo workspace and replay the scenario.

The existing district field supplies routing; first release does not add a dispatch optimiser or employee-assignment product. Retain Arabic/English and right-to-left behaviour in the core flow. Keep secondary screens only if they work accurately; hide or label unavailable capabilities rather than leaving misleading controls.

## Demo data and access model

Proposed implementation defaults, subject to review:

- Use a new Supabase development project with synthetic records and licensed or self-created sample images. No team backend, citizen export, real officials' contact information or Halvern material.
- For the public demo, create a short-lived anonymous visitor identity and a workspace scoped to that identity. Store a workspace/owner reference on demo records. Enforce isolation in the database and storage policies.
- Persona switching is explicitly a demonstration feature inside that visitor's workspace. It never grants access to other visitors' work, user management, role administration, service credentials or the Supabase console.
- Normal citizen/staff/district authorization remains a distinct server-enforced path, exercised with isolated test identities. A client-supplied persona label must never authorize access to ordinary non-demo records.
- Builder decision for normal roles: citizens read and track their own reports; staff administrators may review and change status across districts; district accounts may read and change status only in their assigned district. Both staff roles follow the same permitted transitions and repair-evidence rules. Role flags and district assignments cannot be edited through the citizen profile path. Demo personas have these workflow capabilities only within their visitor's synthetic workspace.
- Scope demo mutation procedures to authenticated anonymous identity plus owned demo workspace, with server-side workflow checks. Test that changed IDs and guessed tracking codes cannot reach another workspace. No shared public admin login.
- Use bounded retention and limits for new workspaces, reports and media. Choose exact safe limits during implementation and document them. Default scope is sample media selection; arbitrary public uploads are deferred until type/size checks and rate limits are verified.
- Store private media paths or expiring access URLs where appropriate. Do not make a real-user upload bucket public to get the demo working.
- Distinguish publishable client configuration from secrets. Service-role keys, database credentials, signing keys and any future AI key stay outside Git and outside the client build.

If the selected Supabase account cannot support safe anonymous demo provisioning without additional services or charges, stop before publishing and present the concrete constraint. Do not replace it silently with unrestricted public writes or shared admin credentials.

## Data consistency and failure handling

- Add versioned schema migrations, access policies and a repeatable synthetic seed/reset process to the repository.
- Make report creation, initial history, notification and any retained points award one consistent database operation. A retry must not duplicate reports or rewards. Media upload has separate compensation/cleanup on failure; do not describe object storage and SQL as one atomic transaction.
- Update status, history and in-app notifications in a database transaction. Reject invalid transitions and duplicate retry effects.
- Enforce required fields, permitted categories/districts and repair-photo requirements on the backend as well as in the UI.
- Show actionable error states for failed saves, expired demo sessions, unavailable backend and denied location permission. Keep entered data available for a safe retry.
- Keep optional category suggestions as the existing clearly labelled local fallback. Restoring paid/live Gemini is outside this release.

## Delivery and quality checks

- Start with a pinned compatible Flutter version and the existing lockfile. Diagnose before broad dependency upgrades.
- Build and smoke-test the web target; address map/image/permission and mobile-layout differences.
- Build a release Android APK with a stable application ID and a private signing key. Check it on an emulator and, before describing device support as verified, a real Android device.
- Add continuous checks for formatting, analysis, relevant tests and both builds. Pin third-party actions to reviewed revisions. Deployment permissions should be limited to the publish job.
- GitHub Pages uses the correct /FixCity/ base path and a routing configuration that survives direct navigation/reloads.
- Preserve provider attribution on maps and observe the chosen tile provider's usage terms. Never claim a map tile service is an owned backend.
- Keep a small recorded walkthrough as a fallback when hosting is unavailable. The README must distinguish an interactive demo from the recording.
- Check availability before including the link in applications. Supabase's free tier currently pauses inactive projects after a week; a permanently awake backend must not be promised or obtained through unapproved spending.

## Acceptance tests

Required before calling the demo ready:

1. A clean checkout can reproduce the schema and seed instructions; setup contains no secrets.
2. A visitor completes report -> staff review -> district resolution -> citizen tracking on web; saved state survives reload.
3. The same core cycle works in the Android build.
4. Visitor A cannot read, modify, reset or fetch private media from visitor B, even by editing IDs or calling the API directly.
5. A normal citizen cannot grant staff privileges or update staff-only fields; staff/district test users have only their intended scope.
6. Retry after a simulated interrupted save does not duplicate the report, points or history.
7. A failed save produces no success notification or points award. A failed status update does not leave inconsistent history.
8. Missing required fields, denied location access, expired session and invalid tracking code have readable recoverable states.
9. Resolution requires the defined repair evidence. Arabic/English layouts and core keyboard navigation remain usable.
10. Public README, demo banner, release notes and recording match the implemented features and preserve attribution.

## What is deliberately outside the first release

Government integration or real incident intake; app-store submission; SMS/WhatsApp/calls; payments; new AI agents or live Gemini; nationwide rollout; new gamification; a framework rewrite; claims of production security or real-world impact. Existing rewards may be retained only with tested consistency, otherwise deferred visibly.

## Evidence for interviews

For each meaningful repair, record: original symptom, reproduction, decision, changed files, relevant test/result, what Mohamed can explain or change himself, and any remaining limitation. Use real measurements from these checks, not invented business outcomes. Separate team-origin work, Codex-assisted new implementation and Mohamed's own contribution.

The release should provide: a working browser link, downloadable APK, source, setup instructions, concise architecture/data-flow notes, tested scenario list, attribution, known limits and a short demonstration script. It counts as project experience, not invented employment or customer delivery.

## Decisions still needing the user or account access

- First-release scope approved, including synthetic isolated demo workspaces and sample media.
- Later: sign in to/choose the Supabase account and approve any new terms or security-sensitive access. Do not paste keys into chat.
- Later: confirm an Android device is available for the final hardware check; an emulator can support initial development.
- Any paid service or billing change requires a separate, specific decision. The proposal assumes no new spending.

## References checked 4 November 2026

- https://docs.flutter.dev/deployment/android
- https://docs.flutter.dev/platform-integration/web/building
- https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages
- https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases
- https://supabase.com/docs/guides/database/postgres/row-level-security
- https://supabase.com/docs/guides/storage/security/access-control
- https://supabase.com/pricing
