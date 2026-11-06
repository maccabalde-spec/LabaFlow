-- =====================================================
-- LabaFlow Database Schema
-- Lab-a-Day Laundry Shop Management System
-- =====================================================

CREATE DATABASE IF NOT EXISTS labaflow_db;
USE labaflow_db;

CREATE TABLE IF NOT EXISTS users (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    email         VARCHAR(100) UNIQUE NOT NULL,
    phone         VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    role          ENUM('ADMIN','STAFF','CUSTOMER') NOT NULL DEFAULT 'CUSTOMER',
    fcm_token     VARCHAR(255),
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS rfid_tags (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    rfid_uid     VARCHAR(50) UNIQUE NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS laundry_orders (
    id                   BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_number         VARCHAR(20) UNIQUE NOT NULL,
    customer_id          BIGINT NOT NULL,
    staff_id             BIGINT,
    rfid_tag_id          BIGINT,
    package_type         ENUM('WASH_DRY_FOLD','WASH_ONLY','DRY_ONLY','IRON_ONLY') NOT NULL,
    weight_kg            DECIMAL(5,2),
    status               ENUM('PENDING','RECEIVED','PROCESSING','READY','RELEASED') NOT NULL DEFAULT 'PENDING',
    special_instructions TEXT,
    estimated_price      DECIMAL(10,2),
    final_price          DECIMAL(10,2),
    drop_off_date        TIMESTAMP NULL,
    ready_date           TIMESTAMP NULL,
    pickup_date          TIMESTAMP NULL,
    created_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES users(id),
    FOREIGN KEY (staff_id)    REFERENCES users(id),
    FOREIGN KEY (rfid_tag_id) REFERENCES rfid_tags(id)
);

CREATE TABLE IF NOT EXISTS inventory_items (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    item_name           VARCHAR(100) NOT NULL,
    category            ENUM('DETERGENT','SOFTENER','BLEACH','OTHER') NOT NULL,
    unit                VARCHAR(20) NOT NULL,
    current_quantity    DECIMAL(10,2) NOT NULL DEFAULT 0,
    low_stock_threshold DECIMAL(10,2) NOT NULL DEFAULT 5,
    consumption_per_kg  DECIMAL(10,4) DEFAULT 0,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS inventory_logs (
    id               BIGINT AUTO_INCREMENT PRIMARY KEY,
    item_id          BIGINT NOT NULL,
    order_id         BIGINT,
    change_type      ENUM('CONSUMPTION','RESTOCK') NOT NULL,
    quantity_changed DECIMAL(10,2) NOT NULL,
    quantity_before  DECIMAL(10,2) NOT NULL,
    quantity_after   DECIMAL(10,2) NOT NULL,
    notes            TEXT,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (item_id)  REFERENCES inventory_items(id),
    FOREIGN KEY (order_id) REFERENCES laundry_orders(id)
);

CREATE TABLE IF NOT EXISTS sales_transactions (
    id                 BIGINT AUTO_INCREMENT PRIMARY KEY,
    transaction_number VARCHAR(20) UNIQUE NOT NULL,
    order_id           BIGINT NOT NULL,
    amount             DECIMAL(10,2) NOT NULL,
    payment_channel    ENUM('CASH','GCASH','MAYA') NOT NULL,
    payment_status     ENUM('PENDING','COMPLETED','REFUNDED') NOT NULL DEFAULT 'PENDING',
    receipt_number     VARCHAR(50),
    transaction_date   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES laundry_orders(id)
);

-- No demo users or passwords are seeded. Create production users in Firebase Auth.

INSERT INTO inventory_items (item_name, category, unit, current_quantity, low_stock_threshold, consumption_per_kg) VALUES
('Surf Detergent Powder', 'DETERGENT', 'kg',  20.00,  5.00, 0.10),
('Downy Fabric Softener', 'SOFTENER',  'L',   10.00,  2.00, 0.05),
('Zonrox Bleach',         'BLEACH',    'L',    5.00,  1.00, 0.02),
('Ariel Detergent Pod',   'DETERGENT', 'pcs', 50.00, 10.00, 1.00);

INSERT INTO rfid_tags (rfid_uid, is_available) VALUES
('04:54:82:1A:E2:20', TRUE),
('04:54:82:1A:E2:21', TRUE),
('04:54:82:1A:E2:22', TRUE),
('04:54:82:1A:E2:23', TRUE),
('04:54:82:1A:E2:24', TRUE),
('04:54:82:1A:E2:25', TRUE),
('04:54:82:1A:E2:26', TRUE),
('04:54:82:1A:E2:27', TRUE),
('04:54:82:1A:E2:28', TRUE),
('04:54:82:1A:E2:29', TRUE);

