import pandas as pd
import numpy as np
import os
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error
import joblib

def load_data():
    base_path = 'Olist Core Data'
    orders = pd.read_csv(os.path.join(base_path, 'olist_orders_dataset.csv'))
    customers = pd.read_csv(os.path.join(base_path, 'olist_customers_dataset.csv'))
    return orders, customers

def train_delivery_model(orders, customers):
    # Połączenie i czyszczenie
    df = pd.merge(orders, customers, on='customer_id')
    df = df[df['order_status'] == 'delivered'].copy()
    
    # Konwersja dat
    df['order_purchase_timestamp'] = pd.to_datetime(df['order_purchase_timestamp'])
    df['order_delivered_customer_date'] = pd.to_datetime(df['order_delivered_customer_date'])
    
    # Obliczamy faktyczny czas dostawy (Target)
    df['actual_delivery_days'] = (df['order_delivered_customer_date'] - df['order_purchase_timestamp']).dt.days
    
    # Wybieramy cechy (Features)
    # Dla uproszczenia: godzina zakupu, dzień tygodnia, region (state)
    df['purchase_hour'] = df['order_purchase_timestamp'].dt.hour
    df['purchase_day_of_week'] = df['order_purchase_timestamp'].dt.dayofweek
    
    # Kodowanie stanów (One-Hot Encoding dla uproszczenia)
    X = pd.get_dummies(df[['purchase_hour', 'purchase_day_of_week', 'customer_state']], drop_first=True)
    y = df['actual_delivery_days'].fillna(df['actual_delivery_days'].median())
    
    # Split danych
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # Model
    print("Trenowanie modelu regresji dla czasu dostawy...")
    model = RandomForestRegressor(n_estimators=50, max_depth=10, random_state=42)
    model.fit(X_train, y_train)
    
    # Ewaluacja
    y_pred = model.predict(X_test)
    mae = mean_absolute_error(y_test, y_pred)
    
    return model, mae, X.columns.tolist()

if __name__ == "__main__":
    print("--- Start Delivery Prediction Model ---")
    try:
        orders, customers = load_data()
        model, mae, features = train_delivery_model(orders, customers)
        
        output_dir = 'Python_Results'
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
            
        # Zapisujemy model i listę cech
        joblib.dump(model, os.path.join(output_dir, 'delivery_model.pkl'))
        pd.Series(features).to_csv(os.path.join(output_dir, 'model_features.csv'), index=False)
        
        print(f"Model wytrenowany! Średni błąd (MAE): {mae:.2f} dni.")
        print(f"Model zapisany jako: {output_dir}/delivery_model.pkl")
        
    except Exception as e:
        print(f"Błąd podczas modelowania: {e}")
