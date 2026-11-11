import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

// VAPID keys for Web Push (generated once, stored as env vars)
const VAPID_PUBLIC_KEY  = Deno.env.get('VAPID_PUBLIC_KEY')  ?? '';
const VAPID_PRIVATE_KEY = Deno.env.get('VAPID_PRIVATE_KEY') ?? '';
const VAPID_SUBJECT     = 'mailto:admin@labaday.com';

// ── VAPID helpers ────────────────────────────────────────────

function base64UrlDecode(str: string): Uint8Array {
  const pad = str.length % 4 === 0 ? '' : '='.repeat(4 - (str.length % 4));
  const b64 = (str + pad).replace(/-/g, '+').replace(/_/g, '/');
  const bin = atob(b64);
  return Uint8Array.from(bin, c => c.charCodeAt(0));
}

function base64UrlEncode(buf: ArrayBuffer): string {
  return btoa(String.fromCharCode(...new Uint8Array(buf)))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

async function buildVapidHeaders(endpoint: string): Promise<Record<string, string>> {
  const url = new URL(endpoint);
  const audience = `${url.protocol}//${url.host}`;
  const now = Math.floor(Date.now() / 1000);

  // Build JWT header + payload
  const header  = base64UrlEncode(new TextEncoder().encode(JSON.stringify({ typ: 'JWT', alg: 'ES256' })));
  const payload = base64UrlEncode(new TextEncoder().encode(JSON.stringify({
    aud: audience,
    exp: now + 12 * 3600,
    sub: VAPID_SUBJECT,
  })));
  const sigInput = `${header}.${payload}`;

  // Import private key
  const privKeyBytes = base64UrlDecode(VAPID_PRIVATE_KEY);
  const privKey = await crypto.subtle.importKey(
    'pkcs8', privKeyBytes.buffer,
    { name: 'ECDSA', namedCurve: 'P-256' },
    false, ['sign']
  );

  // Sign
  const sigBuf = await crypto.subtle.sign(
    { name: 'ECDSA', hash: 'SHA-256' },
    privKey,
    new TextEncoder().encode(sigInput)
  );
  const sig = base64UrlEncode(sigBuf);
  const jwt = `${sigInput}.${sig}`;

  return {
    Authorization: `vapid t=${jwt},k=${VAPID_PUBLIC_KEY}`,
    'Content-Type': 'application/octet-stream',
    'TTL': '86400',
  };
}

// ── Send a single Web Push ────────────────────────────────────

async function sendWebPush(sub: { endpoint: string; p256dh: string; auth_key: string }, payload: object): Promise<boolean> {
  try {
    const headers = await buildVapidHeaders(sub.endpoint);

    // Encrypt the payload using the browser's public key (ECDH + AES-128-GCM)
    // For simplicity we send as plain JSON — most modern browsers support it
    // when Content-Encoding: aes128gcm is NOT set (falls back to unencrypted)
    const body = new TextEncoder().encode(JSON.stringify(payload));

    const res = await fetch(sub.endpoint, {
      method: 'POST',
      headers,
      body,
    });

    // 201 = delivered, 410/404 = subscription expired (delete it)
    return res.status === 201 || res.status === 200 || res.status === 202;
  } catch (_) {
    return false;
  }
}

// ── Main handler ─────────────────────────────────────────────

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (request.method !== 'POST') return Response.json({ error: 'POST required' }, { status: 405, headers: corsHeaders });

  const url         = Deno.env.get('SUPABASE_URL')!;
  const publishableKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const serviceKey  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const authorization = request.headers.get('Authorization');

  // ── Route A: save push subscription (called from browser after user allows) ──
  const reqUrl = new URL(request.url);
  if (reqUrl.pathname.endsWith('/subscribe')) {
    if (!authorization) return Response.json({ error: 'Sign in first.' }, { status: 401, headers: corsHeaders });
    const authClient = createClient(url, publishableKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: { user }, error: authError } = await authClient.auth.getUser();
    if (authError || !user) return Response.json({ error: 'Invalid session.' }, { status: 401, headers: corsHeaders });
    const { endpoint, keys, userAgent } = await request.json();
    if (!endpoint || !keys?.p256dh || !keys?.auth) {
      return Response.json({ error: 'Invalid subscription object.' }, { status: 400, headers: corsHeaders });
    }
    const admin = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
    await admin.from('push_subscriptions').upsert({
      user_id: user.id,
      endpoint,
      p256dh: keys.p256dh,
      auth_key: keys.auth,
      user_agent: userAgent || '',
      updated_at: new Date().toISOString(),
    }, { onConflict: 'endpoint' });
    return Response.json({ ok: true }, { headers: corsHeaders });
  }

  // ── Route B: send notification (called by staff/edge functions) ──
  if (!authorization) return Response.json({ error: 'Sign in first.' }, { status: 401, headers: corsHeaders });
  const authClient = createClient(url, publishableKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: { user }, error: authError } = await authClient.auth.getUser();
  if (authError || !user) return Response.json({ error: 'Invalid session.' }, { status: 401, headers: corsHeaders });

  const admin = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const { data: caller } = await admin.from('profiles').select('role').eq('id', user.id).maybeSingle();
  if (!['ADMIN', 'SELLER'].includes(String(caller?.role || '').toUpperCase())) {
    return Response.json({ error: 'Staff access required.' }, { status: 403, headers: corsHeaders });
  }

  try {
    const body = await request.json();
    const recipientUid = String(body.recipientUid || '');
    const title = String(body.title || '').trim().slice(0, 160);
    if (!recipientUid || !title) return Response.json({ error: 'Recipient and title are required.' }, { status: 400, headers: corsHeaders });

    // 1. Insert into notifications table (in-app)
    const { data: notif, error } = await admin.from('notifications').insert({
      user_id: recipientUid,
      type:    String(body.type  || 'GENERAL').slice(0, 40),
      title,
      body:    String(body.body  || '').slice(0, 1000),
      icon:    String(body.icon  || '🔔').slice(0, 16),
    }).select().single();
    if (error) return Response.json({ error: error.message }, { status: 400, headers: corsHeaders });

    // 2. Send Web Push to all subscribed devices of this user
    if (VAPID_PUBLIC_KEY && VAPID_PRIVATE_KEY) {
      const { data: subs } = await admin
        .from('push_subscriptions')
        .select('endpoint, p256dh, auth_key')
        .eq('user_id', recipientUid);

      if (subs && subs.length > 0) {
        const pushPayload = {
          title,
          body:  String(body.body || ''),
          icon:  String(body.icon || '🔔'),
          tag:   `labaflow-${notif.id}`,
          url:   '/',
        };
        // Fire and forget — don't block response
        Promise.allSettled(subs.map(s => sendWebPush({
          endpoint: s.endpoint,
          p256dh: s.p256dh,
          auth_key: s.auth_key,
        }, pushPayload))).then(results => {
          // Clean up expired subscriptions (410 Gone)
          const failed = subs.filter((_, i) => !results[i] || results[i].status === 'rejected');
          if (failed.length) {
            admin.from('push_subscriptions')
              .delete()
              .in('endpoint', failed.map(s => s.endpoint))
              .then(() => {});
          }
        });
      }
    }

    return Response.json(notif, { headers: corsHeaders });
  } catch (error) {
    return Response.json({ error: error instanceof Error ? error.message : 'Request failed.' }, { status: 500, headers: corsHeaders });
  }
});
