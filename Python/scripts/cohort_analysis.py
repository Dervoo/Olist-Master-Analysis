import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt
import seaborn as sns

def load_data():
    base_path = os.path.join('Olist Core Data')
    orders = pd.read_csv(os.path.join(base_path, 'olist_orders_dataset.csv'))
    customers = pd.read_csv(os.path.join(base_path, 'olist_customers_dataset.csv'))
    return orders, customers

def perform_cohort_analysis(orders, customers):
    # Połączenie danych
    df = pd.merge(orders, customers, on='customer_id')
    
    # Konwersja dat
    df['order_purchase_timestamp'] = pd.to_datetime(df['order_purchase_timestamp'])
    
    # Wyciągnięcie miesiąca zamówienia
    def get_month(x): return pd.Timestamp(x.year, x.month, 1)
    df['order_month'] = df['order_purchase_timestamp'].apply(get_month)
    
    # Znalezienie miesiąca pierwszej transakcji dla każdego klienta (Kohorta)
    grouping = df.groupby('customer_unique_id')['order_month']
    df['cohort_month'] = grouping.transform('min')
    
    # Obliczanie różnicy miesięcy (Cohort Index)
    def get_date_int(df, column):
        year = df[column].dt.year
        month = df[column].dt.month
        return year, month

    purchase_year, purchase_month = get_date_int(df, 'order_month')
    cohort_year, cohort_month = get_date_int(df, 'cohort_month')
    
    years_diff = purchase_year - cohort_year
    months_diff = purchase_month - cohort_month
    df['cohort_index'] = years_diff * 12 + months_diff + 1
    
    # Budowanie macierzy kohortowej (liczba unikalnych klientów)
    cohort_data = df.groupby(['cohort_month', 'cohort_index'])['customer_unique_id'].nunique().reset_index()
    cohort_counts = cohort_data.pivot(index='cohort_month', columns='cohort_index', values='customer_unique_id')
    
    # Obliczanie retencji w procentach
    cohort_sizes = cohort_counts.iloc[:, 0]
    retention = cohort_counts.divide(cohort_sizes, axis=0)
    
    return retention

if __name__ == "__main__":
    print("--- Start Cohort Analysis ---")
    try:
        orders, customers = load_data()
        retention_matrix = perform_cohort_analysis(orders, customers)
        
        # Zapis do CSV
        output_dir = 'Python_Results'
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
            
        retention_matrix.to_csv(os.path.join(output_dir, 'cohort_retention.csv'))
        print(f"Analiza kohortowa zakończona. Wyniki zapisano w {output_dir}/cohort_retention.csv")
        
        # Opcjonalnie: Wyświetl fragment
        print("\nFragment macierzy retencji (pierwsze 5 kohort):")
        print(retention_matrix.head().iloc[:, :6])
        
    except Exception as e:
        print(f"Błąd: {e}")
