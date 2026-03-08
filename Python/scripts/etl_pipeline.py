import pandas as pd
import sqlite3
import os
import glob

def clean_data(df, file_name):
    """Przykładowe reguły czyszczenia danych dla konkretnych plików."""
    # Konwersja kolumn z datą (szukamy fraz 'timestamp' lub 'date' w nazwie)
    date_cols = [col for col in df.columns if 'timestamp' in col or 'date' in col]
    for col in date_cols:
        df[col] = pd.to_datetime(df[col], errors='coerce')
    
    # Obsługa brakujących wartości (proste usunięcie lub wypełnienie)
    if 'order_status' in df.columns:
        df = df.dropna(subset=['order_status'])
        
    return df

def run_etl():
    """Uruchamia proces ETL: CSV -> Cleaning -> SQLite."""
    csv_path = 'Olist Core Data'
    db_path = 'Python_Results/olist_clean.db'
    
    if not os.path.exists('Python_Results'):
        os.makedirs('Python_Results')
        
    # Połączenie z bazą SQLite
    conn = sqlite3.connect(db_path)
    print(f"--- Start ETL Pipeline: Zapis do {db_path} ---")
    
    csv_files = glob.glob(os.path.join(csv_path, "*.csv"))
    
    for file in csv_files:
        table_name = os.path.basename(file).replace('.csv', '')
        print(f"Przetwarzanie: {table_name}...")
        
        # Wczytanie i czyszczenie
        df = pd.read_csv(file)
        df_clean = clean_data(df, table_name)
        
        # Zapis do bazy (zastępujemy stare tabele)
        df_clean.to_sql(table_name, conn, if_exists='replace', index=False)
        print(f"  [OK] Załadowano {len(df_clean)} rekordów do tabeli '{table_name}'.")
        
    conn.close()
    print("\n--- ETL Zakończony Sukcesem ---")

if __name__ == "__main__":
    run_etl()
