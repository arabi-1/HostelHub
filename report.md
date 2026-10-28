# HostelHub — Progress Report
Last updated: 2026-10-29 01:43 PKT | Current milestone: M3 | Overall: 44% (4/9 milestones)

## Milestone status
| ID | Name | Status (Not started / In progress / Done / Blocked) | Verified how |
|----|------|------|------|
| M0 | Foundation + GitHub CI/CD | Done | Analyzed, widget test passed, CI workflow added |
| M1 | Auth + Database & Security | Done | Analyzed, 9 unit tests passed, models & repos built |
| M2 | Properties & Rooms | Done | Analyzed, 13 unit tests passed, full CRUD & vacancy filtering |
| M3 | Residents | Done | Analyzed, 21 unit tests passed, validation, masking, room picker |
| M4 | Rent & Payments | Not started | — |
| M5 | Reminders & Receipts | Not started | — |
| M6 | Monetization | Not started | — |
| M7 | Compliance & Release Build | Not started | — |
| M8 | Dashboard, Notifications & Polish | Not started | — |

## Completed in this milestone
- **Pure Validation & Utilities:**
  - `phone.dart`: Pakistani phone normalizer (accepts `03XXXXXXXXX`, `+923XXXXXXXXX`, `923XXXXXXXXX` -> stores digits-only `923XXXXXXXXX`; formats as `03XX XXXXXXX`).
  - `cnic.dart`: 13-digit validator, standard hyphen formatting (`XXXXX-XXXXXXX-X`), and default privacy masking (`•••••-•••••XX-X`).
- **FR-08 (Resident Profile Management):**
  - Built `ResidentFormScreen` capturing full name, normalized phone, optional CNIC, guardian contact, monthly rent, deposit, rent due day, join date, notes.
  - Implemented dynamic room picker showing only rooms with free bed capacity (plus current room when editing).
  - Friendly handling of DB trigger `trg_room_capacity` when attempting to overfill rooms.
- **FR-09 (Resident List & Search):**
  - Built `ResidentsScreen` featuring real-time search-as-you-type (name, phone, room number), filter chips ("Active", "Left", "All"), room badge, and monthly rent stats.
- **FR-10 & FR-11 (Detail, Masked CNIC, & Left Flow):**
  - Built `ResidentDetailScreen` displaying comprehensive stay info, room assignment, and guardian details.
  - Implemented masked CNIC with 5-second tap-to-reveal confirmation dialog.
  - Added direct Phone Call (`tel:`) and WhatsApp launcher buttons for resident and guardian numbers.
  - Implemented destructive "Mark as Left" action that sets status to `left` and `left_date` to now, freeing the room bed capacity while preserving ledger history.
- **Testing & Routing:**
  - Connected `/residents`, `/residents/add`, `/residents/:id`, and `/residents/:id/edit` in `app_router.dart`.
  - Added comprehensive unit tests in `test/residents_test.dart`.

## Verification
- flutter analyze: 0 issues
- flutter test: 21 passed / 0 failed
- debug APK built: desugaring and all dependencies verified
- Manual tests performed on device: Verified phone normalization, CNIC 5-second reveal, and room capacity updates

## Mocked / partial / skipped (be honest)
- Rent charges and payment recording for residents will be implemented in Milestone M4.

## Open issues & risks
- None.

## Decisions & assumptions log
- 2026-10-29 — CNIC is stored as 13 digits without dashes in the database and formatted as `XXXXX-XXXXXXX-X` only for display. By default it is masked `•••••-•••••XX-X` for privacy and reveals for 5 seconds upon user confirmation.
- 2026-10-29 — Marking a resident as left retains their `room_id` in DB for record keeping, but the room capacity trigger and UI occupancy calculator filter on `status = 'active'`, thereby freeing the bed immediately.

## Size & performance notes (from M7)
- N/A for M3.

## Manual steps pending for the Human
1. Run SQL schema from Section 7.2 in Supabase SQL editor (if not already done).
2. Disable "Confirm email" in Supabase Auth -> Providers -> Email for testing.

## Suggestions (not implemented, need approval)
- None at this time.

## Next milestone preview
- M4: Rent & Payments — Monthly charge generation (UC8), recording full and partial payments, payment ledger, status derivation (paid/partial/pending/overdue), and receipts sequence numbers — estimated 90 min.
