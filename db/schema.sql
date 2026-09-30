-- Databasement portfolio schema
-- Based on the Olist Brazilian E-Commerce Public Dataset (Kaggle, CC BY-NC-SA 4.0).
-- See README.md for attribution and instructions on loading the full dataset.

DROP TABLE IF EXISTS order_status_history CASCADE;
DROP TABLE IF EXISTS order_reviews CASCADE;
DROP TABLE IF EXISTS order_payments CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS product_category_name_translation CASCADE;
DROP TABLE IF EXISTS sellers CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS geolocation CASCADE;

-- ---------------------------------------------------------------------------
-- Core Olist tables
-- ---------------------------------------------------------------------------

-- customer_id is per-ORDER, not per-person: this mirrors the real Olist
-- dataset, where the same physical customer gets a fresh customer_id on
-- each new order. customer_unique_id is what actually identifies the same
-- person across multiple orders -- use that, not customer_id, if you want
-- to count or group by "the same customer."
CREATE TABLE customers (
    customer_id             TEXT PRIMARY KEY,
    customer_unique_id      TEXT NOT NULL,
    customer_name           TEXT NOT NULL,
    customer_zip_code_prefix TEXT NOT NULL,
    customer_city           TEXT NOT NULL,
    customer_state          TEXT NOT NULL
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix TEXT NOT NULL,
    geolocation_lat              DOUBLE PRECISION NOT NULL,
    geolocation_lng               DOUBLE PRECISION NOT NULL,
    geolocation_city              TEXT NOT NULL,
    geolocation_state             TEXT NOT NULL
);
-- Deliberately no PK: the raw dataset has many lat/lng samples per zip prefix.
-- This is the ~1M-row table used for the indexing/EXPLAIN week.

CREATE TABLE sellers (
    seller_id             TEXT PRIMARY KEY,
    seller_name            TEXT NOT NULL,
    seller_zip_code_prefix TEXT NOT NULL,
    seller_city            TEXT NOT NULL,
    seller_state            TEXT NOT NULL
);

CREATE TABLE product_category_name_translation (
    product_category_name          TEXT PRIMARY KEY,
    product_category_name_english  TEXT NOT NULL
);

CREATE TABLE products (
    product_id                  TEXT PRIMARY KEY,
    product_name                 TEXT NOT NULL,
    product_category_name       TEXT REFERENCES product_category_name_translation(product_category_name),
    product_name_lenght         INTEGER,
    product_description_lenght  INTEGER,
    product_photos_qty          INTEGER,
    product_weight_g            INTEGER,
    product_length_cm           INTEGER,
    product_height_cm           INTEGER,
    product_width_cm            INTEGER
);

CREATE TABLE orders (
    order_id                       TEXT PRIMARY KEY,
    customer_id                    TEXT NOT NULL REFERENCES customers(customer_id),
    order_status                   TEXT NOT NULL,
    order_purchase_timestamp       TIMESTAMP NOT NULL,
    order_approved_at              TIMESTAMP,
    order_delivered_carrier_date   TIMESTAMP,
    order_delivered_customer_date  TIMESTAMP,
    order_estimated_delivery_date  TIMESTAMP NOT NULL
);

CREATE TABLE order_items (
    order_id            TEXT NOT NULL REFERENCES orders(order_id),
    order_item_id        INTEGER NOT NULL,
    product_id            TEXT NOT NULL REFERENCES products(product_id),
    seller_id             TEXT NOT NULL REFERENCES sellers(seller_id),
    shipping_limit_date   TIMESTAMP NOT NULL,
    price                 NUMERIC(10,2) NOT NULL,
    freight_value         NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
    order_id            TEXT NOT NULL REFERENCES orders(order_id),
    payment_sequential   INTEGER NOT NULL,
    payment_type          TEXT NOT NULL,
    payment_installments  INTEGER NOT NULL,
    payment_value          NUMERIC(10,2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE order_reviews (
    review_id                TEXT PRIMARY KEY,
    order_id                  TEXT NOT NULL REFERENCES orders(order_id),
    review_score               INTEGER NOT NULL CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title        TEXT,
    review_comment_message      TEXT,
    review_creation_date          TIMESTAMP NOT NULL,
    review_answer_timestamp       TIMESTAMP
);

-- ---------------------------------------------------------------------------
-- Course-added table (not part of raw Olist) — target for the week 9 trigger.
-- Students write a trigger on `orders` that appends a row here whenever
-- order_status changes, then wire a small "audit log" widget to read it.
-- ---------------------------------------------------------------------------

CREATE TABLE order_status_history (
    id           SERIAL PRIMARY KEY,
    order_id      TEXT NOT NULL REFERENCES orders(order_id),
    old_status     TEXT,
    new_status      TEXT NOT NULL,
    changed_at        TIMESTAMP NOT NULL DEFAULT now()
);

-- Helpful indexes for the join-heavy weeks (kept light; week 6 has students
-- add the ones that actually matter, e.g. on geolocation).
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_order_items_seller_id ON order_items(seller_id);
