import { createClient } from 'jsr:@supabase/supabase-js@2';

const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID')!;
const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY')!;
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// This function is a database webhook target with verify_jwt = false (the
// Postgres trigger cannot attach a user JWT), so ANYONE on the internet can
// call it. It therefore never trusts the request body: it only reads the
// row's id from the payload, re-loads that row from the database with the
// service role, and builds the push from the stored values. A forged request
// cannot push anything that was not really inserted, and a row is only
// pushed within a short window after it was created, so old rows cannot be
// replayed.
const MAX_AGE_MS = 2 * 60 * 1000;
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const recentlyHandled = new Map<string, number>();

function alreadyHandled(key: string): boolean {
  const now = Date.now();
  for (const [k, t] of recentlyHandled) {
    if (now - t > MAX_AGE_MS) recentlyHandled.delete(k);
  }
  if (recentlyHandled.has(key)) return true;
  recentlyHandled.set(key, now);
  return false;
}

function isFresh(createdAt: unknown): boolean {
  if (typeof createdAt !== 'string') return false;
  const age = Date.now() - new Date(createdAt).getTime();
  return age >= -5000 && age <= MAX_AGE_MS;
}

interface WebhookPayload {
  type?: string;
  table?: string;
  record?: Record<string, unknown>;
}

async function sendOneSignalPush(
  externalUserId: string,
  title: string,
  body: string,
  data: Record<string, unknown>,
) {
  // OneSignal's Nov 2024 key rotation replaced the legacy REST API Key
  // (Basic auth) with App API Keys prefixed `os_v2_app_` (Key auth) --
  // detect which one we were handed so this keeps working either way.
  const authScheme = ONESIGNAL_REST_API_KEY.startsWith('os_v2_app_') ? 'Key' : 'Basic';
  const response = await fetch('https://onesignal.com/api/v1/notifications', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `${authScheme} ${ONESIGNAL_REST_API_KEY}`,
    },
    body: JSON.stringify({
      app_id: ONESIGNAL_APP_ID,
      include_external_user_ids: [externalUserId],
      channel_for_external_user_ids: 'push',
      headings: { en: title },
      contents: { en: body },
      data,
      // High priority tells FCM to wake the device immediately instead of
      // batching delivery for later (Android defers "normal" priority
      // messages when the device is idle/Doze mode, which can add minutes
      // of delay).
      priority: 10,
    }),
  });
  const text = await response.text();
  if (!response.ok) {
    console.error(`OneSignal API error (${response.status}): ${text}`);
    return;
  }
  // OneSignal answers 200 even when nobody was reachable: `recipients` is how many
  // devices it queued the push for, and `errors` explains why it queued none
  // (for example "All included players are not subscribed").
  try {
    const result = JSON.parse(text) as { id?: string; recipients?: number; errors?: unknown };
    if (!result.recipients) {
      console.error(`OneSignal queued the push for 0 devices (user ${externalUserId}): ${text}`);
    } else {
      console.log(`push sent to ${result.recipients} device(s) for user ${externalUserId}: ${title}`);
    }
  } catch (_) {
    console.log(`OneSignal replied: ${text}`);
  }
}

// Which switch in the user's notification preferences controls a notification
// type. Types not listed here (documents, system notices...) always push.
const PREF_FOR_TYPE: Record<string, string> = {
  application: 'application_updates',
  interview_request: 'application_updates',
  interview_reminder: 'application_updates',
  offered: 'application_updates',
  offer_letter: 'application_updates',
  report: 'report_deadlines',
  reports: 'report_deadlines',
  evaluation: 'supervisor_feedback',
  message: 'messages',
};

/** False when the person switched this kind of alert off in their profile. The
 *  in-app notification is still stored; only the phone alert is skipped. */
async function pushAllowed(userId: string, prefKey: string | undefined): Promise<boolean> {
  if (!prefKey) return true;
  const { data, error } = await supabase.from('profiles').select('notification_prefs').eq('profile_id', userId).maybeSingle();
  if (error || !data) return true;
  const prefs = (data.notification_prefs ?? {}) as Record<string, unknown>;
  return prefs[prefKey] !== false;
}

async function handleNotificationInsert(notificationId: string) {
  if (alreadyHandled(`n:${notificationId}`)) return;
  const { data: row, error } = await supabase
    .from('notifications')
    .select('user_id, title, body, type, related_id, created_at, msg_key, msg_args')
    .eq('notification_id', notificationId)
    .maybeSingle();
  if (error || !row) {
    console.error(`notification ${notificationId} could not be loaded: ${error?.message ?? 'not found'}`);
    return;
  }
  if (!isFresh(row.created_at)) {
    console.error(`notification ${notificationId} is too old to push (${row.created_at})`);
    return;
  }

  const prefKey = PREF_FOR_TYPE[row.type as string];
  if (!(await pushAllowed(row.user_id as string, prefKey))) {
    console.log(`push skipped: ${row.user_id} turned off '${prefKey}'`);
    return;
  }

  // Only real values go into the push's data: OneSignal rejects or drops nulls.
  const data: Record<string, unknown> = { source: 'notification', type: row.type };
  if (row.related_id) data.related_id = row.related_id;

  // Notifications saved with a message key are written in the language the person uses NOW (their
  // profile setting), the same way the app shows them. Older rows keep their stored text.
  let title = row.title as string;
  let body = (row.body as string | null) ?? '';
  if (row.msg_key) {
    const { data: lang } = await supabase.rpc('_profile_lang', { p_profile: row.user_id });
    const { data: rendered, error: renderError } = await supabase.rpc('render_notification', {
      p_key: row.msg_key,
      p_args: row.msg_args ?? {},
      p_lang: (lang as string | null) ?? 'en',
    });
    const first = Array.isArray(rendered) ? rendered[0] : rendered;
    if (!renderError && first?.title) {
      title = first.title as string;
      body = (first.body as string | null) ?? '';
    }
  }

  await sendOneSignalPush(row.user_id as string, title, body, data);
}

async function handleMessageInsert(messageId: string) {
  if (alreadyHandled(`m:${messageId}`)) return;
  const { data: message, error: messageError } = await supabase
    .from('messages')
    .select('conversation_id, sender_id, body, created_at')
    .eq('message_id', messageId)
    .maybeSingle();
  if (messageError || !message || !isFresh(message.created_at)) return;

  const conversationId = message.conversation_id as string;
  const senderId = message.sender_id as string;

  // These two lookups don't depend on each other — running them in
  // parallel shaves one round-trip off the delivery path.
  const [membersResult, senderResult] = await Promise.all([
    supabase.from('profile_conversations').select('profile_id, muted').eq('conversation_id', conversationId),
    supabase.from('profile_directory').select('full_name').eq('profile_id', senderId).single(),
  ]);

  const { data: members, error: membersError } = membersResult;
  if (membersError || !members) {
    console.error(`Could not load conversation members for ${conversationId}: ${membersError?.message}`);
    return;
  }

  const recipient = members.find((m) => m.profile_id !== senderId);
  if (!recipient) return;
  if (recipient.muted) return;
  const recipientId = recipient.profile_id as string;
  if (!(await pushAllowed(recipientId, 'messages'))) return;

  const { data: sender, error: senderError } = senderResult;
  if (senderError) {
    console.error(`Could not load sender ${senderId}: ${senderError.message}`);
  }
  const senderName = sender?.full_name?.trim() ? sender.full_name : 'New message';

  const rawBody = (message.body as string | null) ?? '';
  const truncatedBody = rawBody.length > 100 ? `${rawBody.slice(0, 100)}…` : rawBody;

  await sendOneSignalPush(recipientId, senderName, truncatedBody, {
    source: 'message',
    conversation_id: conversationId,
  });
}

Deno.serve(async (req: Request) => {
  try {
    const payload = (await req.json()) as WebhookPayload;
    const record = payload.record ?? {};
    if (payload.table === 'notifications') {
      const id = record.notification_id;
      if (typeof id === 'string' && UUID_RE.test(id)) await handleNotificationInsert(id);
    } else if (payload.table === 'messages') {
      const id = record.message_id;
      if (typeof id === 'string' && UUID_RE.test(id)) await handleMessageInsert(id);
    }
  } catch (err) {
    console.error(`send-push-notification failed: ${err}`);
  }
  // Always 200 — this is a fire-and-forget webhook target, a non-200 here
  // would just make pg_net retry the same failing call.
  return new Response('ok', { status: 200 });
});
