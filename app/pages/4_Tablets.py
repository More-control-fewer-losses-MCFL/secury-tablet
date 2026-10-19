import streamlit as st

from armario_tablets.views import tablets_view

st.set_page_config(page_title="Tablets", layout="wide")
tablets_view.render()
