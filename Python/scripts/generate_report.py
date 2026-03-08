from fpdf import FPDF
import pandas as pd
import os
from datetime import datetime

class PDF(FPDF):
    def header(self):
        self.set_font('Arial', 'B', 16)
        self.cell(0, 10, 'Olist Business Analytics - Executive Summary', 0, 1, 'C')
        self.set_font('Arial', '', 10)
        self.cell(0, 10, f'Generated on: {datetime.now().strftime("%Y-%m-%d %H:%M")}', 0, 1, 'C')
        self.ln(10)

    def chapter_title(self, title):
        self.set_font('Arial', 'B', 12)
        self.set_fill_color(200, 220, 255)
        # Usuwamy polskie znaki dla kompatybilności z latin-1
        safe_title = title.replace('ó', 'o').replace('ł', 'l').replace('ą', 'a').replace('ć', 'c').replace('ę', 'e').replace('ń', 'n').replace('ś', 's').replace('ź', 'z').replace('ż', 'z')
        self.cell(0, 10, safe_title, 0, 1, 'L', fill=True)
        self.ln(4)

    def chapter_body(self, body):
        self.set_font('Arial', '', 10)
        # Usuwamy polskie znaki dla kompatybilności z latin-1
        safe_body = body.replace('ó', 'o').replace('ł', 'l').replace('ą', 'a').replace('ć', 'c').replace('ę', 'e').replace('ń', 'n').replace('ś', 's').replace('ź', 'z').replace('ż', 'z')
        self.multi_cell(0, 8, safe_body)
        self.ln()

def generate_report():
    print("Generowanie raportu PDF Executive Summary (Bezpieczne kodowanie)...")
    results_dir = 'Python_Results'
    pdf = PDF()
    pdf.add_page()

    # 1. RFM Summary
    rfm_path = os.path.join(results_dir, 'rfm_segmentation.csv')
    if os.path.exists(rfm_path):
        rfm_df = pd.read_csv(rfm_path)
        segments = rfm_df['Segment'].value_counts()
        rfm_text = "Analiza segmentacji klientow (RFM) wykazala:\n"
        for seg, count in segments.items():
            rfm_text += f"- {seg}: {count} klientow\n"
        
        pdf.chapter_title("1. Segmentacja Klientow (RFM)")
        pdf.chapter_body(rfm_text)

    # 2. Sales Forecast
    forecast_path = os.path.join(results_dir, 'sales_forecast_30d.csv')
    if os.path.exists(forecast_path):
        forecast_df = pd.read_csv(forecast_path)
        avg_sales = forecast_df['y_forecast'].mean()
        forecast_text = (f"Na podstawie historycznych trendow sprzedazy, prognozowana srednia "
                         f"sprzedaz dzienna na kolejne 30 dni wynosi: {avg_sales:.2f} BRL.\n"
                         f"Calkowity spodziewany przychod (30 dni): {forecast_df['y_forecast'].sum():.2f} BRL.")
        
        pdf.chapter_title("2. Prognoza Sprzedazy (30 dni)")
        pdf.chapter_body(forecast_text)

    # 3. Sentiment Analysis
    sentiment_path = os.path.join(results_dir, 'sentiment_analysis_results.csv')
    if os.path.exists(sentiment_path):
        sent_df = pd.read_csv(sentiment_path)
        stats = sent_df['Sentiment'].value_counts(normalize=True) * 100
        sent_text = "Analiza nastroju (NLP) na podstawie komentarzy klientow:\n"
        for mood, pct in stats.items():
            sent_text += f"- {mood}: {pct:.1f}%\n"
        
        pdf.chapter_title("3. Analiza Nastroju Klientow (Sentiment Analysis)")
        pdf.chapter_body(sent_text)

    # Save PDF
    abs_results_dir = os.path.abspath('Python_Results')
    if not os.path.exists(abs_results_dir):
        os.makedirs(abs_results_dir)
        
    output_path = os.path.join(abs_results_dir, 'Olist_Executive_Summary.pdf')
    pdf.output(output_path)
    print(f"Raport PDF zapisany pomyslnie w: {output_path}")

if __name__ == "__main__":
    try:
        generate_report()
    except Exception as e:
        print(f"Blad podczas generowania raportu: {e}")
