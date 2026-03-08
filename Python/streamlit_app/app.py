import streamlit as st
import pandas as pd
import os
import plotly.express as px
import joblib

# Konfiguracja strony
st.set_page_config(page_title="Olist Advanced Analytics 3.0", layout="wide")

st.title("🚀 Olist Advanced Business Intelligence")
st.markdown("Kompleksowy ekosystem: SQL + Python (ML, NLP, Clustering, PDF Reports)")

# Ścieżka do wyników
RESULTS_DIR = 'Python_Results'

@st.cache_data
def load_csv(name):
    path = os.path.join(RESULTS_DIR, name)
    if os.path.exists(path):
        return pd.read_csv(path)
    return None

# Sidebar
st.sidebar.header("Ustawienia Panelu")
menu = st.sidebar.selectbox("Wybierz Moduł", 
    ["Overview & RFM", "Sales Forecasting", "Sentiment Analysis (NLP)", "Logistics Optimization", "Delivery Prediction"])

if menu == "Overview & RFM":
    st.header("👥 Segmentacja Klientów (RFM)")
    rfm_df = load_csv('rfm_segmentation.csv')
    if rfm_df is not None:
        col1, col2 = st.columns(2)
        with col1:
            fig = px.pie(rfm_df, names='Segment', title="Udział Segmentów")
            st.plotly_chart(fig, use_container_width=True)
        with col2:
            fig = px.box(rfm_df, x='Segment', y='Monetary', title="Dystrybucja Wydatków wg Segmentu")
            st.plotly_chart(fig, use_container_width=True)
    else:
        st.warning("Uruchom 'Python/run_all.py' aby wygenerować dane.")

elif menu == "Sales Forecasting":
    st.header("📈 Prognozowanie Sprzedaży")
    hist = load_csv('daily_sales_history.csv')
    fore = load_csv('sales_forecast_30d.csv')
    if hist is not None and fore is not None:
        hist['Type'] = 'Historia'
        fore['Type'] = 'Prognoza'
        fore.columns = ['ds', 'y', 'Type']
        all_data = pd.concat([hist.tail(90), fore])
        fig = px.line(all_data, x='ds', y='y', color='Type', title="Prognoza Przychodów (następne 30 dni)")
        st.plotly_chart(fig, use_container_width=True)
        st.metric("Prognozowana Średnia Dzienna", f"{fore['y'].mean():.2f} BRL")

elif menu == "Sentiment Analysis (NLP)":
    st.header("💬 Analiza Nastroju Klientów (NLP)")
    sent_df = load_csv('sentiment_analysis_results.csv')
    if sent_df is not None:
        col1, col2 = st.columns([1, 2])
        with col1:
            sentiment_counts = sent_df['Sentiment'].value_counts().reset_index()
            fig = px.bar(sentiment_counts, x='Sentiment', y='count', color='Sentiment', 
                        title="Rozkład Nastrojów (Komentarze)")
            st.plotly_chart(fig, use_container_width=True)
        with col2:
            st.subheader("Przykładowe Komentarze")
            st.dataframe(sent_df[['review_comment_message', 'Sentiment']].sample(20))
    else:
        st.warning("Brak danych NLP.")

elif menu == "Logistics Optimization":
    st.header("📍 Optymalizacja Lokalizacji Hubów")
    hubs_df = load_csv('optimal_logistics_hubs.csv')
    if hubs_df is not None:
        st.markdown("Poniżej przedstawiono 5 optymalnych lokalizacji dla nowych centrów logistycznych (K-Means Clustering).")
        # Wykorzystanie mapy Plotly
        fig = px.scatter_geo(hubs_df, lat='Lat', lon='Lng', text='Hub_ID', 
                             title="Optymalne Punkty Dystrybucji w Brazylii",
                             projection="natural earth")
        fig.update_traces(marker=dict(size=15, color="red"))
        st.plotly_chart(fig, use_container_width=True)
        st.dataframe(hubs_df)
    else:
        st.warning("Brak danych o hubach logistycznych.")

elif menu == "Delivery Prediction":
    st.header("🚚 Przewidywanie Czasu Dostawy (ML)")
    model_path = os.path.join(RESULTS_DIR, 'delivery_model.pkl')
    features_path = os.path.join(RESULTS_DIR, 'model_features.csv')
    if os.path.exists(model_path):
        model = joblib.load(model_path)
        features_list = pd.read_csv(features_path).squeeze().tolist()
        state_list = [f.replace('customer_state_', '') for f in features_list if 'customer_state_' in f]
        
        col1, col2 = st.columns(2)
        with col1:
            selected_state = st.selectbox("Stan (Region)", sorted(state_list))
            hour = st.slider("Godzina zakupu", 0, 23, 12)
        with col2:
            day = st.selectbox("Dzień tygodnia", ["Poniedziałek", "Wtorek", "Środa", "Czwartek", "Piątek", "Sobota", "Niedziela"])
            day_idx = ["Poniedziałek", "Wtorek", "Środa", "Czwartek", "Piątek", "Sobota", "Niedziela"].index(day)
            
        if st.button("Szacuj czas dostawy"):
            input_data = pd.DataFrame(0, index=[0], columns=features_list)
            input_data['purchase_hour'] = hour
            input_data['purchase_day_of_week'] = day_idx
            state_col = f'customer_state_{selected_state}'
            if state_col in input_data.columns: input_data[state_col] = 1
            prediction = model.predict(input_data)[0]
            st.success(f"Szacowany czas dostawy: **{prediction:.1f} dni**")

st.sidebar.markdown("---")
st.sidebar.download_button(
    label="📄 Pobierz Raport PDF",
    data=open(os.path.join(RESULTS_DIR, 'Olist_Executive_Summary.pdf'), "rb") if os.path.exists(os.path.join(RESULTS_DIR, 'Olist_Executive_Summary.pdf')) else b"",
    file_name="Olist_Executive_Summary.pdf",
    mime="application/pdf",
    disabled=not os.path.exists(os.path.join(RESULTS_DIR, 'Olist_Executive_Summary.pdf'))
)
