-- Tworzenie schematu bazy danych: definiujemy strukturę tabel olist_orders i olist_order_items, które będą przechowywać dane o zamówieniach i szczegółach zamówień
CREATE TABLE olist_orders (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TEXT,
    order_approved_at TEXT,
    order_delivered_carrier_date TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT,
    actual_delivery_time TEXT,       -- Tutaj wpadną te "#VALUE!"
    estimated_vs_actual TEXT,        -- I tutaj też
    is_late TEXT
);

CREATE TABLE olist_order_items (
    order_id TEXT,
    order_item_id INT,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TEXT,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);