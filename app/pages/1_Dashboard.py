import streamlit as st

from armario_tablets.views import dashboard_view

st.set_page_config(page_title="Dashboard", layout="wide")
dashboard_view.render()
