import streamlit as st

from armario_tablets.views import professors_view

st.set_page_config(page_title="Professores", layout="wide")
professors_view.render()
