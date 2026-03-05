-- Pytanie 1: Jaka jest pełna wartość finansowa każdego zamówienia (cena + transport)?
-- Cel: Łączymy dane o statusach z cenami, aby uzyskać pełny obraz operacyjny każdego ID zamówienia.
-- Question 1: What is the total financial value of each order (price + shipping)?
-- Objective: We are merging status data with pricing to get a full operational overview of each order ID.
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
-- Question 2: Do orders with specific statuses (e.g., cancelled vs. delivered) differ in average value?
-- Objective: Checking whether higher-value or lower-value orders are lost during the cancellation process.
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
-- Question 3: Is there a correlation between order value and its delay?
-- Objective: Verifying the hypothesis of whether higher-value orders are prioritized (less frequent delays).
SELECT 
    is_late, 
    COUNT(*) as number_of_orders,
    ROUND(AVG(price + freight_value), 2) as avg_value
FROM olist_orders o
JOIN olist_order_items i ON o.order_id = i.order_id
GROUP BY is_late;

-- Pytanie 4: Jak przygotować dane do końcowego raportu w Power BI/Tableau?
-- Cel: Utworzenie skonsolidowanej warstwy raportowej (View), która zawiera tylko dostarczone zamówienia z poprawnymi typami danych.
-- Question 4: How to prepare data for the final Power BI/Tableau report?
-- Objective: Creating a consolidated reporting layer (View) containing only delivered orders with correct data types.
CREATE VIEW v_master_orders_report AS
SELECT 
    o.order_id,
    o.order_status,
    o.is_late,
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
-- Question 5: What percentage of the order value does the shipping cost represent?
-- Objective: Identifying orders where transport is disproportionately expensive compared to the goods.
SELECT 
    order_id, 
    price, 
    freight_value,
    ROUND((freight_value / price) * 100, 2) AS freight_ratio_pct
FROM v_master_orders_report
ORDER BY freight_ratio_pct DESC
LIMIT 10;

-- Pytanie 6 : Którzy sprzedawcy generują najwięcej spóźnień?
-- Cel: Monitoring jakości pracy partnerów biznesowych.
-- Question 6: Which sellers generate the most delays?
-- Objective: Monitoring the performance quality of business partners.
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
-- Question 7: In which years does the platform record the highest sales?
-- Objective: Analysis of seasonal and annual trends.
-- Monthly Trend Analysis (Year-over-Year)
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

-- Pytanie 8: Które miasta są najbardziej aktywne w recenzowaniu zamówień?
-- Cel: Identyfikacja geograficznych wzorców zaangażowania klientów w platformę.
-- Question 8: Which cities are most active in reviewing orders?
-- Objective: Identifying geographical patterns of customer engagement with the platform.
SELECT 
    customer_city, 
    COUNT(*) as liczba_opinii,
    ROUND(AVG(LENGTH(order_status)), 2) as avg_comment_length, 
    ROUND(AVG(review_score), 2) as avg_score
FROM olist_dataset_general
WHERE order_status IS NOT NULL 
GROUP BY customer_city
HAVING liczba_opinii >= 50
ORDER BY avg_comment_length DESC
LIMIT 10;

-- Pytanie 9: W których miastach klienci wystawiają najwięcej recenzji o wysokich ocenach?
-- Cel: Identyfikacja geograficznych wzorców zadowolenia klientów
-- Question 9: In which cities do customers post the most high-rated reviews?
-- Objective: Identifying geographical patterns of customer satisfaction.
SELECT 
    customer_city, 
    COUNT(*) as liczba_opinii, 
    ROUND(AVG(review_score), 2) as avg_score
FROM olist_dataset_general
WHERE order_status IS NOT NULL
GROUP BY customer_city
HAVING liczba_opinii >= 50 AND avg_score >= 4.00
ORDER BY liczba_opinii DESC
LIMIT 100;

-- Pytanie 10: Jaki jest związek między typem płatności a spóźnieniami?
-- Cel: Sprawdzenie, czy niektóre metody płatności są bardziej narażone na opóźnienia, co może wskazywać na problemy z przetwarzaniem płatności lub preferencje klientów.
-- Question 10: What is the relationship between payment type and delays?
-- Objective: Checking whether certain payment methods are more prone to delays, which could indicate payment processing issues or customer preferences.
CREATE VIEW v_business_health_check AS
SELECT 
    is_late,
    payment_type,
    COUNT(*) as total_orders,
    ROUND(AVG(payment_value), 2) as avg_revenue,
    ROUND(AVG(review_score), 2) as avg_satisfaction
FROM olist_dataset_general
GROUP BY is_late, payment_type;

-- Pytanie 11: O ile dni Olist myli się w swoich obietnicach dostawy w podziale na stany?
-- Cel: Pokazanie precyzji algorytmu szacującego czas dostawy.
-- Question 11: By how many days does Olist miss its delivery promises, broken down by state?
-- Objective: Showing the precision of the delivery time estimation algorithm.
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
-- Question 12: What is the Customer Retention Rate?
-- Objective: Understanding how many customers make repeat purchases, which is a key indicator of e-commerce business health.
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
-- Initial analysis showed no returning customers (Retention Rate 0%). After a deeper dive into the database schema, it was identified that the customer_id column refers to a specific transaction rather than a unique user profile. For a full CRM analysis, joining the olist_customers_dataset table and mapping by customer_unique_id would be required.
-- Question 13: Is there a difference in customer satisfaction depending on the day of the week the purchase was made?
-- Objective: Comparing satisfaction based on the day of purchase.
SELECT 
    CASE WHEN DAYOFWEEK(order_purchase_timestamp) IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END as purchase_period,
    COUNT(*) as total_orders,
    ROUND(AVG(Actual_Delivery_Time), 2) as avg_delivery_time,
    ROUND(AVG(review_score), 2) as avg_satisfaction
FROM olist_dataset_general
GROUP BY purchase_period;

-- Pytanie 14: Jakie są realne dni spóźnienia dla zamówień oznaczonych jako "spóźnione" i czy różnią się one w zależności od miasta?
-- Poprawione Pytanie 14: Realne dni spóźnienia.
-- Question 14: What are the actual delay days for orders marked as "late," and do they vary by city?
-- Revised Question 14: Actual delay days.
SELECT 
    customer_city,
    COUNT(*) as total_orders,
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
-- Question 15: Is there a relationship between shipping cost and customer satisfaction?
-- Objective: Checking whether more expensive shipping translates into higher customer satisfaction, which might suggest better courier service quality or faster delivery.
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
-- Question 16: Which cities have the best ratio of orders to delays?
-- Objective: Identifying the most reliable cities in terms of delivery punctuality, which may indicate better logistical infrastructure or more efficient courier partners.
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
-- Question 17: What is the financial value of orders that are delayed and have low review ratings?
-- Objective: Identifying the most problematic orders that may require special attention or compensation to improve customer satisfaction and minimize financial losses.
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
-- Question 18: What are the most problematic order categories (e.g., low-value, high-value, micro-orders) in the context of delays and low review ratings?
-- Objective: Identifying order segments most prone to delivery issues and customer dissatisfaction, which can help in developing strategies to improve service for these specific segments.
SELECT 
    order_id,
    customer_city,
    payment_value,
    CASE 
        WHEN payment_value < 30 THEN 'Micro-order'
        WHEN payment_value BETWEEN 30 AND 100 THEN 'Standard'
        ELSE 'High-value'
    END as order_category
FROM v_master_general_data_3
ORDER BY payment_value ASC
LIMIT 150;