# FixCity app review and repair evidence

Review started 4 November 2026 on branch `codex/fixcity-demo`, from portfolio snapshot `5bcbc4f`. The app code and any new repairs must be distinguished from the original team's contribution. Findings below are open until a test or runtime check verifies the fix.

| Finding | Source evidence | User effect | Verification planned | Status |
|---|---|---|---|---|
| Report side effects happen before persistence | report_page.dart awards points/inserts notification before inserting reports | Failed submission can appear successful in notifications and rewards | Failed-write and retry transaction tests | Fixed; SQL/widget regressions pass |
| Status and history use separate writes | admin/report_details_page.dart and governor/governor_report_page.dart | Partial failure leaves status and timeline inconsistent | SQL failure/rollback and retry tests | Fixed; SQL/widget regressions pass |
| Offscreen notifications are marked read | MainScaffold creates all IndexedStack children; NotificationsPage writes is_read in initState fetch | Messages are consumed before the user opens alerts | Widget test: home mount, then alerts activation | Fixed; regression passes |
| Signup profile write requires a session too early | signup_page.dart upserts profiles whenever res.user is nonnull | Email-confirmation signup can create the account but display a profile permission failure | Signup without session; assert confirmation success and auth metadata | Fixed; regression passes |
| Password input is trimmed | citizen/admin/district login and signup | A password containing intended leading/trailing spaces is changed before authentication | Exact auth request payload tests | Fixed; regression passes |
| Admin login has asynchronous setState paths without a mounted guard | admin/admin_login_page.dart after sign-out/auth failure | Leaving the page while a request completes can throw | Delayed response after disposal widget test | Fixed; regression passes |
| Tracking requests can overwrite each other | track_page.dart mutates shared state after each request, without an operation generation | Older request can replace the latest search result | Controlled out-of-order responses | Fixed; regression passes |
| Tracking conflates database/permission failure with absence | track_page.dart catches every PostgrestException as not_found | Backend problems appear as an invalid tracking code | Distinct absent/transport/permission fixtures | Fixed; regression passes |
| Async image/position paths need lifecycle review | report_page.dart and governor/governor_report_page.dart | Navigating away during permission/upload may use a disposed state/context | Pending-operation disposal tests | Fixed lifecycle guards; OS permission checks pending |
| Report success uses the popped route's context | report_page.dart pops then opens its success dialog | Fragile navigation; result may disappear or use stale context | Submit flow/navigation widget test | Fixed; SQL/widget regressions pass |

Backend access policies, role assignment, private media and idempotency are release requirements in the approved design. The original repository does not contain the backend definitions needed to verify them. Client role checks alone do not establish database access control.

No findings are labelled fixed merely because a patch exists. Test commands, observed results and commits will be added as work proceeds. Scope is the active Flutter app and the separate synthetic backend, not historical website/archive folders or the old team backend.

## Verification — 4 November 2026, first repair set

- Official Flutter 3.35.7 / Dart 3.9.2; existing package lockfile preserved.
- Baseline web build succeeded with synthetic configuration, before changes. This does not verify a live backend.
- Ten widget regressions pass: exact password payloads across three login screens, confirmation signup metadata/no premature profile write, disposed admin-login response, alert activation/batch marking, alert fetch failure, tracking response ordering, backend error and genuine absence. Relevant tests failed before the fixes.
- `flutter analyze --no-fatal-infos`: zero errors/warnings; 30 informational diagnostics remain, including async-context paths being reviewed in the next repair set.
- Signup now supplies profile metadata to Auth. Persisting it depends on the new database trigger in the next task.
- Also repaired narrow login/signup footer overflow and disposed the home Auth stream subscription when leaving the tab.

These tests mock the HTTP boundary; database authorization and cross-user isolation require the separate SQL/integration checks.

## Workflow repair verification

- 59 disposable PostgreSQL checks pass, including two concurrent requests with one retry ID: one report and one points award persisted. Fifty-eight assertions cover owner/staff/district/demo boundaries, escalation denial, transaction rollback, retry conflicts, invalid coordinates/text, repair evidence, expired workspaces and reset isolation.
- 23 Flutter tests pass with `flutter test --no-pub --dart-define=DEMO_MODE=true`. New checks exercise failed/retried citizen submissions, success-dialog route lifetime, leaving while saving, atomic staff updates, required repair evidence, duplicate taps, profile update permissions, disposed profile saves, district-profile errors and private PNG upload/size rejection.
- Browser release compilation succeeds with synthetic configuration. This still does not establish a live backend connection.
- Staff and district details now share the same page. The backend enforces district permissions; the frontend offers only the next valid status.
- Removed the manual notification/points button and the reminder button that claimed delivery without a delivery service. Status changes create the actual in-app notification transactionally. SMS is explicitly unavailable.
- Images use a private storage reference; the client obtains a one-minute signed URL. JPEG/PNG types and a 5 MiB limit are checked before upload. Synthetic media are labelled illustrations. Referenced evidence cannot be deleted even after a role revocation (SQL regression).
- Profile edits use permitted column updates rather than insert/upsert. Late replies after leaving are ignored. District-profile errors display a retry action instead of an endless spinner.
- Image-picker and geolocation paths gained mounted guards; location is now requested explicitly. OS camera/location permissions and real-device behaviour still need platform checks.

These fixes target the new isolated schema. Pointing this version at the old team backend is unsupported; no old data or service was modified.

## Interactive demo verification

- The separate hosted Supabase project completed 19 REST/Auth checks: two isolated visitors, bootstrap/reload reuse, simultaneous duplicate submissions, cross-visitor reads and writes denied, full resolution/history/notification persistence, and role-escalation rejection. Only a public client key was used; access tokens stayed in memory.
- Chrome completed citizen submission → staff review → district repair → citizen report, tracking timeline and alerts. Three persisted history entries and labelled before/after illustrations were visible. A reload retained the visitor's workspace.
- 37 Flutter tests pass in demo mode. Added bootstrap/reload, failed setup/reset, explicit expired-session recovery, persona routing, immediate Arabic/English switching with an unfinished draft, failed dashboard retry, narrow Arabic layouts with larger text, and report-to-tracking navigation tests.
- Fixed duplicate demo initialization caused by an initial `/demo` route on top of `/`; banners now wrap routes so screen readers can reach their controls.
- Dashboard request failures now show retry states instead of empty/zero results. Flexible home and filter layouts repair narrow-screen Arabic overflow.
- The old map provider returned “API KEY REQUIRED.” Maps now use standard OpenStreetMap tiles, visible linked attribution and flutter_map's normal HTTP caching; no bulk/offline download feature is included.
- “Track this report” previously lost the selected code. It now passes the full code and loads that report; report cards wrap long codes on small screens. Stale ten-character hints were removed.
- Analyzer: no errors or warnings; informational style/deprecation findings remain. Normal email-auth/private-upload integration and Android hardware are not yet verified against the hosted backend.

## Release preparation

The database suite now passes 67 checks, including simultaneous signups at the final daily slot, total identity bounds and cleanup that retains active workspaces. The hosted daily-cap test failed before the new migration and passed afterwards; both runs rolled back test identities. Real Auth/REST workflow checks still pass after email signup was disabled.

Normal app mode passes 27 tests (two demo-only suites are skipped). Its narrow-screen regression also exposed the original language-selector row overflowing by 51 pixels; flexible text width repairs it. The signed Android release compiles successfully; device and published-host checks are recorded separately from compilation.

## Final review repairs

An independent whole-branch review found an uncertain-save retry defect: switching interface language changed the generated report title and therefore its retry identity. The new regression first produced two request IDs, then passed with a stable persisted title and one report. A second regression reproduced a 522-pixel overflow for long desktop tracking descriptions; flexible width now keeps the text inside the demo layout.

The final suites pass 39 demo tests and 28 normal-mode tests (two demo-only suites skipped in normal mode). Analyzer reports no errors or warnings; informational style/deprecation diagnostics remain. The development-only Flutter integration-test dependency adds no changes to existing package versions.

The final web build renders OpenStreetMap tiles in Chrome. Reset confirmation restored exactly two starter reports for that browser session. Hosted cleanup history records a successful scheduled run at 18:17 UTC on 4 November 2026. Browser viewport emulation did not change the actual viewport, so narrow-browser testing is not claimed; narrow Arabic layouts are covered by widget regressions and Android checks recorded below.

Android API 35 arm64 emulator: the opt-in integration test passed the full live-backend cycle in 37 seconds after compilation. It entered a fictional report through the UI, submitted staff and district updates, and checked the saved resolved status, three history entries and three notifications. It then displayed the persisted repair note on the citizen tracking page and switched to Arabic without a Flutter exception. This tests a debug integration build on an emulator; it is distinct from signed-release compilation and physical-device testing.

Publication verified: GitHub Actions run [41893078618](https://github.com/mosalah-77/FixCity/actions/runs/41893078618) passed app checks, database checks and Pages deployment for source `c227667`. The published site created a workspace, saved staff and district transitions, and retained the resolved status, both illustrations and three history entries after a deep-link reload. The public APK from release `v1.0.0-demo.1` was downloaded again and matched the uploaded checksum. See [release verification](RELEASE-VERIFICATION.md) for limits and the decision record.
