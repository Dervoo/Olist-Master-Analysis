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

-- Pytanie 8: Które miasta są najbardziej aktywne w recenzowaniu zamówień?
-- Cel: Identyfikacja geograficznych wzorców zaangażowania klientów w platformę.

SELECT 
    customer_city, 
    COUNT(*) as liczba_opinii,
    ROUND(AVG(LENGTH(order_status)), 2) as avg_comment_length, -- Zakładając, że tu masz tekst recenzji
    ROUND(AVG(review_score), 2) as avg_score
FROM olist_dataset_general
WHERE order_status IS NOT NULL -- Tu wstaw nazwę kolumny z tekstem recenzji
GROUP BY customer_city
HAVING liczba_opinii >= 50
ORDER BY avg_comment_length DESC
LIMIT 10;

-- Pytanie 9: W których miastach klienci wystawiają najwięcej recenzji o wysokich ocenach?
-- Cel: Identyfikacja geograficznych wzorców zadowolenia klientów

SELECT 
    customer_city, 
    COUNT(*) as liczba_opinii, -- Zakładając, że tu masz tekst recenzji
    ROUND(AVG(review_score), 2) as avg_score
FROM olist_dataset_general
WHERE order_status IS NOT NULL -- Tu wstaw nazwę kolumny z tekstem recenzji
GROUP BY customer_city
HAVING liczba_opinii >= 50 AND avg_score >= 4.00
ORDER BY liczba_opinii DESC
LIMIT 100;

-- Pytanie 10: Jaki jest związek między typem płatności a spóźnieniami?
-- Cel: Sprawdzenie, czy niektóre metody płatności są bardziej narażone na opóźnienia, co może wskazywać na problemy z przetwarzaniem płatności lub preferencje klientów.

CREATE VIEW v_business_health_check AS
SELECT 
    is_late,
    payment_type,
    COUNT(*) as total_orders,
    ROUND(AVG(payment_value), 2) as avg_revenue,
    ROUND(AVG(review_score), 2) as avg_satisfaction
FROM olist_dataset_general
GROUP BY is_late, payment_type;

SELECT * FROM olist_dataset_general;

-- Pytanie 11: O ile dni Olist myli się w swoich obietnicach dostawy w podziale na stany?
-- Cel: Pokazanie precyzji algorytmu szacującego czas dostawy.
SELECT 
    customer_city,
    ROUND(AVG(Estimated_vs_Actual), 2) AS avg_days_off,
    COUNT(*) AS total_orders
FROM olist_dataset_general
WHERE is_late = 'Yes'
GROUP BY customer_city
HAVING total_orders > 20
ORDER BY avg_days_off ASC;

-- Pytanie 12: Jaki jest współczynnik powracalności klientów (Retention Rate)?
-- Cel: Zrozumienie, jak wielu klientów dokonuje ponownych zakupów, co jest kluczowym wskaźnikiem zdrowia biznesu e-commerce.
SELECT 
    sub.purchase_count,
    COUNT(*) as number_of_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct_of_total
FROM (
    SELECT customer_id, COUNT(order_id) as purchase_count
    FROM v_master_general_data_3
    GROUP BY customer_id
) sub
GROUP BY sub.purchase_count
ORDER BY sub.purchase_count ASC;

-- Pierwotna analiza wykazała brak powracających klientów (Retention Rate 0%). Po głębszej analizie schematu bazy danych zidentyfikowano, że kolumna customer_id odnosi się do transakcji, a nie unikalnego profilu użytkownika. Do pełnej analizy CRM wymagane byłoby dołączenie tabeli olist_customers_dataset i mapowanie po customer_unique_id.

-- Pytanie 13: Czy istnieje różnica w satysfakcji klientów w zależności od dnia tygodnia, w którym dokonali zakupu?
-- Cel: Porównanie satysfakcji w zależności od dnia zakupu.
SELECT 
    CASE WHEN DAYOFWEEK(order_purchase_timestamp) IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END as purchase_period,
    COUNT(*) as total_orders,
    ROUND(AVG(Actual_Delivery_Time), 2) as avg_delivery_time,
    ROUND(AVG(review_score), 2) as avg_satisfaction
FROM olist_dataset_general
GROUP BY purchase_period;
SELECT * FROM olist_dataset_general;

-- Pytanie 14: Jakie są realne dni spóźnienia dla zamówień oznaczonych jako "spóźnione" i czy różnią się one w zależności od miasta?
-- Poprawione Pytanie 14: Realne dni spóźnienia
SELECT 
    customer_city,
    COUNT(*) as total_orders,
    -- Używamy ABS, żeby zamienić ujemne wyniki na dodatnie dni spóźnienia
    ROUND(AVG(ABS(Estimated_vs_Actual)), 2) as avg_delay_days, 
    MAX(ABS(Estimated_vs_Actual)) as worst_delay_days
FROM olist_dataset_general
WHERE is_late = 'Yes'
GROUP BY customer_city
HAVING total_orders > 30
ORDER BY avg_delay_days DESC
LIMIT 10;

-- Pytanie 15: Czy istnieje związek między kosztem wysyłki a satysfakcją klientów?
-- Cel: Sprawdzenie, czy droższa wysyłka przekłada się na wyższą satysfakcję klientów, co może sugerować lepszą jakość usług kurierskich lub szybszą dostawę.

SELECT 
    CASE 
        WHEN freight_value < 50 THEN 'Cheap Shipping (<5)'
        WHEN freight_value BETWEEN 50 AND 150 THEN 'Medium Shipping (5-12)'
        ELSE 'Expensive Shipping (>12)'
    END as shipping_tier,
    ROUND(AVG(Actual_Delivery_Time), 2) as avg_delivery_days,
    ROUND(AVG(review_score), 2) as avg_satisfaction
FROM v_master_general_data_3
WHERE order_status = 'delivered'
GROUP BY shipping_tier;

-- Pytanie 16: Które miasta mają najlepszy stosunek liczby zamówień do spóźnień?
-- Cel: Identyfikacja miast, które są najbardziej niezawodne pod względem terminowości dostaw, co może wskazywać na lepszą infrastrukturę logistyczną lub bardziej efektywnych partnerów kurierskich.

SELECT 
    customer_city,
    COUNT(*) as total_orders,
    ROUND(SUM(CASE WHEN is_late = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as delay_rate_pct
FROM olist_dataset_general
GROUP BY customer_city
HAVING total_orders > 100 AND delay_rate_pct < 2.00
ORDER BY delay_rate_pct ASC;

-- Pytanie 17: Jaka jest wartość finansowa zamówień, które są spóźnione i mają niskie oceny recenzji?
-- Cel: Identyfikacja najbardziej problematycznych zamówień, które mogą wymagać specjalnej uwagi lub rekompensaty, aby poprawić satysfakcję klientów i zminimalizować straty finansowe.

SELECT 
    is_late,
    review_score,
    COUNT(*) as number_of_orders,
    ROUND(SUM(payment_value), 2) as total_at_risk_value
FROM v_master_general_data_3
WHERE is_late = 'Yes' AND review_score = 1
GROUP BY is_late, review_score;

-- Pytanie 18: Jakie są najbardziej problematyczne kategorie zamówień (np. niska wartość, wysoka wartość, mikro-zamówienia) w kontekście spóźnień i niskich ocen recenzji?
-- Cel: Identyfikacja segmentów zamówień, które są najbardziej narażone na problemy z dostawą i niezadowolenie klientów, co może pomóc w opracowaniu strategii poprawy obsługi tych segmentów.

SELECT 
    order_id,
    customer_city,
    payment_value,
    -- Przyjmujemy, że szukamy zamówień o bardzo niskiej wartości, gdzie transport "zjada" marżę
    CASE 
        WHEN payment_value < 30 THEN 'Micro-order'
        WHEN payment_value BETWEEN 30 AND 100 THEN 'Standard'
        ELSE 'High-value'
    END as order_category
FROM v_master_general_data_3
ORDER BY payment_value ASC
LIMIT 150;