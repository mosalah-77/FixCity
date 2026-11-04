# Try FixCity in two minutes

Open the [browser demo](https://mosalah-77.github.io/FixCity/). Choose English or Arabic at the top. Use fictional descriptions only; the sample reports and illustrations are synthetic.

1. Select **Start demo**, then **Citizen**. Two example reports are already present.
2. Choose **Roads**, write a short fictional description, select the damaged-road illustration and **Demo North**, then submit. Keep the tracking code. Success appears only after the backend saves the report.
3. Open **Demo menu → Staff review**. Select the pencil button beside your report, add a review note and move it to **In Progress**.
4. Open **Demo menu → District team**. Open the same report, add a repair note and a repaired-road illustration, then submit the update. The report becomes **Resolved**.
5. Return to **Citizen → Reports**. Open the report and choose **Track this report**. You should see the resolution and three history entries. **Alerts** contains the submission and status notifications.
6. Reload. Your session should retain its workspace. **Reset my demo** removes only your own examples and reports; it has a one-minute cooldown.

The district persona handles Demo North. Choose that district for the walkthrough. The staff persona can review both fictional districts. Persona switching changes the demonstration interface; the database still checks ownership on every request.

## What to explain in an interview

- **Problem:** a citizen needs a clear way to report an infrastructure issue and see whether anyone acted on it.
- **Team foundation:** the six-person BIS graduation project supplied the concept, Flutter interface and reporting flow. Mohamed worked on the concept, user flow, shared technical direction and AI-assisted implementation/debugging. Existing developer credits remain in ATTRIBUTION.md.
- **Repair example:** the original app awarded points and wrote a notification before saving a report. The new database operation commits the report, initial history, notification and points together, or rolls them all back.
- **Retry example:** the client retains a request ID after an uncertain response. The backend returns the first saved result instead of duplicating it. Two simultaneous requests are tested.
- **Access example:** a visitor can try staff actions only on their own demo data. Changing a report ID or profile role field does not grant another visitor's permissions.
- **Tradeoff:** synthetic illustrations and anonymous sessions make the flow easy to try. Real incident intake, agency integration, camera/geolocation permissions and production operations require additional work.

Use “I directed and reviewed this with AI assistance” where that reflects your work. Practise tracing one report from the button to `ReportActions`, the SQL transaction and the tracking response before using it as an interview example.

## Availability and privacy

No real citizen information, contact requests or government endorsement. Up to 20 reports per visitor, seven-day expiry, 100 new identities per rolling 24 hours and 500 retained anonymous identities globally. Clearing app/browser storage loses access to the anonymous session. Free hosting and public map tiles can be unavailable; this prototype has no uptime guarantee.

If the demo cannot load, retry once and check the Supabase project status before sharing its link. Do not enter real incident data as a test. Keep a short screen recording of the walkthrough after verifying the published version; a recording is supporting evidence and does not prove live availability.
