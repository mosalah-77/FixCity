# Changes in the portfolio copy

Updated through 6 November 2026 with Codex assistance. The original repository is unchanged. The current portfolio release is [1.1.1](https://github.com/mosalah-77/FixCity/releases/tag/v1.1.1-demo.1); [release verification](docs/RELEASE-VERIFICATION.md) distinguishes current checks from the earlier stages below.

## Initial source cleanup, 24 October

1. Replaced the original Supabase URL and client key with compile-time configuration. Missing configuration stops startup before any backend request.
2. Removed the hard-coded Gemini key. With the key unset, category suggestions use the existing local keyword rules; the visible label no longer promises a live AI result. The original integration code is retained for review, but a secure backend proxy must replace it before production use.
3. Changed admin login so a failed role lookup denies access. This does not replace server-side authorisation or secure direct dashboard routes.
4. Removed unused Firebase Android Gradle configuration together with its project-specific configuration file. The current Dart app uses Supabase and has no Firebase dependency.
5. Declared the directly imported HTTP package and aligned the Dart minimum with the checked-in lockfile. No package upgrade was performed.
6. Excluded legacy Flask code, old project copies, databases, media archives, build output and backup files. No old Git history was imported.
7. Rewrote setup and project documentation around the inspected source and retained the original developer credit and source revision.

At this stage, validation covered the file inventory, local relative imports, configuration/secret patterns, JSON/XML parsing and the diff. Flutter and backend checks were not yet available. Those checks were completed during the November demo work below.

## Working demo, 4–6 November

- Added a separate Supabase schema with isolated synthetic workspaces, server-managed roles, row security, bounded anonymous accounts and expiry cleanup. The original team's backend was not used.
- Moved report creation and status updates into transactions, with retry IDs that prevent duplicate reports, history, notifications and points. Fixed authentication, navigation, notification-read and tracking defects documented in the [bug review](docs/BUG-REVIEW.md).
- Redesigned the Arabic/English interface, grouped report fields, added compact and wide navigation, and preserved the team's design context. The [design record](docs/REDESIGN.md) includes the logo options.
- Separated staff validation/handoff from district repair. Photos can be attached on the first update and remain in history. District progress updates keep reports open; resolution requires repair evidence.
- Restricted private media deletion, removed stale profile navigation, disabled Android backup/transfer and bounded image decoding. The [security/performance record](docs/SECURITY-PERFORMANCE-REVIEW.md) describes the checks and their limits.
- Published the browser demo and signed Android APKs. Version 1.1.1 is built from `3720902ec81ab8504faefa4331ca3b55064d7753`. Mohamed recorded the 90-second Android walkthrough on 6 November; its public MP4 retains the sequence and speed, with audio removed.

The 5 November verification passed 54 demo tests and 41 normal-app tests, database and hosted API checks, and the live browser workflow. Physical Android testing and ordinary-account hosted camera/GPS/upload checks remain outstanding. The updated Android integration script was not rerun for 1.1.1. See the release record for the exact evidence; no production-readiness claim is made.
