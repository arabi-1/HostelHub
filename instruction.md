# instruction.md — HostelHub (working name)

> **Single source of truth for this project.** If anything in chat conflicts with this file, stop and ask the human (Muhammad Arabi) which wins, then update this file. Never silently deviate.

- **Product:** Rent & resident manager for hostel / PG / boarding-house owners in Pakistan.
- **Platform:** Android only (Flutter + Dart). Keep code iOS-compatible, but do not build for iOS.
- **Hard deadline:** 2026-10-29, 15:00 (Pakistan time). Working app + signed release AAB/APK.
- **Human:** Muhammad Arabi. Final decisions are his. He is the gate between milestones.

---

## 0. How this project is run (READ FIRST)

### 0.1 Roles
| Role | Who | Responsibility |
|---|---|---|
| **Human** | Muhammad | Approves every milestone, performs manual steps (Supabase dashboard, keystore, Play Console), answers questions. |
| **Lead** | Gemini (chat) | Reads this file, plans, writes one **Execution Brief** per milestone for the Executor, reviews results against acceptance criteria, maintains `report.md`. Does not write large code itself. |
| **Executor** | Antigravity (agent IDE) | Implements exactly what the Execution Brief says inside the project folder, runs commands, reports back. |

If Gemini and Antigravity end up being the same session, one agent plays both roles but still follows the protocol below.

### 0.2 Non‑negotiable rules
1. **Milestones, not one go.** Work only on the current milestone (Section 12). Never start the next one without the Human's explicit "yes".
2. **Stop gate after every milestone.** When a milestone is done: run `flutter analyze` and `flutter test`, build a debug APK (`flutter build apk --debug`), update `report.md` (template in Section 13), then **STOP** and ask: *"Milestone N complete. Continue to Milestone N+1? (yes / change something / pause)"*.
3. **No scope creep.** Do not add features, packages, screens, or backends not in this file. Propose them in `report.md → Suggestions` instead.
4. **No guessing on critical items.** If a requirement is ambiguous or a manual step is needed (keys, accounts), ask the Human with a short numbered question list (max 5 questions) before coding.
5. **Never invent secrets.** Never hard-code Supabase keys, keystore passwords, or API keys. Never commit `env.json`, `key.properties`, `*.jks`, `*.keystore`.
6. **Never use the Supabase `service_role` key in the app.** Only the public anon key, protected by RLS.
7. **Package versions:** add dependencies with `flutter pub add <name>` (latest compatible). Do not hard-code versions from memory. Do not add packages outside Section 6 without asking.
8. **Keep it small.** The APK size window is 25–60 MB (Section 10). Avoid heavy SDKs (no Firebase, no analytics SDKs, no ad SDKs).
9. **Honesty in reports.** If something is mocked, partial, or failing, say so plainly in `report.md`. Never mark an item done unless it was run and verified.
10. **Small commits.** `git init` at M0. One commit per completed task with message `M<n>: <what>`.

### 0.3 Execution Brief template (Lead → Executor)
```
MILESTONE: M<n> — <name>
GOAL: <1–2 sentences>
READ FIRST: instruction.md sections <list>
TASKS (ordered): 1… 2… 3…
FILES TO CREATE/CHANGE: <paths>
ACCEPTANCE CRITERIA: <checklist copied from instruction.md>
COMMANDS TO RUN: <analyze / test / build>
DO NOT: <explicit exclusions for this milestone>
REPORT BACK: files changed, commands run + results, anything mocked or skipped, blockers
```

### 0.4 Coding conventions
- Dart 3, null-safe, `flutter_lints` clean. No `print`; use `debugPrint` guarded by `kDebugMode`.
- Feature-first structure (Section 6.2). Widgets stay small; business logic lives in providers/repositories, never in widgets.
- All money is `Decimal`-safe: store as `numeric(12,2)` in DB; in Dart use `int` paisa-free approach: parse as `double` only for display, compute with integers of rupees where possible (rent is whole rupees in the UI; DB keeps 2 decimals). Format with `intl`: `Rs 12,500`.
- All dates stored as UTC timestamps or `date`; displayed in local time, format `dd MMM yyyy`.
- Every async screen has **loading, empty, error (with retry), and success** states.
- Every form validates inputs and shows inline errors. Every destructive action asks for confirmation.
- User-facing strings are English, kept in one `strings.dart` (easy to localize later).
- Never log CNIC, phone numbers, passwords, or tokens.

---

## 1. Product overview

Hostel/PG owners in Pakistan track residents, rooms, monthly rent and dues in notebooks and WhatsApp. HostelHub replaces that with one phone app: add rooms and residents, see who has paid, send a WhatsApp reminder or receipt in two taps, and see monthly totals.

**Assumed scope (confirm in M0 if wrong):** single user type = **owner/manager**. Residents do **not** log in. One owner may have several properties. Currency = PKR. Rent is monthly with a due day.

### 1.1 Core feature groups
1. **Properties & Rooms** — buildings, rooms, bed capacity, default rent, occupancy.
2. **Residents** — profile, room assignment, CNIC (optional, masked), guardian contact, join/leave.
3. **Rent & Payments** — monthly charges, record full/partial payments, ledger, status (paid / partial / pending / overdue).
4. **Reminders & Receipts** — WhatsApp reminder + receipt via `wa.me` prefilled links, PDF receipts, local due-date notifications.

### 1.2 Extras (decided)
Dashboard with totals · Account deletion + privacy policy screen · PDF receipts (printable/shareable) · Local notifications for due dates.

### 1.3 Revenue model
**Free trial 30 days → paid subscription** (monthly and yearly plans) via Google Play Billing. For this deadline billing is **mocked** behind an interface so the real Play Billing implementation can be swapped in without UI changes (Section 9).

---

## 2. Objectives

| ID | Objective | Measure of success |
|---|---|---|
| O1 | Let an owner replace paper/WhatsApp rent tracking | Owner can add a room, add a resident, record a payment in under 2 minutes total |
| O2 | Make dues visible at a glance | Dashboard shows collected / pending / overdue and occupancy for the current month |
| O3 | Cut chasing effort | Reminder or receipt sent to WhatsApp in ≤ 3 taps from a resident or payment |
| O4 | Generate revenue | Trial gating + paywall + subscription state works end to end (mock now, Play Billing ready) |
| O5 | Pass store review | Meets Section 10 compliance checklist (privacy policy, data safety, account deletion, minimal permissions) |
| O6 | Ship on time | Signed release AAB/APK installed and smoke-tested by deadline |
| O7 | Stay lightweight | Play download size within 25–60 MB, startup < 3 s on a mid-range phone |

---

## 3. Actors & assumptions
- **Owner** (only authenticated actor). Signs up with email + password.
- **System** (Supabase Auth/DB, device scheduler, Google Play Billing).
- **Resident** (data subject, no login). Contacted externally via WhatsApp.
- Assumptions: stable-ish mobile internet (online-first app; no offline sync in this version), Android 8+ devices, owners are non-technical → simple screens, big touch targets, no jargon.

---

## 4. Use cases

| ID | Use case | Actor | Main flow (short) | Alternate / error |
|---|---|---|---|---|
| UC1 | Sign up | Owner | Enter name, email, password → account + profile created → trial starts → land on Dashboard | Email taken / weak password / no network |
| UC2 | Sign in / out | Owner | Email + password → Dashboard; Sign out from Settings | Wrong credentials; session expired → login |
| UC3 | Reset password | Owner | Enter email → receive 6-digit code → enter code + new password | Invalid/expired code |
| UC4 | Manage properties | Owner | Add / edit / archive property | Cannot delete property with active residents |
| UC5 | Manage rooms | Owner | Add room (number, floor, capacity, default rent), edit, deactivate | Duplicate room number in property |
| UC6 | Add resident | Owner | Fill form, pick room (only rooms with free beds) → save | Room full; invalid phone/CNIC |
| UC7 | Edit / mark resident left | Owner | Edit details; "Mark as left" sets status + left date, frees bed | Resident has unpaid balance → warn, allow |
| UC8 | Generate monthly charges | System | On app open (and month change) create missing `rent_charges` for active residents for current month | Idempotent — never duplicates |
| UC9 | Record payment | Owner | Open resident/charge → enter amount, date, method → save → receipt created | Amount > balance blocked; amount ≤ 0 blocked |
| UC10 | Send WhatsApp reminder | Owner | Tap "Remind" on pending/overdue resident → WhatsApp opens with prefilled message | WhatsApp not installed → show message + copy button |
| UC11 | Send / share receipt | Owner | After payment: "Send on WhatsApp" and/or "Share PDF" | PDF generation failure → retry |
| UC12 | View dashboard | Owner | See collected, pending, overdue, occupancy, recent payments | Empty state with "Add first room" CTA |
| UC13 | Receive due notification | System/Owner | Local notification at 09:00 on days rent is due/overdue | Notification permission denied → in-app banner |
| UC14 | Subscribe | Owner | Trial ends/expiring → paywall → choose plan → (mock) purchase → premium active | Cancelled purchase; restore purchases |
| UC15 | Delete account | Owner | Settings → Delete account → confirm by typing `DELETE` → all data erased → login screen | Network error → nothing deleted |
| UC16 | View privacy policy | Owner | Settings → Privacy Policy (in-app screen) | — |

---

## 5. User stories (with acceptance criteria)

**Auth & account**
- **US1** As an owner, I want to sign up with email and password so that my data is private to me. *AC:* password ≥ 8 chars; profile row auto-created; trial_started_at = now; I land on Dashboard.
- **US2** As an owner, I want to stay signed in so that I don't log in every time. *AC:* session persists across restarts; sign-out clears it.
- **US3** As an owner, I want to reset a forgotten password. *AC:* code emailed; new password works; old one fails.
- **US4** As an owner, I want to delete my account and all my data. *AC:* confirmation required; all rows gone; cannot log in again.

**Rooms**
- **US5** As an owner, I want to add properties and rooms with bed capacity and default rent. *AC:* duplicates blocked; list shows "occupied/capacity" per room.
- **US6** As an owner, I want to see which rooms have free beds. *AC:* filter "Vacant"; full rooms not selectable when adding a resident.

**Residents**
- **US7** As an owner, I want to save a resident's name, phone, optional CNIC, guardian name/phone, rent, deposit, due day. *AC:* phone validated (PK format); CNIC optional 13 digits, shown masked `•••••-•••••XX-X`; guardian optional.
- **US8** As an owner, I want to mark a resident as left. *AC:* bed freed; history and payments retained; resident hidden from "Active".
- **US9** As an owner, I want to search and filter residents (name/phone/room/status). *AC:* results update as I type.

**Rent**
- **US10** As an owner, I want this month's rent auto-created for each active resident. *AC:* exactly one charge per resident per month; amount = resident's monthly rent; due date = due day.
- **US11** As an owner, I want to record cash / bank / Easypaisa / JazzCash payments, including partial ones. *AC:* balance updates; status chip updates; receipt number generated.
- **US12** As an owner, I want to see each resident's ledger. *AC:* list of charges and payments, running balance.

**Reminders & receipts**
- **US13** As an owner, I want to send a rent reminder on WhatsApp in a few taps. *AC:* WhatsApp opens to the resident's number with the text filled; I press send myself.
- **US14** As an owner, I want a printable/shareable PDF receipt. *AC:* PDF has business name, receipt no, resident, period, amount, method, date, balance.
- **US15** As an owner, I want phone notifications when rents are due. *AC:* notification 09:00 on due date and for overdue; tapping opens Pending list.

**Dashboard & money**
- **US16** As an owner, I want totals for the month. *AC:* collected, billed, pending, overdue, occupancy % shown and correct against the database.
- **US17** As an owner, I want to try the app free for 30 days, then subscribe. *AC:* days-left shown; after expiry the app becomes read-only (view/export allowed, no new residents/payments) with a paywall.

---

## 6. Technical design

### 6.1 Stack
| Layer | Choice |
|---|---|
| UI | Flutter (stable channel) + Material 3 |
| State | **Riverpod** (`flutter_riverpod`; use plain `Notifier`/`AsyncNotifier`, **no code generation** to save time) |
| Routing | `go_router` with auth redirect |
| Backend/DB | **Supabase** (Postgres + Auth + RLS). No custom server. |
| Billing | `in_app_purchase` behind `BillingService` interface; `MockBillingService` for now |
| PDF | `pdf` + `printing` |
| Notifications | `flutter_local_notifications` + `timezone` (+ `flutter_timezone`) |
| Links | `url_launcher` (WhatsApp `wa.me`, privacy URL) |
| Misc | `intl`, `shared_preferences`, `share_plus` (only if `printing` share is insufficient) |

Dependency policy: only the packages above. Anything else needs Human approval.

### 6.2 Project structure
```
lib/
  main.dart
  app.dart                    // MaterialApp.router, theme, providers scope
  core/
    config/env.dart           // reads --dart-define values
    theme/ (app_colors.dart, app_theme.dart, app_text.dart)
    router/app_router.dart
    utils/ (phone.dart, cnic.dart, money.dart, dates.dart, validators.dart)
    widgets/ (app_button, app_text_field, status_chip, empty_state, error_view, loading_view, stat_card, confirm_dialog)
    strings.dart
  data/
    supabase_client.dart
    models/ (profile, property, room, resident, rent_charge, payment)
    repositories/ (auth_repo, property_repo, room_repo, resident_repo, rent_repo, payment_repo, profile_repo)
  features/
    auth/        (login, signup, reset_password)
    dashboard/
    rooms/       (properties list, rooms list, room form)
    residents/   (list, detail, form)
    rent/        (pending list, ledger, record_payment)
    receipts/    (pdf_builder, whatsapp_service)
    notifications/ (notification_service)
    billing/     (billing_service.dart, mock_billing_service.dart, play_billing_service.dart stub, paywall_screen, subscription_provider)
    settings/    (settings, privacy_policy, delete_account, about)
test/
assets/ (fonts/, images/, lottie/)
```

### 6.3 Config & secrets
- `env.json` (gitignored) with `SUPABASE_URL` and `SUPABASE_ANON_KEY`. Commit `env.example.json` with placeholders.
- Run: `flutter run --dart-define-from-file=env.json`. Build: `flutter build appbundle --release --dart-define-from-file=env.json`.
- `Env` class reads `String.fromEnvironment`; app shows a clear "Missing configuration" screen if empty.

### 6.4 Navigation (bottom bar, 5 tabs)
`Dashboard · Residents · Rooms · Rent · Settings` (Rent tab = Pending/Overdue first, ledger and payments inside). Auth screens outside the shell. `go_router` redirects: unauthenticated → `/login`; authenticated on auth routes → `/`.

---

## 7. Data design

### 7.1 Entities
`profiles (1) — (N) properties (1) — (N) rooms (1) — (N) residents (1) — (N) rent_charges (1) — (N) payments`. Every business table has `owner_id` and RLS `owner_id = auth.uid()`.

| Table | Purpose | Key fields |
|---|---|---|
| profiles | Owner profile + subscription state | id (=auth user), full_name, phone, business_name, trial_started_at, subscription_status, subscription_plan, subscription_expires_at |
| properties | Hostel buildings | name, address, city |
| rooms | Rooms in a property | room_number, floor, capacity, default_rent, is_active |
| residents | People living there | full_name, phone, cnic?, guardian_name?, guardian_phone?, monthly_rent, security_deposit, rent_due_day, join_date, status, left_date, room_id? |
| rent_charges | One bill per resident per month | period (first of month), amount, due_date; unique(resident_id, period) |
| payments | Money received | charge_id, amount, paid_on, method, receipt_no (unique), note |

Derived (not stored): charge **paid / balance / status** via view `charge_balances`:
`paid` if balance ≤ 0 · `partial` if 0 < paid < amount · `overdue` if balance > 0 and due_date < today · `pending` otherwise.
Occupancy = active residents with a room ÷ total capacity of active rooms.

### 7.2 SQL — run once in Supabase SQL Editor (M1)
```sql
-- ===== Extensions =====
create extension if not exists pgcrypto;

-- ===== Tables =====
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text,
  business_name text,
  trial_started_at timestamptz not null default now(),
  subscription_status text not null default 'trial'
    check (subscription_status in ('trial','active','expired','canceled')),
  subscription_plan text check (subscription_plan in ('monthly','yearly')),
  subscription_expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.properties (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  name text not null,
  address text,
  city text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.rooms (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade,
  room_number text not null,
  floor text,
  capacity int not null check (capacity between 1 and 20),
  default_rent numeric(12,2) not null default 0 check (default_rent >= 0),
  notes text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (property_id, room_number)
);

create table public.residents (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  room_id uuid references public.rooms(id) on delete set null,
  full_name text not null,
  phone text not null,
  cnic text check (cnic is null or cnic ~ '^[0-9]{13}$'),
  guardian_name text,
  guardian_phone text,
  monthly_rent numeric(12,2) not null check (monthly_rent >= 0),
  security_deposit numeric(12,2) not null default 0 check (security_deposit >= 0),
  rent_due_day int not null default 5 check (rent_due_day between 1 and 28),
  join_date date not null default current_date,
  status text not null default 'active' check (status in ('active','left')),
  left_date date,
  notes text,
  created_at timestamptz not null default now()
);

create table public.rent_charges (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  resident_id uuid not null references public.residents(id) on delete cascade,
  period date not null,                      -- always the 1st of the month
  amount numeric(12,2) not null check (amount >= 0),
  due_date date not null,
  created_at timestamptz not null default now(),
  unique (resident_id, period)
);

create sequence public.receipt_seq start 1;

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  resident_id uuid not null references public.residents(id) on delete cascade,
  charge_id uuid not null references public.rent_charges(id) on delete cascade,
  amount numeric(12,2) not null check (amount > 0),
  paid_on date not null default current_date,
  method text not null default 'cash'
    check (method in ('cash','bank_transfer','easypaisa','jazzcash','other')),
  receipt_no text not null unique
    default ('RCT-' || lpad(nextval('public.receipt_seq')::text, 6, '0')),
  note text,
  created_at timestamptz not null default now()
);
grant usage, select on sequence public.receipt_seq to authenticated;

create index on public.rooms (owner_id, property_id);
create index on public.residents (owner_id, status);
create index on public.residents (room_id);
create index on public.rent_charges (owner_id, period);
create index on public.payments (owner_id, paid_on);
create index on public.payments (charge_id);

-- ===== Room capacity guard =====
create or replace function public.enforce_room_capacity() returns trigger
language plpgsql as $$
declare cap int; occ int;
begin
  if new.room_id is null or new.status <> 'active' then return new; end if;
  select capacity into cap from public.rooms where id = new.room_id;
  select count(*) into occ from public.residents
    where room_id = new.room_id and status = 'active' and id <> new.id;
  if occ >= cap then raise exception 'Room is full'; end if;
  return new;
end $$;
create trigger trg_room_capacity
  before insert or update of room_id, status on public.residents
  for each row execute function public.enforce_room_capacity();

-- ===== Auto-create profile on signup =====
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''));
  return new;
end $$;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ===== Balances view =====
create view public.charge_balances with (security_invoker = true) as
select c.*,
       coalesce(sum(p.amount), 0) as paid,
       c.amount - coalesce(sum(p.amount), 0) as balance
from public.rent_charges c
left join public.payments p on p.charge_id = c.id
group by c.id;

-- ===== Dashboard summary =====
create or replace function public.dashboard_summary(
  p_month date default date_trunc('month', current_date)::date)
returns json language sql stable security invoker as $$
  select json_build_object(
    'billed',    coalesce((select sum(amount)  from public.charge_balances where period = p_month), 0),
    'collected', coalesce((select sum(amount)  from public.payments
                           where date_trunc('month', paid_on)::date = p_month), 0),
    'pending',   coalesce((select sum(balance) from public.charge_balances
                           where period = p_month and balance > 0), 0),
    'overdue',   coalesce((select sum(balance) from public.charge_balances
                           where balance > 0 and due_date < current_date), 0),
    'beds_total',    coalesce((select sum(capacity) from public.rooms where is_active), 0),
    'beds_occupied', (select count(*) from public.residents
                      where status = 'active' and room_id is not null),
    'active_residents', (select count(*) from public.residents where status = 'active')
  );
$$;

-- ===== Row Level Security =====
alter table public.profiles enable row level security;
create policy profiles_select_own on public.profiles
  for select to authenticated using (id = (select auth.uid()));
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));

do $$
declare t text;
begin
  foreach t in array array['properties','rooms','residents','rent_charges','payments'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format(
      'create policy %I on public.%I for all to authenticated
         using (owner_id = (select auth.uid()))
         with check (owner_id = (select auth.uid()))',
      t || '_owner_all', t);
  end loop;
end $$;

-- ===== Account deletion (called from the app) =====
create or replace function public.delete_my_account() returns void
language plpgsql security definer set search_path = public, auth as $$
begin
  delete from auth.users where id = auth.uid();   -- cascades to every owned row
end $$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
```
**Security notes to record in `report.md`:** (1) subscription fields are client-writable in the mock phase — before real launch, move verification to a server-side check of Google Play purchase tokens (Supabase Edge Function + Play Developer API). (2) CNIC is stored in a normal text column protected by RLS and Supabase's encryption at rest; it is masked in the UI and never logged. Mention this honestly in the privacy policy. (3) Test RLS: a second test user must never see the first user's data.

### 7.3 Dart models
One immutable class per table with `fromJson`/`toJson` handwritten (no codegen). Keep snake_case ↔ camelCase mapping in the model.

### 7.4 Business rules
- Phone input accepts `03XXXXXXXXX`, `+923XXXXXXXXX`, `923XXXXXXXXX`; **store normalized as `923XXXXXXXXX`** (digits only). Display as `03XX XXXXXXX`.
- CNIC input accepts `XXXXX-XXXXXXX-X` or 13 digits; store 13 digits; display masked.
- Charge generation (UC8): on app start and on resuming after a month change, for each active resident upsert `(resident_id, period=first of month)` with `ignoreDuplicates`; `due_date = period + (rent_due_day − 1) days`. Only for months ≥ join_date's month and ≤ current month; stop for residents with status `left` after left_date's month.
- Payment amount must be > 0 and ≤ current balance of the chosen charge. Default charge = oldest unpaid.
- Mark as left: set `status='left'`, `left_date`, `room_id` stays for history **but** the capacity trigger ignores non-active residents, so the bed is free.
- Subscription state (computed client-side from profile): `trialDaysLeft = 30 − days since trial_started_at`. `isPremium = status=='active' && expires_at > now`. `isTrial = !isPremium && trialDaysLeft > 0`. `isLocked = !isPremium && !isTrial`. When locked: read-only + paywall; allow viewing, PDF/share of existing receipts, settings, **account deletion and privacy policy always available**.

---

## 8. Functional requirements

Priority: **M** = must (needed to ship), **S** = should, **C** = could (only if time remains).

**Authentication & account**
- FR-01 (M) Email+password sign-up with name; profile auto-created; trial begins.
- FR-02 (M) Sign-in, persisted session, sign-out.
- FR-03 (S) Password reset via emailed 6-digit code (Supabase "Reset Password" email template edited to include `{{ .Token }}`; use `verifyOTP(type: recovery)` then `updateUser(password)`).
- FR-04 (M) Delete account via `delete_my_account()` after typed confirmation; then sign out and clear local data and scheduled notifications.
- FR-05 (M) Edit profile (name, phone, business name used in receipts/messages).

**Properties & rooms**
- FR-06 (M) CRUD properties (archive instead of delete when it has residents).
- FR-07 (M) CRUD rooms with capacity, default rent; show occupied/capacity; vacancy filter.

**Residents**
- FR-08 (M) Add/edit resident with fields in 7.1; room picker shows only rooms with free beds (plus the resident's current room).
- FR-09 (M) Resident list with search (name/phone/room) and filters (Active/Left, Dues).
- FR-10 (M) Resident detail: info, masked CNIC (tap-to-reveal for 5 s with confirm), guardian call/WhatsApp buttons, ledger, actions.
- FR-11 (M) Mark as left / reactivate.

**Rent & payments**
- FR-12 (M) Auto-generate monthly charges (7.4).
- FR-13 (M) Rent tab: filters Overdue / Pending / Partial / Paid for the selected month, with month switcher.
- FR-14 (M) Record payment (amount, date, method, note); partial allowed; receipt no. auto.
- FR-15 (M) Resident ledger with running balance.
- FR-16 (S) Edit/delete a payment within 24 h of creation (with confirmation) to fix mistakes.

**Reminders & receipts**
- FR-17 (M) WhatsApp reminder (template 8.1) via `https://wa.me/<number>?text=<url-encoded>` using `url_launcher` external mode. Fallback: copy-to-clipboard.
- FR-18 (M) WhatsApp receipt message after payment.
- FR-19 (M) PDF receipt generated on device (`pdf`), share/print via `printing`.
- FR-20 (S) Guardian reminder button (same template, guardian number) — only if guardian phone saved; owner triggers manually.
- FR-21 (S) Local notifications (09:00 local) for "N rents due today" and "N overdue", rescheduled whenever data changes and on app start; permission requested in context (Android 13+).

**Dashboard**
- FR-22 (M) Cards: Collected, Pending, Overdue (this month/all overdue), Occupancy %, Active residents; recent 5 payments; quick actions (Add resident, Record payment). Pull-to-refresh.

**Monetization**
- FR-23 (M) Trial banner with days left; paywall screen with Monthly and Yearly plans, benefits list, "Restore purchases", terms/privacy links, auto-renew disclosure text.
- FR-24 (M) `BillingService` interface + `MockBillingService` (simulates purchase success/cancel/failure, writes `subscription_status='active'`, plan, `subscription_expires_at`).
- FR-25 (M) Lock behaviour when `isLocked` (7.4).
- FR-26 (S) `PlayBillingService` implemented against `in_app_purchase` with product IDs `premium_monthly` and `premium_yearly` (disabled by a single flag until the Play Console products exist).

**Compliance & settings**
- FR-27 (M) In-app Privacy Policy screen (full text, Section 10.3) + link to the hosted URL.
- FR-28 (M) Settings: profile, subscription status, privacy policy, delete account, sign out, about/version, "Contact support" (mailto).
- FR-29 (S) Light and dark themes following system.

### 8.1 WhatsApp / receipt text templates
Reminder:
```
Assalam o Alaikum {resident_name},
This is a reminder from {business_name}: your rent of Rs {balance} for {month_year} {is_overdue ? "was due on" : "is due on"} {due_date}.
Kindly pay at your earliest convenience. Thank you.
```
Receipt:
```
Receipt {receipt_no} — {business_name}
Received Rs {amount} from {resident_name} for {month_year} on {paid_on} via {method}.
Remaining balance: Rs {balance}.
Thank you.
```
`business_name` falls back to the owner's name. Messages are sent **only when the owner presses send in WhatsApp** (no automation, no bulk blasting — store policy and spam safe).

---

## 9. Non-functional requirements

| ID | Area | Requirement |
|---|---|---|
| NFR-01 | Performance | Cold start < 3 s on mid-range device; list screens paginate or limit to 50 rows per fetch, with infinite scroll; 60 fps scrolling |
| NFR-02 | Size | Play download size 25–60 MB (Section 11) |
| NFR-03 | Security | RLS on all tables; HTTPS only; no secrets in repo; anon key only; no PII in logs; `android:allowBackup="false"`; screenshots of CNIC screen not blocked but CNIC masked by default |
| NFR-04 | Privacy | Collect only needed data; delete-account works; privacy policy accurate; no third-party analytics/ads |
| NFR-05 | Reliability | Graceful errors, retry buttons, no crashes on network loss; idempotent charge generation; double-tap protection on save/pay buttons |
| NFR-06 | Usability | Big touch targets (≥ 48 dp), readable text (≥ 14 sp body), one primary action per screen, English plain language, accessible contrast (WCAG AA) |
| NFR-07 | Compatibility | Android 8.0+ (API 26+) phones; handle small screens (360 dp wide) and large font scale |
| NFR-08 | Maintainability | Layered (UI → provider → repository → Supabase); lints clean; unit tests for pure logic |
| NFR-09 | Compliance | Google Play policies (Section 10) |
| NFR-10 | Observability | Debug-only logging; user-friendly error messages; no crash SDK |
| NFR-11 | Billing abstraction | Swapping mock → Play Billing requires no UI changes |
| NFR-12 | Data integrity | Money checks in both app and DB constraints; capacity enforced by DB trigger |

---

## 10. Store compliance checklist (must pass before release)

### 10.1 Google Play
- Release as **AAB**, signed with an upload key; enroll in Play App Signing.
- **Target API level:** the latest level Play currently requires (check at M7; do not assume). Flutter's default `targetSdk` is usually fine — verify.
- Permissions only: `INTERNET`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` (for re-scheduling notifications), `VIBRATE`. **No** exact-alarm permission (use inexact scheduling), **no** contacts/SMS/call-log/location/storage permissions.
- AndroidManifest `<queries>` for `https` VIEW intents and `com.whatsapp` / `com.whatsapp.w4b` so WhatsApp links resolve.
- **Data safety form:** data collected = name, email, phone numbers (owner, residents, guardians), CNIC (optional), financial info (rent records, no card data); encrypted in transit; user can request deletion; not shared with third parties; not sold.
- **Account deletion:** in-app option (FR-04) **and** a public web page describing how to delete the account/data (Play requires a web link). Host a simple static page (e.g. GitHub Pages) containing the privacy policy and deletion instructions.
- **Subscriptions:** digital features must be sold through Google Play Billing (no external payment links). Show price, billing period, free-trial terms, auto-renew and cancel instructions on the paywall. Provide "Manage subscription" link to Play.
- **Sensitive data:** CNIC is sensitive; collect only if the owner opts in; mask; never include in WhatsApp text, notifications, PDFs or logs.
- **User-generated/third-party data:** residents didn't consent in-app, so the privacy policy must state the owner is responsible for lawful collection of residents' data.
- Content rating: no objectionable content. App must not look like a clone of other apps; unique name/icon/screenshots.
- Provide Play reviewers a **test account** (email/password) and note that email confirmation is disabled or pre-confirmed.
- No misleading claims (do not claim bank-level or military-grade security).

### 10.2 App Store readiness (not building iOS now)
Keep everything compatible: in-app account deletion (guideline 5.1.1(v)), In-App Purchase for subscriptions, privacy policy link, no unused permissions. Do not write Android-only code outside `android/` and the billing/notification services.

### 10.3 Privacy policy contents (draft in `lib/features/settings/privacy_policy.dart`, plain text)
Who we are · data collected (account, residents' contact details, CNIC if entered, rent records) · why (provide the service) · storage (Supabase, encrypted in transit and at rest) · sharing (none sold; processors: Supabase, Google Play for billing) · WhatsApp messages are sent by the owner through their own WhatsApp · retention and deletion (in-app + web page) · owner's responsibility for residents' data · children (not for under-18 users) · contact email (Human to provide) · last-updated date.

---

## 11. Size strategy (25–60 MB on Play)
A lean Flutter app is usually ~12–20 MB; the target floor of 25 MB is reached **honestly** with real assets, not junk files.
- Bundle fonts locally (two families, 3–4 weights each) — no `google_fonts` runtime download.
- Include real assets: onboarding/empty-state illustrations (WebP), 2–4 small Lottie animations (success, empty, paywall), app icon set, receipt logo.
- `printing`, `in_app_purchase`, `flutter_local_notifications` add native code.
- Release with R8 minify + resource shrinking enabled, `--obfuscate --split-debug-info=build/symbols` (keep symbols out of git), tree-shaken icons (default).
- **Measure, don't guess** (M7): `flutter build appbundle --release --analyze-size`, and install-size check with `bundletool build-apks … && bundletool get-size total --apks=…`. Report numbers in `report.md`. If below 25 MB add more legitimate assets (extra illustration sets, additional font weights); if above 60 MB, compress images to WebP and remove unused assets.
- Never add dummy/padding files.

---

## 12. Milestones (ordered by importance/criticality)

Each milestone ends with the **stop gate** (0.2 rule 2). Rough time box is a guide; if time is short, the Lead must warn the Human early and cut from **C/S** items first, never from **M** items.

### M0 — Foundation (≈ 45 min) — *everything depends on it*
- `flutter create` (org/app id: `com.arabi.hostelhub` — Human to confirm), `git init`, `.gitignore` (add `env.json`, `key.properties`, `*.jks`, `build/symbols`).
- Add packages (Section 6.1), folder structure (6.2), theme (Section 14), router skeleton with bottom navigation placeholders, `Env` loader, `strings.dart`, shared widgets.
- **Human manual step:** create Supabase project, copy URL + anon key to `env.json` (Lead gives exact click path). Disable "Confirm email" under Auth → Providers → Email for development/testing.
- Acceptance: `flutter analyze` clean; app launches to a themed placeholder shell on a device/emulator; missing-config screen works.

### M1 — Auth + Database + Security (≈ 90 min) — *critical*
- Human runs the SQL (7.2). Executor builds models, repositories base, `auth_repo`, login/signup screens, session persistence, router redirect, sign-out, profile fetch.
- Acceptance: sign up → profile row exists with `trial_started_at`; login persists after restart; **RLS test with two accounts** shows isolation; invalid input handled.

### M2 — Properties & Rooms (≈ 60 min)
- FR-06, FR-07 with occupancy display and states.
- Acceptance: create property + 3 rooms, duplicates blocked, edits persist, empty/error/loading states present.

### M3 — Residents (≈ 90 min)
- FR-08 – FR-11 with phone/CNIC utils + unit tests, room picker, masked CNIC, guardian fields, search/filters.
- Acceptance: capacity trigger error shown friendly; left residents free beds; unit tests pass.

### M4 — Rent & Payments (≈ 90 min) — *core value*
- FR-12 – FR-15 (+ FR-16 if time), charge generation, balances view usage, record payment, ledger.
- Acceptance: month of data produces correct statuses (paid/partial/pending/overdue); partial payments sum correctly; duplicate charge generation impossible; unit tests for status logic.

### M5 — Reminders & Receipts (≈ 60 min)
- FR-17 – FR-19 (FR-20 if time): WhatsApp service with number normalization and fallback, templates, PDF receipt builder, share/print.
- Acceptance: tapping Remind opens WhatsApp chat with correct text on a real phone; PDF opens with correct data; no CNIC anywhere.

### M6 — Monetization (≈ 75 min) — *required revenue feature*
- FR-23 – FR-26 (stub real billing), trial banner, paywall, lock behaviour, subscription provider, restore purchases (mock).
- Acceptance: new account shows 30 days; manually setting `trial_started_at` to 31 days ago locks writes and shows paywall; mock purchase unlocks; billing flag cleanly switchable.

### M7 — Compliance & Release Build (≈ 75 min) — *required to ship*
- FR-04, FR-05, FR-27, FR-28 complete; manifest permissions audit; app icon + splash; `key.properties` + signing config; R8/shrink; size measurement (Section 11); privacy policy hosting page text; Data safety answers file `store_listing.md` (short + long description, screenshots list, data-safety answers, test account notes).
- Human manual step: generate upload keystore (Lead provides the exact `keytool` command), keep it safe and backed up.
- Acceptance: `flutter build appbundle --release --dart-define-from-file=env.json` succeeds; release APK installs and passes the smoke test (Section 15); size recorded.

### M8 — Dashboard, Notifications & Polish (≈ 90 min)
- FR-22 dashboard (could be a stub from M1 until now), FR-21 notifications, FR-29 dark mode, FR-03 password reset, animations, empty states, accessibility pass, error-message cleanup, final size re-check.
- Acceptance: dashboard totals match DB; notification fires on test schedule; no overflow at 360 dp / large fonts.
> If the clock runs short, the Lead may move the **dashboard** forward into M2–M3 as a simple version, but must never skip M6 or M7.

### Final (after M8)
Lead produces final `report.md`, release checklist, and Play Console upload steps (internal testing track first).

---

## 13. report.md protocol

Create `report.md` at M0 and **update it at every stop gate**. Template:

```markdown
# HostelHub — Progress Report
Last updated: <date time> | Current milestone: M<n> | Overall: <x>% (<done>/<total> milestones)

## Milestone status
| ID | Name | Status (Not started / In progress / Done / Blocked) | Verified how |
|----|------|------|------|

## Completed in this milestone
- <feature/FR ids> — what was built, where (file paths)

## Verification
- flutter analyze: <result>   - flutter test: <x passed / y failed>   - debug APK built: <yes/no>
- Manual tests performed on device: <list>

## Mocked / partial / skipped (be honest)
- ...

## Open issues & risks
- ...

## Decisions & assumptions log
- <date> — <decision> — <why>

## Size & performance notes (from M7)
- AAB size, estimated download size, startup time

## Manual steps pending for the Human
- ...

## Suggestions (not implemented, need approval)
- ...

## Next milestone preview
- M<n+1>: <name> — what will be built — estimated time
```
After writing it, ask: **"Milestone N complete. Continue to Milestone N+1? (yes / change something / pause)"** and wait.

---

## 14. UI & design system

**Positioning:** trustworthy, calm, money-aware, uniquely "Pakistani hostel owner" friendly — not a generic blue SaaS look.

### 14.1 Palette (light)
| Token | Hex | Use |
|---|---|---|
| primary | `#0F766E` (deep teal) | App bars, primary buttons, active nav |
| primaryDark | `#134E4A` | Gradient end, headers |
| primaryContainer | `#D7F0EC` | Soft fills, selected chips |
| accent (gold) | `#C9922E` | Money highlights, premium badge, paywall CTA accents |
| background | `#F5F8F7` | Screen background |
| surface | `#FFFFFF` | Cards |
| ink | `#10201D` | Primary text |
| muted | `#5F706B` | Secondary text |
| outline | `#DCE5E2` | Dividers, borders |
| success (paid) | `#15803D` on `#DCFCE7` | Paid chip |
| warning (pending/partial) | `#B45309` on `#FEF3C7` | Pending / partial chip |
| danger (overdue) | `#B91C1C` on `#FEE2E2` | Overdue chip, destructive |

### 14.2 Palette (dark)
background `#0B1513` · surface `#12211E` · surface2 `#18302B` · primary `#2DD4BF` · accent `#E0AE4E` · ink `#E6F2EF` · muted `#93A9A3` · outline `#23403A`; status colors use the same hues with dark-tinted backgrounds.

### 14.3 Rules
- Use `ColorScheme.fromSeed` seeded with primary, then override with the tokens above. Material 3 enabled.
- Signature elements: a **teal→deep-teal gradient summary card** on the dashboard (white text, gold amount underline), status chips with the colors above, generous 16–20 dp radii, soft elevation (≤ 2), 8-dp spacing grid.
- Typography (bundled fonts): headings **Plus Jakarta Sans** (600/700), body **Inter** (400/500). Amounts use tabular figures (`FontFeature.tabularFigures()`), prefix `Rs`.
- Gold is an accent only (≤ 10% of any screen). Never use red except overdue/destructive.
- Icons: Material Symbols Rounded (built-in `Icons.*_rounded`).
- Empty states: illustration + one sentence + one button. Loading: skeleton/shimmer-like simple placeholders (no extra package).
- Buttons: filled for primary, tonal for secondary, text for tertiary. Minimum height 48 dp.
- Paywall: dark teal gradient, gold CTA, clear price + period + trial/renewal text, no dark patterns, visible close/“Not now” (while the trial is still active).
- Keep the app icon simple: white rounded “H” + key/door motif on teal; adaptive icon.

---

## 15. Testing & definition of done

**Per-milestone DoD:** all milestone ACs met · `flutter analyze` 0 issues · `flutter test` passes · debug APK builds · no secrets committed · `report.md` updated · Human approved.

**Unit tests (pure logic, M3–M6):** phone normalize/format, CNIC validate/mask, charge status derivation, due-date calc, subscription state calc, WhatsApp URL builder, template rendering.

**Release smoke test (M7, on a real phone with the release build):**
1. Fresh install → sign up → land on Dashboard with "30 days left".
2. Add property, 2 rooms, 2 residents (one with CNIC + guardian).
3. Confirm this month's charges exist; record a full and a partial payment.
4. Send WhatsApp reminder and receipt; open PDF.
5. Kill/restart app → still signed in.
6. Set trial to expired (SQL) → locked state + paywall → mock subscribe → unlocked.
7. Second account cannot see first account's data.
8. Delete account → data gone → login fails.
9. Airplane mode → friendly errors, no crash.

---

## 16. Manual steps for the Human (Lead must walk through these with exact clicks)
1. Create Supabase project → copy Project URL + anon key → `env.json`.
2. Auth settings: disable email confirmation for dev; (optional, FR-03) edit the Reset Password email template to include `{{ .Token }}`.
3. Run SQL from 7.2 in the SQL Editor; verify tables + RLS enabled.
4. Create upload keystore (`keytool`), create `android/key.properties`, back both up outside the repo.
5. Host privacy policy + deletion page (GitHub Pages or similar) and provide the URL + support email.
6. Google Play Console (when ready): create app, App content forms (Data safety, privacy URL, content rating, target audience 18+), create subscriptions `premium_monthly` / `premium_yearly` (needed before enabling real billing), upload AAB to Internal testing, add test account details.

---

## 17. Out of scope (do NOT build)
Resident login/portal · online payment gateways (JazzCash/Easypaisa APIs) · automatic/bulk WhatsApp sending · WhatsApp Business API · SMS · multi-language/Urdu UI · iOS build · web/desktop · offline sync · expense tracking/accounting · staff accounts/roles · Firebase/analytics/ads · complex reports/exports (CSV/Excel) · in-app chat.
These may be listed under `report.md → Suggestions` only.

---

## 18. Quick glossary
PG = paying guest accommodation · CNIC = Pakistani national ID (13 digits) · RLS = Row Level Security · AAB = Android App Bundle · PKR = Pakistani rupee (`Rs`).
