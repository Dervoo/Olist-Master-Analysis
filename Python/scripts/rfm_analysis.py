import pandas as pd
import numpy as np
import os
from datetime import datetime

def load_data():
    """Wczytuje niezbędne pliki CSV z Olist Core Data."""
    base_path = os.path.join('..', '..', 'Olist Core Data')
    
    # Obsługa ścieżki względnej (zależy skąd uruchamiamy skrypt)
    if not os.path.exists(base_path):
        base_path = os.path.join('Olist Core Data')
    
    orders = pd.read_csv(os.path.join(base_path, 'olist_orders_dataset.csv'))
    payments = pd.read_csv(os.path.join(base_path, 'olist_order_payments_dataset.csv'))
    customers = pd.read_csv(os.path.join(base_path, 'olist_customers_dataset.csv'))
    
    return orders, payments, customers

def perform_rfm_analysis(orders, payments, customers):
    """Przeprowadza segmentację RFM."""
    
    # 1. Przygotowanie danych (Merge)
    # Sumujemy płatności na poziomie zamówienia (order_id)
    order_payments = payments.groupby('order_id')['payment_value'].sum().reset_index()
    
    # Łączymy zamówienia z klientami i płatnościami
    df = pd.merge(orders, customers, on='customer_id')
    df = pd.merge(df, order_payments, on='order_id')
    
    # Wybieramy tylko dostarczone zamówienia
    df = df[df['order_status'] == 'delivered'].copy()
    
    # Konwersja daty
    df['order_purchase_timestamp'] = pd.to_datetime(df['order_purchase_timestamp'])
    
    # 2. Obliczanie metryk
    # Przyjmujemy datę "dzisiejszą" jako dzień po ostatnim zamówieniu w zbiorze
    now = df['order_purchase_timestamp'].max() + pd.Timedelta(days=1)
    
    rfm = df.groupby('customer_unique_id').agg({
        'order_purchase_timestamp': lambda x: (now - x.max()).days, # Recency
        'order_id': 'count',                                         # Frequency
        'payment_value': 'sum'                                      # Monetary
    }).rename(columns={
        'order_purchase_timestamp': 'Recency',
        'order_id': 'Frequency',
        'payment_value': 'Monetary'
    })
    
    # 3. Punktacja (Scoring 1-5) - im niższy Recency, tym lepiej (5)
    rfm['R_Score'] = pd.qcut(rfm['Recency'], 5, labels=[5, 4, 3, 2, 1])
    # Frequency i Monetary - im wyższy, tym lepiej (obsługa duplikatów w Frequency)
    rfm['F_Score'] = pd.qcut(rfm['Frequency'].rank(method='first'), 5, labels=[1, 2, 3, 4, 5])
    rfm['M_Score'] = pd.qcut(rfm['Monetary'], 5, labels=[1, 2, 3, 4, 5])
    
    # RFM Score jako suma (do ogólnego rankingu)
    rfm['RFM_Total_Score'] = rfm[['R_Score', 'F_Score', 'M_Score']].sum(axis=1)
    
    # 4. Segmentacja biznesowa (przykładowa logika)
    def segment_customer(df):
        r = int(df['R_Score'])
        f = int(df['F_Score'])
        if r >= 4 and f >= 4:
            return 'Champions'
        elif r >= 3 and f >= 3:
            return 'Loyal Customers'
        elif r >= 4 and f <= 2:
            return 'Recent Customers'
        elif r <= 2 and f >= 4:
            return 'Can\'t Lose Them'
        elif r <= 2 and f <= 2:
            return 'Hibernating'
        else:
            return 'Others'

    rfm['Segment'] = rfm.apply(segment_customer, axis=1)
    
    return rfm

if __name__ == "__main__":
    print("--- Start RFM Analysis ---")
    
    try:
        orders, payments, customers = load_data()
        rfm_results = perform_rfm_analysis(orders, payments, customers)
        
        # Statystyki segmentów
        segment_stats = rfm_results.groupby('Segment').agg({
            'Recency': 'mean',
            'Frequency': 'mean',
            'Monetary': ['mean', 'count']
        }).round(2)
        
        print("\nPodsumowanie segmentów:")
        print(segment_stats)
        
        # Zapis wyników
        output_dir = os.path.join('..', '..', 'Python_Results')
        if not os.path.exists(output_dir):
            # Próba zapisu w aktualnym folderze jeśli relatywny nie istnieje
            output_dir = 'Python_Results'
            
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
            
        output_file = os.path.join(output_dir, 'rfm_segmentation.csv')
        rfm_results.to_csv(output_file)
        print(f"\nWyniki zapisano w: {output_file}")
        
    except Exception as e:
        print(f"Błąd podczas analizy: {e}")
