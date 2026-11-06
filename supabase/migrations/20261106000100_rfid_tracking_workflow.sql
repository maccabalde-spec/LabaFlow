-- ============================================================
-- LabaFlow RFID Tracking & Workflow Audit Schema (PDF Spec)
-- ============================================================

-- 1. Extend order_status enum to support granular laundry stages:
-- Pending, Received, Washing, Drying, Folding, Ready for Pick-up, Completed, Cancelled
alter type public.order_status add value if not exists 'Washing';
alter type public.order_status add value if not exists 'Drying';
alter type public.order_status add value if not exists 'Folding';

-- 2. RFID Assignments Table (Enforces 1 active order per RFID tag at any time)
create table if not exists public.rfid_assignments (
  id uuid primary key default gen_random_uuid(),
  rfid_tag_id text not null,
  order_id text not null,
  assigned_by text,
  assigned_at timestamptz not null default now(),
  released_at timestamptz
);

create unique index if not exists idx_unique_active_rfid_assignment
  on public.rfid_assignments (rfid_tag_id)
  where released_at is null;

alter table public.rfid_assignments enable row level security;

drop policy if exists "rfid_assignments_read_all" on public.rfid_assignments;
create policy "rfid_assignments_read_all"
on public.rfid_assignments for select to anon, authenticated using (true);

drop policy if exists "rfid_assignments_write_all" on public.rfid_assignments;
create policy "rfid_assignments_write_all"
on public.rfid_assignments for all to anon, authenticated using (true) with check (true);

-- 3. Order Status History Table (Records every laundry stage change)
create table if not exists public.order_status_history (
  id text primary key,
  order_id text not null,
  order_num text,
  status text not null,
  updated_by text,
  role text,
  notes text,
  created_at timestamptz not null default now()
);

alter table public.order_status_history enable row level security;

drop policy if exists "order_status_history_read_all" on public.order_status_history;
create policy "order_status_history_read_all"
on public.order_status_history for select to anon, authenticated using (true);

drop policy if exists "order_status_history_write_all" on public.order_status_history;
create policy "order_status_history_write_all"
on public.order_status_history for all to anon, authenticated using (true) with check (true);

-- 4. RFID Scan Logs Table (Audit trail for every RFID scan, assignment, duplicate block, or release)
create table if not exists public.rfid_scan_logs (
  id text primary key,
  rfid_uid text not null,
  order_id text,
  order_num text,
  staff_user text,
  action_performed text not null,
  scan_result text not null,
  details text,
  scanned_at timestamptz not null default now()
);

alter table public.rfid_scan_logs enable row level security;

drop policy if exists "rfid_scan_logs_read_all" on public.rfid_scan_logs;
create policy "rfid_scan_logs_read_all"
on public.rfid_scan_logs for select to anon, authenticated using (true);

drop policy if exists "rfid_scan_logs_write_all" on public.rfid_scan_logs;
create policy "rfid_scan_logs_write_all"
on public.rfid_scan_logs for all to anon, authenticated using (true) with check (true);

-- 5. Seed new real-time synced collections into app_collections
insert into public.app_collections (key, items) values
  ('rfidScanLogs', '[]'::jsonb),
  ('statusHistory', '[]'::jsonb)
on conflict (key) do nothing;
