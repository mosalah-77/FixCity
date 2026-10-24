# Changes in the portfolio copy

Prepared on 24 October 2026 with Codex assistance. The original repository is unchanged.

1. Replaced the original Supabase URL and client key with compile-time configuration. Missing configuration stops startup before any backend request.
2. Removed the hard-coded Gemini key. With the key unset, category suggestions use the existing local keyword rules; the visible label no longer promises a live AI result. The original integration code is retained for review, but a secure backend proxy must replace it before production use.
3. Changed admin login so a failed role lookup denies access. This does not replace server-side authorisation or secure direct dashboard routes.
4. Removed unused Firebase Android Gradle configuration together with its project-specific configuration file. The current Dart app uses Supabase and has no Firebase dependency.
5. Declared the directly imported HTTP package and aligned the Dart minimum with the checked-in lockfile. No package upgrade was performed.
6. Excluded legacy Flask code, old project copies, databases, media archives, build output and backup files. No old Git history was imported.
7. Rewrote setup and project documentation around the inspected source and retained the original developer credit and source revision.

Validation completed: file inventory, local relative-import checks, configuration/secret-pattern scan, JSON/XML parsing where applicable, and diff review of these edits. Flutter analysis, automated app tests, a fresh build and live-backend verification remain pending because the SDK and backend definitions were unavailable.
