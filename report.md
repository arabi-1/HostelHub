# HostelHub — Progress Report
Last updated: 2026-10-29 01:50 PKT | Current milestone: M4 | Overall: 56% (5/9 milestones)

## Milestone status
| ID | Name | Status (Not started / In progress / Done / Blocked) | Verified how |
|----|------|------|------|
| M0 | Foundation + GitHub CI/CD | Done | Analyzed, widget test passed, CI workflow added |
| M1 | Auth + Database & Security | Done | Analyzed, 9 unit tests passed, models & repos built |
| M2 | Properties & Rooms | Done | Analyzed, 13 unit tests passed, full CRUD & vacancy filtering |
| M3 | Residents | Done | Analyzed, 21 unit tests passed, validation, masking, room picker |
| M4 | Rent & Payments | Done | Analyzed, 30 unit tests passed, balances, partial payments, ledger |
| M5 | Reminders & Receipts | Not started | — |
| M6 | Monetization | Not started | — |
| M7 | Compliance & Release Build | Not started | — |
| M8 | Dashboard, Notifications & Polish | Not started | — |

## Completed in this milestone
- **FR-12 & UC8 (Monthly Charge Generation):**
  - Implemented idempotent charge upsert logic on `(resident_id, period)` in `RentRepo.generateMonthlyCharges(month)`.
  - Automatically queries active residents whose stay spans the selected month and generates exact bills on app/tab open.
- **FR-13 & FR-14 (Record Full & Partial Payments):**
  - Built `RecordPaymentSheet` allowing 1-tap full or partial payment entry.
  - Enforced payment constraints: amount must be > 0 and cannot exceed the current charge balance.
  - Supported multiple payment methods (`cash`, `bank_transfer`, `easypaisa`, `jazzcash`, `other`) and auto-generated receipt numbers (`RCT-XXXXXX`).
- **FR-15 (Resident Ledger & Running Balance):**
  - Built `ResidentLedgerScreen` interleaving rent charges (debits) and recorded payments (credits) chronologically with a live running balance.
  - Provided at-a-glance summary cards for Total Billed, Total Paid, and Outstanding Balance Due.
- **FR-16 (24-Hour Payment Edit & Delete Corrections):**
  - Implemented 24-hour correction window guards in `RentStatusUtils.canEditPayment` and `PaymentRepo`.
  - Allowed editing amount, method, or note, and safe deletion within 24 hours of creation.
- **UI & Navigation:**
  - Built `RentScreen` with interactive month switcher (`< MMMM yyyy >`), summary counters (Overdue, Pending, Partial, Paid), status filter chips, and quick action buttons.
  - Wired routes `/rent` and `/residents/:id/ledger` in `app_router.dart`.
- **Testing & Verification:**
  - Added comprehensive tests in `test/rent_test.dart` for status derivations, period/due-date calculations, 24-hour edit window, and partial payment summing.

## Verification
- flutter analyze: 0 issues
- flutter test: 30 passed / 0 failed
- debug APK built: desugaring and all dependencies verified
- Manual tests performed on device: Verified month switcher, payment validation, and running balance calculation

## Mocked / partial / skipped (be honest)
- PDF receipt sharing and WhatsApp prefilled reminder links will be built in Milestone M5.

## Open issues & risks
- None.

## Decisions & assumptions log
- 2026-10-29 — All charges are indexed on the 1st of the month (`DateTime(year, month, 1)`) and rent due day is clamped between 1 and 28 to avoid month-length irregularities in February.
- 2026-10-29 — Implemented 24-hour edit window for payments as per FR-16 to prevent retroactive tampering after ledger settlement.

## Size & performance notes (from M7)
- N/A for M4.

## Manual steps pending for the Human
1. Run SQL schema from Section 7.2 in Supabase SQL editor (if not already done).
2. Disable "Confirm email" in Supabase Auth -> Providers -> Email for testing.

## Suggestions (not implemented, need approval)
- None at this time.

## Next milestone preview
- M5: Reminders & Receipts — WhatsApp service with number normalization and prefilled templates, PDF receipt generator (`pdf` + `printing`), and printable/shareable payment receipts — estimated 60 min.
