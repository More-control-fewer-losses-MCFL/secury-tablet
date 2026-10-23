"""View Devolução — conciliação de tablets devolvidos."""

from __future__ import annotations

import uuid

import streamlit as st

from armario_tablets.config import get_settings
from armario_tablets.models import ItemStatus
from armario_tablets.views.common import (
    friendly_error,
    record_database_status,
    services_scope,
)
from armario_tablets.views.theme import (
    page_header,
    render_sidebar_status,
    render_simulation_warning,
)


def render() -> None:
    settings = get_settings()
    simulated = settings.hardware_simulated

    render_sidebar_status(simulated=simulated, api_ok=st.session_state.get("database_connected"))
    page_header(
        "Devolução",
        "Concilie o que voltou ao armário, tablet a tablet.",
    )

    if simulated:
        render_simulation_warning()

    # ── Dados ────────────────────────────────────────────────────────
    try:
        with services_scope() as services:
            pending = services.returns.pending_returns()
            in_cabinet = services.tablets.list_available()
        record_database_status(True)
    except Exception as err:
        st.error(friendly_error(err))
        record_database_status(False)
        return

    if not pending:
        st.markdown(
            '<div class="sc-card"><div class="sc-card-header">'
            "<h3>📥 Devoluções Pendentes</h3></div></div>",
            unsafe_allow_html=True,
        )
        st.success("Nenhuma devolução pendente no momento.", icon=":material/check_circle:")
        return

    # ── Seleção da solicitação ───────────────────────────────────────
    st.markdown(
        '<div class="sc-card"><div class="sc-card-header">'
        "<h3>📥 Selecionar Solicitação</h3></div></div>",
        unsafe_allow_html=True,
    )

    labels = {
        f"#{p.session_id} — {p.professor_name} ({p.pending_quantity} pendente(s))": p
        for p in pending
    }
    chosen_label = st.selectbox("Solicitação com devolução pendente", list(labels))
    chosen = labels[chosen_label]

    # Tablets esperados
    expected = [i.asset_code for i in chosen.items if i.status == ItemStatus.ACTIVE]

    st.markdown(
        '<div class="sc-card"><div class="sc-card-header">'
        "<h3>📋 Detalhes da Devolução</h3></div></div>",
        unsafe_allow_html=True,
    )

    col1, col2 = st.columns(2)
    col1.metric("Professor", chosen.professor_name)
    col2.metric("Tablets pendentes", chosen.pending_quantity)

    st.write("**Tablets esperados:**", ", ".join(expected) if expected else "—")

    if chosen.divergence:
        st.warning(f"⚠️ {chosen.divergence}")

    # ── Simulação de devolução ───────────────────────────────────────
    st.divider()
    st.caption(
        "⚠️ Simulação: selecione os tablets que foram colocados de volta no armário. "
        "Em produção, a leitura RFID será automática."
    )

    returned = st.multiselect("Tablets devolvidos (simulação)", expected)

    if st.button("Ler inventário e conciliar (simulado)", type="primary", width="stretch"):
        # Montar conjunto de tags presentes
        with services_scope() as services:
            all_tablets = services.tablets.list_all()

        codes_to_tags = {t.asset_code: t.rfid_tag_uid for t in all_tablets if t.rfid_tag_uid}
        present = {t.rfid_tag_uid for t in in_cabinet} | {
            codes_to_tags[c] for c in returned if c in codes_to_tags
        }

        try:
            with services_scope() as services:
                result = services.returns.reconcile(
                    chosen.session_id,
                    uuid.uuid4().hex,
                    present,
                    source="simulation",
                )
        except Exception as err:
            st.error(friendly_error(err))
            return

        if result.pending_quantity:
            st.warning(
                f"⚠️ Devolução parcial: ainda {result.pending_quantity} tablet(s) pendente(s). "
                f"{result.divergence or ''}"
            )
        else:
            st.success("✅ Todos os tablets foram devolvidos com sucesso!")
