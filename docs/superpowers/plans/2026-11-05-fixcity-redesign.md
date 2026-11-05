# FixCity redesign implementation plan

> For agentic workers: use superpowers:executing-plans. Continue through routine decisions under the user's overnight authorization.

**Goal:** Make reporting and tracking easier to understand without changing the demo's data boundaries.

**Architecture:** Keep the existing Flutter pages and Supabase calls. Apply a shared Material theme and brand mark, simplify the navigation and home screen, and improve the existing form and report lists.

**Tech stack:** Flutter 3.35.7, Dart 3.9.2, Material 3, existing Supabase backend.

**Spec:** `docs/superpowers/specs/2026-11-05-fixcity-redesign.md`

## Constraints and review focus

Preserve attribution, both languages, all routes and backend validation. No new package or paid service. Humanizer covers reader-facing writing. Check Arabic at 360 dp and larger text, dark-mode contrast, alert read timing, draft retention when switching language, and existing staff/district transitions.

## Tasks

- [x] Reproduce the PostgreSQL startup race and repair the readiness gate in `.github/workflows/checks.yml`. Verify with delayed initialization in an isolated container; push for CI confirmation.
- [x] Update `app/lib/theme.dart`, `main.dart`, brand assets and font configuration. Create a local brand-options sheet and document the chosen design.
- [x] Add regression tests for accessible compact/wide navigation and preserved secondary routes. Replace the six-item custom bar in `main_scaffold.dart`; simplify `home_page.dart` and `demo_page.dart`.
- [x] Improve report form hierarchy and staff report selection. Preserve existing validation, retries and status history. Update the relevant tests and integration selectors if behavior changes.
- [x] Apply Humanizer to README, changed app copy and new documentation. Retain original authors, source links and qualifications about the prototype.
- [x] Run both widget suites, analyzer, database checks, web and Android builds. Inspect rendered Arabic/English and light/dark screens. Obtain a fresh whole-change review and address material findings.
- [ ] Publish the verified web build, prepare the signed APK and a concise visual handoff. Record exactly what passed and what still needs physical-device testing.
