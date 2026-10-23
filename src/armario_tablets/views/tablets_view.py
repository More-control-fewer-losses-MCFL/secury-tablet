"""View Tablets — inventário e situação de cada tablet."""

from __future__ import annotations

import streamlit as st

from armario_tablets.config import get_settings
from armario_tablets.views.common import (
    friendly_error,
    record_database_status,
    services_scope,
)
from armario_tablets.views.components import tablet_table_data
from armario_tablets.views.theme import (
    page_header,
    render_sidebar_status,
    tablet_grid,
)


def render() -> None:
    settings = get_settings()
    simulated = settings.hardware_simulated
    render_sidebar_status(simulated=simulated, api_ok=st.session_state.get("database_connected"))

    page_header(
        "Tablets",
        "Patrimônio e situação de cada tablet do armário.",
    )

    # ── Filtros ──────────────────────────────────────────────────────
    col_filter, col_search, _ = st.columns([1, 2, 3])
    status_options = ["Todas", "AVAILABLE", "CHECKED_OUT", "MAINTENANCE"]
    status = col_filter.selectbox("Situação", status_options)
    search = col_search.text_input("Buscar por patrimônio", placeholder="Ex: TAB-001")

    # ── Dados ────────────────────────────────────────────────────────
    try:
        with services_scope() as services:
            tablets = services.tablets.list_all(None if status == "Todas" else status)
        record_database_status(True)
    except Exception as err:
        st.error(friendly_error(err))
        record_database_status(False)
        return

    # Filtro de busca por texto
    search_terms = [
        term.strip().casefold()
        for term in (search, st.session_state.get("global_search", ""))
        if term.strip()
    ]
    if search_terms:
        tablets = [
            tablet
            for tablet in tablets
            if all(term in tablet.asset_code.casefold() for term in search_terms)
        ]

    # ── Grid visual ──────────────────────────────────────────────────
    st.markdown(
        '<div class="sc-card"><div class="sc-card-header">'
        f"<h3>📱 {len(tablets)} tablet(s) encontrado(s)</h3></div></div>",
        unsafe_allow_html=True,
    )
    tablet_grid((t.asset_code, t.status) for t in tablets)

    # ── Tabela detalhada ─────────────────────────────────────────────
    st.markdown("<br>", unsafe_allow_html=True)
    st.markdown(
        '<div class="sc-card"><div class="sc-card-header">'
        "<h3>📋 Detalhes dos Tablets</h3></div></div>",
        unsafe_allow_html=True,
    )
    data = tablet_table_data(tablets)
    if data:
        st.dataframe(data, hide_index=True, width="stretch")
    else:
        st.info("Nenhum tablet encontrado com os filtros selecionados.")
