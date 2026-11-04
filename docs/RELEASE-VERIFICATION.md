# FixCity release verification

Verified 4 November 2026; handoff completed 5 November (Cairo).

[Browser demo](https://mosalah-77.github.io/FixCity/) · [Signed Android APK release](https://github.com/mosalah-77/FixCity/releases/tag/v1.0.0-demo.1) · [Captured-screen summary](evidence/2026-11-04/visual-walkthrough.mp4)

Published application source: `c2276672e28a0b2140b5f819c850c1f4c3822d93`. Later documentation commits do not change that binary. The original six-person project and Ahmed Wael Ali / DoctorJhin remain credited in the README, app and release.

| Check | Observed result |
|---|---|
| Demo widget regressions | 39 passed |
| Normal-app regressions | 28 passed; two demo-only suites skipped |
| Disposable PostgreSQL checks | 67 passed, including concurrent retry and signup-cap cases |
| Real hosted Auth/REST checks | 19 passed using isolated anonymous visitors |
| Android API 35 arm64 emulator | Complete report, review, repair, tracking and Arabic switch passed |
| Final analyzer | Zero errors/warnings; 88 informational style/deprecation findings |
| Web and signed release APK | Both built successfully with pinned Flutter 3.35.7 |
| Independent whole-branch review | Retry defect and desktop clipping reproduced, fixed and covered by regressions; no deferred minors |
| GitHub Actions | App checks, database checks and Pages deployment passed in run 41893078618 |
| Published website | Workspace started; staff review and district repair saved; resolved report and three history entries survived deep-link reload |
| APK distribution | Public download matched the local signed APK: 54,128,117 bytes |
| Hosted cleanup | Scheduled job succeeded; hourly schedule active |

APK SHA-256: `cc968384425b54e2a8dc7505cda6308ebb810e57c875e13381c5366dcd63d545`. This checksum is public verification data, not a signing key. The release uses a private RSA-3072 signing key, verified with APK signature scheme v2; the key is not in Git. Preserve the private signing backup for future updates.

[GitHub check run](https://github.com/mosalah-77/FixCity/actions/runs/41893078618) · [Download evidence](evidence/2026-11-04/android-release.json)

## What remains unverified

A physical Android phone was unavailable. Install the APK and run the [two-minute flow](DEMO.md); check launch, back navigation, Arabic layout and reopening the app. The emulator test used a debug integration build; release signing and compilation were checked separately.

The public demo uses synthetic illustrations. Normal-account hosted email signup, camera/GPS permissions and real private-media uploads were not exercised against the hosted project. SQL and mocked tests cover their access/request rules. The browser viewport override did not change the real width, so narrow-browser validation is not claimed; narrow Arabic widget tests and the Android emulator provide that coverage.

This is a portfolio prototype, with no municipal connection or production security/uptime claim. The free backend can pause or hit its account limits. Storage is bounded, but request/egress abuse is still possible without CAPTCHA. No paid service was added.

The visual summary is a 26-second sequence of actual captured screens, not a continuous interaction recording. It is an offline fallback; functional evidence comes from the running app and tests. A narrated walkthrough after Mohamed practises the flow would be useful additional interview material.

## Decisions and tradeoffs

The following is the complete chronological decision record from implementation and review. Historical statements about main being untouched describe that stage; the later publication decision supersedes them.

1. Ruling: Implement natively in the clean dedicated codex/fixcity-demo branch — user authorised work on this branch and avoiding another worktree/approval conserves time; main and remote remain untouched — changes share this checkout, so do not allow concurrent editors.
2. Task 1: Ruling: notification read means the successfully loaded batch (max 50), not viewport intersection — existing UI has no per-row visibility tracking, and unseen later records must retain the unread badge — loaded but unscrolled rows are considered read.
3. Task 2/3 Ruling: continue Flutter integration against the tested RPC contract while the local engine is unavailable — backend interfaces are stable, so independent app work need not wait — Task 2 stays incomplete until concurrency/reproducibility check finishes.
4. Task 3: Ruling: district report details reuse the existing staff details page — both need the same validated next-status workflow and server authorization already distinguishes roles — district-specific visual differences are removed, while its dashboard and access scope remain.
5. Task 3/4: Ruling: add synthetic media selection and the demo compile flag during citizen-flow integration so save/retry tests can exercise the complete form without OS camera plugins — no new framework/dependency — demo entry/session tests still belong to Task 4.
6. Task 3/4: Ruling: synthetic media are labelled built-in illustrations rendered by Flutter instead of new bitmap assets — zero external media dependencies and no claim of real photographic evidence — visual fidelity is intentionally modest.
7. Task 4: Ruling: wrap each demo route with its banner instead of MaterialApp.builder — the outer banner was absent from Flutter web accessibility semantics — new demo routes must use the same wrapper.
8. Task 4: Ruling: use built-in OpenStreetMap tiles with attribution and existing library caching after CARTO returned API-key errors — removes a broken dependency without a new package/account — public tiles have no uptime guarantee.
9. Task 4: Ruling: replace the fixed-height home header with intrinsic content and category extents that allow larger Arabic text — reproduced narrow-screen overflows — the original collapsing-header animation is removed.
10. Task 5: Ruling: review the prepared release before publication, then finish deployment/device evidence — the plan places publication inside Task 5 but also requires review first — Task 5 remains in progress until actual release verification.
11. Task 5: Ruling: retain the hosted free-plan 30/IP/hour limit and add database-enforced 100/24-hour and 500-total anonymous caps; disable every non-anonymous signup provider — the dashboard limit is read-only — no CAPTCHA is included, so request/egress abuse remains a monitored prototype limitation.
12. Task 5: Ruling: use hourly pg_cron cleanup of expired synthetic data and old anonymous identities without active workspaces — keeps free resources bounded and preserves renewed sessions — this is isolated-demo maintenance, never a production account-deletion policy.
13. Task 5: Ruling: disable the generated web service worker — local testing repeatedly served a stale build until a second reload — offline use is unavailable.
14. Final: Ruling: regrade desktop tracking overflow from Minor to Important and fix in the same review pass — a valid long report description was clipped by 522 pixels in the main reading flow — one Expanded replaces a viewport-derived width constraint; no redesign.
15. Final: Ruling: production municipal intake is outside this demo — the approved scope is an isolated portfolio workflow — no production readiness or municipal adoption claim is made.
16. Final: Ruling: keep the documented request/egress-abuse limitation without CAPTCHA — stored data is capped and synthetic, and adding a new verification service would expand this release — an exposed free demo can still be throttled or unavailable.
17. Final: Ruling: separate emulator, release compilation and real-device evidence — none proves the others — physical hardware remains a user check, while the hosted browser and emulator workflow are tested here.
18. Final: Ruling: normal email-auth/private-storage behaviour remains SQL/mock verified — the public demo deliberately disables email signup — camera, GPS and ordinary-account integration cannot be claimed as hosted-tested.
19. Final: Ruling: publish to the existing portfolio repository and its main-based Pages workflow under the user's approved deployed-demo plan — this is the integration choice already authorized, not a new PR proposal — recheck remote main and use a fast-forward push only.
20. Final: Ruling: provide a clearly labelled captured-screen video as the offline fallback — browser control has no continuous-recording API — the 26-second visual summary shows real published states, but does not demonstrate uninterrupted interaction. The live app and separate integration tests establish behaviour.

Deferred review minors: none.
