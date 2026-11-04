# Builds and release checks

Pinned Flutter: **3.35.7**, git commit `adc901062556672b4138e18a4dc62a4be8f4b3c2`. Dart **3.9.2**; Java **17**. Android application ID: `dev.mosalah.fixcity`.

## Verify

From `app/`:

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib/demo.dart lib/demo_page.dart lib/report_actions.dart lib/report_media.dart test
flutter analyze --no-fatal-infos
flutter test --dart-define=DEMO_MODE=true
flutter test
```

Formatting covers new shared/demo modules and tests; untouched legacy files have not been reformatted wholesale. Analyzer informational findings remain; errors and warnings fail the check.

Run the disposable PostgreSQL tests as described in BACKEND-SETUP.md. The script uses only the named FixCity container and does not reset any hosted backend. `hosted-smoke.py --run` separately tests the allowlisted synthetic project's real Auth and REST API.

## Web

```sh
flutter build web --release --base-href /FixCity/ --pwa-strategy=none \
  --dart-define-from-file=demo-config.json
```

Pages uses `/FixCity/`; navigation uses URL fragments, so deep links survive reloads. Offline/service-worker caching is intentionally disabled to avoid serving stale application code. In GitHub repository Settings → Pages, choose GitHub Actions. The publish workflow runs app and database checks before granting the deployment job Pages write permission. Third-party actions are pinned to verified commit revisions. Pull requests run checks without deployment permissions.

## Android

Install Google's SDK after accepting its licence. The pinned Flutter version requires Android API 36 and NDK `27.0.12077973`. Use Java 17. Keep signing material outside Git.

Create `app/android/key.properties` locally:

```properties
storeFile=/absolute/private/path/fixcity-demo-release.jks
storePassword=YOUR_PRIVATE_PASSWORD
keyPassword=YOUR_PRIVATE_PASSWORD
keyAlias=fixcity-demo
```

The file and keystore extensions are ignored by Git. Keep a private backup; losing the release key prevents installing future updates over the existing app. CI builds a debug APK for compilation checks only. A distributable release must be signed with the private release key and verified before upload:

```sh
flutter build apk --release --dart-define-from-file=demo-config.json
apksigner verify --verbose --print-certs build/app/outputs/flutter-apk/app-release.apk
shasum -a 256 build/app/outputs/flutter-apk/app-release.apk
```

Check the entire report-to-resolution cycle on an Android emulator and then a real device. Verify launch, network access, Arabic layout, back navigation, session persistence and retry handling. Do not describe camera/GPS or real-device support as verified from compilation alone.

Upload the signed APK and its SHA-256 checksum to a versioned GitHub Release. Record its source commit and the checks that actually ran. The demo APK uses synthetic illustrations and does not request location or camera access through its demo flow.
