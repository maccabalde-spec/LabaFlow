CREATE TABLE notification_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    fcm_token TEXT UNIQUE NOT NULL,
    device_platform TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS: Users can only manage their own tokens
ALTER TABLE notification_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own tokens"
ON notification_tokens FOR ALL USING (auth.uid() = user_id);

-- Create a Database Webhook Trigger to call our Edge Function when order status changes
-- (This is usually configured via the Supabase Dashboard UI -> Database -> Webhooks,
-- but here is the logical structure for the trigger)