import { createClient } from 'jsr:@supabase/supabase-js@2';

const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID')!;
const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY')!;
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

interface WebhookPayload {
  type: 'INSERT';
  table: string;
  schema: string;
  record: Record<string, unknown>;
  old_record: null;
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
  if (!response.ok) {
    console.error(`OneSignal API error (${response.status}): ${await response.text()}`);
  }
}

async function handleNotificationInsert(record: Record<string, unknown>) {
  const userId = record.user_id as string;
  const title = record.title as string;
  const body = (record.body as string | null) ?? '';
  await sendOneSignalPush(userId, title, body, {
    source: 'notification',
    type: record.type,
    related_id: record.related_id,
  });
}

async function handleMessageInsert(record: Record<string, unknown>) {
  const conversationId = record.conversation_id as string;
  const senderId = record.sender_id as string;

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

  const { data: sender, error: senderError } = senderResult;
  if (senderError) {
    console.error(`Could not load sender ${senderId}: ${senderError.message}`);
  }
  const senderName = sender?.full_name?.trim() ? sender.full_name : 'New message';

  const rawBody = (record.body as string | null) ?? '';
  const truncatedBody = rawBody.length > 100 ? `${rawBody.slice(0, 100)}…` : rawBody;

  await sendOneSignalPush(recipientId, senderName, truncatedBody, {
    source: 'message',
    conversation_id: conversationId,
  });
}

Deno.serve(async (req: Request) => {
  try {
    const payload = (await req.json()) as WebhookPayload;
    if (payload.table === 'notifications') {
      await handleNotificationInsert(payload.record);
    } else if (payload.table === 'messages') {
      await handleMessageInsert(payload.record);
    }
  } catch (err) {
    console.error(`send-push-notification failed: ${err}`);
  }
  // Always 200 — this is a fire-and-forget webhook target, a non-200 here
  // would just make pg_net retry the same failing call.
  return new Response('ok', { status: 200 });
});
