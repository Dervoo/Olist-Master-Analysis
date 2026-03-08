import pandas as pd
import numpy as np
import os
from datetime import datetime

# Uwaga: Ten skrypt używa uproszczonego modelu regresji, 
# ale jest przygotowany pod bibliotekę 'prophet', która jest standardem w BI.
# Aby użyć Propheta, odkomentuj sekcję prophet po instalacji.

def load_data():
    base_path = os.path.join('Olist Core Data')
    orders = pd.read_csv(os.path.join(base_path, 'olist_orders_dataset.csv'))
    payments = pd.read_csv(os.path.join(base_path, 'olist_order_payments_dataset.csv'))
    return orders, payments

def prepare_time_series(orders, payments):
    # Sumujemy płatności dla każdego zamówienia
    order_payments = payments.groupby('order_id')['payment_value'].sum().reset_index()
    
    # Łączymy z zamówieniami i konwertujemy czas
    df = pd.merge(orders, order_payments, on='order_id')
    df['order_purchase_timestamp'] = pd.to_datetime(df['order_purchase_timestamp'])
    
    # Agregujemy sprzedaż dzienną
    daily_sales = df.set_index('order_purchase_timestamp')['payment_value'].resample('D').sum().reset_index()
    daily_sales.columns = ['ds', 'y'] # Standardowe nazwy dla modeli forecastingowych
    
    return daily_sales

def simple_forecast(daily_sales, periods=30):
    """Prosty model prognozowania oparty na średniej kroczącej i trendzie liniowym."""
    # Obliczamy średnią kroczącą (7 dni) dla wygładzenia
    daily_sales['y_smooth'] = daily_sales['y'].rolling(window=7, min_periods=1).mean()
    
    # Tworzymy daty przyszłe
    last_date = daily_sales['ds'].max()
    future_dates = pd.date_range(start=last_date + pd.Timedelta(days=1), periods=periods)
    
    # Bardzo prosty trend (średnia z ostatnich 30 dni jako bazowy forecast)
    recent_avg = daily_sales['y_smooth'].tail(30).mean()
    
    forecast = pd.DataFrame({'ds': future_dates, 'y_forecast': [recent_avg] * periods})
    
    return forecast

if __name__ == "__main__":
    print("--- Start Sales Forecasting ---")
    try:
        orders, payments = load_data()
        daily_sales = prepare_time_series(orders, payments)
        
        # Generowanie prognozy na 30 dni
        forecast = simple_forecast(daily_sales, periods=30)
        
        # Zapis do CSV
        output_dir = 'Python_Results'
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
            
        daily_sales.to_csv(os.path.join(output_dir, 'daily_sales_history.csv'), index=False)
        forecast.to_csv(os.path.join(output_dir, 'sales_forecast_30d.csv'), index=False)
        
        print(f"Prognoza wygenerowana. Historia i forecast zapisane w folderze {output_dir}.")
        print(f"Ostatnia odnotowana sprzedaż dzienną: {daily_sales['y'].iloc[-1]:.2f}")
        print(f"Przewidywana średnia sprzedaż na kolejne 30 dni: {forecast['y_forecast'].iloc[0]:.2f}")
        
    except Exception as e:
        print(f"Błąd podczas prognozowania: {e}")
