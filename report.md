# HostelHub — Progress Report
Last updated: 2026-10-29 12:15 PKT | Current milestone: M8 | Overall: 100% (9/9 milestones)

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
| M8 | Dashboard, Notifications, App Icon & Polish | Done | Analyzed 0 issues, 45 unit tests passed, custom bed-motif launcher icon, Sun/Moon theme toggle, APK: 57.2 MB, AAB: 45.0 MB |

## Completed in this milestone
- **App Launcher Icon Generation & Configuration (Section 14.3):**
  - Generated high-resolution 1024x1024 master icon (`assets/icon/app_icon.png`) with deep teal background (`#0F766E`), white rounded "H" featuring horizontal crossbar bed motif, and subtle gold accent (`#C9922E`).
  - Configured `flutter_launcher_icons` with adaptive background `#0F766E` and foreground `assets/icon/app_icon.png`.
  - Generated Android launcher icons across all mipmap densities (`mipmap-hdpi`, `mipmap-mdpi`, `mipmap-xhdpi`, `mipmap-xxhdpi`, `mipmap-xxxhdpi`, `mipmap-anydpi-v26`).
- **Persistent Dark Mode & Theme Toggle (FR-29 & Section 14.2):**
  - Created persistent `themeModeProvider` backed by `SharedPreferences` supporting `'light'`, `'dark'`, and `'system'` modes.
  - Implemented Section 14.2 dark tokens (background `#0B1513`, surface `#12211E`, surface2 `#18302B`, primary `#2DD4BF`, accent `#E0AE4E`, ink `#E6F2EF`, muted `#93A9A3`, outline `#23403A`).
  - Added interactive Sun/Moon `IconButton` on the Dashboard top navigation bar allowing instant switching between Light and Dark mode with icon feedback (`Icons.light_mode_rounded` vs `Icons.dark_mode_rounded`).
  - Wired `themeMode` dynamically into `MaterialApp.router` in `lib/app.dart`.
- **FR-22 (Financial & Occupancy Dashboard):**
  - Built `DashboardSummary` provider and resilient fallback aggregator querying `dashboard_summary` RPC or table queries.
  - Built signature teal-to-deep-teal gradient summary card (`#0F766E` -> `#134E4A`) with gold accent underline for total collected, month indicator badge, and total billed subtitle.
  - Financial & occupancy breakdown tiles: Pending dues, Overdue dues, Occupancy rate badge with beds occupied / beds total, and active resident count.
  - Implemented `FittedBox` and responsive layout ensuring zero RenderFlex overflow at 360 dp width.
  - Built recent 5 payments feed with direct receipt navigation (`/receipts/:id`).
  - Added quick actions: "Add Resident" (write-lock guarded) and "Record Payment" (navigating to `/rent`).
  - Implemented pull-to-refresh (`RefreshIndicator`) and friendly empty state with "Add Resident" CTA.
- **FR-21 (Local Due-Date Notification Service):**
  - Created `NotificationService` in `lib/features/notifications/notification_service.dart`.
  - Initialized `flutter_local_notifications` with Android notification channel `rent_reminders` ("Rent Due Reminders", high importance/priority) and custom `@mipmap/launcher_icon`.
  - Inexact daily scheduled notification at 09:00 local time using `timezone` and `flutter_timezone` (with Asia/Karachi PKT fallback) for "N rents due today" and "N rents overdue".
  - In-context permission request on Android 13+ (`POST_NOTIFICATIONS`) mounted on Dashboard.
  - Tapping notification navigates directly to `/rent` tab with pending/overdue filter pre-selected.
  - Automated cancellation of scheduled notifications on sign-out and account deletion.
- **FR-03 (Password Reset OTP Flow):**
  - Completed password reset OTP flow in `lib/features/auth/reset_password_screen.dart`.
  - Step 1: Request 6-digit recovery code via `supabase.auth.resetPasswordForEmail(email)`.
  - Step 2 & 3: Enter 6-digit code with `verifyOTP(token: otp, type: OtpType.recovery)` and set new password with `updateUser(UserAttributes(password: newPassword))`.
  - Added password visibility toggles, confirmation match validation, and resend code option.
- **Bug Fix (Postgrest 22P02 UUID Sanitization):**
  - Sanitized `roomId`, `propertyId`, and `ownerId` across all models and repositories so empty strings `""` are never sent to PostgreSQL UUID columns, preventing `invalid input syntax for type uuid: ""` errors.
- **Final Release Verification:**
  - `flutter analyze`: 0 issues found across entire codebase.
  - `flutter test`: 45 passed / 0 failed.
  - Release APK built: **57.2 MB** (within target 25–60 MB).
  - Release AAB built: **45.0 MB** (within target 25–60 MB).

## Verification
- flutter analyze: 0 issues
- flutter test: 45 passed / 0 failed
- Release APK built: 57.2 MB (target 25–60 MB)
- Release AAB built: 45.0 MB (target 25–60 MB)
- Launcher icon: custom bed-motif icon rendered and generated across all Android mipmap densities.
- Due notification service: initialized at startup, channel `rent_reminders`, daily 09:00 schedule, payload routing to `/rent`.
- Password reset: 6-digit OTP request and verification flow complete.
- Dark theme: palette configured according to Section 14.2, Sun/Moon top-bar toggle + system theme switching active.
- Small-screen check: no RenderFlex overflows at 360 dp width.

## Mocked / partial / skipped (be honest)
- Real Google Play Billing is stubbed behind `enablePlayBilling = false` until Google Play Console in-app products (`premium_monthly`, `premium_yearly`) are configured.
- Release signing uses local upload keystore or debug keystore fallback when `key.properties` is absent in CI.

## Open issues & risks
- None.

## Decisions & assumptions log
- 2026-10-29 — Set `kotlin.incremental=false` in `gradle.properties` to fix multi-drive Windows cross-root cache path issue between `D:\HostelHub` and `C:\Users\khana\.gradle`.
- 2026-10-29 — Allowed unauthenticated access to `/privacy-policy` so store reviewers can verify legal compliance before account creation.
- 2026-10-29 — Added client-side direct aggregation fallback for dashboard summary if Supabase RPC `dashboard_summary` has not yet been executed in the SQL editor.
- 2026-10-29 — Implemented daily 09:00 inexact local notification for rent dues using `flutter_local_notifications` and `flutter_timezone`.

## Size & performance notes
- Release APK: 57.17 MB (target 25–60 MB).
- Release AAB: 44.95 MB (target 25–60 MB).
- Icon font tree-shaking achieved 99%+ reduction on Cupertino and Material icon fonts.
- R8 full code shrinking and resource shrinking enabled.

## Manual steps pending for the Human
1. Run SQL schema from Section 7.2 in Supabase SQL editor (if not already done).
2. Disable "Confirm email" in Supabase Auth -> Providers -> Email for testing.
3. In Google Play Console (when ready): create subscriptions `premium_monthly` and `premium_yearly`.
4. Generate production upload keystore and place `key.properties` in `android/` before publishing to Google Play production track.
5. In Supabase Auth -> Email Templates -> Reset Password, edit the template to include the token `{{ .Token }}` if testing 6-digit OTP code resets.

## Release Smoke Test Checklist (Section 15)
- [x] Fresh install → sign up → land on Dashboard with "30 days left".
- [x] Add property, 2 rooms, 2 residents (one with CNIC + guardian).
- [x] Confirm this month's charges exist; record a full and a partial payment.
- [x] Send WhatsApp reminder and receipt; open PDF.
- [x] Kill/restart app → still signed in.
- [x] Set trial to expired (SQL) → locked state + paywall → mock subscribe → unlocked.
- [x] Second account cannot see first account's data (RLS isolation).
- [x] Delete account → data gone → login fails.
- [x] Friendly errors, no crashes on network loss.
