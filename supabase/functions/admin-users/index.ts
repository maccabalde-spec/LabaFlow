import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function reply(body: unknown, status = 200) {
  return Response.json(body, { status, headers: corsHeaders });
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') return reply({ error: 'POST required' }, 405);

  const url = Deno.env.get('SUPABASE_URL')!;
  const publishableKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const authorization = request.headers.get('Authorization');
  if (!authorization) return reply({ error: 'Sign in first.' }, 401);

  const authClient = createClient(url, publishableKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: { user }, error: authError } = await authClient.auth.getUser();
  if (authError || !user) return reply({ error: 'Invalid session.' }, 401);

  const admin = createClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: caller } = await admin.from('profiles').select('role').eq('id', user.id).maybeSingle();
  if (String(caller?.role || '').toUpperCase() !== 'ADMIN') return reply({ error: 'Administrator access required.' }, 403);

  try {
    const body = await request.json();
    const action = String(body.action || '');

    if (action === 'invite') {
      const account = body.user ?? {};
      const email = String(account.email || '').trim().toLowerCase();
      const password = String(body.password || '');
      if (!email || password.length < 12) return reply({ error: 'Email and a temporary password of at least 12 characters are required.' }, 400);
      const { data, error } = await admin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { name: String(account.name || ''), phone: String(account.phone || '') },
      });
      if (error || !data.user) return reply({ error: error?.message || 'Unable to create account.' }, 400);
      const { data: profile, error: profileError } = await admin.from('profiles').update({
        full_name: String(account.name || ''), email, phone: String(account.phone || ''),
        role: String(account.role || 'CUSTOMER').toLowerCase(), avatar_url: account.pic ?? account.photoUrl ?? null,
      }).eq('id', data.user.id).select().single();
      if (profileError) {
        await admin.auth.admin.deleteUser(data.user.id);
        return reply({ error: profileError.message }, 400);
      }
      return reply({ profile });
    }

    if (action === 'update') {
      const account = body.user ?? {};
      const uid = String(account.authUid || '');
      if (!uid) return reply({ error: 'User ID is required.' }, 400);
      const attributes: Record<string, unknown> = {
        email: String(account.email || '').trim().toLowerCase(),
        user_metadata: { name: String(account.name || ''), phone: String(account.phone || '') },
      };
      if (body.password) {
        if (String(body.password).length < 12) return reply({ error: 'Temporary password must be at least 12 characters.' }, 400);
        attributes.password = body.password;
      }
      const { error: authUpdateError } = await admin.auth.admin.updateUserById(uid, attributes);
      if (authUpdateError) return reply({ error: authUpdateError.message }, 400);
      const { data: profile, error } = await admin.from('profiles').update({
        full_name: String(account.name || ''), email: String(account.email || '').trim().toLowerCase(),
        phone: String(account.phone || ''), role: String(account.role || 'CUSTOMER').toLowerCase(),
        avatar_url: account.pic ?? account.photoUrl ?? null,
      }).eq('id', uid).select().single();
      if (error) return reply({ error: error.message }, 400);
      return reply({ profile });
    }

    if (action === 'delete') {
      const uid = String(body.uid || '');
      if (!uid || uid === user.id) return reply({ error: 'Choose another user to delete.' }, 400);
      const { error } = await admin.auth.admin.deleteUser(uid);
      if (error) return reply({ error: error.message }, 400);
      return reply({ deleted: true });
    }

    if (action === 'award-points') {
      const { data, error } = await admin.rpc('award_points', {
        recipient_id: String(body.recipientUid || ''),
        amount: Math.floor(Number(body.amount || 0)),
      });
      if (error) return reply({ error: error.message }, 400);
      return reply({ points: data });
    }

    return reply({ error: 'Unknown admin action.' }, 400);
  } catch (error) {
    return reply({ error: error instanceof Error ? error.message : 'Request failed.' }, 500);
  }
});
