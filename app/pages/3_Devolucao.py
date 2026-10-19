import streamlit as st

from armario_tablets.views import return_view

st.set_page_config(page_title="Devolução", layout="wide")
return_view.render()
