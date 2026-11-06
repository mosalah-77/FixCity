# Security and Android performance review

Reviewed on 5 November 2026 for the 1.1.0 portfolio release. The review covers this repository and its isolated synthetic backend. The original team's backend was not accessed.

The 1.1.1 workflow update was reviewed later on 5 November. It adds server-enforced staff handoff and district repair permissions, validates photos on every update and applies report-access rules to history attachments. SQL regressions cover skipped review, staff attempts to resolve, district boundaries, update-photo access, retries and the reserved final history slot. Hosted Auth/REST and live browser checks passed. A fresh publishable-source scan identified only the existing public client key. No dependency changed. The measurements below remain the 1.1.0 measurements; performance was not reprofiled for 1.1.1.

On 6 November, the public 1.1.1 APK hashes matched the signed local artifacts. The user's emulator recording was reviewed before release. This documentation/media update changes no app code or backend permissions. [Current release evidence](RELEASE-VERIFICATION.md) records the remaining limits.

## Security findings and repairs

| Finding | Repair and evidence |
| --- | --- |
| A normal user could delete an unused upload while a concurrent report update attached it. The report could then reference a missing image. | Removed client-side media deletion and its database policy. A two-connection reproduction demonstrated the defect before the fix and retained the image after it. The new migration is applied to the hosted demo. Public demo visitors cannot upload images and were outside this affected path. |
| Replacing a demo identity could leave the previous profile behind the menu in the navigation stack. | Profile and account navigation now clear previous routes. A regression test changes identity, tries to return and verifies that the old profile and points are absent. Ordinary login/logout paths also clear prior routes. This was a local cached-screen defect; no database access-policy bypass was found. |
| Android's default backup settings could carry saved session preferences to another device. | Disabled app backup and shared-preference transfer in the Android manifest and extraction rules. A physical backup/restore test remains outstanding. |

Removing media deletion has a cost: abandoned uploads in the separate normal-account app require trusted maintenance, with report writes stopped and references rechecked. No automatic orphan cleaner is installed. Demo illustrations do not create stored uploads.

The manual review traced authentication, role assignment, report ownership, district boundaries, workspace expiry, storage access, input validation and retry behavior. Database tests cover forged ownership, direct writes, self-promotion, cross-workspace reads, private media, rollback and concurrent requests. The review used Trail of Bits' differential-review and audit-context-building methods, local adversarial reproductions and regression tests.

## Repository and dependency checks

Gitleaks 8.30.1 scanned the repository's reachable history and the complete publication candidate, including untracked files intended for the release. Its only identified key was the deliberate Supabase **publishable client key** in `app/demo-config.json`. That key identifies the project and relies on authentication and database access policies. It is not a service-role credential.

Additional searches found no private contact details, street address, signed media links, private keys or privileged tokens in the publication candidate. Release signing material and local configuration remain outside version control. Original contributor names and source attribution are retained deliberately.

OSV returned no known advisory matches for the 122 pinned Pub packages and 91 resolved Android Maven packages queried. These results do not cover every possible flaw in the Flutter engine, operating system or application. Gitleaks and OSV are detection aids, not a security certificate. Semgrep and Claude Security were not run.

The exposed key in the original upstream source was removed from this copy before its initial publication. Its owner still needs to revoke or rotate it if that has not happened; this review did not test the key or claim that it was revoked.

## Android work

Photo selection now bounds both width and height to 2,048 pixels. Report and preview images decode within 1,280 × 1,280 pixels while preserving aspect ratio. This reduces decoded-image memory for large photos; the existing 5 MiB upload limit remains.

The app keeps long report lists lazy, loads network data outside widget builds, and disposes animation controllers and subscriptions. Demo workspaces are capped at 20 reports. The normal-account application still needs pagination and larger-data testing before municipal use; the staff list currently shows at most 200 recent reports. Cairo is bundled with the app, so font rendering needs no download.

The release provides a universal APK and smaller ARM64, ARMv7 and x86-64 downloads. Android 7.0/API 24 is the minimum build target. This describes compilation compatibility; it does not mean every device in that range was tested.

## Profile run

The Android 15/API 35 ARM64 emulator completed report creation, staff review, district resolution, persisted history and notifications, then Arabic tracking. The test used a registered simulated keyboard; it does not verify a physical keyboard or IME. Profile mode rendered continuously during measurement.

An initial emulator run used software graphics. Repeating the same workflow with host GPU rendering changed the results substantially:

| Measurement | Software renderer | Host GPU |
| --- | ---: | ---: |
| Recorded frames | 294 | 1,473 |
| Mean widget-build time | 7.257 ms | 0.436 ms |
| 99th percentile build time | 106.261 ms | 3.230 ms |
| Mean raster time | 123.776 ms | 10.857 ms |
| 99th percentile raster time | 368.503 ms | 18.572 ms |
| Build samples above the test's 16 ms threshold | 34 | 0 |
| Raster samples above that threshold | 264 | 739 |

These are two emulator samples, not an app speed-up benchmark. The high raster count includes host/emulator scheduling and remains a reason to check physical hardware. The result does not establish sustained 60 fps, battery life or thermal behavior on a phone. Raw summaries are in [software-renderer results](evidence/2026-11-05/android-profile-software-renderer.json) and [host-GPU results](evidence/2026-11-05/android-profile-host-gpu.json).

[Flutter recommends profiling on physical hardware](https://docs.flutter.dev/perf/ui-performance), especially the slowest device expected to run the app. The [Android emulator's host GPU setting](https://developer.android.com/studio/run/emulator-acceleration) is useful for local interaction and recording, but does not replace that check.

## Remaining checks

Before using real citizen information, test ordinary Auth/Storage uploads, camera and location permissions, offline/retry behavior on phones, backup restoration and cross-tab identity changes. Run the profile workflow on a low-memory Android device and an ARM64 phone, including large text, repeated navigation and a long session. The checked-in [release commands](RELEASE.md) reproduce the automated checks.

Anonymous signup caps limit retained data and new identities, but cannot prevent someone from exhausting the demo's available signup slots. The free backend may pause, and public map tiles can fail. These are prototype limits. No claim of a complete penetration test, production readiness or vulnerability-free code is made.
