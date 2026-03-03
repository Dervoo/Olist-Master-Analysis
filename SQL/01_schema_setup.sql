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

CREATE TABLE olist_customers (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix INT,
    customer_city TEXT,
    customer_state TEXT
);

CREATE TABLE olist_reviews (
    review_id VARCHAR(255),
    order_id VARCHAR(255),
    review_score INT,
    review_comment_title MEDIUMTEXT,
    review_comment_message MEDIUMTEXT,
    review_creation_date VARCHAR(50),
    review_answer_timestamp VARCHAR(50)
);

Treść Twojej wiadomości
CREATE TABLE olist_dataset_general (
    order_id VARCHAR(255),
    customer_id VARCHAR(255),
    order_status TEXT,
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    Actual_Delivery_Time INT,
    Estimated_vs_Actual INT,
    Is_Late VARCHAR(10),
    Customer_City VARCHAR(100),
    Customers_Zip_Code VARCHAR(20),
    Payment_Type VARCHAR(50),
    Payment_Value DECIMAL(10,2),
    Review_Score int
);