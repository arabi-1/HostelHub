# HostelHub — Google Play Store Listing & Compliance Metadata

## 1. Store Listing Details

### App Title
**HostelHub: PG & Rent Manager**
*(30 characters / 30 max)*

### Short Description
**Manage hostels & PGs in Pakistan: residents, rent dues, ledgers & PDF receipts.**
*(79 characters / 80 max)*

### Full Description
HostelHub is the premier hostel and paying guest (PG) management application built specifically for property managers, hostel owners, and landlords across Pakistan. Simplify resident onboarding, bed occupancy tracking, monthly rent collection, running ledgers, and receipt generation with a secure, offline-friendly interface priced in whole Pakistani Rupees (PKR).

**KEY FEATURES:**

🏠 **Property & Room Management**
• Organize multiple properties and buildings under a single account.
• Track floor-by-floor room capacities, default rent rates, and live bed occupancy.
• Instant vacancy filtering helps you find available beds in seconds.
• Smart protections prevent accidental room duplication or over-allocation.

👥 **Resident Profiles & Identity Protection**
• Complete resident directory with join dates, room assignments, and guardian contacts.
• Built-in Pakistani phone normalization (`03XX XXXXXXX`).
• Secure CNIC management: 13-digit validation with default privacy masking (`•••••-•••••XX-X`) and timed 5-second tap-to-reveal verification.
• Bed auto-freeing when residents check out, with permanent ledger preservation.

💰 **Automated Rent & Chronological Ledgers**
• Idempotent monthly rent charge generation for all active residents.
• Flexible payment recording: full and partial payments across Cash, Bank Transfer, Easypaisa, and JazzCash.
• Chronological running ledger (debits vs credits) with clear outstanding balances.
• 24-hour payment edit and deletion window to easily fix accidental data entry mistakes.

📄 **1-Tap WhatsApp Reminders & PDF Receipts**
• Preformatted WhatsApp rent reminders and payment receipts sent via your installed WhatsApp app with one tap.
• Zero CNIC leakage: sensitive national identification is never included in reminder texts or receipts.
• Generate, share, or print professional A5 PDF receipts directly from your phone.
• Optional guardian reminders keep families informed of pending dues.

🔒 **Enterprise-Grade Security & Privacy**
• Built on PostgreSQL with Row Level Security (RLS) ensuring strict tenant isolation.
• Encrypted data in transit (HTTPS / TLS 1.3) and at rest.
• Full in-app account deletion that permanently wipes all properties, residents, and ledgers in one click.

---

## 2. Google Play Data Safety Questionnaire Answers

| Question | Answer |
|---|---|
| **Does your app collect or share user data?** | Yes |
| **Is all user data encrypted in transit?** | Yes (HTTPS / TLS 1.3) |
| **Do you provide a way for users to request data deletion?** | Yes (In-app deletion cascades all data immediately; support email provided) |
| **Is this app intended for children under 13?** | No (Target audience: 18+ property owners) |

### Data Types Collected:
1. **Personal Info:**
   - **Name:** Collected for account creation and resident tracking. (App functionality, Account management)
   - **Email address:** Collected for owner account authentication. (App functionality, Account management)
   - **Phone number:** Collected for owner profile, resident contacts, and guardian communication. (App functionality)
   - **National ID / CNIC:** Optional. Collected solely if owner chooses to record resident verification details. Stored encrypted and masked. (App functionality)
2. **Financial Info:**
   - **Purchase history:** In-app subscription tier via Google Play Billing. (Account management, Fraud prevention)
   - **Other financial info:** Rent amounts due, payment records, dates, and payment methods. No credit card or bank account numbers are ever collected or stored. (App functionality)

### Data Sharing:
- **Data Shared:** None. User data is never sold or shared with third-party advertisers or data brokers.
- **Service Processors:** Supabase Inc. (cloud database & auth) and Google Play (subscription billing).

---

## 3. Google Play Reviewer Test Credentials & Instructions

- **Test Account Username:** `tester@hostelhub.app`
- **Test Account Password:** `HostelHubTest2026!`
- **Authentication Note:** Email confirmation is pre-verified. The reviewer can sign in immediately without email confirmation.
- **Monetization / Subscription Testing:**
  - New accounts receive an automatic 30-day full-access free trial.
  - The in-app purchase flow operates via `BillingService`. In debug/review builds, the Paywall includes a 1-tap "Start Subscription" action that updates the subscription status to active immediately without requiring live Google Play payment methods.
- **Contact Support:** `support@hostelhub.app`
