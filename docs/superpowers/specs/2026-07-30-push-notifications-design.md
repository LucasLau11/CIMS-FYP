# OS push notifications (Android)

## Context

CIMS already has an in-app notifications system: a `notifications` table
(`user_id, title, body, type, related_id, read, created_at`), a
`notify_student` RPC that staff roles use to write rows into it (e.g. on
application status changes), and a per-role `StudentNotificationsScreen`
(reused across roles despite the name) that lists them. There's a
separate `messages`/`conversations` chat system. None of this reaches the
device's actual notification bar — a user only sees any of it while the
app is open and they navigate to the right screen.

The ask: deliver real OS-level push notifications (system tray, works
even when the app is backgrounded or closed), covering everything that
already generates an in-app notification, plus new chat messages.

This project has an established zero-billing constraint (see
`resume_parser_nlp_deferred` memory / the NLP hosting decision) — every
piece of this design was checked against that before being proposed.

## Decisions made during brainstorming

- **Trigger scope**: everything that already writes to `notifications`,
  plus new `messages` rows. (Not narrowed to chat-only, not a custom
  subset.)
- **Platforms**: Android only. iOS push requires enrollment in Apple's
  Developer Program ($99/year) for APNs keys — an Apple platform
  requirement, unrelated to which push provider is used. The user does
  not currently have this and chose to defer iOS rather than pay for it.
- **Delivery provider**: OneSignal, not a hand-rolled FCM integration.
  Both are free at this project's scale (OneSignal free tier: unlimited
  notifications, 10k subscribers). OneSignal was chosen over calling FCM
  directly because it removes the need to generate/rotate a Firebase
  service-account key and hand-sign JWTs — one REST API key instead.
  Confirmed via Supabase docs search: Database Webhooks and Edge
  Functions (the two pieces of Supabase infra this depends on) are both
  free-tier GA features, not paid add-ons.
- **Out of scope for this pass**: iOS; wiring the existing
  `notification_prefs` per-category toggle (currently stored on
  `profiles` but not enforced anywhere server-side) to actually gate
  which pushes get sent; suppressing a push when the recipient is already
  looking at that exact chat screen.

## Architecture

```
notifications/messages INSERT
        |
        v
Supabase Database Webhook (pg_net-based, free)
        |
        v
Edge Function: send-push-notification
        |  (resolves recipient, builds payload)
        v
OneSignal REST API -> FCM -> Android notification tray
```

No new Supabase table for device tokens. The OneSignal Flutter SDK links
each installed device to the logged-in Supabase user via
`OneSignal.login(supabaseUserId)` (an "External ID"); the Edge Function
targets that same ID via `include_external_user_ids` when calling
OneSignal's REST API. OneSignal owns the device-token bookkeeping.

## Components

### 1. Database Webhooks (Supabase dashboard config, not app code)

Two webhooks, both pointed at the same Edge Function:
- `INSERT` on `public.notifications` → payload `{ source: 'notification', record }`.
- `INSERT` on `public.messages` → payload `{ source: 'message', record }`.

### 2. Edge Function `send-push-notification`

- For `source: 'notification'`: recipient is `record.user_id`. Title/body
  come straight from `record.title`/`record.body`.
- For `source: 'message'`: look up `record.conversation_id` in
  `conversations` to find the other participant (excluding
  `record.sender_id`, so the sender never gets pushed their own message).
  Title is the sender's name (looked up from `profile_directory`), body
  is the message text (truncated to a reasonable length).
- Both cases: call OneSignal's REST API
  (`POST https://onesignal.com/api/v1/notifications`) with
  `include_external_user_ids: [recipientId]` and a `data` payload
  carrying enough to deep-link (`type`, `related_id` for notifications;
  `conversation_id` + other participant's profile for messages).
- OneSignal App ID and REST API Key stored as Edge Function secrets
  (`ONESIGNAL_APP_ID`, `ONESIGNAL_REST_API_KEY`) — never shipped in the
  Flutter app.

### 3. Flutter app (`onesignal_flutter` package)

- Initialize with the OneSignal App ID in `main.dart` at startup.
- Request Android notification permission (required on Android 13+/API
  33+) once, the first time a user is signed in.
- Call `OneSignal.login(userId)` right after a successful sign-in
  (wherever `AuthService` currently establishes a session); call
  `OneSignal.logout()` on sign-out — otherwise a device that's later
  reused by a different account would keep receiving the previous user's
  pushes.
- Notification-tap handling (OneSignal's click listener): if the payload
  has a `conversation_id`, push `ChatScreen` directly (same widget
  already used everywhere else — `student_messages_screen.dart`).
  Otherwise, open the existing shared in-app notifications screen
  (`StudentNotificationsScreen`, already reused across all roles).

### 4. One-time external setup (not code, but required before this works)

1. Create a free OneSignal account + one "App" (Android platform).
2. Create a Firebase project (free Spark plan) purely to get Cloud
   Messaging credentials — no Firebase SDK/code in the Flutter app itself,
   just linking those credentials in OneSignal's dashboard.
3. Add the OneSignal App ID to the Flutter app's init call.
4. Store the OneSignal REST API Key as a Supabase Edge Function secret.

## Error handling

- Edge Function failures (OneSignal API error, missing recipient, etc.)
  must not roll back or block the underlying `INSERT` — Database Webhooks
  are already fire-and-forget/async (`pg_net`), so this is automatic, but
  the function should still log failures rather than throwing unhandled.
- If a user has never opened the app on Android (no OneSignal
  subscription yet) or denied the permission prompt, OneSignal simply
  won't deliver — no special-casing needed on our side.
- Missing/deleted conversation participant on a `messages` webhook (edge
  case, shouldn't normally happen given existing RLS) → function no-ops
  rather than erroring.

## Testing / verification

- End-to-end on a real Android device or emulator with Google Play
  services: sign in, background the app, trigger an event that already
  creates an in-app notification (e.g. an HR status update or a
  supervisor report review) and a new chat message from another account,
  confirm both arrive in the system tray with correct title/body, and
  that tapping each lands on the right screen.
- Confirm `OneSignal.logout()` on sign-out by signing in as a second
  account on the same device and checking the first account's
  in-flight notifications don't arrive there.
- Edge Function: check Supabase function logs after each test event to
  confirm the OneSignal API call succeeded (or see the logged failure
  reason if not).
