import streamlit as st

from armario_tablets.config import get_settings

st.set_page_config(page_title="Armário de Tablets", page_icon="🗄️", layout="wide")

st.title("Armário Inteligente de Tablets")
st.write(
    "Controle de retirada e devolução de tablets por professores identificados por crachá RFID. "
    "Use o menu lateral para navegar."
)

if get_settings().hardware_simulated:
    st.info(
        "Hardware **simulado**: leitores e fechadura são de mentira. "
        "Nenhuma fechadura real será acionada."
    )
else:
    st.warning("HARDWARE_SIMULATED=false, mas não há adaptador de hardware real implementado.")

st.markdown(
    """
1. **Dashboard** — disponibilidade e divergências
2. **Solicitar Tablets** — validar crachá, destravar e simular a retirada
3. **Devolução** — conciliar tablet a tablet
4. **Tablets** e 5. **Professores** — cadastros
6. **Histórico** — retiradas anteriores
"""
)
