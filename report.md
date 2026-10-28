# HostelHub — Progress Report
Last updated: 2026-10-29 02:30 PKT | Current milestone: M6 | Overall: 78% (7/9 milestones)

## Milestone status
| ID | Name | Status (Not started / In progress / Done / Blocked) | Verified how |
|----|------|------|------|
| M0 | Foundation + GitHub CI/CD | Done | Analyzed, widget test passed, CI workflow added |
| M1 | Auth + Database & Security | Done | Analyzed, 9 unit tests passed, models & repos built |
| M2 | Properties & Rooms | Done | Analyzed, 13 unit tests passed, full CRUD & vacancy filtering |
| M3 | Residents | Done | Analyzed, 21 unit tests passed, validation, masking, room picker |
| M4 | Rent & Payments | Done | Analyzed, 30 unit tests passed, balances, partial payments, ledger |
| M5 | Reminders & Receipts | Done | Analyzed, 38 unit tests passed, WhatsApp templates, PDF receipt generator, zero CNIC leakage verified |
| M6 | Monetization | Done | Analyzed, 45 unit tests passed, mock billing, paywall with Play disclosures, write-lock verified |
| M7 | Compliance & Release Build | Not started | — |
| M8 | Dashboard, Notifications & Polish | Not started | — |

## Completed in this milestone
- **FR-23 (Paywall & Plan Selector):**
  - Built `PaywallScreen` with teal-to-dark-teal gradient header, gold premium badge, and clear value props (unlimited residents/rooms, 1-tap WhatsApp reminders, PDF invoices, and ledger tracking).
  - Implemented interactive plan selector for Monthly (Rs 1,500/mo) and Yearly (Rs 14,000/yr — "SAVE 22% • BEST VALUE").
  - Included required Google Play compliance disclosures: auto-renewal terms, 24h cancellation window, Play account charge notices, and clickable Terms of Service and Privacy Policy dialogs.
  - Implemented "Restore Purchases" and dynamic header action (Close button when unlocked; "Sign Out" button when locked to avoid dead-ends).
- **FR-24 & FR-26 (Billing Architecture & Mock Service):**
  - Defined `BillingService` interface with `BillingPurchaseStatus` stream and current status getter.
  - Built `MockBillingService` simulating realistic store roundtrip delay, updating Supabase user profile on purchase (`subscription_status = 'active'`, plan, expiry +30d or +365d), and handling restore flows.
  - Built `PlayBillingService` against `in_app_purchase` for Google Play product IDs `premium_monthly` and `premium_yearly`, controlled by a single debug toggle flag (`enablePlayBilling = false`).
- **FR-25 (Write-Lock Behavior & Trial Banner):**
  - Implemented pure domain calculator in `SubscriptionUtils` calculating exact trial days remaining (`30 - elapsed`), `isPremium`, `isTrial`, and `isLocked`.
  - Built `TrialBanner` showing remaining days in free trial with an "Upgrade" button (and red urgent banner when expired). Mounted on Dashboard and main navigation.
  - Built `WriteLockGuard` intercepting write actions (Add Resident, Add Room, Add Property, Record Payment) with an informative account locked dialog when `isLocked == true`.
  - Preserved full unrestricted read access: resident details, room lists, rent charges, ledger history, PDF receipt generation, Settings, Account Deletion, and Privacy Policy remain completely available.
- **UI & Routing Integration:**
  - Added `/paywall` route in `AppRouter`.
  - Replaced static subscription banner in `SettingsScreen` with an interactive Subscription Status Card navigating directly to `/paywall`.
- **Testing & Verification:**
  - Added 7 new unit tests in `test/subscription_test.dart` (45 total tests, all passing).
  - Verified static analysis with 0 issues.

## Verification
- flutter analyze: 0 issues
- flutter test: 45 passed / 0 failed
- debug APK built: assembleDebug verified with desugaring and definitions
- Security & Compliance check: Digital features exclusively routed through BillingService; no external payment links; Privacy Policy and Account Deletion unrestricted when locked.

## Mocked / partial / skipped (be honest)
- Real Google Play Billing is stubbed behind `enablePlayBilling = false` until the Google Play Console product catalog (`premium_monthly`, `premium_yearly`) is set up by the owner in production.

## Open issues & risks
- None.

## Decisions & assumptions log
- 2026-10-29 — Subscription calculation is pure and deterministic client-side from `trial_started_at` and `subscription_expires_at` on the user's Profile record.
- 2026-10-29 — When `isLocked`, the paywall replaces the Close button with "Sign Out" so owners can safely sign out or switch accounts without being trapped.

## Size & performance notes (from M7)
- N/A for M6.

## Manual steps pending for the Human
1. Run SQL schema from Section 7.2 in Supabase SQL editor (if not already done).
2. Disable "Confirm email" in Supabase Auth -> Providers -> Email for testing.
3. In Google Play Console (when ready): create subscriptions `premium_monthly` and `premium_yearly`.

## Suggestions (not implemented, need approval)
- None at this time.

## Next milestone preview
- M7: Compliance & Release Build — Full in-app Privacy Policy screen, signed release AAB/APK build configuration, R8 optimization and size verification, and `store_listing.md` preparation — estimated 60 min.
