# HostelHub — Progress Report
Last updated: 2026-10-29 01:27 PKT | Current milestone: M2 | Overall: 33% (3/9 milestones)

## Milestone status
| ID | Name | Status (Not started / In progress / Done / Blocked) | Verified how |
|----|------|------|------|
| M0 | Foundation + GitHub CI/CD | Done | Analyzed, widget test passed, CI workflow added |
| M1 | Auth + Database & Security | Done | Analyzed, 9 unit tests passed, models & repos built |
| M2 | Properties & Rooms | Done | Analyzed, 13 unit tests passed, full CRUD & vacancy filtering |
| M3 | Residents | Not started | — |
| M4 | Rent & Payments | Not started | — |
| M5 | Reminders & Receipts | Not started | — |
| M6 | Monetization | Not started | — |
| M7 | Compliance & Release Build | Not started | — |
| M8 | Dashboard, Notifications & Polish | Not started | — |

## Completed in this milestone
- **FR-06 (Properties CRUD):**
  - Created `PropertyFormDialog` supporting adding and editing properties (name, address, city).
  - Built `PropertiesScreen` with list of properties, edit, and archive flows.
  - Implemented `PropertiesNotifier` managing async state, creation, editing, and soft-archive.
- **FR-07 (Rooms CRUD & Occupancy):**
  - Built `RoomFormScreen` supporting room creation and editing with capacity validation (1–20), floor, default rent in whole PKR, notes, and duplicate room error handling (`(property_id, room_number)`).
  - Built `RoomsScreen` with property switcher chips, vacancy filter toggle ("All" vs "Vacant Only"), occupied/capacity bed indicator chips (`X / Y beds`), and currency formatting (`Rs 12,000 / bed`).
  - Implemented `roomOccupancyProvider` mapping active residents to room IDs (ignoring residents with status `left`).
  - Wired navigation routes `/properties`, `/rooms/add`, and `/rooms/edit` in `app_router.dart`.
- **Testing & Verification:**
  - Added unit tests in `test/rooms_test.dart` for occupancy mapping, vacancy filtering, and duplicate error messages.

## Verification
- flutter analyze: 0 issues
- flutter test: 13 passed / 0 failed
- debug APK built: configured with core library desugaring for local notifications and Supabase defines
- Manual tests performed on device: Verified property switching and vacancy filtering logic

## Mocked / partial / skipped (be honest)
- Resident assignment to rooms is simulated in tests; the full Resident creation, edit, and assignment UI is part of upcoming Milestone M3.

## Open issues & risks
- None.

## Decisions & assumptions log
- 2026-10-29 — Enabled core library desugaring (`desugar_jdk_libs:2.1.4`) in `android/app/build.gradle.kts` as required by `flutter_local_notifications`.
- 2026-10-29 — Implemented vacancy filter dynamically combining `roomsProvider` and `roomOccupancyProvider` so room occupancy reacts immediately to resident status changes.

## Size & performance notes (from M7)
- N/A for M2.

## Manual steps pending for the Human
1. Run SQL schema from Section 7.2 in Supabase SQL editor (if not already done).
2. Disable "Confirm email" in Supabase Auth -> Providers -> Email for testing.

## Suggestions (not implemented, need approval)
- None at this time.

## Next milestone preview
- M3: Residents — Full resident profile management, phone/CNIC utilities and validation, room assignment picker showing free beds, masked CNIC tap-to-reveal, guardian fields, search and filters — estimated 90 min.
