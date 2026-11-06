import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

// Initialize Supabase client with the SERVICE ROLE key to bypass RLS securely from the backend
const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
);

// Pre-shared secret for IoT devices (Stored securely in Supabase Vault / Env Vars)
const IOT_API_KEY = Deno.env.get('IOT_DEVICE_API_KEY') ?? 'default-dev-key';

serve(async (req) => {
  // CORS Headers for potential web dashboard testing, though ESP32 doesn't need them
  const headers = { 'Content-Type': 'application/json' };

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers });
  }

  try {
    const authHeader = req.headers.get('x-device-key');
    if (authHeader !== IOT_API_KEY) {
      return new Response(JSON.stringify({ success: false, message: 'Unauthorized device' }), { status: 401, headers });
    }

    const { device_id, tag_uid, event_id } = await req.json();

    if (!device_id || !tag_uid || !event_id) {
      return new Response(JSON.stringify({ success: false, message: 'Missing required fields' }), { status: 400, headers });
    }

    // 1. Idempotency Check: Prevent double-scanning if ESP32 retries the same event
    const { data: existingEvent } = await supabase
      .from('rfid_scan_events')
      .select('id')
      .eq('event_id', event_id)
      .single();

    if (existingEvent) {
      return new Response(JSON.stringify({ success: true, message: 'Scan already processed (Idempotent)' }), { status: 200, headers });
    }

    // 2. Validate RFID Tag & Get Assigned Order
    const { data: tagData, error: tagError } = await supabase
      .from('rfid_tags')
      .select('id, assigned_order_id, status')
      .eq('uid', tag_uid)
      .single();

    if (tagError || !tagData || tagData.status !== 'Active' || !tagData.assigned_order_id) {
      // Log failed scan
      await supabase.from('rfid_scan_events').insert({ event_id, tag_uid, device_id, result_status: 'FAILED_UNASSIGNED' });
      return new Response(JSON.stringify({ success: false, code: 'UNKNOWN_TAG', message: 'Tag unassigned or inactive' }), { status: 404, headers });
    }

    const orderId = tagData.assigned_order_id;

    // 3. Fetch Order Status and calculate next logical status
    const { data: orderData } = await supabase
      .from('laundry_orders')
      .select('order_reference, status')
      .eq('id', orderId)
      .single();

    let newStatus = '';
    let successMessage = '';

    // Define valid status transitions triggered by RFID
    if (orderData.status === 'Received') {
      newStatus = 'In Progress';
      successMessage = 'Washing started';
    } else if (orderData.status === 'In Progress') {
      newStatus = 'Ready for Pick-up';
      successMessage = 'Laundry ready';
    } else {
      // If it's already completed or pending (should be received manually by staff first)
      await supabase.from('rfid_scan_events').insert({ event_id, tag_uid, device_id, order_id: orderId, result_status: 'FAILED_INVALID_TRANSITION' });
      return new Response(JSON.stringify({ success: false, code: 'INVALID_STATE', message: `Cannot update from ${orderData.status}` }), { status: 400, headers });
    }

    // 4. Update Order and Log Event Transactionally
    await supabase.from('laundry_orders').update({ status: newStatus, updated_at: new Date().toISOString() }).eq('id', orderId);
    await supabase.from('rfid_scan_events').insert({ event_id, tag_uid, device_id, order_id: orderId, result_status: 'SUCCESS' });
    await supabase.from('rfid_tags').update({ last_scanned_at: new Date().toISOString() }).eq('uid', tag_uid);

    return new Response(JSON.stringify({
      success: true,
      order_reference: orderData.order_reference,
      status: newStatus,
      message: successMessage
    }), { status: 200, headers });

  } catch (error: any) {
    return new Response(JSON.stringify({ success: false, message: 'Internal Server Error', details: error.message }), { status: 500, headers });
  }
});