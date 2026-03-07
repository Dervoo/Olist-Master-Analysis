-- 1. Zamieniamy puste stringi na NULL, aby SQL mógł poprawnie obliczać różnice dat
UPDATE olist_orders 
SET 
    order_purchase_timestamp = NULLIF(order_purchase_timestamp, ''),
    order_delivered_customer_date = NULLIF(order_delivered_customer_date, ''),
    order_estimated_delivery_date = NULLIF(order_estimated_delivery_date, '');

-- 2. Nadpisujemy "#VALUE!" prawdziwymi obliczeniami SQL
UPDATE olist_orders 
SET 
    actual_delivery_time = DATEDIFF(order_delivered_customer_date, order_purchase_timestamp),
    estimated_vs_actual = DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date)
WHERE order_delivered_customer_date IS NOT NULL;

-- 3. Czyścimy kolumnę Is_Late (na wypadek gdyby tam też były błędy)
UPDATE olist_orders
SET is_late = CASE 
    WHEN estimated_vs_actual < 0 THEN 'Yes' 
    ELSE 'No' 
END
WHERE estimated_vs_actual IS NOT NULL;

-- 4. Sprawdzamy wyniki
SELECT * FROM olist_order_items LIMIT 10;

-- 5. Tworzymy widok do analizy, który łączy dane z obu tabel i zawiera obliczenia wartości zamówienia
CREATE VIEW v_order_delivery_analysis AS
SELECT 
    o.order_id, 
    o.customer_id,
    o.order_status, 
    o.is_late, 
    o.actual_delivery_time,
    i.price, 
    i.freight_value,
    (i.price + i.freight_value) AS total_value
FROM olist_orders o
JOIN olist_order_items i ON o.order_id = i.order_id;

-- 6. Tworzymy widok z najważniejszymi danymi do dalszej analizy
CREATE VIEW v_master_general_data_3 AS
SELECT
o.order_id,
o.customer_id,
o.order_status,
o.order_purchase_timestamp,
o.order_approved_at, 
o.order_delivered_carrier_date, 
o.order_delivered_customer_date, 
o.order_estimated_delivery_date, 
o.Actual_Delivery_Time, 
o.Estimated_vs_Actual, 
o.Is_Late, 
o.Customer_City, 
o.Customers_Zip_Code, 
o.Payment_Type, 
o.Payment_Value, 
o.Review_Score,
o.price,
o.freight_value,
o.total_value,
o.Customers_Unique_Id,
i.seller_id
FROM v_master_general_data_2 o
JOIN olist_order_items2 i ON o.order_id = i.order_id;
