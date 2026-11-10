import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);

const IOT_API_KEY = Deno.env.get('IOT_DEVICE_API_KEY') ?? 'labaflow-iot-esp32-key-001';
const headers = { 'Content-Type': 'application/json' };

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers });
  }

  try {
    // --- Auth check ---
    const authHeader = req.headers.get('x-device-key');
    if (authHeader !== IOT_API_KEY) {
      return new Response(JSON.stringify({ success: false, message: 'Unauthorized device' }), { status: 401, headers });
    }

    const { device_id, tag_uid, event_id } = await req.json();
    if (!device_id || !tag_uid || !event_id) {
      return new Response(JSON.stringify({ success: false, message: 'Missing required fields' }), { status: 400, headers });
    }

    // --- Idempotency check ---
    const { data: existingEvent } = await supabase
      .from('rfid_scan_events')
      .select('id')
      .eq('event_id', event_id)
      .single();

    if (existingEvent) {
      return new Response(JSON.stringify({ success: true, message: 'Already processed' }), { status: 200, headers });
    }

    // --- Find or create RFID tag record ---
    let { data: tagData } = await supabase
      .from('rfid_tags')
      .select('id, uid, assigned_order_id, status')
      .eq('uid', tag_uid)
      .single();

    if (!tagData) {
      const { data: newTag } = await supabase
        .from('rfid_tags')
        .insert({ uid: tag_uid, status: 'Active' })
        .select()
        .single();
      tagData = newTag;
    }

    if (!tagData) {
      return new Response(JSON.stringify({ success: false, message: 'Could not create tag record' }), { status: 500, headers });
    }

    // ================================================================
    // CASE A: TAG IS UNASSIGNED — Confirm & assign to oldest PENDING order
    // ================================================================
    if (!tagData.assigned_order_id) {

      // ⚠️ DUPLICATE PROTECTION: Check if this tag UID is already in use
      // by any OTHER active order (belt-and-suspenders check)
      const { data: activeTagCheck } = await supabase
        .from('rfid_tags')
        .select('id, uid, assigned_order_id')
        .eq('uid', tag_uid)
        .not('assigned_order_id', 'is', null)
        .maybeSingle();

      if (activeTagCheck?.assigned_order_id) {
        // Tag is already linked to another active order — BLOCK
        await supabase.from('rfid_scan_events').insert({
          event_id, tag_uid, device_id, result_status: 'DUPLICATE_BLOCKED'
        });
        return new Response(JSON.stringify({
          success: false,
          code: 'DUPLICATE_TAG',
          message: `Tag ${tag_uid} is already assigned to an active order. Use a different tag.`
        }), { status: 409, headers });
      }

      // Find the oldest PENDING order that has NO rfid tag yet
      const { data: pendingOrder } = await supabase
        .from('laundry_orders')
        .select('id, order_reference, status, customer_id, rfid_tag_id')
        .eq('status', 'Pending')
        .is('rfid_tag_id', null)
        .order('created_at', { ascending: true })
        .limit(1)
        .single();

      if (!pendingOrder) {
        await supabase.from('rfid_scan_events').insert({
          event_id, tag_uid, device_id, result_status: 'FAILED_NO_ORDER'
        });
        return new Response(JSON.stringify({
          success: false,
          code: 'NO_PENDING_ORDER',
          message: 'No pending orders to confirm. All orders already have RFID tags.'
        }), { status: 404, headers });
      }

      // Get customer name for display
      let customerName = 'Customer';
      if (pendingOrder.customer_id) {
        const { data: profile } = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', pendingOrder.customer_id)
          .single();
        if (profile?.full_name) customerName = profile.full_name;
      }

      // Assign tag to order and set status to Received
      await supabase
        .from('rfid_tags')
        .update({
          assigned_order_id: pendingOrder.id,
          last_scanned_at: new Date().toISOString()
        })
        .eq('uid', tag_uid);

      await supabase
        .from('laundry_orders')
        .update({
          rfid_tag_id: tagData.id,
          status: 'Received',
          updated_at: new Date().toISOString()
        })
        .eq('id', pendingOrder.id);

      // Insert notification for customer in Supabase notifications table
      if (pendingOrder.customer_id) {
        await supabase.from('notifications').insert({
          user_id: pendingOrder.customer_id,
          type: 'RFID_CONFIRMED',
          title: `Order ${pendingOrder.order_reference} confirmed! 📡`,
          body: `Your laundry has been received and linked to RFID Tag ${tag_uid}. You can now track your laundry progress in real-time!`,
          icon: '📡'
        });
      }

      await supabase.from('rfid_scan_events').insert({
        event_id, tag_uid, device_id,
        order_id: pendingOrder.id,
        result_status: 'ASSIGNED'
      });

      return new Response(JSON.stringify({
        success: true,
        action: 'ASSIGNED',
        order_reference: pendingOrder.order_reference,
        status: 'Received',
        customer_name: customerName,
        message: `Order confirmed for ${customerName}`
      }), { status: 200, headers });
    }

    // ================================================================
    // CASE B: TAG IS ALREADY ASSIGNED — Advance order status
    // ================================================================
    const orderId = tagData.assigned_order_id;

    const { data: orderData } = await supabase
      .from('laundry_orders')
      .select('id, order_reference, status, customer_id')
      .eq('id', orderId)
      .single();

    if (!orderData) {
      // Order no longer exists — release the tag
      await supabase
        .from('rfid_tags')
        .update({ assigned_order_id: null })
        .eq('uid', tag_uid);
      return new Response(JSON.stringify({
        success: false,
        code: 'ORDER_NOT_FOUND',
        message: 'Linked order not found. Tag has been released.'
      }), { status: 404, headers });
    }

    // Status transition map
    const transitions: Record<string, { next: string; message: string }> = {
      'Received':          { next: 'Washing',           message: 'Washing started!' },
      'In Progress':       { next: 'Ready for Pick-up',  message: 'Laundry ready for pickup!' },
      'Washing':           { next: 'Drying',             message: 'Now drying' },
      'Drying':            { next: 'Folding',            message: 'Now folding' },
      'Folding':           { next: 'Ready for Pick-up',  message: 'Ready for pickup!' },
      'Ready for Pick-up': { next: 'Completed',          message: 'Order completed!' },
    };

    const transition = transitions[orderData.status];

    if (!transition) {
      await supabase.from('rfid_scan_events').insert({
        event_id, tag_uid, device_id, order_id: orderId,
        result_status: 'FAILED_INVALID_TRANSITION'
      });
      return new Response(JSON.stringify({
        success: false,
        code: 'INVALID_STATE',
        message: `Order is already: ${orderData.status}`
      }), { status: 400, headers });
    }

    const newStatus = transition.next;

    // Update order status
    await supabase
      .from('laundry_orders')
      .update({ status: newStatus, updated_at: new Date().toISOString() })
      .eq('id', orderId);

    // If completed — release the tag for reuse by next customer
    if (newStatus === 'Completed') {
      await supabase
        .from('rfid_tags')
        .update({ assigned_order_id: null, last_scanned_at: new Date().toISOString() })
        .eq('uid', tag_uid);
    } else {
      await supabase
        .from('rfid_tags')
        .update({ last_scanned_at: new Date().toISOString() })
        .eq('uid', tag_uid);
    }

    // Notify customer of stage update
    if (orderData.customer_id) {
      const notifMap: Record<string, { title: string; body: string; icon: string }> = {
        'Washing':           { title: `🫧 Order ${orderData.order_reference} is washing`, body: 'Your laundry is now in the washing cycle.', icon: '🫧' },
        'Drying':            { title: `💨 Order ${orderData.order_reference} is drying`,  body: 'Your laundry is now in the dryer.', icon: '💨' },
        'Folding':           { title: `👕 Order ${orderData.order_reference} is being folded`, body: 'Your laundry is being neatly folded and packed.', icon: '👕' },
        'Ready for Pick-up': { title: `✅ Order ${orderData.order_reference} is READY!`,  body: 'Your clean laundry is ready for pickup at the shop!', icon: '✅' },
        'Completed':         { title: `🎉 Order ${orderData.order_reference} completed`,  body: 'Thank you for choosing Lab-a-Day Laundry!', icon: '🎉' },
      };

      const notif = notifMap[newStatus];
      if (notif) {
        await supabase.from('notifications').insert({
          user_id: orderData.customer_id,
          type: newStatus.toUpperCase().replace(/ /g, '_'),
          title: notif.title,
          body: notif.body,
          icon: notif.icon
        });
      }
    }

    await supabase.from('rfid_scan_events').insert({
      event_id, tag_uid, device_id, order_id: orderId, result_status: 'SUCCESS'
    });

    return new Response(JSON.stringify({
      success: true,
      action: 'ADVANCED',
      order_reference: orderData.order_reference,
      status: newStatus,
      message: transition.message
    }), { status: 200, headers });

  } catch (error: any) {
    console.error('Error:', error);
    return new Response(JSON.stringify({
      success: false,
      message: 'Internal Server Error',
      details: error.message
    }), { status: 500, headers });
  }
});
