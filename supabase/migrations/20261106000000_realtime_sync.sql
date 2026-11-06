-- Real-time cross-device data synchronization for LabaFlow (Web + Android App)
-- Synchronizes orders, inventory, rfidTags, transactions, messages, restockLog, promoCodes, and reviews.

create table if not exists public.app_collections (
  key text primary key,
  items jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

-- Seed default collections if they do not exist yet
insert into public.app_collections (key, items)
values
  ('inventory', '[
    {"id":1,"name":"Surf Liquid Detergent","cat":"DETERGENT","unit":"L","qty":12.5,"thresh":1.0,"packSize":2.5,"packQty":5,"perLoad":0.1,"perKg":0},
    {"id":2,"name":"Surf Fabric Conditioner","cat":"SOFTENER","unit":"L","qty":8.0,"thresh":0.8,"packSize":1.6,"packQty":5,"perLoad":0.1,"perKg":0},
    {"id":3,"name":"Zonrox Color Safe","cat":"BLEACH","unit":"L","qty":4.5,"thresh":0.45,"packSize":0.9,"packQty":5,"perLoad":0.01,"perKg":0}
  ]'::jsonb),
  ('rfidTags', '[
    {"id":1,"uid":"TAG-001","available":true,"orderId":null},
    {"id":2,"uid":"TAG-002","available":true,"orderId":null},
    {"id":3,"uid":"TAG-003","available":true,"orderId":null},
    {"id":4,"uid":"TAG-004","available":true,"orderId":null},
    {"id":5,"uid":"TAG-005","available":true,"orderId":null},
    {"id":6,"uid":"TAG-006","available":true,"orderId":null},
    {"id":7,"uid":"TAG-007","available":true,"orderId":null},
    {"id":8,"uid":"TAG-008","available":true,"orderId":null},
    {"id":9,"uid":"TAG-009","available":true,"orderId":null},
    {"id":10,"uid":"TAG-010","available":true,"orderId":null}
  ]'::jsonb),
  ('promoCodes', '[
    {"id":1,"code":"WELCOME","disc":10,"maxUses":100,"uses":0,"desc":"Welcome discount for new customers","active":true},
    {"id":2,"code":"LABA20","disc":20,"maxUses":30,"uses":0,"desc":"Special promo - limited time","active":true}
  ]'::jsonb),
  ('orders', '[]'::jsonb),
  ('transactions', '[]'::jsonb),
  ('messages', '[]'::jsonb),
  ('restockLog', '[]'::jsonb),
  ('reviews', '[]'::jsonb)
on conflict (key) do nothing;

alter table public.app_collections enable row level security;

grant select on public.app_collections to anon, authenticated;
grant insert, update on public.app_collections to authenticated;

drop policy if exists "anyone can read app collections" on public.app_collections;
create policy "anyone can read app collections"
  on public.app_collections for select
  to anon, authenticated
  using (true);

drop policy if exists "authenticated users can insert app collections" on public.app_collections;
create policy "authenticated users can insert app collections"
  on public.app_collections for insert
  to authenticated
  with check (true);

drop policy if exists "authenticated users can update app collections" on public.app_collections;
create policy "authenticated users can update app collections"
  on public.app_collections for update
  to authenticated
  using (true)
  with check (true);

-- Enable Supabase Realtime for app_collections and profiles
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'app_collections'
    ) then
      alter publication supabase_realtime add table public.app_collections;
    end if;

    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'profiles'
    ) then
      alter publication supabase_realtime add table public.profiles;
    end if;
  end if;
end;
$$;
