"""View Professores — listagem, pesquisa e filtros."""

from __future__ import annotations

import streamlit as st

from armario_tablets.config import get_settings
from armario_tablets.views.common import (
    friendly_error,
    record_database_status,
    services_scope,
)
from armario_tablets.views.components import professor_table_data
from armario_tablets.views.theme import (
    page_header,
    render_sidebar_status,
)


def render() -> None:
    settings = get_settings()
    simulated = settings.hardware_simulated
    render_sidebar_status(simulated=simulated, api_ok=st.session_state.get("database_connected"))

    page_header(
        "Professores",
        "Cadastro de professores e crachás RFID. O UID do crachá aparece mascarado por segurança.",
    )

    # ── Filtros ──────────────────────────────────────────────────────
    col_search, col_status, _ = st.columns([2, 1, 3])
    search = col_search.text_input(
        "Buscar por nome ou matrícula",
        placeholder="Digite para buscar…",
    )
    status_filter = col_status.selectbox("Situação", ["Todos", "Ativos", "Inativos"])

    # ── Dados ────────────────────────────────────────────────────────
    try:
        with services_scope() as services:
            professors = services.professors.list_all()
        record_database_status(True)
    except Exception as err:
        st.error(friendly_error(err))
        record_database_status(False)
        return

    # Filtros em memória
    if status_filter == "Ativos":
        professors = [p for p in professors if p.active]
    elif status_filter == "Inativos":
        professors = [p for p in professors if not p.active]

    search_terms = [
        term.strip().casefold()
        for term in (search, st.session_state.get("global_search", ""))
        if term.strip()
    ]
    if search_terms:
        professors = [
            p
            for p in professors
            if all(
                any(term in value.casefold() for value in (p.name, p.registration, p.badge_uid))
                for term in search_terms
            )
        ]

    # ── Métricas rápidas ─────────────────────────────────────────────
    col1, col2, col3 = st.columns(3)
    total = len(professors)
    ativos = sum(1 for p in professors if p.active)
    col1.metric("Total", total)
    col2.metric("Ativos", ativos)
    col3.metric("Inativos", total - ativos)

    # ── Tabela ───────────────────────────────────────────────────────
    st.markdown(
        '<div class="sc-card"><div class="sc-card-header">'
        "<h3>👥 Professores Cadastrados</h3></div></div>",
        unsafe_allow_html=True,
    )
    data = professor_table_data(professors)
    if data:
        st.dataframe(data, hide_index=True, width="stretch")
    else:
        st.info("Nenhum professor encontrado com os filtros selecionados.")

    st.caption(
        "ℹ️ O cadastro e edição de professores são gerenciados pela API do sistema. "
        "Caso precise adicionar ou alterar um registro, utilize o endpoint REST "
        "ou o banco de dados."
    )
