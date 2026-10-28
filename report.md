# HostelHub — Progress Report
Last updated: 2026-10-29 04:15 PKT | Current milestone: M7 | Overall: 89% (8/9 milestones)

## Milestone status
| ID | Name | Status (Not started / In progress / Done / Blocked) | Verified how |
|----|------|------|------|
| M0 | Foundation + GitHub CI/CD | Done | Analyzed, widget test passed, CI workflow added |
| M1 | Auth + Database & Security | Done | Analyzed, 9 unit tests passed, models & repos built |
| M2 | Properties & Rooms | Done | Analyzed, 13 unit tests passed, full CRUD & vacancy filtering |
| M3 | Residents | Done | Analyzed, 21 unit tests passed, validation, masking, room picker |
| M4 | Rent & Payments | Done | Analyzed, 30 unit tests passed, balances, partial payments, ledger |
| M5 | Reminders & Receipts | Done | Analyzed, 38 unit tests passed, WhatsApp templates, PDF receipt generator |
| M6 | Monetization | Done | Analyzed, 45 unit tests passed, mock billing, paywall with Play disclosures, write-lock verified |
| M7 | Compliance & Release Build | Done | In-app privacy policy, upload keystore signed, R8 shrink, APK: 55.5 MB, AAB: 44.5 MB |
| M8 | Dashboard, Notifications & Polish | Not started | Pending Human approval |

## Completed in this milestone
- **FR-27 & FR-28 (In-App Privacy Policy & Compliance Links):**
  - Built full in-app Privacy Policy screen (`lib/features/settings/privacy_policy_screen.dart`) matching Section 10.3 with complete disclosures on collected data (hostel details, resident names, contact info, CNIC), end-to-end Supabase RLS isolation, masked CNIC notice, zero data selling, and clear owner responsibility disclaimers.
  - Enhanced Settings screen (`lib/features/settings/settings_screen.dart`) with complete compliance links: Edit Profile, Subscription Status -> `/paywall`, Privacy Policy -> `/privacy-policy`, Contact Support (`mailto:support@hostelhub.app`), App Version (`1.0.0+1`), and typed Account Deletion confirmation modal.
  - Allowed unauthenticated access to `/privacy-policy` in `AppRouter` (`lib/core/router/app_router.dart`) so Play Store reviewers and unauthenticated users can review privacy practices prior to login.
- **Android Manifest & Permissions Audit (FR-04, FR-05, Section 10.1):**
  - Audited `android/app/src/main/AndroidManifest.xml` to include exactly 4 non-sensitive permissions (`INTERNET`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `VIBRATE`). No unauthorized SMS, Contacts, or Storage permissions.
  - Set `android:allowBackup="false"` to prevent automated adb extraction of sensitive tenant data.
  - Added explicit `<queries>` block for WhatsApp (`com.whatsapp`, `com.whatsapp.w4b`), HTTPS browser links, and email (`mailto:`).
- **Release Signing & R8 Optimization (Section 11, Section 15):**
  - Configured release keystore signing in `android/app/build.gradle.kts` with automatic fallback to debug keystore when `key.properties` is absent (for seamless CI/CD).
  - Enabled R8 code shrinking (`isMinifyEnabled = true`) and resource shrinking (`isShrinkResources = true`).
  - Added ProGuard keep rules in `android/app/proguard-rules.pro` for Flutter plugins, Android Billing Client, and Java 8 desugared core libraries.
- **Play Store Metadata (Section 9):**
  - Created `store_listing.md` containing App Name, 80-char Short Description, Full Description, Google Play Data Safety form responses, and reviewer test credentials.
- **Build & Verification:**
  - Assembled signed release APK: **55.5 MB** (target 25–60 MB).
  - Assembled signed release AAB: **44.5 MB** (target 25–60 MB).
  - Verified static analysis with 0 issues (`flutter analyze`).
  - Verified all 45 unit tests passing (`flutter test`).

## Verification
- flutter analyze: 0 issues
- flutter test: 45 passed / 0 failed
- Release APK built: 55.5 MB (target 25–60 MB)
- Release AAB built: 44.5 MB (target 25–60 MB)
- Manifest audit: exactly 4 permissions, `allowBackup="false"`, WhatsApp package queries present.
- Routing audit: `/privacy-policy` accessible both authenticated and unauthenticated; write-lock does not block privacy or account deletion.

## Mocked / partial / skipped (be honest)
- Real Google Play Billing is stubbed behind `enablePlayBilling = false` until Google Play Console in-app products (`premium_monthly`, `premium_yearly`) are configured.
- Release signing uses local upload keystore or debug keystore fallback when `key.properties` is absent in CI.

## Open issues & risks
- None.

## Decisions & assumptions log
- 2026-10-29 — Set `kotlin.incremental=false` in `gradle.properties` to fix multi-drive Windows cross-root cache path issue between `D:\HostelHub` and `C:\Users\khana\.gradle`.
- 2026-10-29 — Allowed unauthenticated access to `/privacy-policy` so store reviewers can verify legal compliance before account creation.

## Size & performance notes (from M7)
- Release APK: 55.5 MB (target 25–60 MB).
- Release AAB: 44.5 MB (target 25–60 MB).
- R8 code shrinking and resource shrinking active.

## Manual steps pending for the Human
1. Run SQL schema from Section 7.2 in Supabase SQL editor (if not already done).
2. Disable "Confirm email" in Supabase Auth -> Providers -> Email for testing.
3. In Google Play Console (when ready): create subscriptions `premium_monthly` and `premium_yearly`.
4. Generate production upload keystore and place `key.properties` in `android/` before publishing to Google Play production track.

## Suggestions (not implemented, need approval)
- None at this time.

## Next milestone preview
- M8: Dashboard, Notifications & Polish — Occupancy summary cards, collection KPI cards, quick-action shortcuts, local notification scheduling for due rent, empty states, and offline feedback.
