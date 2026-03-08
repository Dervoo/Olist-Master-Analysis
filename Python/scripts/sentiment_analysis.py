import pandas as pd
from textblob import TextBlob
import os

def load_reviews():
    path = os.path.join('Olist Core Data', 'olist_order_reviews_dataset.csv')
    df = pd.read_csv(path)
    # Wybieramy tylko te rekordy, które mają komentarz tekstowy
    df = df.dropna(subset=['review_comment_message'])
    return df

def analyze_sentiment(df):
    print("Analizowanie nastroju w komentarzach (NLP)...")
    
    # Funkcja pomocnicza: 1 = Pozytywny, 0 = Neutralny, -1 = Negatywny
    def get_sentiment(text):
        analysis = TextBlob(str(text))
        # Polarity: -1.0 to 1.0 (Skalujemy do kategorycznego)
        if analysis.sentiment.polarity > 0.1:
            return 'Positive'
        elif analysis.sentiment.polarity < -0.1:
            return 'Negative'
        else:
            return 'Neutral'

    df['Sentiment'] = df['review_comment_message'].apply(get_sentiment)
    return df

if __name__ == "__main__":
    print("--- Start Sentiment Analysis ---")
    try:
        reviews = load_reviews()
        # Przykładowa próbka 5000 dla szybkości (można zwiększyć)
        reviews_sample = reviews.head(5000).copy()
        
        results = analyze_sentiment(reviews_sample)
        
        output_dir = 'Python_Results'
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
            
        results.to_csv(os.path.join(output_dir, 'sentiment_analysis_results.csv'), index=False)
        
        # Statystyki
        stats = results['Sentiment'].value_counts(normalize=True) * 100
        print("\nPodsumowanie nastrojów:")
        print(stats.round(2).astype(str) + '%')
        print(f"Wyniki zapisano w {output_dir}/sentiment_analysis_results.csv")
        
    except Exception as e:
        print(f"Błąd podczas NLP: {e}")
