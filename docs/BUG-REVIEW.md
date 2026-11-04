# FixCity app review and repair evidence

Review started 4 November 2026 on branch `codex/fixcity-demo`, from portfolio snapshot `5bcbc4f`. The app code and any new repairs must be distinguished from the original team's contribution. Findings below are open until a test or runtime check verifies the fix.

| Finding | Source evidence | User effect | Verification planned | Status |
|---|---|---|---|---|
| Report side effects happen before persistence | report_page.dart awards points/inserts notification before inserting reports | Failed submission can appear successful in notifications and rewards | Failed-write and retry transaction tests | Open |
| Status and history use separate writes | admin/report_details_page.dart and governor/governor_report_page.dart | Partial failure leaves status and timeline inconsistent | SQL failure/rollback and retry tests | Open |
| Offscreen notifications are marked read | MainScaffold creates all IndexedStack children; NotificationsPage writes is_read in initState fetch | Messages are consumed before the user opens alerts | Widget test: home mount, then alerts activation | Fixed; regression passes |
| Signup profile write requires a session too early | signup_page.dart upserts profiles whenever res.user is nonnull | Email-confirmation signup can create the account but display a profile permission failure | Signup without session; assert confirmation success and auth metadata | Fixed; regression passes |
| Password input is trimmed | citizen/admin/district login and signup | A password containing intended leading/trailing spaces is changed before authentication | Exact auth request payload tests | Fixed; regression passes |
| Admin login has asynchronous setState paths without a mounted guard | admin/admin_login_page.dart after sign-out/auth failure | Leaving the page while a request completes can throw | Delayed response after disposal widget test | Fixed; regression passes |
| Tracking requests can overwrite each other | track_page.dart mutates shared state after each request, without an operation generation | Older request can replace the latest search result | Controlled out-of-order responses | Fixed; regression passes |
| Tracking conflates database/permission failure with absence | track_page.dart catches every PostgrestException as not_found | Backend problems appear as an invalid tracking code | Distinct absent/transport/permission fixtures | Fixed; regression passes |
| Async image/position paths need lifecycle review | report_page.dart and governor/governor_report_page.dart | Navigating away during permission/upload may use a disposed state/context | Pending-operation disposal tests | Review pending |
| Report success uses the popped route's context | report_page.dart pops then opens its success dialog | Fragile navigation; result may disappear or use stale context | Submit flow/navigation widget test | Open |

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
