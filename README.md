# FixCity

Team graduation project · Business Information Systems · Badr University in Cairo

FixCity is a Flutter prototype for reporting infrastructure problems in Egypt. A citizen can describe a problem, choose a location, attach a photo and track the report. Separate screens support municipal staff and district officials.

## Project origin and credit

This is Mohamed Elmorshedy's portfolio copy of a **six-person team project**. The original repository is [moatazahmedshaker/Fixcity](https://github.com/moatazahmedshaker/Fixcity). Its README credits **Ahmed Wael Ali ([DoctorJhin](https://github.com/DoctorJhin))** as developer. Those credits remain attached to this copy.

The source snapshot comes from commit [`a414da9`](https://github.com/moatazahmedshaker/Fixcity/commit/a414da9ffc3f2eab69e1cb2f4ef6c676d73b4e27). The upstream history records Ahmed Wael and DoctorJhin as author names, with Claude Sonnet 4.6 credited on one commit. A new history was created for this copy to avoid carrying credentials and archived data from the original repository. It does not reassign authorship of the original code.

See [ATTRIBUTION.md](ATTRIBUTION.md) for provenance and the limits of individual attribution.

## My contribution

I helped develop the concept and planned the reporting flow. With five colleagues, I contributed to technical direction, AI-assisted implementation, debugging and presentations. I hand-wrote portions of the frontend. Most of the team's code was produced with AI assistance, and we used a shared GitHub account for much of the work.

My contribution was shared with the team. This portfolio copy documents that work and the repairs I have since directed and reviewed with AI assistance.

## Try the reporting workflow

[Browser demo](https://mosalah-77.github.io/FixCity/) · [Android releases](https://github.com/mosalah-77/FixCity/releases) · [Two-minute walkthrough](docs/DEMO.md)

Start a demo workspace, submit a fictional report, review it as staff, add repair evidence as the district team, then return to the citizen's tracking page. The report, status history and in-app notifications are saved in a separate Supabase project. Each visitor sees only their own synthetic workspace.

The demo builds on the team's Flutter app and supports Arabic and English. Its revised interface puts reporting and tracking first, with separate screens for staff review and repair updates. Sample illustrations replace camera uploads. There is no government affiliation, real incident delivery, SMS service or cash value attached to points. Data expires after seven days. The free backend can pause after inactivity; check the link before sharing it in an application.

## Work added to this portfolio copy

In November 2026, I used Codex to help turn the source snapshot into a reproducible demo and investigate bugs in the existing app. The work adds:

- Database migrations and row-level access policies for citizens, staff, districts and isolated demo visitors.
- Transactional report creation and status updates. A retried request does not award points or create history twice.
- Required repair evidence, private media rules for the separate normal-app path, and bounded demo accounts with expiry cleanup.
- Fixes for password handling, confirmation signup, unread notifications, stale tracking results, failed saves and small-screen layouts.
- A test suite, pinned builds and release documentation.
- A revised interface with four main destinations, Arabic typography, a desktop navigation rail and a new logo. The [design notes and logo options](docs/REDESIGN.md) explain those choices.
- A security review with fixes for concurrent media deletion and stale profile navigation, plus smaller Android downloads and bounded photo decoding. The [review record](docs/SECURITY-PERFORMANCE-REVIEW.md) explains the evidence and remaining checks.

The [bug review](docs/BUG-REVIEW.md) separates reproduced defects, tests and remaining checks. The [backend guide](BACKEND-SETUP.md) describes access rules and limits. This remains a student-project prototype developed with AI assistance. It has not been used for municipal operations.

## Run locally

Use **Flutter 3.35.7 / Dart 3.9.2** and the checked-in lockfile.

```sh
git clone https://github.com/mosalah-77/FixCity.git
cd FixCity/app
flutter pub get --enforce-lockfile
flutter run -d chrome --dart-define-from-file=demo-config.json
```

`demo-config.json` contains only a public client key and the isolated portfolio backend URL. For your own backend, follow [BACKEND-SETUP.md](BACKEND-SETUP.md), copy the config and change those public values. Never put a service-role key, database password or AI secret into the Flutter client.

```sh
flutter test --dart-define=DEMO_MODE=true
flutter test
flutter analyze --no-fatal-infos
flutter build web --release --base-href /FixCity/ --pwa-strategy=none \
  --dart-define-from-file=demo-config.json
```

See [release instructions](docs/RELEASE.md) for Android signing, database checks and deployment. The normal citizen/staff application remains in the codebase and needs its own configured backend and privately assigned roles. The public demo backend permits anonymous sign-in only.

## Stack and limits

Flutter/Dart, Supabase Auth/PostgreSQL/Storage, flutter_map, OpenStreetMap tiles, geolocator and image_picker. Map coordinates are ordinary latitude/longitude fields; no PostGIS behaviour is claimed. Category suggestions use a labelled local keyword fallback. The original Gemini integration is disabled, and old project credentials, archived data and binaries remain excluded.

## Licensing

The upstream README states "License: MIT", but the reviewed revision contains no standalone LICENSE file. This copy preserves that statement without inventing a copyright owner or changing the team's licensing terms. Confirm the complete licence with the project team before wider reuse.
