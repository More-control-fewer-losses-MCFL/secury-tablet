import streamlit as st

from armario_tablets.views import history_view

st.set_page_config(page_title="Histórico", layout="wide")
history_view.render()
