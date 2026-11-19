# Tutor-feedback changes — Design

**Status:** Approved by the user, 2026-11-03. Built in the phase order below.
**Source:** consultation with the FYP tutor; nine requested changes.

## Decisions (from the user)

| Question | Decision |
|---|---|
| Who owns interview slots? | **Company HR** owns availability and runs interviews. The company supervisor is not involved in interviewing. |
| Parent acknowledgement without parent accounts | **Parent signs on the student's phone** (signature pad), form opened from the student's own screen. |
| Offers | A student may **hold several offers**; accepting one makes it `active` and every other open application becomes unavailable. Only one active application per student. |
| Password reset | **6-digit code typed into the app.** |
| Login email check | Format only while typing (existence check would enable account enumeration). Wrong password shows on submit. |
| Cancel / reschedule | Either side acts immediately, **reason mandatory**, other side sees it and is notified. No approval step. |
| ngrok | Unchanged (current solution). URL editor works in debug builds only. |

## Phase 1 — Password reset and live validation (items 1, 2)

Diagnosis of item 1 (verified from Supabase auth logs): the app's `/recover` call succeeds
(HTTP 200) but (a) Supabase answers 200 for unknown / unconfirmed emails and the app always
said "link sent"; (b) the default Supabase email service only delivers to project team
members at a very low rate; (c) even a delivered link pointed at `localhost:3000` and the app
had no screen to receive it. Fix: in-app code flow + custom SMTP (dashboard step for the user).

- `Validators` (pure, unit-tested): email, password (+ live checklist), confirm password,
  full name, Malaysian phone, date of birth, CGPA, semester, money, lengths, required,
  future date/time, date ordering, 6-digit code.
- `ValidatedField`: live validation after first interaction, inline message, tick when valid.
- Reset flow: email -> 6-digit code -> new password -> sign out -> login. 60 s resend timer.
- Apply live validation to every form that takes meaningful input. Pure search boxes and the
  chat box are excluded (chat: send disabled while empty).

## Phase 2 — Rejection reason and one accepted offer (items 5, 6) — BUILT

- `applications.rejection_reason` (required, 10–500 chars) when status = `rejected`; enforced by a
  CHECK constraint and by the `applications_guard` trigger.
- New status `offered` (HR "Make offer") and `unavailable` (closed because another offer was accepted).
  Life cycle: `pending -> interview -> offered -> active`; HR may reject from pending/interview/offered.
- `accept_offer(application_id)` RPC: atomic (locks the student's rows); sets chosen to `active`,
  all other open applications to `unavailable`, notifies the affected companies' HR.
- Partial unique index: one `active` application per student.
- Existing data: the test student's 3 `active` rows -> kept the most recently updated, the other
  two became `unavailable`. The one old rejected row got a placeholder reason.
- Security fix found on the way: the old UPDATE policy let a student (or a company supervisor) set
  any application column, including `status = 'active'`. `applications_guard` now allows status
  changes only for the company's HR (and admin), restricts withdrawal to `pending`, locks the
  application's identity columns, and blocks new applications once the student has an active one.
- Not built (not asked): a student "decline offer" button. A student simply leaves an offer unanswered
  or accepts a different one.
- Messages are English only (as with Phase 1 validation).

## Phase 3 — Interview slots, cancel and reschedule (items 3, 4) — BUILT

Built as designed below (migration `00027`, checks in `supabase/tests/interview_slots_check.sql`).
Decisions made while building:
- HR picks the slot when scheduling; the student picks from the same interviewer's free slots when
  rescheduling. One interview row per application; a cancelled interview is re-booked by HR (same row,
  history in `interview_changes`). The application stays `interview` while its interview is cancelled.
- All writes to `interviews` go through the three RPCs; the old client INSERT/UPDATE/DELETE policies were dropped.
- Rejecting an application, or the student accepting another offer, cancels its scheduled interview
  automatically (`auto_cancelled`); making an offer marks it `completed`.
- Slot lead time: nothing is offered within the next hour. Slot lengths: 15/20/30/45/60/90/120 min.
- Dev data: the existing test HR has Mon–Fri 09:00–12:00 and 14:00–17:00 (30 min) so the flow can be tried.

### Original design

- `hr_availability` (weekly windows, several per weekday, slot length), `hr_unavailable_dates`.
- Free slots are computed (rules minus booked minus past minus blocked), timezone Asia/Kuala_Lumpur.
- `interviews`: add interviewer, status (`scheduled`/`cancelled`/`completed`), end time;
  exclusion constraint prevents overlapping bookings for one interviewer (race-safe).
- `interview_changes` history: action, actor, reason (mandatory for cancel/reschedule), old/new time.
- RPCs `book_interview`, `reschedule_interview`, `cancel_interview` (atomic, authorisation inside).
- Cancellation cutoff: 2 hours before the interview.

## Phase 4 — Remove the parent role (item 9) — BUILT (data deletion awaiting confirmation)

- App: parent sign-up option, shell, dashboard, linking, progress screens, `ParentDataService`, parent-link
  notifications and the parent contact in the student directory are removed (`UserRole.parent` is gone).
- The acknowledgement form moved to the student's Documents tab (`ParentAcknowledgementScreen`, now in
  `screens/student/`): a hand-over notice, the parent fills in and signs on the student's phone, the submission is
  stored under the student's own account.
- Migration `00028` (applied): every function/policy that mentioned parents rewritten; sign-up no longer creates
  parents; `find_student_for_link` dropped. Non-destructive.
- Migration `00029` (written, dry-run tested and rolled back, **not applied**): deletes the parent account(s), their
  links, their conversations/messages and notifications, drops `parents`/`parent_child_links`/`is_approved_parent_of`
  and removes the values from the role and notification-type constraints. Needs the user's confirmation.
- Report impacts (not edited): use-case/functional requirement for the Parent actor, the ERD (`parents`,
  `parent_child_links`, and the new `hr_availability`, `hr_unavailable_dates`, `interview_changes`,
  `interviews` columns, `applications.rejection_reason`/statuses), activity diagrams for apply/interview/offer.

### Original design

- Remove parent sign-up, shell, dashboard, linking, notifications and permissions.
- Student opens the Parent Acknowledgement form from their own screen; parent signs on the phone.
- **Destructive step (drops the parent account, `parents`, `parent_child_links`) needs the user's
  explicit confirmation immediately before it runs.**

## Phase 5 — Role themes (item 8) — BUILT

- `RolePalette` (in `theme/app_theme.dart`): student = royal blue + pencil-yellow accent, academic supervisor =
  plum, company supervisor = copper, admin = slate; HR and the signed-out screens keep the original teal.
  Page/card/border/text neutrals are derived from each primary's hue, in light and dark mode. Status colours
  (green/amber/red) are the same for every role.
- `AppColors.primary` & co. are now getters reading the active palette (about 150 `const` usages were converted
  mechanically). `RoleController` (`theme/role_theme.dart`) is set by `AuthService` on sign-in / session restore
  and cleared on sign-out; `main.dart` rebuilds the app on change, like a theme change.
- Header artwork: `RoleHeaderBackground` draws a role-specific icon pattern (books/pencils/school for students,
  clipboard/gown for the academic supervisor, people/badges for HR, hard hat/tools for the company supervisor,
  control-panel icons for admin) over the gradient on every dashboard and `GradientAppBar`.
- Bottom-navigation icons are role-specific (e.g. student: school, travel_explore, assignment_ind, menu_book).
- Tests check contrast (white-on-primary, text on backgrounds, light and dark) and that role switches update the colours.

### Original design

- Per-role palette, header artwork and icon set, drawn in code (no stock photos).
- `AppColors` already uses brightness-aware getters, so `primary` etc. can become role-aware getters.
