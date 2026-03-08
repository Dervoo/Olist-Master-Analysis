import pandas as pd
from sklearn.cluster import KMeans
import os

def load_geodata():
    path = os.path.join('Olist Core Data', 'olist_geolocation_dataset.csv')
    # Wczytujemy z próbkowaniem, bo plik ma 1M+ rekordów
    df = pd.read_csv(path).sample(20000, random_state=42)
    return df[['geolocation_lat', 'geolocation_lng']]

def optimize_logistics(df, n_hubs=5):
    print(f"Wyznaczanie {n_hubs} optymalnych hubów logistycznych (K-Means Clustering)...")
    
    # Usuwamy błędy w danych (NaN)
    df = df.dropna()
    
    # Modelowanie klastrów
    kmeans = KMeans(n_clusters=n_hubs, random_state=42, n_init=10)
    kmeans.fit(df)
    
    # Pobieramy centra (nasze huby)
    hubs = pd.DataFrame(kmeans.cluster_centers_, columns=['Lat', 'Lng'])
    hubs['Hub_ID'] = range(1, n_hubs + 1)
    
    return hubs

if __name__ == "__main__":
    print("--- Start Logistics Optimization ---")
    try:
        geo_data = load_geodata()
        hubs_df = optimize_logistics(geo_data)
        
        output_dir = 'Python_Results'
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
            
        hubs_df.to_csv(os.path.join(output_dir, 'optimal_logistics_hubs.csv'), index=False)
        
        print("\nWyznaczone lokalizacje Hubów (Współrzędne):")
        print(hubs_df)
        print(f"\nWyniki zapisano w {output_dir}/optimal_logistics_hubs.csv")
        
    except Exception as e:
        print(f"Błąd podczas optymalizacji geo: {e}")
