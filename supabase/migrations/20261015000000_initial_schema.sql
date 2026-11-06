-- 1. ENUMS
CREATE TYPE user_role AS ENUM ('admin', 'seller', 'customer');
CREATE TYPE order_status AS ENUM ('Pending', 'Received', 'In Progress', 'Ready for Pick-up', 'Completed', 'Cancelled');
CREATE TYPE payment_status AS ENUM ('Unpaid', 'Partially Paid', 'Paid', 'Refunded');
CREATE TYPE payment_method AS ENUM ('Cash', 'GCash', 'Maya', 'None');
CREATE TYPE rfid_status AS ENUM ('Active', 'Inactive', 'Lost');

-- 2. TABLES
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    role user_role NOT NULL DEFAULT 'customer',
    full_name TEXT,
    phone TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    price_per_kg DECIMAL(10, 2) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE rfid_tags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    uid TEXT UNIQUE NOT NULL,
    status rfid_status DEFAULT 'Active',
    assigned_order_id UUID, -- Will be linked after orders table is created
    last_scanned_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE laundry_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_reference TEXT UNIQUE, -- e.g., LF-2026-00001
    customer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    service_id UUID REFERENCES services(id),
    status order_status DEFAULT 'Pending',
    weight_kg DECIMAL(10, 2),
    total_amount DECIMAL(10, 2),
    payment_status payment_status DEFAULT 'Unpaid',
    rfid_tag_id UUID REFERENCES rfid_tags(id) ON DELETE SET NULL,
    handled_by UUID REFERENCES profiles(id), -- Staff member who last updated
    expected_completion TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Circular foreign key update for rfid_tags
ALTER TABLE rfid_tags ADD CONSTRAINT fk_assigned_order FOREIGN KEY (assigned_order_id) REFERENCES laundry_orders(id) ON DELETE SET NULL;

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES laundry_orders(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    method payment_method NOT NULL,
    processed_by UUID REFERENCES profiles(id),
    receipt_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE inventory_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    unit TEXT NOT NULL, -- e.g., 'ml', 'kg', 'pcs'
    current_stock DECIMAL(10, 2) DEFAULT 0,
    min_threshold DECIMAL(10, 2) DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE rfid_scan_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id TEXT UNIQUE NOT NULL, -- To ensure idempotency from ESP32
    tag_uid TEXT NOT NULL,
    device_id TEXT NOT NULL,
    result_status TEXT NOT NULL,
    order_id UUID REFERENCES laundry_orders(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. FUNCTIONS & TRIGGERS

-- A. Auto-create profile on auth signup
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (new.id, new.raw_user_meta_data->>'full_name', 'customer');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- B. Auto-generate human readable Order Reference (LF-YYYY-XXXXX)
CREATE SEQUENCE order_seq START 1;
CREATE OR REPLACE FUNCTION generate_order_reference()
RETURNS TRIGGER AS $$
BEGIN
  NEW.order_reference := 'LF-' || to_char(CURRENT_DATE, 'YYYY') || '-' || LPAD(nextval('order_seq')::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_generate_order_ref
  BEFORE INSERT ON laundry_orders
  FOR EACH ROW EXECUTE PROCEDURE generate_order_reference();

-- 4. ROW LEVEL SECURITY (RLS) POLICIES

-- Helper function to get current user role securely without recursion
CREATE OR REPLACE FUNCTION auth_user_role() RETURNS text AS $$
  SELECT role::text FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE laundry_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE rfid_tags ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
CREATE POLICY "Users can view their own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admins and Sellers can view all profiles" ON profiles FOR SELECT USING (auth_user_role() IN ('admin', 'seller'));
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Only Admins can update roles" ON profiles FOR UPDATE USING (auth_user_role() = 'admin');

-- Services Policies
CREATE POLICY "Anyone can view active services" ON services FOR SELECT USING (is_active = true OR auth_user_role() IN ('admin', 'seller'));
CREATE POLICY "Only Admins can modify services" ON services FOR ALL USING (auth_user_role() = 'admin');

-- Laundry Orders Policies
CREATE POLICY "Customers can view their own orders" ON laundry_orders FOR SELECT USING (auth.uid() = customer_id);
CREATE POLICY "Staff can view all orders" ON laundry_orders FOR SELECT USING (auth_user_role() IN ('admin', 'seller'));
CREATE POLICY "Customers can create pending orders" ON laundry_orders FOR INSERT WITH CHECK (auth.uid() = customer_id AND status = 'Pending');
CREATE POLICY "Staff can insert and update orders" ON laundry_orders FOR ALL USING (auth_user_role() IN ('admin', 'seller'));

-- Inventory Policies
CREATE POLICY "Staff can view inventory" ON inventory_items FOR SELECT USING (auth_user_role() IN ('admin', 'seller'));
CREATE POLICY "Only Admins can modify inventory" ON inventory_items FOR ALL USING (auth_user_role() = 'admin');