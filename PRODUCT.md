# FixCity

FixCity is a six-person BIS graduation project extended by Mohamed Elmorshedy as an AI-assisted portfolio prototype. It lets a resident report an infrastructure problem, staff review it, and a district team record a repair. The public demo uses isolated synthetic workspaces. It has no government affiliation and does not deliver real reports.

The primary audience is an Egyptian resident using an Android phone, often in Arabic. Staff need to find reports and see which action is available next. Recruiters need a working example they can try in a browser without registration.

## Product commitments

- Keep Arabic and English usable, including right-to-left layout and larger text.
- Put reporting and tracking ahead of points, badges and account settings.
- Preserve the complete reporting-to-resolution workflow, validation, private media rules and workspace isolation.
- Keep the original team's attribution. Do not imply government endorsement or municipal adoption.
- Run Humanizer over all reader-facing writing, including app copy, documentation and release notes.
- InstaPay is a reference for the potential partnership model, not a visual template. FixCity needs its own identity.

## Stack

Flutter 3.35.7, Dart 3.9.2, Supabase, Material 3. Android APK and browser demo. Reuse existing libraries; no paid services or backend expansion for this redesign.

## Sources

- [Team prototype deck](https://www.figma.com/deck/BQo4ic0fklIEw0jn4t7BNi): six slides reviewed on 5 November 2026. Navy and gold identity, separate Report and Track actions, category selection and status timeline.
- [InstaPay](https://www.instapay.eg/?lang=en): context for an accessible Egyptian service product. The user clarified that this is a business-model reference.
- [في خدمتك](https://play.google.com/store/apps/details?hl=ar&id=idsc.shakwa): official complaint channel describing submission, supporting documents and follow-up. FixCity is independent of this service.
- [Arab Contractors](https://www.arabcont.com/): current public terminology for infrastructure sectors. Its identity and logo are not reused.
