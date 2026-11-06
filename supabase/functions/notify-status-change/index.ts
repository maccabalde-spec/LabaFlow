import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';
import { initializeApp, cert } from 'npm:firebase-admin/app';
import { getMessaging } from 'npm:firebase-admin/messaging';

// Initialize Firebase Admin with Service Account (stored in Supabase Secrets)
const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') || '{}');
if (Object.keys(serviceAccount).length > 0) {
  initializeApp({ credential: cert(serviceAccount) });
}

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);

serve(async (req) => {
  try {
    // Webhook payload from Supabase
    const payload = await req.json();
    const { record, old_record } = payload;

    // Only proceed if the status actually changed
    if (record.status === old_record.status) {
      return new Response('Status unchanged', { status: 200 });
    }

    // Determine notification content based on the new status
    let title = '';
    let body = '';

    if (record.status === 'Ready for Pick-up') {
      title = 'Laundry Ready! 🎉';
      body = `Your order (${record.order_reference}) is clean, folded, and ready for pickup.`;
    } else if (record.status === 'In Progress') {
      title = 'Washing Started 🫧';
      body = `We've started processing your order (${record.order_reference}).`;
    } else {
      // Do not send notifications for other intermediate statuses to avoid spam
      return new Response('No notification required for this status', { status: 200 });
    }

    // Fetch the customer's FCM tokens
    const { data: tokens, error } = await supabase
      .from('notification_tokens')
      .select('fcm_token')
      .eq('user_id', record.customer_id);

    if (error || !tokens || tokens.length === 0) {
      return new Response('No registered devices for this user', { status: 200 });
    }

    // Send push notification via Firebase Admin
    const fcmTokens = tokens.map(t => t.fcm_token);
    const message = {
      notification: { title, body },
      data: { orderId: record.id, status: record.status },
      tokens: fcmTokens,
    };

    const response = await getMessaging().sendEachForMulticast(message);

    return new Response(JSON.stringify({ success: true, firebaseResponse: response }), {
      headers: { 'Content-Type': 'application/json' }
    });

  } catch (error: any) {
    console.error('Notification Error:', error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
});