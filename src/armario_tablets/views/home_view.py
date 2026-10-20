import streamlit as st

from armario_tablets.config import get_settings
from armario_tablets.views.theme import page_header, render_sidebar_profile

_SHORTCUTS = [
    ("Dashboard", "Visão semanal da agenda, ocupação e divergências dos tablets."),
    ("Solicitar tablets", "Validar o crachá, destravar o armário e registrar a retirada."),
    ("Devolução", "Conferir tablet a tablet o que voltou ao armário."),
    ("Tablets e Professores", "Cadastros de crachás RFID e patrimônios."),
    ("Histórico", "Retiradas anteriores com filtros e exportação."),
]


def render() -> None:
    render_sidebar_profile()
    simulated = get_settings().hardware_simulated
    page_header(
        "Armário Inteligente de Tablets",
        "Retirada e devolução de tablets por professores identificados por crachá RFID.",
        chip="Hardware Simulado Ativo" if simulated else None,
    )
    if simulated:
        st.info(
            "Leitores RFID e fechadura estão em modo simulado. "
            "Nenhuma fechadura física será acionada.",
            icon=":material/info:",
        )
    else:
        st.warning("HARDWARE_SIMULATED=false, mas não há adaptador de hardware real implementado.")

    cards = "".join(f"<div><b>{title}</b><span>{text}</span></div>" for title, text in _SHORTCUTS)
    st.markdown(f'<div class="sc-home">{cards}</div>', unsafe_allow_html=True)
    st.write("")
    st.caption("Acesse a Agenda do Armário, Retiradas e Devoluções pelo menu lateral.")
