-- Pytanie 1: Jaka jest pełna wartość finansowa każdego zamówienia (cena + transport)?
-- Cel: Łączymy dane o statusach z cenami, aby uzyskać pełny obraz operacyjny każdego ID zamówienia.
SELECT 
    o.order_id, 
    o.order_status, 
    o.is_late, 
    i.price, 
    i.freight_value,
    (i.price + i.freight_value) AS total_order_value
FROM olist_orders o
JOIN olist_order_items i ON o.order_id = i.order_id
LIMIT 20;

-- Pytanie 2: Czy zamówienia o konkretnych statusach (np. anulowane vs dostarczone) różnią się średnią wartością?
-- Cel: Sprawdzenie, czy tracimy droższe, czy tańsze zamówienia w procesie anulacji.
SELECT 
    order_status, 
    COUNT(*) AS total_orders, 
    AVG(price + freight_value) AS avg_order_value
FROM olist_orders o
JOIN olist_order_items i ON o.order_id = i.order_id
GROUP BY order_status
ORDER BY total_orders DESC;

-- Pytanie 3: Czy istnieje korelacja między wartością zamówienia a jego spóźnieniem?
-- Cel: Weryfikacja hipotezy, czy zamówienia o wyższej wartości są traktowane priorytetowo (rzadziej spóźnione).
SELECT 
    is_late, 
    COUNT(*) as number_of_orders,
    ROUND(AVG(price + freight_value), 2) as avg_value
FROM olist_orders o
JOIN olist_order_items i ON o.order_id = i.order_id
GROUP BY is_late;

-- Pytanie 4: Jak przygotować dane do końcowego raportu w Power BI/Tableau?
-- Cel: Utworzenie skonsolidowanej warstwy raportowej (View), która zawiera tylko dostarczone zamówienia z poprawnymi typami danych.
CREATE VIEW v_master_orders_report AS
SELECT 
    o.order_id,
    o.order_status,
    o.is_late,
    -- Zamieniamy tekst na liczby dla pewności obliczeń
    CAST(o.actual_delivery_time AS SIGNED) AS delivery_days,
    i.product_id,
    i.seller_id,
    i.price,
    i.freight_value,
    (i.price + i.freight_value) AS total_order_amount
FROM olist_orders o
JOIN olist_order_items i ON o.order_id = i.order_id
WHERE o.order_status = 'delivered';

-- Pytanie 5: Jaki procent wartości zamówienia stanowi koszt wysyłki?
-- Cel: Identyfikacja zamówień, gdzie transport jest nieproporcjonalnie drogi w stosunku do towaru.
SELECT 
    order_id, 
    price, 
    freight_value,
    ROUND((freight_value / price) * 100, 2) AS freight_ratio_pct
FROM v_master_orders_report
ORDER BY freight_ratio_pct DESC
LIMIT 10;

-- Pytanie6 : Którzy sprzedawcy generują najwięcej spóźnień?
-- Cel: Monitoring jakości pracy partnerów biznesowych.
SELECT 
    seller_id, 
    COUNT(*) as total_orders,
    SUM(CASE WHEN is_late = 'Yes' THEN 1 ELSE 0 END) as late_count
FROM v_master_orders_report
GROUP BY seller_id
HAVING total_orders > 5
ORDER BY late_count DESC
LIMIT 10;

-- Pytanie 7: W jakich latach platforma notuje największą sprzedaż?
-- Cel: Analiza trendów sezonowych i rocznych.
-- Analiza Trendu Miesięcznego (Rok do Roku)
SELECT 
    YEAR(order_purchase_timestamp) AS year_num,
    MONTHNAME(order_purchase_timestamp) AS month_name,
    MONTH(order_purchase_timestamp) AS month_num,
    COUNT(*) AS total_orders,
    ROUND(SUM(i.price + i.freight_value), 2) AS monthly_revenue
FROM olist_orders o
JOIN olist_order_items i ON o.order_id = i.order_id
GROUP BY year_num, month_name, month_num
ORDER BY year_num, month_num;

-- tu skonczylem teraz do readme apropo 7 i dalej...