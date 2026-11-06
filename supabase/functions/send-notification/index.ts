import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') return Response.json({ error: 'POST required' }, { status: 405, headers: corsHeaders });

  const url = Deno.env.get('SUPABASE_URL')!;
  const publishableKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const authorization = request.headers.get('Authorization');
  if (!authorization) return Response.json({ error: 'Sign in first.' }, { status: 401, headers: corsHeaders });

  const authClient = createClient(url, publishableKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: { user }, error: authError } = await authClient.auth.getUser();
  if (authError || !user) return Response.json({ error: 'Invalid session.' }, { status: 401, headers: corsHeaders });

  const admin = createClient(url, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: caller } = await admin.from('profiles').select('role').eq('id', user.id).maybeSingle();
  if (!['ADMIN', 'SELLER'].includes(String(caller?.role || '').toUpperCase())) {
    return Response.json({ error: 'Staff access required.' }, { status: 403, headers: corsHeaders });
  }

  try {
    const body = await request.json();
    const recipientUid = String(body.recipientUid || '');
    const title = String(body.title || '').trim().slice(0, 160);
    if (!recipientUid || !title) return Response.json({ error: 'Recipient and title are required.' }, { status: 400, headers: corsHeaders });
    const { data, error } = await admin.from('notifications').insert({
      user_id: recipientUid,
      type: String(body.type || 'GENERAL').slice(0, 40),
      title,
      body: String(body.body || '').slice(0, 1000),
      icon: String(body.icon || '🔔').slice(0, 16),
    }).select().single();
    if (error) return Response.json({ error: error.message }, { status: 400, headers: corsHeaders });
    return Response.json(data, { headers: corsHeaders });
  } catch (error) {
    return Response.json({ error: error instanceof Error ? error.message : 'Request failed.' }, { status: 500, headers: corsHeaders });
  }
});
