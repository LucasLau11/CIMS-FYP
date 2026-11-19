# CIMS — Centralized Internship Management System

A mobile app (Flutter, Android) that brings TARUMT's internship process into
one place: students find and apply for internships, companies post roles and
run interviews, supervisors review reports and evaluate students, and
administrators run the programme.

Final Year Project — Tunku Abdul Rahman University of Management and Technology.

## Roles

| Role | What they do |
|---|---|
| Student | Profile and resume (with autofill), search and apply, track applications, accept one internship offer, reschedule or cancel interviews (with a reason), submit reports and forms (the parent signs the acknowledgement form on the student's phone), chat, review companies |
| Academic supervisor | Review reports and documents, evaluate students, chat |
| Company HR | Post internships, review applicants (a reason is required to reject), set interview availability and book free slots, make offers, upload offer letters, sign acceptance letters, see recommended candidates |
| Company supervisor | Review interns' reports and evaluate them |
| Administrator | Create student accounts (one by one or from a CSV list; each gets a random temporary password that the student must change at first login), approve supervisor/company accounts, manage companies, intakes, document templates, supervisor assignment; see system-wide reports |

Supervisor and company accounts register themselves but stay **pending** (no
access to any data) until an administrator approves them in
*More › Pending approvals*.

## Tech stack

- **App:** Flutter / Dart (Android)
- **Backend:** Supabase — Postgres with row-level security, Auth, Storage, Edge Functions
- **Push notifications:** OneSignal + Firebase Cloud Messaging
- **Resume autofill:** Python service in `nlp_service/` (spaCy) with an on-device regex fallback

## Running the app

```bash
flutter pub get
flutter gen-l10n
flutter run
```

The Supabase URL and the *publishable* key are in `lib/main.dart`. The
publishable key is designed to be public; access is enforced by row-level
security, not by hiding the key. **Never** put a `service_role` key or a
OneSignal REST key in the app — those live only in Supabase Edge Function
secrets (`ONESIGNAL_APP_ID`, `ONESIGNAL_REST_API_KEY`).

## Database

All schema changes are numbered SQL files in `supabase/migrations/`. Security
rules (role protection, who can read whose profile, staff approval, account
anonymisation) are in `00023` and `00024`.

To re-check the security rules against your database, paste
`supabase/tests/rls_security_check.sql` into the Supabase SQL editor. It
impersonates each role, tries the attacks the rules should stop, and prints
PASS/FAIL per rule. It rolls back, so it changes nothing.

`supabase/seed.sql` creates demo accounts with a shared password — local,
throwaway databases only.

## Tests and checks

```bash
flutter analyze
flutter test
```

CI (`.github/workflows/ci.yml`) runs both on every push.

## Building a release

A release APK must be signed with your own key — **keep it safe and back it up;
you cannot publish updates without it.**

```bash
keytool -genkey -v -keystore %USERPROFILE%\cims-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then create `android/key.properties` (it is gitignored — never commit it):

```properties
storePassword=<your keystore password>
keyPassword=<your key password>
keyAlias=upload
storeFile=C:\\Users\\<you>\\cims-upload.jks
```

```bash
flutter build apk --release
```

Without `key.properties` the release build falls back to the debug key. That
is fine for testing on your own phone but **must not be published**.

Before publishing, also replace the application id `com.example.fyp_cims`
with your own (this requires registering the new id in Firebase and
replacing `android/app/google-services.json`).

## Privacy

The in-app privacy notice is `lib/screens/privacy_policy_screen.dart`. Users
can delete (anonymise) their account from their profile; see
`anonymise_my_account()` in migration `00024`. Add a real contact address to
the notice before publishing.
