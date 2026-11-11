import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

/**
 * notify-status-change
 *
 * Called manually or via a webhook when an order status changes.
 * Uses the same notifications table as rfid-scan for consistency.
 *
 * NOTE: The app's primary notification path is rfid-scan → notifyCustomer().
 * This function is a secondary path for manual staff status advances.
 *
 * Expected body:
 * {
 *   order_id: number,       // numeric order id from app_collections orders
 *   customer_id: number,    // numeric custId (profiles.public_id)
 *   order_num: string,      // e.g. "ORD-001"
 *   status: string,         // new status e.g. "READY", "WASHING"
 *   prev_status: string     // previous status
 * }
 */

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);

const notifMap: Record<string, { title: string; body: string; icon: string }> = {
  'RECEIVED': { title: 'Order received!',         body: 'Your laundry has been received. Track your progress now!',  icon: '📡' },
  'WASHING':  { title: 'Washing in progress! 🫧', body: 'Your laundry is now in the washing cycle.',                 icon: '🫧' },
  'DRYING':   { title: 'Drying in progress! 💨',  body: 'Your laundry is now in the dryer.',                         icon: '💨' },
  'FOLDING':  { title: 'Being folded! 👕',         body: 'Your laundry is being neatly folded and packed.',           icon: '👕' },
  'READY':    { title: 'Ready for pickup! ✅',      body: 'Your clean laundry is ready. Visit the shop to pick it up!',icon: '✅' },
  'RELEASED': { title: 'Order completed! 🎉',      body: 'Thank you for choosing Lab-a-Day Laundry!',                 icon: '🎉' },
};

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'POST required' }), { status: 405 });
  }

  try {
    const { order_id, customer_id, order_num, status, prev_status } = await req.json();

    if (!order_id || !customer_id || !status) {
      return new Response(
        JSON.stringify({ error: 'order_id, customer_id, and status are required' }),
        { status: 400 }
      );
    }

    const newStatus = String(status).toUpperCase();
    const notif = notifMap[newStatus];

    if (!notif) {
      return new Response(
        JSON.stringify({ skipped: true, reason: `No notification defined for status: ${newStatus}` }),
        { status: 200 }
      );
    }

    // Resolve numeric customer id → auth UUID via profiles.public_id
    const { data: profileRow, error: profileErr } = await supabase
      .from('profiles')
      .select('id')
      .eq('public_id', Number(customer_id))
      .maybeSingle();

    if (profileErr || !profileRow) {
      console.error('notify-status-change: could not resolve customer_id', customer_id, profileErr?.message);
      return new Response(
        JSON.stringify({ error: 'Customer profile not found' }),
        { status: 404 }
      );
    }

    const authUid = profileRow.id as string;
    const title = order_num ? `Order ${order_num}: ${notif.title}` : notif.title;

    const { error: insertErr } = await supabase.from('notifications').insert({
      user_id: authUid,
      type: newStatus,
      title,
      body: notif.body,
      icon: notif.icon,
    });

    if (insertErr) {
      console.error('notify-status-change: insert failed', insertErr.message);
      return new Response(JSON.stringify({ error: insertErr.message }), { status: 500 });
    }

    return new Response(
      JSON.stringify({ success: true, notified: authUid, status: newStatus }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    );

  } catch (err: any) {
    console.error('notify-status-change error:', err);
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});
