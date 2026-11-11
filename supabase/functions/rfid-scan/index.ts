import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);

const headers = { 'Content-Type': 'application/json' };

// ── Web Push helper (VAPID) ───────────────────────────────────
const VAPID_PUBLIC_KEY  = Deno.env.get('VAPID_PUBLIC_KEY')  ?? '';
const VAPID_PRIVATE_KEY = Deno.env.get('VAPID_PRIVATE_KEY') ?? '';

function b64urlDecode(s: string): Uint8Array {
  const pad = s.length % 4 === 0 ? '' : '='.repeat(4 - s.length % 4);
  const b64 = (s + pad).replace(/-/g, '+').replace(/_/g, '/');
  const bin = atob(b64); return Uint8Array.from(bin, c => c.charCodeAt(0));
}
function b64urlEncode(buf: ArrayBuffer): string {
  return btoa(String.fromCharCode(...new Uint8Array(buf))).replace(/\+/g,'-').replace(/\//g,'_').replace(/=+$/,'');
}
async function sendWebPush(sub: { endpoint: string; p256dh: string; auth_key: string }, payload: object): Promise<void> {
  if (!VAPID_PUBLIC_KEY || !VAPID_PRIVATE_KEY) return;
  try {
    const url = new URL(sub.endpoint);
    const audience = `${url.protocol}//${url.host}`;
    const now = Math.floor(Date.now() / 1000);
    const hdr  = b64urlEncode(new TextEncoder().encode(JSON.stringify({ typ:'JWT', alg:'ES256' })));
    const pay  = b64urlEncode(new TextEncoder().encode(JSON.stringify({ aud: audience, exp: now + 43200, sub: 'mailto:admin@labaday.com' })));
    const privKey = await crypto.subtle.importKey('pkcs8', b64urlDecode(VAPID_PRIVATE_KEY).buffer, { name:'ECDSA', namedCurve:'P-256' }, false, ['sign']);
    const sig  = b64urlEncode(await crypto.subtle.sign({ name:'ECDSA', hash:'SHA-256' }, privKey, new TextEncoder().encode(`${hdr}.${pay}`)));
    await fetch(sub.endpoint, {
      method: 'POST',
      headers: { Authorization: `vapid t=${hdr}.${pay}.${sig},k=${VAPID_PUBLIC_KEY}`, 'Content-Type': 'application/octet-stream', TTL: '86400' },
      body: new TextEncoder().encode(JSON.stringify(payload)),
    });
  } catch (_) {}
}

// ── Simple in-memory rate limiter ────────────────────────
// Prevents the same tag from flooding the endpoint (e.g. held near reader).
const _scanCooldowns = new Map<string, number>();
const SCAN_COOLDOWN_MS = 3000; // 3 seconds per tag UID

function isRateLimited(uid: string): boolean {
  const now = Date.now();
  const last = _scanCooldowns.get(uid) ?? 0;
  if (now - last < SCAN_COOLDOWN_MS) return true;
  _scanCooldowns.set(uid, now);
  // Prune old entries to prevent memory leak (keep last 500 tags max)
  if (_scanCooldowns.size > 500) {
    const oldest = [..._scanCooldowns.entries()]
      .sort((a, b) => a[1] - b[1])
      .slice(0, 100)
      .map(e => e[0]);
    oldest.forEach(k => _scanCooldowns.delete(k));
  }
  return false;
}

// ── Helpers ──────────────────────────────────────────────

/**
 * Resolves the app's numeric customer id (stored on orders as `custId`,
 * which equals `profiles.public_id`) to the customer's auth UUID
 * (`profiles.id`), which is what the `notifications.user_id` column requires.
 *
 * If the value already looks like a UUID it is returned as-is for safety.
 */
async function resolveAuthUid(custId: any): Promise<string | null> {
  if (custId == null) return null;
  const s = String(custId).trim();
  // Already a UUID? Use directly.
  if (/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s)) {
    return s;
  }
  const cid = Number(s);
  if (Number.isNaN(cid)) return null;
  const { data, error } = await supabase
    .from('profiles')
    .select('id')
    .eq('public_id', cid)
    .maybeSingle();
  if (error || !data) {
    console.error('resolveAuthUid: could not resolve custId', custId, error?.message);
    return null;
  }
  return data.id as string;
}

/** Generates an id string matching the dashboard's log id format. */
function logId(prefix: string): string {
  return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;
}

/** Upserts a JSON-blob collection row in app_collections (creates the row if missing). */
async function saveCollection(key: string, items: any[]) {
  const { error } = await supabase
    .from('app_collections')
    .upsert({ key, items }, { onConflict: 'key' });
  if (error) console.error(`saveCollection(${key}) failed:`, error.message);
}

/** Inserts a notification for the customer AND sends Web Push to all their devices. */
async function notifyCustomer(custId: any, type: string, title: string, body: string, icon: string) {
  const authUid = await resolveAuthUid(custId);
  if (!authUid) {
    console.error('notifyCustomer: skipped, could not resolve auth UID for custId', custId);
    return;
  }
  try {
    // 1. Insert into notifications table (in-app realtime)
    await supabase.from('notifications').insert({
      user_id: authUid,
      type,
      title,
      body,
      icon,
    });
  } catch (e: any) {
    console.error('notifyCustomer: insert failed:', e?.message);
  }

  // 2. Send Web Push to all subscribed browser devices
  try {
    const { data: subs } = await supabase
      .from('push_subscriptions')
      .select('endpoint, p256dh, auth_key')
      .eq('user_id', authUid);

    if (subs && subs.length > 0) {
      await Promise.allSettled(subs.map(s => sendWebPush(s, { title, body, icon, tag: `labaflow-${Date.now()}`, url: '/' })));
    }
  } catch (_) {}
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers });
  }

  try {
    const { tag_uid } = await req.json();
    if (!tag_uid) {
      return new Response(JSON.stringify({ success: false, message: 'Missing tag_uid' }), { status: 400, headers });
    }

    const uid = String(tag_uid).toUpperCase().trim();
    const now = new Date().toISOString();

    // ── Rate limit: same tag cannot trigger within 3 seconds
    if (isRateLimited(uid)) {
      return new Response(JSON.stringify({
        success: false, code: 'RATE_LIMITED',
        message: 'Scan too fast. Wait 3 seconds before scanning the same tag again.'
      }), { status: 429, headers });
    }

    // ── Load app_collections: orders, rfidTags, rfidScanLogs, statusHistory
    const { data: colData, error: colErr } = await supabase
      .from('app_collections')
      .select('key, items')
      .in('key', ['orders', 'rfidTags', 'rfidScanLogs', 'statusHistory']);

    if (colErr || !colData) {
      return new Response(JSON.stringify({ success: false, message: 'DB error: ' + colErr?.message }), { status: 500, headers });
    }

    const ordersRow        = colData.find(r => r.key === 'orders');
    const tagsRow          = colData.find(r => r.key === 'rfidTags');
    const scanLogsRow      = colData.find(r => r.key === 'rfidScanLogs');
    const statusHistRow    = colData.find(r => r.key === 'statusHistory');
    const orders: any[]         = Array.isArray(ordersRow?.items)      ? ordersRow.items      : [];
    const rfidTags: any[]       = Array.isArray(tagsRow?.items)        ? tagsRow.items        : [];
    const scanLogs: any[]       = Array.isArray(scanLogsRow?.items)    ? scanLogsRow.items    : [];
    const statusHistory: any[] = Array.isArray(statusHistRow?.items)  ? statusHistRow.items  : [];

    // ── Find this tag in rfidTags
    const existingTag = rfidTags.find((t: any) => String(t.uid).toUpperCase() === uid);
    const tagAssignedOrdId = existingTag && !existingTag.available ? existingTag.orderId : null;

    // ════════════════════════════════════════
    // CASE A: Tag unassigned → assign to oldest PENDING order (FIFO)
    // ════════════════════════════════════════
    if (!tagAssignedOrdId) {

      // Find oldest PENDING order with no RFID tag
      const pendingOrders = orders
        .filter((o: any) => String(o.status).toUpperCase() === 'PENDING' && !o.tagId)
        .sort((a: any, b: any) => new Date(a.created).getTime() - new Date(b.created).getTime());

      if (pendingOrders.length === 0) {
        // Log the scan attempt for audit even when there's no order to assign.
        scanLogs.push({
          id: logId('SCAN'), uid, orderId: null, orderNum: '—',
          staffUser: 'ESP32 Reader', staffRole: 'STAFF',
          action: 'NO_PENDING_ORDER', result: 'NO_ORDER',
          details: 'Tag scanned but no pending order to assign',
          date: now,
        });
        await saveCollection('rfidScanLogs', scanLogs);
        return new Response(JSON.stringify({
          success: false,
          code: 'NO_PENDING_ORDER',
          message: 'No pending orders to assign. Customer must book first.'
        }), { status: 404, headers });
      }

      const targetOrder = pendingOrders[0];

      // Get or create tag ID
      let newTagId = existingTag?.id;
      if (!newTagId) {
        newTagId = rfidTags.length > 0 ? Math.max(...rfidTags.map((t: any) => t.id)) + 1 : 1;
      }

      // Update rfidTags — mark as in use
      const updatedTags = rfidTags.filter((t: any) => String(t.uid).toUpperCase() !== uid);
      updatedTags.push({ id: newTagId, uid: uid, available: false, orderId: targetOrder.id });

      // Update orders — set tagId and status to RECEIVED
      const updatedOrders = orders.map((o: any) => {
        if (o.id === targetOrder.id) {
          return { ...o, tagId: newTagId, status: 'RECEIVED', dropOff: now };
        }
        return o;
      });

      // ── Audit: stage transition history (PENDING → RECEIVED)
      statusHistory.push({
        id: logId('SH'), orderId: targetOrder.id, orderNum: targetOrder.num,
        status: 'RECEIVED', by: 'ESP32 RFID Reader', role: 'SYSTEM',
        notes: `RFID tag ${uid} linked automatically by ESP32 scanner`,
        date: now,
      });

      // ── Audit: RFID scan event log
      scanLogs.push({
        id: logId('SCAN'), uid, orderId: targetOrder.id, orderNum: targetOrder.num,
        staffUser: 'ESP32 Reader', staffRole: 'STAFF',
        action: 'ASSIGNED', result: 'SUCCESS',
        details: `Tag assigned to ${targetOrder.num} (${targetOrder.custName})`,
        date: now,
      });

      // Save all collections (upsert — creates row if it doesn't exist yet)
      await saveCollection('rfidTags', updatedTags);
      await saveCollection('orders', updatedOrders);
      await saveCollection('statusHistory', statusHistory);
      await saveCollection('rfidScanLogs', scanLogs);

      // Notify customer (resolves numeric custId → auth UUID)
      await notifyCustomer(
        targetOrder.custId,
        'RFID_CONFIRMED',
        `Order ${targetOrder.num} confirmed! 📡`,
        `Your laundry has been received and linked to RFID Tag ${uid}. You can now track your laundry progress!`,
        '📡'
      );

      return new Response(JSON.stringify({
        success: true,
        action: 'ASSIGNED',
        order_num: targetOrder.num,
        order_id: targetOrder.id,
        customer: targetOrder.custName,
        status: 'RECEIVED',
        message: `Tag assigned to ${targetOrder.num} (${targetOrder.custName})`
      }), { status: 200, headers });
    }

    // ════════════════════════════════════════
    // CASE B: Tag assigned → advance order status
    // ════════════════════════════════════════
    const targetOrder = orders.find((o: any) => o.id === tagAssignedOrdId);

    if (!targetOrder) {
      // Order gone — free the tag
      const updatedTags = rfidTags.map((t: any) =>
        String(t.uid).toUpperCase() === uid
          ? { ...t, available: true, orderId: null }
          : t
      );
      scanLogs.push({
        id: logId('SCAN'), uid, orderId: null, orderNum: '—',
        staffUser: 'ESP32 Reader', staffRole: 'STAFF',
        action: 'ORDER_NOT_FOUND', result: 'NO_ORDER',
        details: 'Tag was linked but order no longer exists; tag released',
        date: now,
      });
      await saveCollection('rfidTags', updatedTags);
      await saveCollection('rfidScanLogs', scanLogs);
      return new Response(JSON.stringify({ success: false, code: 'ORDER_NOT_FOUND', message: 'Order not found, tag released.' }), { status: 404, headers });
    }

    const cur = String(targetOrder.status).toUpperCase();

    // Block READY → RELEASED if not yet paid
    if (cur === 'READY') {
      const { data: txnData } = await supabase
        .from('app_collections')
        .select('items')
        .eq('key', 'transactions')
        .maybeSingle();

      const txns = Array.isArray(txnData?.items) ? txnData.items : [];
      const isPaid = txns.some((t: any) => t.orderId === targetOrder.id && t.status === 'COMPLETED');

      if (!isPaid) {
        scanLogs.push({
          id: logId('SCAN'), uid, orderId: targetOrder.id, orderNum: targetOrder.num,
          staffUser: 'ESP32 Reader', staffRole: 'STAFF',
          action: 'BLOCKED_UNPAID', result: 'UNPAID',
          details: `Order ${targetOrder.num} is READY but unpaid; release blocked`,
          date: now,
        });
        await saveCollection('rfidScanLogs', scanLogs);
        return new Response(JSON.stringify({
          success: false,
          code: 'UNPAID',
          message: `Order ${targetOrder.num} must be paid first before release. Please collect payment at the counter.`
        }), { status: 402, headers });
      }
    }

    // Status transition map
    const transitions: Record<string, string> = {
      'PENDING':     'RECEIVED',
      'RECEIVED':    'WASHING',
      'WASHING':     'DRYING',
      'DRYING':      'FOLDING',
      'FOLDING':     'READY',
      'READY':       'RELEASED',
      'IN PROGRESS': 'READY',
    };

    const nextStatus = transitions[cur];

    if (!nextStatus) {
      scanLogs.push({
        id: logId('SCAN'), uid, orderId: targetOrder.id, orderNum: targetOrder.num,
        staffUser: 'ESP32 Reader', staffRole: 'STAFF',
        action: 'INVALID_STATE', result: 'NO_CHANGE',
        details: `Order ${targetOrder.num} already at ${targetOrder.status}`,
        date: now,
      });
      await saveCollection('rfidScanLogs', scanLogs);
      return new Response(JSON.stringify({
        success: false,
        code: 'INVALID_STATE',
        message: `Order ${targetOrder.num} is already: ${targetOrder.status}`
      }), { status: 400, headers });
    }

    // Update order status
    const updatedOrders = orders.map((o: any) => {
      if (o.id === targetOrder.id) {
        const updated = { ...o, status: nextStatus };
        if (nextStatus === 'READY')     updated.ready  = now;
        if (nextStatus === 'RELEASED')  updated.pickup = now;
        return updated;
      }
      return o;
    });

    // If RELEASED — free the tag for reuse
    let updatedTags = rfidTags;
    if (nextStatus === 'RELEASED') {
      updatedTags = rfidTags.map((t: any) =>
        String(t.uid).toUpperCase() === uid
          ? { ...t, available: true, orderId: null }
          : t
      );
    }

    // ── Audit: stage transition history
    statusHistory.push({
      id: logId('SH'), orderId: targetOrder.id, orderNum: targetOrder.num,
      status: nextStatus, by: 'ESP32 RFID Reader', role: 'SYSTEM',
      notes: `Status advanced to ${nextStatus} by ESP32 RFID scan`,
      date: now,
    });

    // ── Audit: RFID scan event log
    scanLogs.push({
      id: logId('SCAN'), uid, orderId: targetOrder.id, orderNum: targetOrder.num,
      staffUser: 'ESP32 Reader', staffRole: 'STAFF',
      action: nextStatus, result: 'SUCCESS',
      details: `${targetOrder.num}: ${cur} → ${nextStatus}`,
      date: now,
    });

    // Save all collections (upsert — creates row if missing)
    await saveCollection('orders', updatedOrders);
    await saveCollection('statusHistory', statusHistory);
    await saveCollection('rfidScanLogs', scanLogs);
    if (nextStatus === 'RELEASED') {
      await saveCollection('rfidTags', updatedTags);
    }

    // Notify customer
    const notifMap: Record<string, { title: string; body: string; icon: string }> = {
      'RECEIVED': { title: `Order ${targetOrder.num} received!`,        body: 'Your laundry has been received. Track your progress now!',    icon: '📡' },
      'WASHING':  { title: `Order ${targetOrder.num} is washing! 🫧`,   body: 'Your laundry is now in the washing cycle.',                    icon: '🫧' },
      'DRYING':   { title: `Order ${targetOrder.num} is drying! 💨`,    body: 'Your laundry is now in the dryer.',                           icon: '💨' },
      'FOLDING':  { title: `Order ${targetOrder.num} is being folded!`, body: 'Your laundry is being neatly folded and packed.',             icon: '👕' },
      'READY':    { title: `Order ${targetOrder.num} is READY! ✅`,     body: 'Your clean laundry is ready for pickup at the shop!',         icon: '✅' },
      'RELEASED': { title: `Order ${targetOrder.num} completed! 🎉`,    body: 'Thank you for choosing Lab-a-Day Laundry!',                   icon: '🎉' },
    };

    const notif = notifMap[nextStatus];
    if (notif) {
      await notifyCustomer(targetOrder.custId, nextStatus, notif.title, notif.body, notif.icon);
    }

    return new Response(JSON.stringify({
      success: true,
      action: 'ADVANCED',
      order_num: targetOrder.num,
      order_id: targetOrder.id,
      customer: targetOrder.custName,
      prev_status: targetOrder.status,
      status: nextStatus,
      message: `${targetOrder.num} → ${nextStatus}`
    }), { status: 200, headers });

  } catch (err: any) {
    console.error('Error:', err);
    return new Response(JSON.stringify({ success: false, message: err.message }), { status: 500, headers });
  }
});
