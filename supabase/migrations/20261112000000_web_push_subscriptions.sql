-- Web Push subscriptions table
-- Stores browser PushSubscription objects so the edge function can send
-- native OS push notifications even when the browser/tab is closed.

create table if not exists public.push_subscriptions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  endpoint    text not null,
  p256dh      text not null,
  auth_key    text not null,
  user_agent  text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  constraint push_subscriptions_endpoint_unique unique (endpoint)
);

create index if not exists push_subscriptions_user_idx
  on public.push_subscriptions (user_id);

alter table public.push_subscriptions enable row level security;

-- Users can only manage their own subscriptions
drop policy if exists "users can manage own push subscriptions" on public.push_subscriptions;
create policy "users can manage own push subscriptions"
  on public.push_subscriptions for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Service role can read all (for sending pushes)
grant select on public.push_subscriptions to service_role;
grant all on public.push_subscriptions to authenticated;
