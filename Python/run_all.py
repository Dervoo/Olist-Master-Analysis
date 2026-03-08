import subprocess
import sys
import os

def run_script(script_path):
    print(f"\n--- Uruchamianie: {script_path} ---")
    try:
        # Używamy sys.executable, aby mieć pewność, że korzystamy z tego samego Pythona
        result = subprocess.run([sys.executable, script_path], check=True, capture_output=True, text=True)
        print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Błąd w {script_path}:")
        print(e.stderr)
        return False

if __name__ == "__main__":
    print("====================================================")
    print("      Olist ADVANCED Python Analytics Pipeline      ")
    print("====================================================\n")
    
    scripts = [
        "Python/scripts/etl_pipeline.py",
        "Python/scripts/rfm_analysis.py",
        "Python/scripts/cohort_analysis.py",
        "Python/scripts/sales_forecasting.py",
        "Python/scripts/delivery_prediction.py",
        "Python/scripts/sentiment_analysis.py",
        "Python/scripts/logistics_optimization.py",
        "Python/scripts/generate_report.py"
    ]
    
    success_count = 0
    for script in scripts:
        if run_script(script):
            success_count += 1
            
    print("\n====================================================")
    print(f"Zakończono! Pomyślnie uruchomiono {success_count}/{len(scripts)} skryptów.")
    print("Twoje wyniki (CSV, Model, PDF) są w: Python_Results/")
    print("\nWYGENEROWANO RAPORT: Python_Results/Olist_Executive_Summary.pdf")
    print("Uruchom interaktywny dashboard: streamlit run Python/streamlit_app/app.py")
    print("====================================================")
