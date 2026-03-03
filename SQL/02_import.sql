-- Import danych: używamy polecenia LOAD DATA INFILE, aby zaimportować dane z plików CSV do tabel olist_orders i olist_order_items
-- Praca z lokalnymi ścieżkami: zmień poniższe ścieżki na własne przed uruchomieniem
LOAD DATA INFILE 'path/to/file' 
INTO TABLE olist_orders 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

LOAD DATA INFILE 'path/to/file.csv' 
INTO TABLE olist_order_items
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_customers_dataset.csv'
INTO TABLE olist_customers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n' -- lub '\r\n' jeśli robisz to na Windowsie
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_reviews_dataset.csv'
INTO TABLE olist_reviews
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
ESCAPED BY '"'   -- TO JEST TA MAGIA: Zabezpiecza wewnętrzne cudzysłowy i entery
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_orders_dataset main.csv'
INTO TABLE olist_dataset_general
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
-- KROK 1: Zmieniamy na samo \n. Jeśli nie zadziała, spróbuj \r
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS
-- KROK 2: Dodajemy @dummy na końcu (na wypadek niewidocznej kolumny z Excela)
(order_id, customer_id, order_status, @v_purchase, @v_approved, @v_carrier, @v_customer, @v_estimated, 
 @v_actual_time, @v_est_vs_act, is_late, customer_city, customers_zip_code, 
 payment_type, payment_value, @v_review, @dummy)
SET 
    order_purchase_timestamp = NULLIF(@v_purchase, ''),
    order_approved_at = NULLIF(@v_approved, ''),
    order_delivered_carrier_date = NULLIF(@v_carrier, ''),
    order_delivered_customer_date = NULLIF(@v_customer, ''),
    order_estimated_delivery_date = NULLIF(@v_estimated, ''),
    Actual_Delivery_Time = NULLIF(@v_actual_time, ''),
    Estimated_vs_Actual = NULLIF(@v_est_vs_act, ''),
    -- Jeśli @v_review to 'No review', wstawiamy NULL, w przeciwnym razie wartość
    review_score = IF(@v_review = 'No review' OR @v_review = '', NULL, @v_review);