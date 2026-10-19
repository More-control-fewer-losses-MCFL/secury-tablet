import streamlit as st

from armario_tablets.views import checkout_view

st.set_page_config(page_title="Solicitar tablets", layout="wide")
checkout_view.render()
