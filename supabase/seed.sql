-- Insert default services
INSERT INTO services (name, description, price_per_kg) VALUES 
('Wash & Dry (Single)', 'Standard wash and dry for daily wear', 5.00),
('Wash, Dry & Fold (Family)', 'Bulk processing with folding service', 6.50),
('Delicate Care', 'Special care for sensitive fabrics', 9.00);

-- Insert default inventory items
INSERT INTO inventory_items (name, unit, current_stock, min_threshold) VALUES
('Premium Liquid Detergent', 'ml', 10000, 2000),
('Fabric Softener', 'ml', 5000, 1000),
('Bleach', 'ml', 3000, 500);

-- Note: User authentication accounts must be created via Supabase Auth UI or API. 
-- The trigger will automatically populate the `profiles` table.