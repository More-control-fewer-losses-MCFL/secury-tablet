"""Ponto de entrada da aplicação Streamlit — Tablet de Segurança."""
import streamlit as st

from armario_tablets.views.theme import apply_theme

st.set_page_config(
    page_title="Tablet de Segurança",
    page_icon="🛡️",
    layout="wide",
)
apply_theme()

navigation = st.navigation(
    [
        st.Page("pages/0_Inicio.py", title="Início", icon=":material/home:", default=True),
        st.Page("pages/1_Dashboard.py", title="Dashboard", icon=":material/dashboard:"),
        st.Page("pages/2_Solicitar_Tablets.py", title="Solicitar Tablets", icon=":material/lock_open:"),
        st.Page("pages/3_Devolucao.py", title="Devolução", icon=":material/assignment_return:"),
        st.Page("pages/4_Tablets.py", title="Tablets", icon=":material/tablet_mac:"),
        st.Page("pages/5_Professores.py", title="Professores", icon=":material/badge:"),
        st.Page("pages/6_Historico.py", title="Histórico", icon=":material/history:"),
        st.Page("pages/7_Configuracoes.py", title="Configurações", icon=":material/settings:"),
    ]
)
navigation.run()
