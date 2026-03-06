# Olist Data Engineering & Logistics Analysis | Analiza Logistyki i Inżynierii Danych
   
Comprehensive analysis of the Olist e-commerce ecosystem. / Kompleksowa analiza ekosystemu e-commerce Olist.

---

## 🛠️ 1. Technical Challenges & Solutions | Wyzwania Techniczne i Rozwiązania

| Feature / Cecha | Technical Problem (EN) | Problem Techniczny (PL) | Solution / Rozwiązanie |
| :--- | :--- | :--- | :--- |
| **Performance** | MySQL Import Wizard failed on large Olist datasets. | Kreator MySQL nie radził sobie z dużymi zbiorami danych. | **LOAD DATA INFILE** + `\n` (**50x faster/szybciej**). |
| **Data Cleaning** | CSV files contained "#VALUE!" strings from Excel. | Pliki CSV zawierały błędy "#ADR!" z Excela. | `NULLIF()` + SQL `DATEDIFF()` recalculation. |
| **Schema Integrity** | Error 1262 due to redundant manual Excel columns. | Błąd 1262 przez nadmiarowe kolumny z ręcznej analizy. | **User Variables (`@dummy`)** to skip metadata. |
| **Analytics** | Shipping costs > 2000% of product price (outliers). | Koszty wysyłki > 2000% ceny towaru (anomalie). | **`v_master_orders_report`** (Filtered View). |

---

## 💡 2. Business & Financial Insights | Wnioski Biznesowe i Finansowe

### 💰 Order Financial Structure | Struktura Finansowa Zamówień
* **EN:** Shipping costs for low-value items reach up to **35% of total value**, creating a barrier to conversion.
* **PL:** Koszt transportu tanich produktów stanowi nawet **35% ceny całkowitej**, co jest barierą zniechęcającą do zakupu.
* **Insight:** High shipping (e.g., 85 BRL for a 179 BRL item) suggests that product dimensions or distance drastically inflate prices.
* **Wniosek:** Wysokie koszty wysyłki sugerują, że gabaryty produktów lub odległości drastycznie podnoszą cenę końcową.

### 📉 Revenue Loss Analysis | Analiza Utraconych Przychodów
* **EN:** Canceled orders average **195.36 BRL**, while delivered ones average **139.93 BRL**. The platform is losing its most valuable transactions.
* **PL:** Średnia wartość anulowanego zamówienia (195.36 BRL) jest znacznie wyższa niż dostarczonego. Firma traci najcenniejsze transakcje.
* **EN:** "Unavailable" status hits premium items (Avg. **305.78 BRL**), indicating poor inventory sync for luxury goods.
* **PL:** Status "Unavailable" dotyczy głównie towarów premium (śr. 305.78 BRL), co wskazuje na błędy synchronizacji stanów magazynowych.

### 🚚 Shipping Efficiency | Rentowność Logistyczna
* **EN:** Identified cases where delivery costs are **2600% higher** than product price (0.85 BRL vs 22.30 BRL).
* **PL:** Zidentyfikowano przypadki, gdzie koszt dostawy stanowił ponad **2600% ceny** produktu (0.85 BRL vs 22.30 BRL).
* **Recommendation:** Introduce **Free Shipping Thresholds** or minimum order value for specific categories.
* **Rekomendacja:** Wprowadzenie progu darmowej dostawy lub minimalnej wartości koszyka.

---

## 🚩 3. Seller Logistics Performance | Wydajność Logistyczna Sprzedawców

### 🚚 Delay Analysis | Analiza Opóźnień
* **EN:** Seller `4a3ca...` had **189 late orders**. ~10% of their shipments are delayed, damaging platform NPS.
* **PL:** Sprzedawca `4a3ca...` wygenerował **189 spóźnień**. Niemal 10% jego wysyłek jest spóźnionych, co obniża NPS platformy.
* **EN:** Seller `06a2c...` shows a **20% late ratio**, suggesting systemic fulfillment issues.
* **PL:** Sprzedawca `06a2c...` ma aż **20% spóźnień**, co sugeruje systemowe problemy z procesowaniem zamówień.

### 📈 Visualizations Breakdown | Podsumowanie Wizualizacji
1. **15-Day Window:** Most delays occur around the 15-day delivery mark.
   * *Największa ilość opóźnień przy dostawie trwającej 15 dni.*
2. **Seller Ranking:** Identification of top offenders by absolute delay volume.
   * *Ranking sprzedawców z największą ilością spóźnień ogółem.*
3. **Volume Analysis (10-50 trans.):** Highlighting risk for mid-scale transactions.
   * *Analiza opóźnień dla transakcji w przedziale 10-50.*

---

## 🚀 4. Action Points | Plan Działania
* **Warning System:** Alerts for sellers exceeding a **15% delay threshold**.
* **System ostrzeżeń:** Dla sprzedawców przekraczających **15% spóźnień**.
* **Audit:** Review warehouse processes for top problematic sellers.
* **Audyt:** Kontrola procesów magazynowych u najbardziej problematycznych dostawców.

# Olist E-commerce Analytics: SQL & Power BI Deep Dive 📊

This project focuses on identifying logistical bottlenecks and financial opportunities within the Olist ecosystem. Below is a full catalog of the analytical queries developed, categorized by business objective.

---

## 🛠️ 1. ETL & Data Preparation
### Inżynieria danych i przygotowanie warstwy raportowej

**Q1: Total Order Value / Pełna wartość zamówienia** *EN: Merging status data with pricing for a full operational overview.* *PL: Łączenie danych o statusach z cenami dla pełnego obrazu operacyjnego.*
```sql
SELECT o.order_id, o.order_status, o.is_late, i.price, i.freight_value,
(i.price + i.freight_value) AS total_order_value
FROM olist_orders o JOIN olist_order_items i ON o.order_id = i.order_id LIMIT 20;

**Q4: Reporting View / Tworzenie widoku raportowego EN: Consolidating data types for seamless Power BI integration. PL: Konsolidacja typów danych pod płynną integrację z Power BI.

CREATE VIEW v_master_orders_report AS
SELECT o.order_id, o.order_status, o.is_late, CAST(o.actual_delivery_time AS SIGNED) AS delivery_days,
i.product_id, i.seller_id, i.price, i.freight_value, (i.price + i.freight_value) AS total_order_amount
FROM olist_orders o JOIN olist_order_items i ON o.order_id = i.order_id WHERE o.order_status = 'delivered';

💰 2. Financial Performance
Analiza finansowa
Q2: Status vs. Avg Value / Status a średnia wartość EN: Checking if higher-value orders are lost during cancellation. PL: Sprawdzenie, czy tracimy droższe zamówienia w procesie anulacji.

SQL
SELECT order_status, COUNT(*) AS total_orders, AVG(price + freight_value) AS avg_order_value
FROM olist_orders o JOIN olist_order_items i ON o.order_id = i.order_id
GROUP BY order_status ORDER BY total_orders DESC;
Q3: Correlation: Value & Latency / Korelacja wartości i spóźnienia EN: Verifying if higher-value orders are prioritized (less frequent delays). PL: Weryfikacja, czy droższe zamówienia są traktowane priorytetowo.

SQL
SELECT is_late, COUNT(*) as number_of_orders, ROUND(AVG(price + freight_value), 2) as avg_value
FROM olist_orders o JOIN olist_order_items i ON o.order_id = i.order_id GROUP BY is_late;
Q5: Shipping Cost Ratio / Procentowy koszt wysyłki EN: Identifying orders where transport is disproportionately expensive. PL: Identyfikacja zamówień z nieproporcjonalnie drogim transportem.

SQL
SELECT order_id, price, freight_value, ROUND((freight_value / price) * 100, 2) AS freight_ratio_pct
FROM v_master_orders_report ORDER BY freight_ratio_pct DESC LIMIT 10;
🚚 3. Logistics & Seller Performance
Wydajność logistyczna i rankingi sprzedawców
Q6: Top Delays by Seller / Ranking spóźnień sprzedawców EN: Monitoring the performance quality of business partners. PL: Monitoring jakości pracy partnerów biznesowych.

SQL
SELECT seller_id, COUNT(*) as total_orders, SUM(CASE WHEN is_late = 'Yes' THEN 1 ELSE 0 END) as late_count
FROM v_master_orders_report GROUP BY seller_id HAVING total_orders > 5 ORDER BY late_count DESC LIMIT 10;
Q11: Delivery Promise Gap / Błąd obietnicy dostawy EN: Precision of the delivery time estimation algorithm by city. PL: Precyzja algorytmu szacującego czas dostawy w podziale na miasta.

SQL
SELECT customer_city, ROUND(AVG(Estimated_vs_Actual), 2) AS avg_days_off, COUNT(*) AS total_orders
FROM olist_dataset_general WHERE is_late = 'Yes' GROUP BY customer_city HAVING total_orders > 20 ORDER BY avg_days_off ASC;
Q14: Actual Delay Days / Realne dni spóźnienia EN: Calculating the magnitude of delays in problematic cities. PL: Obliczanie skali opóźnień w najbardziej problematycznych miastach.

SQL
SELECT customer_city, COUNT(*) as total_orders, ROUND(AVG(ABS(Estimated_vs_Actual)), 2) as avg_delay_days, 
MAX(ABS(Estimated_vs_Actual)) as worst_delay_days FROM olist_dataset_general WHERE is_late = 'Yes'
GROUP BY customer_city HAVING total_orders > 30 ORDER BY avg_delay_days DESC LIMIT 10;
Q16: Reliability Ratio / Wskaźnik niezawodności miast EN: Identifying cities with the lowest delay rates. PL: Identyfikacja miast o najniższym współczynniku spóźnień.

SQL
SELECT customer_city, COUNT(*) as total_orders, ROUND(SUM(CASE WHEN is_late = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as delay_rate_pct
FROM olist_dataset_general GROUP BY customer_city HAVING total_orders > 100 AND delay_rate_pct < 2.00 ORDER BY delay_rate_pct ASC;
👤 4. Customer Insights & Satisfaction
Perspektywa klienta i satysfakcja
Q8 & Q9: Geographical Satisfaction / Satysfakcja geograficzna EN: Mapping customer engagement and high-rated reviews by city. PL: Mapowanie zaangażowania klientów i wysokich ocen według miast.

SQL
SELECT customer_city, COUNT(*) as liczba_opinii, ROUND(AVG(review_score), 2) as avg_score
FROM olist_dataset_general WHERE order_status IS NOT NULL 
GROUP BY customer_city HAVING liczba_opinii >= 50 AND avg_score >= 4.00 ORDER BY liczba_opinii DESC LIMIT 10;
Q10: Payment Type vs. Delay / Typ płatności a spóźnienia EN: Checking if payment methods correlate with processing speed. PL: Sprawdzenie, czy metoda płatności koreluje z szybkością procesowania.

SQL
SELECT is_late, payment_type, COUNT(*) as total_orders, ROUND(AVG(payment_value), 2) as avg_revenue, ROUND(AVG(review_score), 2) as avg_satisfaction
FROM olist_dataset_general GROUP BY is_late, payment_type;
Q12: Retention Rate Analysis / Analiza powracalności EN: Evaluating loyalty and repeat purchase behavior. PL: Ocena lojalności i zachowań zakupowych.

SQL
SELECT sub.purchase_count, COUNT(*) as number_of_customers, ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as pct_of_total
FROM (SELECT customer_id, COUNT(order_id) as purchase_count FROM v_master_general_data_3 GROUP BY customer_id) sub
GROUP BY sub.purchase_count;
Q13: Purchase Period / Dzień zakupu a satysfakcja EN: Comparing weekend vs. weekday delivery performance. PL: Porównanie wydajności dostaw dla zakupów w weekendy i dni robocze.

SQL
SELECT CASE WHEN DAYOFWEEK(order_purchase_timestamp) IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END as purchase_period,
COUNT(*) as total_orders, ROUND(AVG(review_score), 2) as avg_satisfaction
FROM olist_dataset_general GROUP BY purchase_period;
Q15: Shipping Price vs. Review / Koszt wysyłki a ocena EN: Does higher shipping cost translate to better customer experience? PL: Czy wyższy koszt wysyłki przekłada się na lepsze doświadczenie klienta?

SQL
SELECT CASE WHEN freight_value < 50 THEN 'Cheap' WHEN freight_value BETWEEN 50 AND 150 THEN 'Medium' ELSE 'Expensive' END as shipping_tier,
ROUND(AVG(review_score), 2) as avg_satisfaction
FROM v_master_general_data_3 WHERE order_status = 'delivered' GROUP BY shipping_tier;
📉 5. Risk Management & Trends
Zarządzanie ryzykiem i trendy
Q7: Revenue Trends / Trendy przychodów EN: Monthly revenue analysis (Year-over-Year). PL: Miesięczna analiza przychodów (Rok do roku).

SQL
SELECT YEAR(order_purchase_timestamp) AS year_num, MONTHNAME(order_purchase_timestamp) AS month_name, 
ROUND(SUM(i.price + i.freight_value), 2) AS monthly_revenue
FROM olist_orders o JOIN olist_order_items i ON o.order_id = i.order_id 
GROUP BY year_num, month_name, MONTH(order_purchase_timestamp) ORDER BY year_num, MONTH(order_purchase_timestamp);
Q17: Financial Value at Risk / Wartość finansowa ryzyka EN: Total value of delayed orders with 1-star reviews. PL: Łączna wartość spóźnionych zamówień z oceną 1 gwiazdka.

SQL
SELECT is_late, review_score, COUNT(*) as number_of_orders, ROUND(SUM(payment_value), 2) as total_at_risk_value
FROM v_master_general_data_3 WHERE is_late = 'Yes' AND review_score = 1 GROUP BY is_late, review_score;
Q18: Order Categorization / Segmentacja problemów EN: Classification of orders by value to identify critical segments. PL: Klasyfikacja zamówień według wartości dla identyfikacji segmentów krytycznych.

SQL
SELECT order_id, payment_value, CASE WHEN payment_value < 30 THEN 'Micro-order' WHEN payment_value BETWEEN 30 AND 100 THEN 'Standard' ELSE 'High-value' END as order_category
FROM v_master_general_data_3 ORDER BY payment_value ASC LIMIT 150;