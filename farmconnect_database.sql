-- ============================================================
-- FarmConnect Database Schema
-- Database: farmconnect
-- Normalization: 3NF (Third Normal Form)
-- ============================================================

-- Create and use the database
CREATE DATABASE IF NOT EXISTS farmconnect;
USE farmconnect;

-- ============================================================
-- TABLE 1: farmers
-- Stores all farmer account information
-- ============================================================
CREATE TABLE IF NOT EXISTS farmers (
    id           INT AUTO_INCREMENT PRIMARY KEY,
    first_name   VARCHAR(100)  NOT NULL,
    last_name    VARCHAR(100)  NOT NULL,
    email        VARCHAR(150)  NOT NULL UNIQUE,
    password     VARCHAR(255)  NOT NULL,
    phone        VARCHAR(20)   NOT NULL,
    farm_name    VARCHAR(150)  NOT NULL,
    address      VARCHAR(255)  NOT NULL,
    city         VARCHAR(100)  NOT NULL,
    state        VARCHAR(100)  NOT NULL,
    farm_size    VARCHAR(50)   DEFAULT NULL,       -- e.g. "5 acres"
    products_grown TEXT        DEFAULT NULL,       -- comma-separated or description
    bio          TEXT          DEFAULT NULL,
    created_at   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================================
-- TABLE 2: buyers
-- Stores all buyer account information
-- ============================================================
CREATE TABLE IF NOT EXISTS buyers (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    first_name          VARCHAR(100)  NOT NULL,
    last_name           VARCHAR(100)  NOT NULL,
    email               VARCHAR(150)  NOT NULL UNIQUE,
    password            VARCHAR(255)  NOT NULL,
    phone               VARCHAR(20)   NOT NULL,
    address             VARCHAR(255)  NOT NULL,
    city                VARCHAR(100)  NOT NULL,
    state               VARCHAR(100)  NOT NULL,
    pincode             VARCHAR(20)   DEFAULT NULL,
    business_type       VARCHAR(100)  DEFAULT NULL,   -- e.g. "Retailer", "Restaurant"
    preferred_products  TEXT          DEFAULT NULL,
    notes               TEXT          DEFAULT NULL,
    created_at          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================================
-- TABLE 3: products
-- Stores products listed by farmers
-- Foreign key: farmer_id -> farmers(id)
-- ============================================================
CREATE TABLE IF NOT EXISTS products (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    farmer_id   INT           NOT NULL,
    name        VARCHAR(150)  NOT NULL,
    category    VARCHAR(100)  DEFAULT NULL,         -- e.g. "Vegetables", "Fruits"
    price       DECIMAL(10,2) NOT NULL,
    quantity    INT           NOT NULL DEFAULT 0,
    unit        VARCHAR(30)   NOT NULL DEFAULT 'kg', -- e.g. kg, litre, bunch
    description TEXT          DEFAULT NULL,
    image_url   TEXT          DEFAULT NULL,
    status      ENUM('available','unavailable','deleted') NOT NULL DEFAULT 'available',
    created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_product_farmer
        FOREIGN KEY (farmer_id) REFERENCES farmers(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- ============================================================
-- TABLE 4: orders
-- One order per buyer-farmer pair per checkout session
-- Foreign keys: buyer_id -> buyers(id), farmer_id -> farmers(id)
-- ============================================================
CREATE TABLE IF NOT EXISTS orders (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    order_number     VARCHAR(100)  NOT NULL UNIQUE,  -- e.g. ORD1716900000000_3
    buyer_id         INT           NOT NULL,
    farmer_id        INT           NOT NULL,
    total_amount     DECIMAL(10,2) NOT NULL,
    status           ENUM('pending','confirmed','processing','shipped','delivered','cancelled')
                     NOT NULL DEFAULT 'pending',
    delivery_address TEXT          DEFAULT NULL,
    notes            TEXT          DEFAULT NULL,
    created_at       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    updated_at       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_order_buyer
        FOREIGN KEY (buyer_id) REFERENCES buyers(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_order_farmer
        FOREIGN KEY (farmer_id) REFERENCES farmers(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- ============================================================
-- TABLE 5: order_items
-- Line items belonging to an order
-- Foreign keys: order_id -> orders(id), product_id -> products(id)
-- ============================================================
CREATE TABLE IF NOT EXISTS order_items (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    order_id    INT           NOT NULL,
    product_id  INT           NOT NULL,
    quantity    INT           NOT NULL,
    price       DECIMAL(10,2) NOT NULL,             -- price at time of purchase
    created_at  TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_item_order
        FOREIGN KEY (order_id) REFERENCES orders(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_item_product
        FOREIGN KEY (product_id) REFERENCES products(id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- ============================================================
-- INDEXES (for faster queries used in server.js)
-- ============================================================
CREATE INDEX idx_products_farmer      ON products(farmer_id);
CREATE INDEX idx_products_status      ON products(status);
CREATE INDEX idx_orders_buyer         ON orders(buyer_id);
CREATE INDEX idx_orders_farmer        ON orders(farmer_id);
CREATE INDEX idx_order_items_order    ON order_items(order_id);
CREATE INDEX idx_order_items_product  ON order_items(product_id);

-- ============================================================
-- SAMPLE DATA (optional — remove if not needed)
-- ============================================================

-- Sample farmer
INSERT INTO farmers (first_name, last_name, email, password, phone, farm_name, address, city, state, farm_size, products_grown, bio)
VALUES ('John', 'Dlamini', 'john@farmconnect.co.za', 'password123', '0812345678',
        'Green Valley Farm', '12 Farm Road', 'Durban', 'KwaZulu-Natal',
        '10 acres', 'Tomatoes, Spinach, Potatoes',
        'Third-generation farmer growing fresh organic vegetables.');

-- Sample buyer
INSERT INTO buyers (first_name, last_name, email, password, phone, address, city, state, pincode, business_type)
VALUES ('Sipho', 'Ndlovu', 'sipho@buyer.co.za', 'password123', '0723456789',
        '45 Market Street', 'Durban', 'KwaZulu-Natal', '4001', 'Retailer');

-- Sample product
INSERT INTO products (farmer_id, name, category, price, quantity, unit, description)
VALUES (1, 'Fresh Tomatoes', 'Vegetables', 25.00, 100, 'kg', 'Ripe, locally grown tomatoes.');

-- ============================================================
-- NORMALIZATION NOTES
-- ============================================================
-- 1NF: All columns hold atomic values; no repeating groups.
--      products_grown in farmers is a text field (acceptable for
--      a simple MVP; split into a separate table for strict 1NF).
--
-- 2NF: Every non-key column depends on the WHOLE primary key.
--      All tables use single-column surrogate PKs, so 2NF is met.
--
-- 3NF: No transitive dependencies.
--      - Buyer/farmer address details belong to their own tables.
--      - order_items.price stores price-at-purchase (snapshot),
--        NOT derived from products.price (avoids update anomalies).
--      - orders.total_amount is a stored aggregate for performance;
--        could be computed from order_items if strict 3NF is needed.
-- ============================================================
