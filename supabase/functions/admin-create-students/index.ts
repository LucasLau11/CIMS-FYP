import { createClient } from 'jsr:@supabase/supabase-js@2';

// Creates student OR academic supervisor accounts for an administrator, one or many at a time.
// The request says which with `role` ('student' by default, or 'academic_supervisor'). A supervisor
// account is approved straight away (the administrator is the one approving) and needs no registration
// number or programme.
//
// Only an approved admin may call it: the caller's own JWT is checked, then their role is read
// from the database with the service role. Every account gets a random password that meets the
// app's password rules and is flagged `must_change_password`, so the student has to choose their
// own password at the first login. The passwords are returned ONCE in the response so the admin
// can pass them on; they are not stored anywhere (Supabase keeps only a hash).
//
// What lets the handle_new_auth_user() trigger accept a 'student' account (a self sign-up cannot do
// this) and approve a supervisor straight away is a one-off row in admin_account_grants that this
// function writes for the exact email just before creating the user (migration 00041). The
// app_metadata flag alone is not enough: Supabase writes it after the row exists, so the trigger
// cannot see it.
//
// Every call that creates accounts is written to audit_log (migration 00036). Passwords are
// never logged.

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const MAX_STUDENTS = 200;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const NAME_RE = /^[\p{L}][\p{L}\s.'’\-]*$/u;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// Letters and digits that cannot be mistaken for each other when read out or typed.
const UPPER = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
const LOWER = 'abcdefghijkmnpqrstuvwxyz';
const DIGIT = '23456789';
const SYMBOL = '!@#$%&*';

function pick(chars: string): string {
  const buf = new Uint32Array(1);
  // Rejection sampling keeps every character equally likely.
  const limit = Math.floor(0x100000000 / chars.length) * chars.length;
  do {
    crypto.getRandomValues(buf);
  } while (buf[0] >= limit);
  return chars[buf[0] % chars.length];
}

/** 12 characters with at least one upper, lower, digit and symbol, in random order. */
function generatePassword(): string {
  const all = UPPER + LOWER + DIGIT + SYMBOL;
  const chars = [pick(UPPER), pick(LOWER), pick(DIGIT), pick(SYMBOL)];
  while (chars.length < 12) chars.push(pick(all));
  for (let i = chars.length - 1; i > 0; i--) {
    const buf = new Uint32Array(1);
    crypto.getRandomValues(buf);
    const j = buf[0] % (i + 1);
    [chars[i], chars[j]] = [chars[j], chars[i]];
  }
  return chars.join('');
}

type CreatableRole = 'student' | 'academic_supervisor';
const ROLES: CreatableRole[] = ['student', 'academic_supervisor'];

interface StudentInput {
  email?: unknown;
  full_name?: unknown;
  student_reg_no?: unknown;
  programme?: unknown;
}

interface Result {
  email: string;
  full_name: string;
  status: 'created' | 'exists' | 'invalid' | 'failed';
  password?: string;
  message?: string;
}

/** A reason the administrator can act on, instead of a bare "could not be created". */
function failureReason(text: string): string {
  if (text.includes('email_address_invalid') || text.includes('invalid format') || text.includes('is invalid')) {
    return 'The email address was refused as invalid. Check it for typing mistakes.';
  }
  if (text.includes('database error') || text.includes('unexpected_failure')) {
    return 'The database refused the new account. The email may not be allowed for this kind of account. Contact the developer if it keeps happening.';
  }
  if (text.includes('weak_password') || text.includes('password')) {
    return 'The generated password was refused. Try again.';
  }
  if (text.includes('over_email_send_rate_limit') || text.includes('rate limit') || text.includes('429')) {
    return 'Too many accounts were created in a short time. Wait a minute and try again.';
  }
  return 'The server could not create the account. Try again, and contact the developer if it keeps happening.';
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'Use POST.' }, 405);

  const authHeader = req.headers.get('Authorization') ?? '';
  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) return json({ error: 'You must be signed in.' }, 401);

  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data: caller } = await admin
    .from('profiles')
    .select('role, approval_status')
    .eq('profile_id', userData.user.id)
    .maybeSingle();
  if (caller?.role !== 'admin' || caller?.approval_status !== 'approved') {
    return json({ error: 'Only an administrator can create accounts.' }, 403);
  }

  let body: { students?: StudentInput[]; role?: string };
  try {
    body = await req.json();
  } catch (_) {
    return json({ error: 'The request was not valid JSON.' }, 400);
  }
  const role = (body.role ?? 'student') as CreatableRole;
  if (!ROLES.includes(role)) return json({ error: 'That kind of account cannot be created here.' }, 400);
  const students = body.students;
  if (!Array.isArray(students) || students.length === 0) {
    return json({ error: 'Send at least one student.' }, 400);
  }
  if (students.length > MAX_STUDENTS) {
    return json({ error: `Create at most ${MAX_STUDENTS} accounts at a time.` }, 400);
  }

  const results: Result[] = [];
  const seen = new Set<string>();

  for (const s of students) {
    const email = String(s.email ?? '').trim().toLowerCase();
    const fullName = String(s.full_name ?? '').trim();
    const regNo = String(s.student_reg_no ?? '').trim();
    const programme = String(s.programme ?? '').trim();

    if (!EMAIL_RE.test(email) || email.length > 254) {
      results.push({ email, full_name: fullName, status: 'invalid', message: 'Not a valid email address.' });
      continue;
    }
    if (fullName.length < 2 || fullName.length > 100 || !NAME_RE.test(fullName)) {
      results.push({ email, full_name: fullName, status: 'invalid', message: 'The name must be 2 to 100 letters (no digits or symbols).' });
      continue;
    }
    if (role === 'student' && (regNo.length > 30 || programme.length > 150)) {
      results.push({ email, full_name: fullName, status: 'invalid', message: 'Registration number or programme is too long.' });
      continue;
    }
    if (seen.has(email)) {
      results.push({ email, full_name: fullName, status: 'invalid', message: 'This email appears twice in the list.' });
      continue;
    }
    seen.add(email);

    const password = generatePassword();
    const { error: grantError } = await admin.from('admin_account_grants').upsert({ email, created_at: new Date().toISOString() });
    if (grantError) {
      console.error(`could not leave the permission for ${email}: ${grantError.message}`);
      results.push({ email, full_name: fullName, status: 'failed', message: 'The server could not prepare this account. Try again in a moment.' });
      continue;
    }
    const { data, error } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { app_role: role, full_name: fullName },
      app_metadata: { created_by_admin: true, must_change_password: true },
    });
    // The trigger removes the row when it uses it; clean up when it never ran.
    await admin.from('admin_account_grants').delete().eq('email', email);

    if (error || !data.user) {
      console.error(`createUser failed for ${email}: ${error?.code ?? ''} ${error?.message ?? 'no user returned'}`);
      const text = `${error?.code ?? ''} ${error?.message ?? ''}`.toLowerCase();
      if (text.includes('already') || text.includes('registered') || text.includes('exists')) {
        results.push({ email, full_name: fullName, status: 'exists', message: 'An account with this email already exists.' });
      } else {
        results.push({ email, full_name: fullName, status: 'failed', message: failureReason(text) });
      }
      continue;
    }

    if (role === 'student' && (regNo || programme)) {
      const { error: updateError } = await admin
        .from('students')
        .update({
          ...(regNo ? { student_reg_no: regNo } : {}),
          ...(programme ? { programme } : {}),
        })
        .eq('profile_id', data.user.id);
      if (updateError) {
        results.push({
          email,
          full_name: fullName,
          status: 'created',
          password,
          message: 'Created, but the registration number or programme could not be saved.',
        });
        continue;
      }
    }

    results.push({ email, full_name: fullName, status: 'created', password });
  }

  const created = results.filter((r) => r.status === 'created');
  if (created.length > 0) {
    const { error: auditError } = await admin.from('audit_log').insert({
      actor_id: userData.user.id,
      actor_role: 'admin',
      action: role === 'student' ? 'students_created' : 'supervisors_created',
      target_type: role === 'student' ? 'student' : 'academic_supervisor',
      summary: `${created.length} ${role === 'student' ? 'student' : 'academic supervisor'} account${created.length === 1 ? '' : 's'} created`,
      details: { emails: created.map((r) => r.email) },
    });
    if (auditError) console.error(`audit log write failed: ${auditError.message}`);
  }

  return json({ results });
});
