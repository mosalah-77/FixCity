# Backend setup required

The frontend alone does not reproduce the original Supabase project. Obtain a schema-only export, storage policies, role model and function definitions from the team. Do not include citizen data, passwords, API secrets or production database exports.

The current Dart code references `reports`, `status_updates`, `profiles` and `notifications`, the storage bucket `files`, and the `increment_points` RPC. Treat that list as a code inventory, not a complete database schema.

Before a demo with synthetic data:

- Enforce citizen ownership, admin privileges and district scope in database policies. A page route or client-side role check is not an access-control boundary.
- Restrict changes to privilege-bearing profile columns and points. Check the `increment_points` function's permissions.
- Decide which report fields are public. A tracking code should not expose private profile details or allow unrestricted report enumeration.
- Validate uploaded images, limit file size, and control who can read uploaded media.
- Make report insertion, status history and rewards consistent, including failures and retries.
- Move Gemini calls to a server function with a secret stored on the server, a supported model, limits and clear handling of fallback results.

The exposed key in the original source needs owner-side rotation or revocation. Removing it from this copy does not revoke it. No key was tested against a provider, and no requests were made to the original Supabase backend during this review.
