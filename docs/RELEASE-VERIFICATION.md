# FixCity release verification

## Current release: 1.1.1, finalized 6 November 2026

[Browser demo](https://mosalah-77.github.io/FixCity/) · [Signed Android APKs](https://github.com/mosalah-77/FixCity/releases/tag/v1.1.1-demo.1) · [90-second Android recording](https://github.com/mosalah-77/FixCity/releases/download/v1.1.1-demo.1/fixcity-demo-1.1.1.mp4)

Application source: `3720902ec81ab8504faefa4331ca3b55064d7753`, version 1.1.1+3. The 6 November documentation and media update does not change the app binary. Original team and developer credits are preserved in [ATTRIBUTION.md](../ATTRIBUTION.md).

| Check | Evidence and date |
| --- | --- |
| Flutter suites | 54 demo tests and 41 normal-app tests passed on 5 November; three demo-only skips in normal mode. |
| Static analysis | No errors or warnings; 97 informational diagnostics on 5 November. |
| Database | Workflow, permissions, rollback, concurrent retries, update-media access and history boundaries passed on 5 November. The log contains 77 labelled PASS notices plus expected-rejection assertions. |
| Hosted API | Real anonymous Auth/REST checks passed the four states, first-update media, idempotence, workspace isolation and privilege denial on 5 November. |
| Live browser | First-update photo, staff handoff/read-only state, district start, progress without resolution and repair-photo completion passed on 5 November. |
| Android distribution | Four signed APKs built; 1.1.1 installed over the emulator app with data retained. On 6 November all four public asset digests matched the local APKs. |
| Deployment | [GitHub Actions run 42083578860](https://github.com/mosalah-77/FixCity/actions/runs/42083578860) passed. The published version endpoint returned 1.1.1/build 3 on 6 November. |
| Code review | Independent review found no remaining blocking findings after regression and security repairs. |
| Recording | Mohamed's 6 November Android-emulator capture shows submission, pending tracking, staff handoff, district start and repair-photo resolution. The resolved district queue is visible before it ends at the role menu. |

The [artifact record](evidence/2026-11-06/release.json) contains sizes and hashes. APKs are unchanged from the 5 November release. The recording's public MP4 preserves its 1080 × 2400 display, sequence and speed; compression and audio removal are the only presentation changes. The original WebM is retained privately. The clip does not show a final citizen-tracking revisit, an Arabic switch or physical hardware.

The updated Android integration script was not rerun for 1.1.1. The earlier 1.1.0 emulator profile results below must not be presented as new performance measurements. Physical-device testing, ordinary-account hosted camera/GPS/private uploads, backup restoration and production-load behavior remain unverified. Free hosting and anonymous-request limits can affect availability. FixCity is a portfolio prototype with no municipal connection.

## Earlier verification records

The remaining sections preserve the earlier releases' results and decisions. Their source revisions, counts and media are historical. The current workflow has four states and separate staff/district responsibilities, as described above and in [the backend guide](../BACKEND-SETUP.md).

## 5 November 2026: version 1.1.0

The redesigned app passed 47 demo widget tests, 34 normal-app tests (three demo-only skips), 68 database checks, both release builds and the Android profile workflow. The analyzer reported 93 informational findings and no errors or warnings. All four APKs have the expected release signature; ZIP alignment and 64-bit ELF segment alignment pass the 16 KB checks.

The [security and performance review](SECURITY-PERFORMANCE-REVIEW.md) documents the two repaired defects, repository scan, dependency results and emulator measurements. [Machine-readable checks](evidence/2026-11-05/checks.json) and [APK hashes, sizes and signatures](evidence/2026-11-05/android-artifacts.json) accompany it. A physical Android test and a new continuous recording were outstanding at this stage; the 6 November recording is linked above.

The entries below describe the earlier 1.0.0 release. Their artifact hashes and video are historical.


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

The 1.1.1 release supersedes decision 4's shared role behavior: one component is still reused, with distinct staff and district actions and server permissions. The 6 November continuous Android recording supersedes decision 20's captured-screen fallback as the current portfolio video. Neither update changes the limits concerning municipal use or physical-device verification.

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
