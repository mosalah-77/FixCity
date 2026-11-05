# Staff handoff and update photos

Mohamed approved separating staff review from district repair on 5 November 2026, after finding that both screens offered the same actions and photos appeared only at resolution.

Staff review validates a pending report and sends it to its existing district. The district starts repair, can save further progress notes without closing the report, and resolves it with repair evidence. The states are `pending`, `assigned`, `in_progress`, and `resolved`. Existing in-progress and resolved records stay valid. District reassignment and a separate employee dispatch system are outside this change.

Each submitted update may have a photo, including the first handoff. Resolution requires a photo. Store evidence with its history entry; an early inspection photo must not appear as the final repair photo. Citizen tracking and staff history both show these attachments. Failed submissions retain the note and selected photo for a safe retry.

The chosen approach separates responsibilities in the shared screen and enforces normal-account actions in the database. Keeping shared controls and changing labels would leave the overlap intact. Separate duplicate screens would add maintenance without changing the workflow.

Staff can hand off across districts but cannot perform district repair actions. District accounts can act only in their assigned district, after handoff. Demo visitors can demonstrate both roles only within their own synthetic workspace; persona switching is not production authentication.

Keep Arabic/English support, private media, immutable uploads, transactional updates and idempotent retries. Preserve team attribution. Test the permissions and photo flow before updating the live demo and recording APK.
