# FixCity

**Team graduation project | Badr University in Cairo | Business Information Systems**

FixCity is a Flutter prototype for reporting infrastructure problems in Egypt. A citizen can describe a problem, choose a location, attach a photo and track the report. Separate screens support municipal staff and district officials.

## Project origin and credit

This is Mohamed Elmorshedy's portfolio copy of a **six-person team project**. The original repository is [moatazahmedshaker/Fixcity](https://github.com/moatazahmedshaker/Fixcity). Its README credits **Ahmed Wael Ali ([DoctorJhin](https://github.com/DoctorJhin))** as developer. Those credits remain attached to this copy.

The source snapshot comes from commit [`a414da9`](https://github.com/moatazahmedshaker/Fixcity/commit/a414da9ffc3f2eab69e1cb2f4ef6c676d73b4e27). The upstream history records Ahmed Wael and DoctorJhin as author names, with Claude Sonnet 4.6 credited on one commit. A new history was created for this copy to avoid carrying credentials and archived data from the original repository. It does not reassign authorship of the original code.

See [ATTRIBUTION.md](ATTRIBUTION.md) for provenance and the limits of individual attribution.

## My contribution

I helped develop the concept and planned the reporting flow. With five colleagues, I contributed to technical direction, AI-assisted implementation, debugging and presentations. I hand-wrote portions of the frontend. Most of the team's code was produced with AI assistance, and we used a shared GitHub account for much of the work.

I present this project as evidence of product thinking and collaborative prototyping. I do not claim sole authorship of its code.

## What is in the source

- Arabic and English interfaces, with right-to-left layout support.
- Photo upload, map-based location selection, report submission and tracking codes.
- Citizen accounts, report history, notifications and points.
- Admin and district-official screens for reviewing reports, updating status and attaching repair photos.
- A Gemini category-suggestion integration in the original source, with a local keyword fallback.

The main stack is Flutter/Dart, Supabase Auth and database/storage APIs, flutter_map, geolocator and image_picker. The map uses CARTO tiles based on OpenStreetMap data. The app sends latitude and longitude values; the repository does not contain a PostGIS schema or migrations that establish geospatial database behaviour.

## Status of this portfolio copy

This is a source snapshot for review, not a production municipal service. The current copy has not been built or tested against a live backend. No government adoption or endorsement is claimed.

- Original service credentials and Firebase project configuration are excluded.
- Supabase configuration must be supplied for a separate development project.
- Live Gemini requests are disabled. The category button uses the local keyword fallback and labels its result accordingly. A server-side proxy is needed before restoring live AI use.
- Admin login now denies access when its role lookup fails. Backend access policies still need to be supplied and tested.
- Archived websites, databases, binaries, build output and old repository history are excluded.

See [PORTFOLIO-CHANGES.md](PORTFOLIO-CHANGES.md) and [BACKEND-SETUP.md](BACKEND-SETUP.md). The original source remains linked above for comparison.

## Local setup

Use Flutter 3.35 or later with a compatible Dart SDK. The checked-in lockfile requires Dart 3.9 or later. Flutter and Dart were not available in the review environment, so these commands have not been run here.

```sh
git clone https://github.com/mosalah-77/FixCity.git
cd FixCity/app
flutter pub get
flutter analyze
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_CLIENT_KEY
```

Use a development Supabase project containing only synthetic data. The original database schema, access policies and RPC definitions are not included in this repository, so supplying a URL and key alone does not reproduce the backend. Never place a Supabase service-role key or Gemini secret in the Flutter client.

## Licensing

The upstream README states "License: MIT", but the reviewed revision contains no standalone LICENSE file. This copy preserves that statement without inventing a copyright owner or changing the team's licensing terms. Confirm the complete licence with the project team before wider reuse.
